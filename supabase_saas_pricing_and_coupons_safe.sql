-- =================================================================================
-- ASTRACK — PRICING AUDIT & COUPON DISCOUNT SYSTEM (SUPABASE POSTGRESQL)
-- [SAFE MIGRATION - NO DESTRUCTIVE DROPS OF TABLES/DATA]
-- =================================================================================

-- 0. IDEMPOTENT ADMIN VERIFICATION HELPER (Matches existing parameter name 'uid')
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

-- 1. CREATE PLAN PRICE HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.plan_price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id TEXT REFERENCES public.plans(id) ON DELETE CASCADE NOT NULL,
  old_price NUMERIC NOT NULL,
  new_price NUMERIC NOT NULL,
  changed_by UUID REFERENCES auth.users(id),
  changed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_price_history_plan ON public.plan_price_history(plan_id);

-- 1.1 ADD TRANSACTION SNAPSHOT COLUMNS TO SUBSCRIPTIONS (IMMUTABLE PAST TRANSACTIONS)
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS paid_amount NUMERIC DEFAULT 0;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS order_id TEXT;

-- 2. CREATE COUPONS TABLE
CREATE TABLE IF NOT EXISTS public.coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  description TEXT,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value NUMERIC NOT NULL CHECK (discount_value > 0),
  starts_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  expires_at TIMESTAMPTZ,
  usage_limit INTEGER DEFAULT 100,
  usage_count INTEGER DEFAULT 0,
  per_user_limit INTEGER DEFAULT 1,
  minimum_purchase NUMERIC DEFAULT 0,
  applicable_plan_ids TEXT[] DEFAULT ARRAY[]::TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_coupons_code ON public.coupons(code);

