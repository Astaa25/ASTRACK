-- ============================================================
-- ASTRACK Phase 1 Migration: APK Distribution & Version Management
-- File: supabase_app_versions_migration.sql
-- Description: Idempotent migration for app_versions table, RLS, and RPC
-- ============================================================

CREATE TABLE IF NOT EXISTS public.app_versions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform            TEXT NOT NULL DEFAULT 'android'
                        CHECK (platform IN ('android')),
  version_name        TEXT NOT NULL,                -- contoh: '1.0.1'
  build_number        INTEGER NOT NULL CHECK (build_number > 0),
  min_supported_build INTEGER NOT NULL CHECK (min_supported_build > 0),
  download_url        TEXT NOT NULL
                        CHECK (download_url ~* '^https://'),
  sha256              TEXT NOT NULL
                        CHECK (sha256 ~* '^[0-9a-f]{64}$'),
  file_size_bytes     BIGINT CHECK (file_size_bytes > 0),
  changelog_id        TEXT NOT NULL DEFAULT '',
  changelog_en        TEXT NOT NULL DEFAULT '',
  is_published        BOOLEAN NOT NULL DEFAULT FALSE,
  is_revoked          BOOLEAN NOT NULL DEFAULT FALSE, -- tarik versi bermasalah
  released_at         TIMESTAMPTZ,
  created_by          UUID REFERENCES auth.users(id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (platform, build_number),
  CHECK (min_supported_build <= build_number)
);

ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- Siapa pun (termasuk belum login) boleh membaca versi yang dipublikasikan
DROP POLICY IF EXISTS "app_versions_read_published" ON public.app_versions;
CREATE POLICY "app_versions_read_published"
  ON public.app_versions FOR SELECT
  TO anon, authenticated
  USING (is_published = TRUE);

-- Hanya admin yang boleh menulis (CRUD)
DROP POLICY IF EXISTS "app_versions_admin_all" ON public.app_versions;
CREATE POLICY "app_versions_admin_all"
  ON public.app_versions FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()))
  WITH CHECK (public.is_admin(auth.uid()));

-- RPC: ambil informasi update terbaru untuk platform tertentu
CREATE OR REPLACE FUNCTION public.get_latest_app_version(p_platform TEXT DEFAULT 'android')
RETURNS TABLE (
  version_name TEXT,
  build_number INTEGER,
  min_supported_build INTEGER,
  download_url TEXT,
  sha256 TEXT,
  file_size_bytes BIGINT,
  changelog_id TEXT,
  changelog_en TEXT,
  released_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT v.version_name, v.build_number, v.min_supported_build,
         v.download_url, v.sha256, v.file_size_bytes,
         v.changelog_id, v.changelog_en, v.released_at
  FROM public.app_versions v
  WHERE v.platform = p_platform
    AND v.is_published = TRUE
    AND v.is_revoked = FALSE
  ORDER BY v.build_number DESC
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_latest_app_version(TEXT) TO anon, authenticated;
