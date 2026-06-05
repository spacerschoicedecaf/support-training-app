-- ============================================================
-- Migration: add theme column to profiles
-- Run in Supabase SQL Editor.
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS theme text NOT NULL DEFAULT 'vhs'
  CHECK (theme IN ('sturnus', 'vhs'));

-- Backfill: set existing users to 'sturnus' (they're all internal for now)
UPDATE public.profiles SET theme = 'sturnus' WHERE theme = 'vhs';

-- Allow admins to update theme for any user (policy already exists for admins)
-- No new policy needed — existing "Admins can update any profile" covers this.
