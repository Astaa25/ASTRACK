-- ==============================================================================
-- ASTRACK - Supabase Auto-Confirm & Instant User Approval Migration
-- Jalankan skrip ini di SQL Editor Supabase Dashboard Anda:
-- https://supabase.com/dashboard/project/dcwdjpjgxtagaozvkesr/sql
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 0. Set default pada subscriptions.expires_at agar tidak melanggar NOT NULL constraint
ALTER TABLE public.subscriptions ALTER COLUMN expires_at SET DEFAULT (NOW() + INTERVAL '100 years');

-- 1. Fungsi RPC untuk Administrator: Menyetujui user sekaligus mengonfirmasi email
--    sehingga user baru langsung bisa login tanpa terhalang verifikasi email.
CREATE OR REPLACE FUNCTION public.admin_approve_user(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- A. Update status profil menjadi 'approved'
  UPDATE public.profiles
  SET 
    status = 'approved',
    updated_at = NOW()
  WHERE id = target_user_id;

  -- B. Konfirmasi email di auth.users secara otomatis
  UPDATE auth.users
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    updated_at = NOW()
  WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Berikan izin eksekusi ke authenticated users & anon
GRANT EXECUTE ON FUNCTION public.admin_approve_user(UUID) TO authenticated, anon;


-- 2. Trigger Otomatis saat Pengguna Baru Mendaftar (auth.users -> profiles, roles, subscriptions)
--    Kebal error: Menggunakan IF NOT EXISTS & EXCEPTION blocks agar signup auth tidak pernah gagal 500.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- A. Sisipkan ke public.profiles
  BEGIN
    INSERT INTO public.profiles (id, email, full_name, status, updated_at)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      'pending',
      NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET 
      email = EXCLUDED.email,
      full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
      updated_at = NOW();
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- B. Sisipkan role bawaan 'user'
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = NEW.id AND role_id = 'user') THEN
      INSERT INTO public.user_roles (user_id, role_id)
      VALUES (NEW.id, 'user');
    END IF;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- C. Sisipkan paket langganan bawaan 'plan_free' (lengkap dengan expires_at 100 tahun)
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.subscriptions WHERE user_id = NEW.id) THEN
      INSERT INTO public.subscriptions (user_id, plan_id, status, expires_at)
      VALUES (NEW.id, 'plan_free', 'active', NOW() + INTERVAL '100 years');
    END IF;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Pasang trigger pada auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 3. AKTIVASI & PEMBUATAN 2 AKUN TESTING (STATUS APPROVED & EMAIL CONFIRMED)
DO $$
DECLARE
  v_user2_id UUID := gen_random_uuid();
  v_enc_pw   TEXT := crypt('Tester123!', gen_salt('bf'));
