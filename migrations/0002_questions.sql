-- ============================================================
-- Migration: replace question/options/correct_option/points
-- with a single questions jsonb array per challenge.
-- Run in Supabase SQL Editor AFTER truncating challenge data,
-- OR run the ALTER + DROP on an existing populated table
-- (you'll need to backfill questions from old columns first).
-- ============================================================

-- 1. Add new columns
ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS questions jsonb NOT NULL DEFAULT '[]';

ALTER TABLE public.submissions
  ADD COLUMN IF NOT EXISTS answers jsonb;

-- 2. Drop old columns (do this AFTER backfilling if you have live data)
ALTER TABLE public.challenges
  DROP COLUMN IF EXISTS question,
  DROP COLUMN IF EXISTS options,
  DROP COLUMN IF EXISTS correct_option,
  DROP COLUMN IF EXISTS points;

-- ============================================================
-- Updated RPC: submit_challenge
-- Accepts all answers at once, grades each question, deducts
-- hint costs from total earned, returns per-question breakdown.
-- ============================================================

create or replace function public.submit_challenge(
  p_challenge_id text,
  p_answers      jsonb   -- [{question_idx: int, selected_option: int}, ...]
) returns json
language plpgsql security definer as $$
declare
  v_uid          uuid := auth.uid();
  v_challenge    public.challenges%rowtype;
  v_hints_cost   integer;
  v_total_earned integer := 0;
  v_graded       jsonb   := '[]'::jsonb;
  v_answer       jsonb;
  v_q_idx        integer;
  v_q            jsonb;
  v_selected     integer;
  v_correct_opt  integer;
  v_q_points     integer;
  v_is_correct   boolean;
  v_cur_score    integer;
begin
  if v_uid is null then
    return json_build_object('success', false, 'error', 'Not authenticated');
  end if;

  select * into v_challenge
  from public.challenges
  where id = p_challenge_id and active = true;

  if not found then
    return json_build_object('success', false, 'error', 'Challenge not found');
  end if;

  if exists (
    select 1 from public.submissions
    where user_id = v_uid and challenge_id = p_challenge_id
  ) then
    return json_build_object('success', false, 'error', 'Already submitted');
  end if;

  -- Hints cost so far
  select coalesce(sum(cost), 0) into v_hints_cost
  from public.hint_unlocks
  where user_id = v_uid and challenge_id = p_challenge_id;

  -- Grade each submitted answer
  for v_answer in select * from jsonb_array_elements(p_answers) loop
    v_q_idx      := (v_answer->>'question_idx')::integer;
    v_q          := v_challenge.questions->v_q_idx;
    v_q_points   := coalesce((v_q->>'points')::integer, 0);
    v_selected   := (v_answer->>'selected_option')::integer;
    v_correct_opt := (v_q->>'correct_option')::integer;
    v_is_correct := (v_selected = v_correct_opt);

    if v_is_correct then
      v_total_earned := v_total_earned + v_q_points;
    end if;

    v_graded := v_graded || jsonb_build_array(
      jsonb_build_object(
        'question_idx',    v_q_idx,
        'selected_option', v_selected,
        'correct_option',  v_correct_opt,
        'correct',         v_is_correct,
        'earned',          case when v_is_correct then v_q_points else 0 end
      )
    );
  end loop;

  -- Deduct hint cost from total (floor at 0)
  v_total_earned := greatest(v_total_earned - v_hints_cost, 0);

  -- Record submission
  insert into public.submissions (user_id, challenge_id, score_earned, hints_cost, answers)
  values (v_uid, p_challenge_id, v_total_earned, v_hints_cost, v_graded);

  -- Update leaderboard score
  update public.profiles
  set score = score + v_total_earned
  where id = v_uid
  returning score into v_cur_score;

  return json_build_object(
    'success',      true,
    'graded',       v_graded,
    'score_earned', v_total_earned,
    'hints_cost',   v_hints_cost,
    'new_score',    v_cur_score
  );
exception
  when others then
    return json_build_object('success', false, 'error', sqlerrm);
end;
$$;
