-- ============================================================
-- Migration: variant_group column for challenge rotation
-- Run in Supabase SQL Editor.
--
-- Usage:
--   Set variant_group to a shared slug on challenges that are
--   variants of the same root cause, e.g. "email-from-error".
--   Leave null for standalone challenges.
--
--   The app will show one challenge per group at a time and
--   rotate to a different variant after 90 days.
-- ============================================================

ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS variant_group text;

-- Index for efficient group lookups
CREATE INDEX IF NOT EXISTS idx_challenges_variant_group
  ON public.challenges (variant_group)
  WHERE variant_group IS NOT NULL;
