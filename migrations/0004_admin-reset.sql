-- ============================================================
-- Migration: reset_user_scores RPC
-- Run in Supabase SQL Editor.
-- Allows admins to wipe a user's submissions, hint unlocks,
-- and reset their score to 0 — useful for testing.
-- ============================================================

create or replace function public.reset_user_scores(p_user_id uuid)
returns json
language plpgsql security definer as $$
declare
  v_caller uuid := auth.uid();
begin
  if v_caller is null then
    return json_build_object('success', false, 'error', 'Not authenticated');
  end if;

  if not exists (
    select 1 from public.profiles where id = v_caller and role = 'admin'
  ) then
    return json_build_object('success', false, 'error', 'Admin access required');
  end if;

  delete from public.hint_unlocks where user_id = p_user_id;
  delete from public.submissions  where user_id = p_user_id;
  update public.profiles set score = 0 where id = p_user_id;

  return json_build_object('success', true);
exception
  when others then
    return json_build_object('success', false, 'error', sqlerrm);
end;
$$;
