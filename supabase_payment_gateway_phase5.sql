-- =================================================================================
-- ASTRACK — PHASE 5: AUTOMATIC PAYMENT GATEWAY ARCHITECTURE (SUPABASE POSTGRESQL)
-- [SAFE MIGRATION - NO DESTRUCTIVE DROPS OF TABLES/DATA]
-- =================================================================================

-- 1. PAYMENT GATEWAY SETTINGS TABLE (SERVER-AUTHORITATIVE FEATURE FLAGS)
CREATE TABLE IF NOT EXISTS public.payment_gateway_settings (
  id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  payment_mode TEXT NOT NULL DEFAULT 'hybrid' CHECK (payment_mode IN ('manual_qris', 'gateway', 'hybrid')),
  active_provider TEXT NOT NULL DEFAULT 'sandbox' CHECK (active_provider IN ('sandbox', 'midtrans', 'xendit', 'stripe')),
  is_sandbox BOOLEAN NOT NULL DEFAULT true,
  webhook_secret TEXT DEFAULT 'astrack_webhook_secret_default',
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_by UUID REFERENCES auth.users(id)
);

-- Seed initial configuration if not present
INSERT INTO public.payment_gateway_settings (id, payment_mode, active_provider, is_sandbox)
VALUES (1, 'hybrid', 'sandbox', true)
ON CONFLICT (id) DO NOTHING;

-- 2. ENSURE PAYMENT WEBHOOK EVENTS TABLE FOR REPLAY & IDEMPOTENCY
CREATE TABLE IF NOT EXISTS public.payment_webhook_events (
  event_id TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  order_id TEXT,
  status TEXT,
  payload JSONB DEFAULT '{}'::jsonb,
  processed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_webhook_events_order ON public.payment_webhook_events(order_id);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processed ON public.payment_webhook_events(processed_at);

-- 3. RPC: GET PAYMENT GATEWAY CONFIG (READABLE BY AUTHENTICATED USERS)
CREATE OR REPLACE FUNCTION public.get_payment_gateway_config()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg RECORD;
BEGIN
  SELECT * INTO v_cfg FROM public.payment_gateway_settings WHERE id = 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'payment_mode', 'hybrid',
      'active_provider', 'sandbox',
      'is_sandbox', true,
      'updated_at', now()
    );
  END IF;

  RETURN jsonb_build_object(
    'payment_mode', v_cfg.payment_mode,
    'active_provider', v_cfg.active_provider,
    'is_sandbox', v_cfg.is_sandbox,
    'updated_at', v_cfg.updated_at
  );
END;
$$;

