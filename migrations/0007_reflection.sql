-- ============================================================
-- Migration: reflection + difficulty rating on submissions
-- Run in Supabase SQL Editor.
-- ============================================================

ALTER TABLE public.submissions
  ADD COLUMN IF NOT EXISTS reflection text,
  ADD COLUMN IF NOT EXISTS difficulty_rating integer CHECK (difficulty_rating BETWEEN 1 AND 5);

-- RPC: save a user's post-solve reflection and difficulty rating
create or replace function public.save_reflection(
  p_challenge_id     text,
  p_reflection       text,
  p_difficulty_rating integer
) returns json
language plpgsql security definer as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return json_build_object('success', false, 'error', 'Not authenticated');
  end if;

  update public.submissions
  set reflection        = p_reflection,
      difficulty_rating = p_difficulty_rating
  where user_id = v_uid and challenge_id = p_challenge_id;

  if not found then
    return json_build_object('success', false, 'error', 'Submission not found');
  end if;

  return json_build_object('success', true);
exception
  when others then
    return json_build_object('success', false, 'error', sqlerrm);
end;
$$;
