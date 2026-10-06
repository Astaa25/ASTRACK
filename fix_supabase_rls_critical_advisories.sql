-- ==============================================================================
-- FIX SUPABASE CRITICAL SECURITY ADVISORIES: ENABLE RLS ON ROLES & WEBHOOK EVENTS
-- ==============================================================================
-- Non-destructive, idempotent, safe to run directly in Supabase SQL Editor.
-- Resolves:
-- 1. "RLS Disabled in Public (CRITICAL) - public.roles"
-- 2. "RLS Disabled in Public (CRITICAL) - public.payment_webhook_events"

-- ------------------------------------------------------------------------------
-- 1. FIX: public.roles
-- ------------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.roles ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  -- Anyone (authenticated or public) can view roles list
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'roles' AND policyname = 'Anyone can view roles') THEN
    CREATE POLICY "Anyone can view roles" ON public.roles FOR SELECT USING (true);
  END IF;

  -- Only admins can modify/insert/delete roles
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'roles' AND policyname = 'Only admins can modify roles') THEN
    CREATE POLICY "Only admins can modify roles" ON public.roles FOR ALL 
    TO authenticated 
    USING (public.is_admin(auth.uid())) 
    WITH CHECK (public.is_admin(auth.uid()));
  END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 2. FIX: public.payment_webhook_events
-- ------------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.payment_webhook_events ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  -- Allow read access for verification and idempotency check
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_webhook_events' AND policyname = 'Allow read payment_webhook_events') THEN
    CREATE POLICY "Allow read payment_webhook_events" ON public.payment_webhook_events FOR SELECT USING (true);
  END IF;

  -- Allow insert to record incoming webhook events safely
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_webhook_events' AND policyname = 'Allow insert payment_webhook_events') THEN
    CREATE POLICY "Allow insert payment_webhook_events" ON public.payment_webhook_events FOR INSERT WITH CHECK (true);
  END IF;

  -- Allow cleanup of test events or administrative deletion
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_webhook_events' AND policyname = 'Allow delete test or admin webhook events') THEN
    CREATE POLICY "Allow delete test or admin webhook events" ON public.payment_webhook_events FOR DELETE 
    USING (public.is_admin(auth.uid()) OR event_id LIKE 'ASTRACK-TEST-%');
  END IF;
END $$;
