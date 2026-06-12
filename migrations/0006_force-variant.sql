-- ============================================================
-- Migration: admin_force_variant RPC
-- Allows admins to immediately trigger the next variant in a
-- group by back-dating all submissions for that group to 92
-- days ago. Useful for testing variant content.
-- ============================================================

create or replace function public.admin_force_variant(p_group text)
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

  -- Back-date all submissions in this variant group to 92 days ago
  -- so every user's cooldown expires and the next variant appears
  update public.submissions
  set completed_at = now() - interval '92 days'
  where challenge_id in (
    select id from public.challenges where variant_group = p_group
  );

  return json_build_object('success', true);
exception
  when others then
    return json_build_object('success', false, 'error', sqlerrm);
end;
$$;
