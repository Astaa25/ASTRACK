-- =================================================================================
-- ASTRACK — PHASE 4: MONETIZATION, MANUAL QRIS & DYNAMIC PRICING (SUPABASE POSTGRESQL)
-- [SAFE MIGRATION - NO DESTRUCTIVE DROPS OF TABLES/DATA]
-- =================================================================================

-- 0. ADMIN ROLE CHECK HELPER (Matches public.user_roles)
CREATE OR REPLACE FUNCTION public.is_admin(uid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF uid IS NULL THEN
    RETURN FALSE;
  END IF;
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = uid AND role_id = 'admin'
  );
END;
$$;

-- 1. PAYMENT ORDERS TABLE
CREATE TABLE IF NOT EXISTS public.payment_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT UNIQUE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_id TEXT REFERENCES public.plans(id) NOT NULL,
  base_amount NUMERIC NOT NULL CHECK (base_amount >= 0),
  discount_amount NUMERIC DEFAULT 0 CHECK (discount_amount >= 0),
  unique_code INTEGER NOT NULL CHECK (unique_code BETWEEN 1 AND 999),
  final_amount NUMERIC NOT NULL CHECK (final_amount > 0),
  currency TEXT DEFAULT 'IDR' NOT NULL,
  payment_method TEXT DEFAULT 'manual_qris' NOT NULL,
  status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'claimed', 'paid', 'rejected', 'expired')),
  coupon_code TEXT,
  rejection_reason TEXT,
  qris_payload TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  claimed_at TIMESTAMPTZ,
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_payment_orders_user ON public.payment_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_orders_status ON public.payment_orders(status);
CREATE INDEX IF NOT EXISTS idx_payment_orders_created ON public.payment_orders(created_at);

