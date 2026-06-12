-- ============================================================
-- Migration: Persist challenge start time across page loads
-- Run once in Supabase SQL editor
-- ============================================================

-- 1. Table (created by Session 2 migration — this is idempotent) ──────────────
CREATE TABLE IF NOT EXISTS public.challenge_starts (
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id text NOT NULL,
  started_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, challenge_id)
);

ALTER TABLE public.challenge_starts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own starts" ON public.challenge_starts;
CREATE POLICY "Users read own starts"
  ON public.challenge_starts
  FOR SELECT
  USING (auth.uid() = user_id);

-- 2. record_challenge_start — re-create to ensure correct shape ────────────────
DROP FUNCTION IF EXISTS public.record_challenge_start(text);

CREATE FUNCTION public.record_challenge_start(p_challenge_id text)
RETURNS timestamptz
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_started_at timestamptz;
BEGIN
  INSERT INTO public.challenge_starts (user_id, challenge_id, started_at)
  VALUES (auth.uid(), p_challenge_id, now())
  ON CONFLICT (user_id, challenge_id) DO NOTHING;

  SELECT started_at INTO v_started_at
  FROM public.challenge_starts
  WHERE user_id = auth.uid() AND challenge_id = p_challenge_id;

  RETURN v_started_at;
END;
$$;