-- 4. RPC: ADMIN UPDATE PAYMENT GATEWAY CONFIG (RESTRICTED TO ADMIN)
CREATE OR REPLACE FUNCTION public.admin_update_payment_gateway_config(
  p_payment_mode TEXT,
  p_active_provider TEXT,
  p_is_sandbox BOOLEAN,
  p_webhook_secret TEXT DEFAULT NULL,
  p_admin_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin UUID := coalesce(auth.uid(), p_admin_id);
  v_now TIMESTAMPTZ := now();
BEGIN
  IF v_admin IS NOT NULL AND NOT public.is_admin(v_admin) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Hanya Administrator yang berwenang mengubah konfigurasi payment gateway.');
  END IF;

  IF p_payment_mode NOT IN ('manual_qris', 'gateway', 'hybrid') THEN
    RETURN jsonb_build_object('success', false, 'error', 'payment_mode tidak valid.');
  END IF;

  IF p_active_provider NOT IN ('sandbox', 'midtrans', 'xendit', 'stripe') THEN
    RETURN jsonb_build_object('success', false, 'error', 'active_provider tidak valid.');
  END IF;

  UPDATE public.payment_gateway_settings
  SET payment_mode = p_payment_mode,
      active_provider = p_active_provider,
      is_sandbox = p_is_sandbox,
      webhook_secret = coalesce(p_webhook_secret, webhook_secret),
      updated_at = v_now,
      updated_by = v_admin
  WHERE id = 1;

  INSERT INTO public.payment_events (order_id, event_type, actor_id, payload)
  VALUES (
    'CONFIG_UPDATE', 'GATEWAY_CONFIG_UPDATED', v_admin,
    jsonb_build_object('payment_mode', p_payment_mode, 'active_provider', p_active_provider, 'is_sandbox', p_is_sandbox)
  );

  RETURN jsonb_build_object(
    'success', true,
    'payment_mode', p_payment_mode,
    'active_provider', p_active_provider,
    'is_sandbox', p_is_sandbox,
    'updated_at', v_now
  );
END;
$$;

-- 5. RPC: PROCESS PAYMENT WEBHOOK (IDEMPOTENT & AUTO-ACTIVATE SUBSCRIPTION)
CREATE OR REPLACE FUNCTION public.process_payment_webhook(
  p_provider TEXT,
  p_order_id TEXT,
  p_event_id TEXT,
  p_status TEXT,
  p_gross_amount NUMERIC,
  p_payload JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order RECORD;
  v_plan RECORD;
  v_current_sub RECORD;
  v_now TIMESTAMPTZ := now();
  v_new_start TIMESTAMPTZ;
  v_new_end TIMESTAMPTZ;
  v_duration_months INTEGER;
  v_days_to_add INTEGER;
BEGIN
  -- 1. Persistent Idempotency Check: if event already processed, exit gracefully
  IF EXISTS (SELECT 1 FROM public.payment_webhook_events WHERE event_id = p_event_id) THEN
    RETURN jsonb_build_object(
      'success', true,
      'is_duplicate', true,
      'message', 'Event webhook sudah pernah diproses (idempotent duplicate).'
    );
  END IF;

  -- 2. Fetch and lock order
  SELECT * INTO v_order FROM public.payment_orders WHERE order_id = p_order_id FOR UPDATE;
  IF NOT FOUND THEN
    -- Record orphan webhook log
    INSERT INTO public.payment_webhook_events (event_id, provider, order_id, status, payload, processed_at)
    VALUES (p_event_id, p_provider, p_order_id, p_status, p_payload, v_now);

    RETURN jsonb_build_object('success', false, 'error', 'Order tidak ditemukan.');
  END IF;

  -- 3. Anti-Tampering Check: Gross Amount Match
  IF abs(v_order.final_amount - p_gross_amount) > 0.01 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Anti-tampering alert: Nominal webhook tidak cocok dengan pesanan.'
    );
  END IF;

  -- 4. Status Transition Handling
  IF p_status IN ('paid', 'settlement', 'capture') THEN
    IF v_order.status <> 'paid' THEN
      -- Fetch plan details
      SELECT * INTO v_plan FROM public.plans WHERE id = v_order.plan_id;
      v_duration_months := coalesce(v_plan.duration_months, 1);
      v_days_to_add := CASE WHEN v_duration_months >= 120 THEN 3650 ELSE (v_duration_months * 30) END;

      -- Check current subscription for Idempotent Extension
      SELECT * INTO v_current_sub
      FROM public.subscriptions
      WHERE user_id = v_order.user_id AND status = 'active'
      ORDER BY expires_at DESC
      LIMIT 1;

      IF FOUND AND v_current_sub.expires_at > v_now THEN
        v_new_start := v_current_sub.expires_at;
        v_new_end := v_current_sub.expires_at + (v_days_to_add || ' days')::interval;
      ELSE
        v_new_start := v_now;
        v_new_end := v_now + (v_days_to_add || ' days')::interval;
      END IF;

      -- Activate subscription
      INSERT INTO public.subscriptions (
        user_id, plan_id, status, starts_at, expires_at, paid_amount, order_id
      ) VALUES (
        v_order.user_id, v_order.plan_id, 'active', v_new_start, v_new_end, v_order.final_amount, v_order.order_id
      );

      -- Redeem coupon if any
      IF v_order.coupon_code IS NOT NULL AND trim(v_order.coupon_code) <> '' THEN
        PERFORM public.redeem_coupon_order(v_order.coupon_code, v_order.plan_id, v_order.user_id, v_order.order_id);
      END IF;

      -- Mark order as paid
      UPDATE public.payment_orders
      SET status = 'paid',
          verified_at = v_now,
          updated_at = v_now
      WHERE order_id = p_order_id;
    END IF;

  ELSIF p_status IN ('cancel', 'deny', 'failed') THEN
    UPDATE public.payment_orders
    SET status = 'failed', updated_at = v_now
    WHERE order_id = p_order_id;

  ELSIF p_status IN ('expire', 'expired') THEN
    UPDATE public.payment_orders
    SET status = 'expired', updated_at = v_now
    WHERE order_id = p_order_id;
  END IF;

  -- 5. Record Webhook Event for Persistent Idempotency
  INSERT INTO public.payment_webhook_events (
    event_id, provider, order_id, status, payload, processed_at
  ) VALUES (
    p_event_id, p_provider, p_order_id, p_status, p_payload, v_now
  );

  -- 6. Log Audit Event
  INSERT INTO public.payment_events (order_id, event_type, actor_id, payload)
  VALUES (
    p_order_id, 'WEBHOOK_PROCESSED', NULL,
    jsonb_build_object('provider', p_provider, 'event_id', p_event_id, 'status', p_status, 'amount', p_gross_amount)
  );

  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'status', p_status,
    'is_duplicate', false,
    'subscription_activated', p_status IN ('paid', 'settlement', 'capture')
  );
END;
$$;

-- 6. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.payment_gateway_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_webhook_events ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- Anyone authenticated can view gateway settings
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_gateway_settings' AND policyname = 'Anyone view gateway settings') THEN
    CREATE POLICY "Anyone view gateway settings" ON public.payment_gateway_settings FOR SELECT USING (true);
  END IF;

  -- Only admins can update gateway settings
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_gateway_settings' AND policyname = 'Admins update gateway settings') THEN
    CREATE POLICY "Admins update gateway settings" ON public.payment_gateway_settings FOR ALL USING (public.is_admin(auth.uid()));
  END IF;

  -- Webhook events: admins can view
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_webhook_events' AND policyname = 'Admins view webhook events') THEN
    CREATE POLICY "Admins view webhook events" ON public.payment_webhook_events FOR SELECT USING (public.is_admin(auth.uid()));
  END IF;
END $$;