-- 2. PAYMENT PROOFS TABLE
CREATE TABLE IF NOT EXISTS public.payment_proofs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT REFERENCES public.payment_orders(order_id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  proof_url TEXT NOT NULL,
  notes TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_payment_proofs_order ON public.payment_proofs(order_id);

-- 3. PAYMENT EVENTS TABLE (AUDIT TRAIL)
CREATE TABLE IF NOT EXISTS public.payment_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  actor_id UUID REFERENCES auth.users(id),
  payload JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_payment_events_order ON public.payment_events(order_id);

-- 4. DETERMINISTIC DAILY UNIQUE CODE GENERATOR (ASIA/JAKARTA RESET)
-- Generates unique code between 001-999 for today without collisions among active pending orders
CREATE OR REPLACE FUNCTION public.generate_daily_unique_code(p_date_tz DATE DEFAULT (now() AT TIME ZONE 'Asia/Jakarta')::date)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code INTEGER;
  v_exists BOOLEAN;
  v_attempts INTEGER := 0;
BEGIN
  LOOP
    -- Calculate pseudo-random or incremental code based on existing active orders today
    SELECT COALESCE(MAX(unique_code), 0) + 1 INTO v_code
    FROM public.payment_orders
    WHERE (created_at AT TIME ZONE 'Asia/Jakarta')::date = p_date_tz
      AND status IN ('pending', 'claimed');

    IF v_code > 999 THEN
      -- If overflow, find first available gap from 1 to 999
      FOR v_code IN 1..999 LOOP
        SELECT EXISTS(
          SELECT 1 FROM public.payment_orders
          WHERE (created_at AT TIME ZONE 'Asia/Jakarta')::date = p_date_tz
            AND status IN ('pending', 'claimed')
            AND unique_code = v_code
        ) INTO v_exists;

        IF NOT v_exists THEN
          EXIT;
        END IF;
      END LOOP;
    END IF;

    -- Ensure within 1..999
    IF v_code < 1 OR v_code > 999 THEN
      v_code := 1;
    END IF;

    RETURN v_code;
  END LOOP;
END;
$$;

-- 5. RPC: CREATE MANUAL QRIS ORDER
CREATE OR REPLACE FUNCTION public.create_manual_qris_order(
  p_plan_id TEXT,
  p_coupon_code TEXT DEFAULT NULL,
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_plan RECORD;
  v_user_id UUID := p_user_id;
  v_base NUMERIC;
  v_discount NUMERIC := 0;
  v_unique_code INTEGER;
  v_final NUMERIC;
  v_order_id TEXT;
  v_now TIMESTAMPTZ := now();
  v_expires_at TIMESTAMPTZ := now() + interval '24 hours';
  v_qris_payload TEXT;
  v_val JSONB;
BEGIN
  IF auth.uid() IS NOT NULL THEN
    v_user_id := auth.uid();
  ELSIF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'User ID wajib disertakan.');
  END IF;

  -- 1. Validate Plan
  SELECT * INTO v_plan FROM public.plans WHERE id = p_plan_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Paket langganan tidak ditemukan.');
  END IF;

  IF v_plan.is_active IS NOT TRUE THEN
    RETURN jsonb_build_object('success', false, 'error', 'Paket langganan sedang tidak aktif.');
  END IF;

  v_base := v_plan.monthly_price;

  -- 2. Validate Coupon if provided
  IF p_coupon_code IS NOT NULL AND trim(p_coupon_code) <> '' THEN
    v_val := public.validate_and_calculate_coupon(p_coupon_code, p_plan_id, v_user_id);
    IF (v_val->>'is_valid')::boolean IS TRUE THEN
      v_discount := (v_val->>'discount_amount')::NUMERIC;
    ELSE
      RETURN jsonb_build_object('success', false, 'error', v_val->>'error_message');
    END IF;
  END IF;

  -- 3. Generate Daily Unique Code with Row Lock to avoid collision
  PERFORM pg_advisory_xact_lock(424242);
  v_unique_code := public.generate_daily_unique_code((v_now AT TIME ZONE 'Asia/Jakarta')::date);

  -- 4. Calculate Final Amount = Base - Discount + Unique Code
  v_final := greatest(v_base - v_discount, 0) + v_unique_code;

  -- 5. Generate Order ID: ORD-QRIS-YYYYMMDD-HHMMSS-RAND
  v_order_id := 'ORD-QRIS-' || to_char(v_now AT TIME ZONE 'Asia/Jakarta', 'YYYYMMDD-HH24MISS') || '-' || lpad(v_unique_code::text, 3, '0');

  -- 6. QRIS Payload String (Standard Indonesian EMVCo Mock/Format)
  v_qris_payload := '00020101021226590014ID.LINKAJA.WWW01189360091800000000000215ID1026001234567520458125303360540' ||
                    length(v_final::text)::text || v_final::text || '5802ID5916ASTRACK OFFICIAL6007JAKARTA6304';

  -- 7. Insert Order
  INSERT INTO public.payment_orders (
    order_id, user_id, plan_id, base_amount, discount_amount, unique_code,
    final_amount, currency, payment_method, status, coupon_code, qris_payload,
    created_at, expires_at
  ) VALUES (
    v_order_id, v_user_id, p_plan_id, v_base, v_discount, v_unique_code,
    v_final, 'IDR', 'manual_qris', 'pending', p_coupon_code, v_qris_payload,
    v_now, v_expires_at
  );

  -- 8. Log Event
  INSERT INTO public.payment_events (order_id, event_type, actor_id, payload)
  VALUES (
    v_order_id, 'ORDER_CREATED', v_user_id,
    jsonb_build_object('plan_id', p_plan_id, 'final_amount', v_final, 'unique_code', v_unique_code)
  );

  RETURN jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'plan_id', p_plan_id,
    'base_amount', v_base,
    'discount_amount', v_discount,
    'unique_code', v_unique_code,
    'final_amount', v_final,
    'qris_payload', v_qris_payload,
    'expires_at', v_expires_at
  );
END;
$$;

