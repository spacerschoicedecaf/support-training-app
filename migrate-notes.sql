-- ============================================================
-- Migration: Private notes per challenge
-- Run once in Supabase SQL editor
-- ============================================================

-- 1. Table ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.challenge_notes (
  user_id      uuid    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id text    NOT NULL,
  note_text    text    NOT NULL DEFAULT '',
  updated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, challenge_id)
);

-- 2. RLS ────────────────────────────────────────────────────
ALTER TABLE public.challenge_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own notes"
  ON public.challenge_notes
  FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 3. Upsert RPC ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.save_challenge_note(
  p_challenge_id text,
  p_note_text    text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.challenge_notes (user_id, challenge_id, note_text, updated_at)
  VALUES (auth.uid(), p_challenge_id, p_note_text, now())
  ON CONFLICT (user_id, challenge_id)
  DO UPDATE SET
    note_text  = EXCLUDED.note_text,
    updated_at = now();
END;
$$;
