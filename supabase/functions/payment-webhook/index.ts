// Supabase Edge Function: payment-webhook
// Secure Multi-Gateway Webhook Processor (Zero-Secret Client Architecture)
// Deno TypeScript Runtime for Supabase Functions

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts";

const REPLAY_TOLERANCE_SECONDS = 300; // 5-minute replay window tolerance

// Helper: Timing-safe comparison to prevent side-channel timing attacks
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

// Helper: Compute SHA-512 hex digest
async function sha512Hex(message: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  const hashBuffer = await crypto.subtle.digest("SHA-512", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padLeft(2, "0")).join("");
}

// Helper: Compute HMAC-SHA256 hex digest
async function hmacSha256Hex(secret: string, message: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(message));
  const hashArray = Array.from(new Uint8Array(signature));
  return hashArray.map((b) => b.toString(16).padLeft(2, "0")).join("");
}

serve(async (req: Request) => {
  // Only accept HTTP POST from authorized gateway webhooks
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    // 1. Fetch server secrets from Supabase Vault / Environment Secrets
    // Note: NEVER stored or exposed in Flutter client binary code!
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const midtransServerKey = Deno.env.get("MIDTRANS_SERVER_KEY") || "";
    const webhookSecret = Deno.env.get("PAYMENT_WEBHOOK_SECRET") || "";
    const xenditWebhookToken = Deno.env.get("XENDIT_WEBHOOK_TOKEN") || "";

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration missing (Supabase credentials)" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Read payload body
    const rawBody = await req.text();
    let payload: Record<string, any>;
    try {
      payload = JSON.parse(rawBody);
    } catch (_) {
      return new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Replay Protection: 5-minute timestamp tolerance
    const eventTimeStr =
      payload.transaction_time ||
      payload.settlement_time ||
      payload.created_at ||
      req.headers.get("x-webhook-timestamp");

    if (eventTimeStr) {
      const eventTime = new Date(eventTimeStr).getTime();
      const now = Date.now();
      const diffSeconds = Math.abs(now - eventTime) / 1000;
      if (diffSeconds > REPLAY_TOLERANCE_SECONDS) {
        return new Response(
          JSON.stringify({
            error: "Replay attack prevented: Event timestamp older than 300 seconds",
            diff_seconds: diffSeconds,
          }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }
    }

    // 3. Cryptographic Signature & Token Verification
    const orderId = payload.order_id || payload.external_id || payload.orderId;
    const statusCode = payload.status_code || payload.statusCode || "200";
    const grossAmount = payload.gross_amount || payload.grossAmount || payload.amount;
    const signatureKey = payload.signature_key || req.headers.get("x-signature-key");

    let isVerified = false;

    // A. Midtrans SHA-512 Verification: SHA512(order_id + status_code + gross_amount + ServerKey)
    if (signatureKey && midtransServerKey) {
      const expectedDigest = await sha512Hex(
        `${orderId}${statusCode}${grossAmount}${midtransServerKey}`
      );
      if (timingSafeEqual(signatureKey.toLowerCase(), expectedDigest.toLowerCase())) {
        isVerified = true;
      }
    }

    // B. Xendit Verification: x-callback-token header validation
    const xenditHeaderToken = req.headers.get("x-callback-token");
    if (!isVerified && xenditHeaderToken && xenditWebhookToken) {
      if (timingSafeEqual(xenditHeaderToken, xenditWebhookToken)) {
        isVerified = true;
      }
    }

    // C. Generic HMAC-SHA256 Header Verification (e.g. Custom Webhooks)
    const hmacHeader = req.headers.get("x-callback-signature") || req.headers.get("x-astrack-signature");
    if (!isVerified && hmacHeader && webhookSecret) {
      const expectedHmac = await hmacSha256Hex(webhookSecret, rawBody);
      if (timingSafeEqual(hmacHeader, expectedHmac)) {
        isVerified = true;
      }
    }

    // D. Sandbox / Development Fallback with configured test environment
    const isDevelopment = Deno.env.get("ENVIRONMENT") === "development";
    if (!isVerified && isDevelopment && payload.provider === "sandbox") {
      isVerified = true;
    }

    if (!isVerified) {
      return new Response(
        JSON.stringify({ error: "Cryptographic signature or token verification failed" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // 4. Idempotency Check via public.payment_webhook_events
    const eventId =
      payload.id ||
      payload.transaction_id ||
      `evt_${orderId}_${payload.transaction_status || "success"}`;

    const { data: existingEvent } = await supabaseAdmin
      .from("payment_webhook_events")
      .select("event_id, processed_at")
      .eq("event_id", eventId)
      .maybeSingle();

    if (existingEvent) {
      // Idempotent duplicate: gracefully return 200 without duplicate billing/mutation
      return new Response(
        JSON.stringify({
          status: "idempotent_duplicate",
          message: "Event already processed previously",
          event_id: eventId,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 5. Record event in payment_webhook_events
    await supabaseAdmin.from("payment_webhook_events").insert({
      event_id: eventId,
      provider: payload.provider || (payload.signature_key ? "midtrans" : "xendit"),
      order_id: orderId,
      payload: payload,
      processed_at: new Date().toISOString(),
    });

    // 6. Process Order Status Update & Subscription Activation
    const transactionStatus = (payload.transaction_status || "").toLowerCase();
    const isPaid =
      transactionStatus === "settlement" ||
      transactionStatus === "capture" ||
      transactionStatus === "paid" ||
      payload.status === "COMPLETED";

    if (isPaid && orderId) {
      // Fetch order from payment_orders to validate pending status & exact amount
      const { data: orderData, error: orderErr } = await supabaseAdmin
        .from("payment_orders")
        .select("order_id, user_id, plan_id, final_amount, status")
        .eq("order_id", orderId)
        .maybeSingle();

      if (orderErr || !orderData) {
        return new Response(
          JSON.stringify({ error: "Order not found in database", order_id: orderId }),
          { status: 404, headers: { "Content-Type": "application/json" } }
        );
      }

      // Ensure order status is currently pending before transitioning to approved
      if (orderData.status !== "pending") {
        if (orderData.status === "approved") {
          return new Response(
            JSON.stringify({
              status: "already_approved",
              message: "Order already approved previously",
              order_id: orderId,
            }),
            { status: 200, headers: { "Content-Type": "application/json" } }
          );
        } else {
          return new Response(
            JSON.stringify({
              error: `Invalid order state transition: current status is '${orderData.status}'`,
              order_id: orderId,
            }),
            { status: 400, headers: { "Content-Type": "application/json" } }
          );
        }
      }

      // Validate payment gross_amount matches order final_amount
      const paidAmount = Number(grossAmount);
      const expectedAmount = Number(orderData.final_amount);
      if (isNaN(paidAmount) || Math.abs(paidAmount - expectedAmount) > 0.01) {
        return new Response(
          JSON.stringify({
            error: "Payment gross_amount mismatch with order final_amount",
            paid_amount: paidAmount,
            expected_amount: expectedAmount,
            order_id: orderId,
          }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }

      // Update order status to approved in payment_orders
      await supabaseAdmin
        .from("payment_orders")
        .update({
          status: "approved",
          updated_at: new Date().toISOString(),
        })
        .eq("order_id", orderId);

      // Determine active plan duration dynamically from plans table
      let durationDays = 30; // fallback default
      if (orderData.plan_id) {
        const { data: planData } = await supabaseAdmin
          .from("plans")
          .select("duration_days, billing_cycle")
          .eq("id", orderData.plan_id)
          .maybeSingle();

        if (planData?.duration_days && Number(planData.duration_days) > 0) {
          durationDays = Number(planData.duration_days);
        } else if (
          planData?.billing_cycle === "yearly" ||
          planData?.billing_cycle === "tahunan"
        ) {
          durationDays = 365;
        }
      }

      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + durationDays);

      await supabaseAdmin.from("subscriptions").upsert({
        user_id: orderData.user_id,
        plan_id: orderData.plan_id,
        status: "active",
        starts_at: new Date().toISOString(),
        expires_at: expiresAt.toISOString(),
        updated_at: new Date().toISOString(),
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        event_id: eventId,
        order_id: orderId,
        is_paid: isPaid,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: "Internal webhook processor error", details: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