-- 6. RPC: USER CLAIMS PAYMENT ("SAYA SUDAH BAYAR")
CREATE OR REPLACE FUNCTION public.claim_payment_order(
  p_order_id TEXT,
  p_proof_url TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order RECORD;
  v_now TIMESTAMPTZ := now();
BEGIN
  SELECT * INTO v_order FROM public.payment_orders WHERE order_id = p_order_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Order tidak ditemukan.');
  END IF;

  -- Verify ownership if authenticated user
  IF auth.uid() IS NOT NULL AND v_order.user_id <> auth.uid() AND NOT public.is_admin(auth.uid()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Akses ditolak: bukan pemilik order.');
  END IF;

  IF v_order.status = 'paid' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Order ini sudah berhasil diverifikasi sebelumnya.');
  END IF;

  IF v_order.status = 'expired' OR v_now > v_order.expires_at THEN
    UPDATE public.payment_orders SET status = 'expired', updated_at = v_now WHERE order_id = p_order_id;
    RETURN jsonb_build_object('success', false, 'error', 'Batas waktu pembayaran untuk order ini telah kedaluwarsa.');
  END IF;

  -- Update order status to claimed
  UPDATE public.payment_orders
  SET status = 'claimed',
      claimed_at = v_now,
      updated_at = v_now
  WHERE order_id = p_order_id;

  -- Insert proof if provided
  IF p_proof_url IS NOT NULL AND trim(p_proof_url) <> '' THEN
    INSERT INTO public.payment_proofs (order_id, user_id, proof_url, notes, uploaded_at)
    VALUES (p_order_id, v_order.user_id, p_proof_url, p_notes, v_now);
  END IF;

  -- Log event
  INSERT INTO public.payment_events (order_id, event_type, actor_id, payload)
  VALUES (
    p_order_id, 'PAYMENT_CLAIMED', coalesce(auth.uid(), v_order.user_id),
    jsonb_build_object('proof_url', p_proof_url, 'notes', p_notes)
  );

  RETURN jsonb_build_object('success', true, 'order_id', p_order_id, 'status', 'claimed');
END;
$$;

-- 7. RPC: ADMIN APPROVE PAYMENT ORDER (IDEMPOTENT EXTENSION)
CREATE OR REPLACE FUNCTION public.admin_approve_payment_order(
  p_order_id TEXT,
  p_admin_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin UUID := coalesce(auth.uid(), p_admin_id);
  v_order RECORD;
  v_plan RECORD;
  v_current_sub RECORD;
  v_now TIMESTAMPTZ := now();
  v_new_start TIMESTAMPTZ;
  v_new_end TIMESTAMPTZ;
  v_duration_months INTEGER;
  v_days_to_add INTEGER;
BEGIN
  -- 1. Check Admin Authorization
  IF v_admin IS NOT NULL AND NOT public.is_admin(v_admin) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Hanya Administrator yang berwenang menyetujui pembayaran.');
  END IF;

  -- 2. Lock and Fetch Order
  SELECT * INTO v_order FROM public.payment_orders WHERE order_id = p_order_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Order tidak ditemukan.');
  END IF;

  IF v_order.status = 'paid' THEN
    RETURN jsonb_build_object('success', true, 'message', 'Order sudah berstatus disetujui sebelumnya.');
  END IF;

  -- 3. Fetch Plan Duration
  SELECT * INTO v_plan FROM public.plans WHERE id = v_order.plan_id;
  v_duration_months := coalesce(v_plan.duration_months, 1);
  v_days_to_add := CASE WHEN v_duration_months >= 120 THEN 3650 ELSE (v_duration_months * 30) END;

  -- 4. Query current user subscription for IDEMPOTENT EXTENSION
  SELECT * INTO v_current_sub
  FROM public.subscriptions
  WHERE user_id = v_order.user_id AND status = 'active'
  ORDER BY expires_at DESC
  LIMIT 1;

  IF FOUND AND v_current_sub.expires_at > v_now THEN
    -- Pro is still active: IDEMPOTENT EXTENSION starts from current_period_end!
    v_new_start := v_current_sub.expires_at;
    v_new_end := v_current_sub.expires_at + (v_days_to_add || ' days')::interval;
  ELSE
    -- No active Pro or expired: starts immediately from now()
    v_new_start := v_now;
    v_new_end := v_now + (v_days_to_add || ' days')::interval;
  END IF;

  -- 5. Record/Extend Subscription
  INSERT INTO public.subscriptions (
    user_id, plan_id, status, starts_at, expires_at, paid_amount, order_id
  ) VALUES (
    v_order.user_id, v_order.plan_id, 'active', v_new_start, v_new_end, v_order.final_amount, v_order.order_id
  );

  -- 6. Redeem Coupon if any
  IF v_order.coupon_code IS NOT NULL AND trim(v_order.coupon_code) <> '' THEN
    PERFORM public.redeem_coupon_order(v_order.coupon_code, v_order.plan_id, v_order.user_id, v_order.order_id);
  END IF;

  -- 7. Update Order status
  UPDATE public.payment_orders
  SET status = 'paid',
      verified_at = v_now,
      verified_by = v_admin,
      updated_at = v_now
  WHERE order_id = p_order_id;

  -- 8. Log Event
  INSERT INTO public.payment_events (order_id, event_type, actor_id, payload)
  VALUES (
    p_order_id, 'ADMIN_APPROVE', v_admin,
    jsonb_build_object('new_start', v_new_start, 'new_end', v_new_end, 'final_amount', v_order.final_amount)
  );

  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'status', 'paid',
    'plan_id', v_order.plan_id,
    'subscription_starts_at', v_new_start,
    'subscription_expires_at', v_new_end
  );
END;
$$;

-- 8. RPC: ADMIN REJECT PAYMENT ORDER (MANDATORY REASON)
CREATE OR REPLACE FUNCTION public.admin_reject_payment_order(
  p_order_id TEXT,
  p_reason TEXT,
  p_admin_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin UUID := coalesce(auth.uid(), p_admin_id);
  v_order RECORD;
  v_now TIMESTAMPTZ := now();
BEGIN
  -- 1. Check Admin Authorization
  IF v_admin IS NOT NULL AND NOT public.is_admin(v_admin) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Hanya Administrator yang berwenang menolak pembayaran.');
  END IF;

  -- 2. Validate Reason
  IF p_reason IS NULL OR length(trim(p_reason)) < 5 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Alasan penolakan wajib diisi minimal 5 karakter.');
  END IF;

  -- 3. Lock and Fetch Order
  SELECT * INTO v_order FROM public.payment_orders WHERE order_id = p_order_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Order tidak ditemukan.');
  END IF;

  IF v_order.status = 'paid' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Order yang sudah disetujui tidak dapat ditolak.');
  END IF;

  -- 4. Update Order
  UPDATE public.payment_orders
  SET status = 'rejected',
      rejection_reason = trim(p_reason),
      verified_at = v_now,
      verified_by = v_admin,
      updated_at = v_now
  WHERE order_id = p_order_id;

  -- 5. Log Event
  INSERT INTO public.payment_events (order_id, event_type, actor_id, payload)
  VALUES (
    p_order_id, 'ADMIN_REJECT', v_admin,
    jsonb_build_object('rejection_reason', trim(p_reason))
  );

  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'status', 'rejected',
    'rejection_reason', trim(p_reason)
  );
END;
$$;

-- 9. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.payment_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_events ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- Payment Orders: Users can view their own orders
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_orders' AND policyname = 'Users view own orders') THEN
    CREATE POLICY "Users view own orders" ON public.payment_orders FOR SELECT USING (auth.uid() = user_id OR public.is_admin(auth.uid()));
  END IF;

  -- Payment Orders: Users can create orders for themselves
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_orders' AND policyname = 'Users insert own orders') THEN
    CREATE POLICY "Users insert own orders" ON public.payment_orders FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  -- Payment Orders: Admins can update orders
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_orders' AND policyname = 'Admins update orders') THEN
    CREATE POLICY "Admins update orders" ON public.payment_orders FOR UPDATE USING (public.is_admin(auth.uid()));
  END IF;

  -- Payment Proofs: Users can view and insert own proofs; Admins can view all
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_proofs' AND policyname = 'Users view own proofs') THEN
    CREATE POLICY "Users view own proofs" ON public.payment_proofs FOR SELECT USING (auth.uid() = user_id OR public.is_admin(auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_proofs' AND policyname = 'Users insert own proofs') THEN
    CREATE POLICY "Users insert own proofs" ON public.payment_proofs FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  -- Payment Events: Admins can view all; Users can view events for their own orders
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_events' AND policyname = 'Events view policy') THEN
    CREATE POLICY "Events view policy" ON public.payment_events FOR SELECT USING (
      public.is_admin(auth.uid()) OR EXISTS (
        SELECT 1 FROM public.payment_orders WHERE payment_orders.order_id = payment_events.order_id AND payment_orders.user_id = auth.uid()
      )
    );
  END IF;
END $$;
