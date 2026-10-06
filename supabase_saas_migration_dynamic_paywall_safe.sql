-- =================================================================================
-- ASTRACK — DYNAMIC UPGRADE PAYWALL SAFE MIGRATION (SUPABASE POSTGRESQL)
-- [SAFE MIGRATION - NO DESTRUCTIVE DROPS OF TABLES/DATA]
-- =================================================================================

-- 1. ADD is_recommended & features TO public.plans IF NOT PRESENT
ALTER TABLE public.plans ADD COLUMN IF NOT EXISTS is_recommended BOOLEAN DEFAULT false;
ALTER TABLE public.plans ADD COLUMN IF NOT EXISTS features JSONB DEFAULT '[]'::jsonb;

-- 2. UPDATE PLAN RECOMMENDED STATUS & FEATURES SAFELY
UPDATE public.plans 
SET 
  is_recommended = true,
  features = '["Semua fitur pada paket Basic", "Auto-scan struk belanja (OCR) instan", "Asisten Finansial AI tanpa batas", "Advanced Financial Analytics & Forecasts", "Sinkronisasi Multi-Device Cloud"]'::jsonb
WHERE id = 'plan_pro';

UPDATE public.plans 
SET 
  is_recommended = false,
  features = '["Catat transaksi tanpa batas", "Impor & Ekspor data transaksi CSV", "Analisis pengeluaran kategori", "Cetak laporan bulanan PDF"]'::jsonb
WHERE id = 'plan_basic';

UPDATE public.plans 
SET 
  is_recommended = false,
  features = '["Catat transaksi manual", "Kategori dasar", "Penyimpanan lokal"]'::jsonb
WHERE id = 'plan_free';

-- 3. ENSURE RLS PERMITS AUTHENTICATED USERS TO READ ACTIVE PLANS
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'plans' AND policyname = 'Anyone can view active plans'
  ) THEN
    CREATE POLICY "Anyone can view active plans" 
      ON public.plans 
      FOR SELECT 
      USING (is_active = true);
  END IF;
END $$;