BEGIN
  -- A. Bersihkan akun testing lama yang invalid jika ada
  DELETE FROM public.profiles WHERE email IN ('tester1@astrack.id', 'tester2@astrack.id');
  DELETE FROM auth.users WHERE email IN ('tester1@astrack.id', 'tester2@astrack.id');

  -- B. Aktivasi Akun 1: astrack.tester1@gmail.com
  UPDATE auth.users 
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    encrypted_password = v_enc_pw,
    updated_at = NOW()
  WHERE email = 'astrack.tester1@gmail.com';

  UPDATE public.profiles 
  SET status = 'approved', full_name = 'Tester Satu', updated_at = NOW() 
  WHERE email = 'astrack.tester1@gmail.com';

  -- C. Buat & Aktivasi Akun 2: astrack.tester2@gmail.com (dengan token konfirmasi acak unik)
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'astrack.tester2@gmail.com') THEN
    INSERT INTO auth.users (
      id, instance_id, email, encrypted_password, email_confirmed_at,
      invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at,
      email_change_token_new, email_change, email_change_sent_at, last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at,
      phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at,
      email_change_token_current, email_change_confirm_status, banned_until,
      reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at,
      is_anonymous, role, aud
    )
    SELECT
      v_user2_id,
      instance_id,
      'astrack.tester2@gmail.com',
      v_enc_pw,
      NOW(),
      invited_at,
      encode(gen_random_bytes(32), 'hex'), -- token unik baru agar tidak kena duplicate key
      confirmation_sent_at,
      encode(gen_random_bytes(32), 'hex'), -- token recovery unik
      recovery_sent_at,
      encode(gen_random_bytes(32), 'hex'), -- token email change unik
      email_change,
      email_change_sent_at,
      NULL,
      raw_app_meta_data,
      '{"full_name":"Tester Dua","email":"astrack.tester2@gmail.com"}'::jsonb,
      is_super_admin,
      NOW(),
      NOW(),
      phone,
      phone_confirmed_at,
      phone_change,
      phone_change_token,
      phone_change_sent_at,
      email_change_token_current,
      email_change_confirm_status,
      banned_until,
      reauthentication_token,
      reauthentication_sent_at,
      is_sso_user,
      deleted_at,
      is_anonymous,
      role,
      aud
    FROM auth.users
    WHERE email = 'astrack.tester1@gmail.com'
    LIMIT 1;

    INSERT INTO public.profiles (id, email, full_name, status, updated_at)
    VALUES (v_user2_id, 'astrack.tester2@gmail.com', 'Tester Dua', 'approved', NOW())
    ON CONFLICT (id) DO UPDATE SET status = 'approved', full_name = 'Tester Dua';

    IF NOT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = v_user2_id) THEN
      INSERT INTO public.user_roles (user_id, role_id) VALUES (v_user2_id, 'user');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.subscriptions WHERE user_id = v_user2_id) THEN
      INSERT INTO public.subscriptions (user_id, plan_id, status, expires_at)
      VALUES (v_user2_id, 'plan_free', 'active', NOW() + INTERVAL '100 years');
    END IF;
  ELSE
    UPDATE auth.users 
    SET 
      email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
      encrypted_password = v_enc_pw,
      updated_at = NOW()
    WHERE email = 'astrack.tester2@gmail.com';

    UPDATE public.profiles 
    SET status = 'approved', full_name = 'Tester Dua', updated_at = NOW() 
    WHERE email = 'astrack.tester2@gmail.com';
  END IF;

  -- D. Bersihkan data keuangan cloud tester agar benar-benar seperti baru buat akun (Rp 0 & 0 transaksi)
  BEGIN
    DELETE FROM public.transactions WHERE user_id IN (
      SELECT id FROM auth.users WHERE email IN ('astrack.tester1@gmail.com', 'astrack.tester2@gmail.com')
    );
  EXCEPTION WHEN OTHERS THEN NULL; END;

  BEGIN
    DELETE FROM public.budgets WHERE user_id IN (
      SELECT id FROM auth.users WHERE email IN ('astrack.tester1@gmail.com', 'astrack.tester2@gmail.com')
    );
  EXCEPTION WHEN OTHERS THEN NULL; END;

  BEGIN
    DELETE FROM public.savings_goals WHERE user_id IN (
      SELECT id FROM auth.users WHERE email IN ('astrack.tester1@gmail.com', 'astrack.tester2@gmail.com')
    );
  EXCEPTION WHEN OTHERS THEN NULL; END;

  BEGIN
    DELETE FROM public.recurring_transactions WHERE user_id IN (
      SELECT id FROM auth.users WHERE email IN ('astrack.tester1@gmail.com', 'astrack.tester2@gmail.com')
    );
  EXCEPTION WHEN OTHERS THEN NULL; END;

  BEGIN
    DELETE FROM public.fund_sources WHERE user_id IN (
      SELECT id FROM auth.users WHERE email IN ('astrack.tester1@gmail.com', 'astrack.tester2@gmail.com')
    );
  EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- SELESAI!
