-- ============================================================
-- Migration: Fix reset_user_scores to also clear challenge_starts
--
-- Bug: after an admin reset, challenge_starts still held the
-- original started_at timestamp. On the next visit the timer
-- called record_challenge_start, got back the old timestamp,
-- and displayed elapsed time of 1000+ minutes.
-- ============================================================

CREATE OR REPLACE FUNCTION public.reset_user_scores(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_caller uuid := auth.uid();
BEGIN
  IF v_caller IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = v_caller AND role = 'admin'
  ) THEN
    RETURN json_build_object('success', false, 'error', 'Admin access required');
  END IF;

  DELETE FROM public.hint_unlocks    WHERE user_id = p_user_id;
  DELETE FROM public.submissions     WHERE user_id = p_user_id;
  DELETE FROM public.challenge_starts WHERE user_id = p_user_id;
  UPDATE public.profiles SET score = 0 WHERE id = p_user_id;

  RETURN json_build_object('success', true);
EXCEPTION
  WHEN others THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;
