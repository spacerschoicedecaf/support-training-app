-- Migration: add walkthrough + est_minutes to challenges
-- Run in Supabase SQL editor

ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS walkthrough  text,
  ADD COLUMN IF NOT EXISTS est_minutes  integer;
