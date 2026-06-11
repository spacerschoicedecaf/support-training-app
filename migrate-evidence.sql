-- ============================================================
-- Migration: multiple log files + screenshots
-- Run in Supabase SQL Editor after migrate-tags-firstblood.sql
-- ============================================================

-- Multiple log files: array of {filename, logs}
ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS log_files jsonb NOT NULL DEFAULT '[]';

-- Screenshots: array of {url, caption}
ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS screenshots jsonb NOT NULL DEFAULT '[]';

-- Backfill log_files from existing single-log columns
UPDATE public.challenges
SET log_files = jsonb_build_array(
  jsonb_build_object(
    'filename', COALESCE(server_logs_filename, 'server-logs.json'),
    'logs',     COALESCE(server_logs, '[]'::jsonb)
  )
)
WHERE log_files = '[]'::jsonb;