-- 3. CREATE COUPON REDEMPTIONS TABLE (USAGE & AUDIT LOG)
CREATE TABLE IF NOT EXISTS public.coupon_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID REFERENCES public.coupons(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  order_id TEXT,
  plan_id TEXT REFERENCES public.plans(id) NOT NULL,
  original_price NUMERIC NOT NULL,
  discount_amount NUMERIC NOT NULL,
  final_price NUMERIC NOT NULL,
  redeemed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_redemptions_user_coupon ON public.coupon_redemptions(user_id, coupon_id);

-- 3.1 CREATE PAYMENT WEBHOOK EVENTS TABLE (PERSISTENT IDEMPOTENCY)
CREATE TABLE IF NOT EXISTS public.payment_webhook_events (
  event_id TEXT PRIMARY KEY,
  provider TEXT,
  order_id TEXT,
  processed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 4. RPC: SERVER-SIDE ATOMIC COUPON VALIDATION & DISCOUNT CALCULATION
CREATE OR REPLACE FUNCTION public.validate_and_calculate_coupon(
  p_coupon_code TEXT,
  p_plan_id TEXT,
  p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_coupon RECORD;
  v_plan RECORD;
  v_user_uses INTEGER;
  v_discount NUMERIC := 0;
  v_final NUMERIC := 0;
  v_clean_code TEXT;
BEGIN
  -- Authoritative user ID override: always prefer auth.uid()
  IF auth.uid() IS NOT NULL THEN
    p_user_id := auth.uid();
  ELSIF current_user NOT IN ('service_role', 'postgres') THEN
    p_user_id := NULL; -- Anonymous cannot spoof another user's identity
  END IF;

  v_clean_code := upper(trim(p_coupon_code));

  -- 1. Fetch Plan
  SELECT * INTO v_plan FROM public.plans WHERE id = p_plan_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('is_valid', false, 'error_message', 'Paket langganan tidak ditemukan.');
  END IF;

  IF v_plan.is_active IS NOT TRUE THEN
    RETURN jsonb_build_object('is_valid', false, 'error_message', 'Paket langganan tidak aktif untuk pembelian baru.');
  END IF;

  -- 2. Fetch Coupon
  SELECT * INTO v_coupon FROM public.coupons WHERE upper(code) = v_clean_code;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('is_valid', false, 'error_message', 'Kode kupon tidak valid.');
  END IF;

  -- 3. Check Active
  IF v_coupon.is_active IS NOT TRUE THEN
    RETURN jsonb_build_object('is_valid', false, 'error_message', 'Kode kupon tidak aktif.');
  END IF;

  -- 4. Check Starts At
  IF now() < v_coupon.starts_at THEN
    RETURN jsonb_build_object('is_valid', false, 'error_message', 'Kode kupon belum dapat digunakan.');
  END IF;

  -- 5. Check Expires At
  IF v_coupon.expires_at IS NOT NULL AND now() > v_coupon.expires_at THEN
    RETURN jsonb_build_object('is_valid', false, 'error_message', 'Kode kupon sudah kedaluwarsa.');
  END IF;

  -- 6. Check Overall Usage Limit
  IF v_coupon.usage_limit > 0 AND v_coupon.usage_count >= v_coupon.usage_limit THEN
    RETURN jsonb_build_object('is_valid', false, 'error_message', 'Kode kupon sudah mencapai batas penggunaan.');
  END IF;

  -- 7. Check Per-User Limit
  IF p_user_id IS NOT NULL THEN
    SELECT count(*) INTO v_user_uses FROM public.coupon_redemptions
    WHERE coupon_id = v_coupon.id AND user_id = p_user_id;

    IF v_coupon.per_user_limit > 0 AND v_user_uses >= v_coupon.per_user_limit THEN
      RETURN jsonb_build_object('is_valid', false, 'error_message', 'Kamu sudah mencapai batas penggunaan kode kupon ini.');
    END IF;
  END IF;

  -- 8. Check Applicable Plan
  IF v_coupon.applicable_plan_ids IS NOT NULL AND array_length(v_coupon.applicable_plan_ids, 1) > 0 THEN
    IF NOT (p_plan_id = ANY(v_coupon.applicable_plan_ids)) THEN
      RETURN jsonb_build_object('is_valid', false, 'error_message', 'Kode kupon tidak berlaku untuk paket ini.');
    END IF;
  END IF;

  -- 9. Check Minimum Purchase
  IF v_coupon.minimum_purchase > 0 AND v_plan.monthly_price < v_coupon.minimum_purchase THEN
    RETURN jsonb_build_object('is_valid', false, 'error_message', 'Minimum pembelian untuk kupon ini belum terpenuhi.');
  END IF;

  -- 10. Calculate Discount
  IF v_coupon.discount_type = 'percentage' THEN
    v_discount := round((v_plan.monthly_price * v_coupon.discount_value / 100.0), 0);
  ELSE
    v_discount := v_coupon.discount_value;
  END IF;

  IF v_discount > v_plan.monthly_price THEN
    v_discount := v_plan.monthly_price;
  END IF;

  v_final := greatest(v_plan.monthly_price - v_discount, 0);

  RETURN jsonb_build_object(
    'is_valid', true,
    'coupon_id', v_coupon.id,
    'code', v_coupon.code,
    'discount_type', v_coupon.discount_type,
    'discount_value', v_coupon.discount_value,
    'original_price', v_plan.monthly_price,
    'discount_amount', v_discount,
    'final_price', v_final
  );
END;
$$;

-- 5. RPC: ATOMIC REDEEM COUPON ON PAYMENT SUCCESS
CREATE OR REPLACE FUNCTION public.redeem_coupon_order(
  p_coupon_code TEXT,
  p_plan_id TEXT,
  p_user_id UUID,
  p_order_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_val JSONB;
  v_coupon_id UUID;
  v_orig NUMERIC;
  v_disc NUMERIC;
  v_final NUMERIC;
BEGIN
  -- Authoritative user ID override: always prefer auth.uid()
  IF auth.uid() IS NOT NULL THEN
    p_user_id := auth.uid();
  ELSIF current_user NOT IN ('service_role', 'postgres') THEN
    RETURN jsonb_build_object('is_valid', false, 'error_message', 'Operasi penukaran kupon memerlukan sesi login yang sah.');
  END IF;

  -- Validate with row lock on coupon table to prevent race conditions
  PERFORM * FROM public.coupons WHERE upper(code) = upper(trim(p_coupon_code)) FOR UPDATE;

  v_val := public.validate_and_calculate_coupon(p_coupon_code, p_plan_id, p_user_id);
  IF (v_val->>'is_valid')::boolean IS NOT TRUE THEN
    RETURN v_val;
  END IF;

  v_coupon_id := (v_val->>'coupon_id')::UUID;
  v_orig := (v_val->>'original_price')::NUMERIC;
  v_disc := (v_val->>'discount_amount')::NUMERIC;
  v_final := (v_val->>'final_price')::NUMERIC;

  -- Increment usage atomically
  UPDATE public.coupons 
  SET usage_count = usage_count + 1, updated_at = now()
  WHERE id = v_coupon_id;

  -- Record redemption log
  INSERT INTO public.coupon_redemptions (
    coupon_id, user_id, order_id, plan_id, original_price, discount_amount, final_price, redeemed_at
  ) VALUES (
    v_coupon_id, p_user_id, p_order_id, p_plan_id, v_orig, v_disc, v_final, now()
  );

  RETURN jsonb_build_object(
    'success', true,
    'final_price', v_final,
    'discount_amount', v_disc
  );
END;
$$;

-- 6. RPC: ADMIN UPDATE PLAN PRICE WITH AUDIT RECORDING
CREATE OR REPLACE FUNCTION public.admin_update_plan_pricing(
  p_plan_id TEXT,
  p_new_price NUMERIC,
  p_name TEXT,
  p_description TEXT,
  p_duration_months INTEGER,
  p_is_recommended BOOLEAN,
  p_is_active BOOLEAN,
  p_admin_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_price NUMERIC;
BEGIN
  -- Authoritative admin ID override if session is authenticated
  IF auth.uid() IS NOT NULL THEN
    p_admin_id := auth.uid();
  END IF;

  IF NOT public.is_admin(p_admin_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Hanya Administrator yang memiliki akses mengubah harga.');
  END IF;

  IF p_new_price < 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Harga tidak boleh negatif.');
  END IF;

  SELECT monthly_price INTO v_old_price FROM public.plans WHERE id = p_plan_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Paket tidak ditemukan.');
  END IF;

  -- If recommended is set to true, reset others to ensure deterministic single best value
  IF p_is_recommended THEN
    UPDATE public.plans SET is_recommended = false WHERE id <> p_plan_id;
  END IF;

  -- Update plan
  UPDATE public.plans SET
    name = COALESCE(p_name, name),
    description = COALESCE(p_description, description),
    monthly_price = p_new_price,
    duration_months = COALESCE(p_duration_months, duration_months),
    is_recommended = p_is_recommended,
    is_active = p_is_active,
    updated_at = now()
  WHERE id = p_plan_id;

  -- Record history if price changed
  IF v_old_price <> p_new_price THEN
    INSERT INTO public.plan_price_history (
      plan_id, old_price, new_price, changed_by, changed_at
    ) VALUES (
      p_plan_id, v_old_price, p_new_price, p_admin_id, now()
    );
  END IF;

  RETURN jsonb_build_object('success', true, 'old_price', v_old_price, 'new_price', p_new_price);
END;
$$;

-- 7. ROW LEVEL SECURITY
ALTER TABLE public.plan_price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payment_webhook_events ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  -- Anyone authenticated can view active coupons
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'coupons' AND policyname = 'Anyone can view active coupons') THEN
    CREATE POLICY "Anyone can view active coupons" ON public.coupons FOR SELECT USING (is_active = true);
  END IF;

  -- Only admins can manage coupons
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'coupons' AND policyname = 'Admins can manage coupons') THEN
    CREATE POLICY "Admins can manage coupons" ON public.coupons FOR ALL USING (public.is_admin(auth.uid()));
  END IF;

  -- Admins can view price history
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'plan_price_history' AND policyname = 'Admins can view price history') THEN
    CREATE POLICY "Admins can view price history" ON public.plan_price_history FOR SELECT USING (public.is_admin(auth.uid()));
  END IF;

  -- Users can view their own redemptions
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'coupon_redemptions' AND policyname = 'Users can view their own redemptions') THEN
    CREATE POLICY "Users can view their own redemptions" ON public.coupon_redemptions FOR SELECT USING (auth.uid() = user_id OR public.is_admin(auth.uid()));
  END IF;

  -- Anyone can view active plans
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'plans' AND policyname = 'Anyone can view active plans') THEN
    CREATE POLICY "Anyone can view active plans" ON public.plans FOR SELECT USING (is_active = true);
  END IF;

  -- Only admins can manage plans
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'plans' AND policyname = 'Admins can manage plans') THEN
    CREATE POLICY "Admins can manage plans" ON public.plans FOR ALL USING (public.is_admin(auth.uid()));
  END IF;

  -- Users can view own subscriptions
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'Users can view own subscriptions') THEN
    CREATE POLICY "Users can view own subscriptions" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id OR public.is_admin(auth.uid()));
  END IF;

  -- Only admins can manage subscriptions directly
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'Admins can manage subscriptions') THEN
    CREATE POLICY "Admins can manage subscriptions" ON public.subscriptions FOR ALL USING (public.is_admin(auth.uid()));
  END IF;

  -- Anyone can view roles
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'roles' AND policyname = 'Anyone can view roles') THEN
    CREATE POLICY "Anyone can view roles" ON public.roles FOR SELECT USING (true);
  END IF;

  -- Only admins can modify roles
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'roles' AND policyname = 'Only admins can modify roles') THEN
    CREATE POLICY "Only admins can modify roles" ON public.roles FOR ALL TO authenticated USING (public.is_admin(auth.uid())) WITH CHECK (public.is_admin(auth.uid()));
  END IF;

  -- Allow read access for webhook idempotency checks
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_webhook_events' AND policyname = 'Allow read payment_webhook_events') THEN
    CREATE POLICY "Allow read payment_webhook_events" ON public.payment_webhook_events FOR SELECT USING (true);
  END IF;

  -- Allow recording of webhook events
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_webhook_events' AND policyname = 'Allow insert payment_webhook_events') THEN
    CREATE POLICY "Allow insert payment_webhook_events" ON public.payment_webhook_events FOR INSERT WITH CHECK (true);
  END IF;

  -- Allow test events cleanup and admin delete
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_webhook_events' AND policyname = 'Allow delete test or admin webhook events') THEN
    CREATE POLICY "Allow delete test or admin webhook events" ON public.payment_webhook_events FOR DELETE USING (public.is_admin(auth.uid()) OR event_id LIKE 'ASTRACK-TEST-%');
  END IF;
END $$;

-- 8. SEED DEFAULT SAMPLE PROMO COUPONS IF NOT EXIST
INSERT INTO public.coupons (code, description, discount_type, discount_value, usage_limit, per_user_limit, minimum_purchase, is_active)
VALUES
  ('ASTRACK20', 'Diskon 20% untuk semua paket langganan', 'percentage', 20, 500, 1, 0, true),
  ('ASTRACK5K', 'Potongan langsung Rp5.000 untuk transaksi pertama', 'fixed', 5000, 1000, 1, 15000, true),
  ('HEMATPRO', 'Diskon 30% khusus paket Pro tahunan/bulanan', 'percentage', 30, 200, 1, 25000, true)
ON CONFLICT (code) DO NOTHING;
