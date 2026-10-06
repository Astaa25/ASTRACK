-- ============================================================
-- ASTRACK Phase 2 Migration: Self-Service Account & Cloud Data Deletion
-- File: supabase_account_deletion_migration.sql
-- Description: Idempotent migration providing secure RPC delete_my_account()
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID;
BEGIN
  -- 1. Ensure caller is an authenticated user (strictly reject anon)
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: User is not authenticated';
  END IF;

  -- 2. Delete user's personal financial ledger records
  DELETE FROM public.transactions WHERE user_id = v_uid;
  DELETE FROM public.recurring_transactions WHERE user_id = v_uid;
  DELETE FROM public.savings_goals WHERE user_id = v_uid;
  DELETE FROM public.budgets WHERE user_id = v_uid;
  DELETE FROM public.categories WHERE user_id = v_uid;
  DELETE FROM public.fund_sources WHERE user_id = v_uid;

  -- 3. Delete user device tokens & subscriptions
  DELETE FROM public.user_device_tokens WHERE user_id = v_uid;
  DELETE FROM public.subscriptions WHERE user_id = v_uid;
  DELETE FROM public.user_roles WHERE user_id = v_uid;

  -- 4. Anonymize commercial payment records for compliance & accounting audit trail
  -- (Preserves ledger totals while removing PII per privacy law regulations)
  UPDATE public.payment_orders 
  SET user_id = NULL,
      status = CASE WHEN status = 'pending' THEN 'cancelled' ELSE status END
  WHERE user_id = v_uid;

  DELETE FROM public.coupon_redemptions WHERE user_id = v_uid;

  -- 5. Delete user profile
  DELETE FROM public.profiles WHERE id = v_uid;

  -- 6. Delete authentication record from auth.users
  DELETE FROM auth.users WHERE id = v_uid;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Akun dan seluruh data finansial cloud berhasil dihapus secara permanen.'
  );
END;
$$;

-- Grant execution strictly to authenticated users only
REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
