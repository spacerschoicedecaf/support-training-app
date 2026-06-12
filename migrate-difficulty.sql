-- Migration: add intended difficulty to challenges
-- Run in Supabase SQL editor

ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS difficulty text
  CHECK (difficulty IN ('easy', 'medium', 'hard'));
