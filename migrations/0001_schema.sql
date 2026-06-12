-- ============================================================
-- CTF Training App – Supabase Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- Enable UUID helper
create extension if not exists "uuid-ossp";

-- ─── Tables ──────────────────────────────────────────────────

create table public.profiles (
  id        uuid        primary key references auth.users(id) on delete cascade,
  handle    text        unique not null,
  role      text        not null default 'user' check (role in ('user', 'admin')),
  score     integer     not null default 0,
  created_at timestamptz not null default now()
);

create table public.challenges (
  id                  text        primary key,          -- e.g. "TICKET-0001"
  title               text        not null,
  scenario            text        not null,
  ticket_quote        text        not null,
  red_herrings        jsonb       not null default '[]', -- string[]
  arch_context        text        not null,
  server_logs         jsonb       not null,              -- log object array
  server_logs_filename text       not null default 'server-logs.json',
  mongo_collections   jsonb       not null default '[]', -- [{collection, required_field, synthetic_docs}]
  hints               jsonb       not null default '[]', -- [{text, cost}]
  question            text        not null,
  options             jsonb       not null,              -- string[4]
  correct_option      integer     not null check (correct_option between 0 and 3),
  points              integer     not null default 100,
  active              boolean     not null default true,
  created_at          timestamptz not null default now()
);

create table public.submissions (
  id           uuid        primary key default uuid_generate_v4(),
  user_id      uuid        not null references auth.users(id) on delete cascade,
  challenge_id text        not null references public.challenges(id),
  score_earned integer     not null,
  hints_cost   integer     not null default 0,
  completed_at timestamptz not null default now(),
  unique (user_id, challenge_id)
);

create table public.hint_unlocks (
  id           uuid        primary key default uuid_generate_v4(),
  user_id      uuid        not null references auth.users(id) on delete cascade,
  challenge_id text        not null references public.challenges(id),
  hint_index   integer     not null,
  cost         integer     not null,
  unlocked_at  timestamptz not null default now(),
  unique (user_id, challenge_id, hint_index)
);

-- ─── Row-Level Security ───────────────────────────────────────

alter table public.profiles      enable row level security;
alter table public.challenges    enable row level security;
alter table public.submissions   enable row level security;
alter table public.hint_unlocks  enable row level security;

-- profiles
create policy "Profiles are publicly readable"
  on public.profiles for select using (true);

create policy "Users can create their own profile"
  on public.profiles for insert with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update using (auth.uid() = id);

create policy "Admins can update any profile"
  on public.profiles for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- challenges
create policy "Authenticated users see active challenges"
  on public.challenges for select
  using (
    auth.role() = 'authenticated'
    and (
      active = true
      or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    )
  );

create policy "Admins can insert challenges"
  on public.challenges for insert
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "Admins can update challenges"
  on public.challenges for update
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "Admins can delete challenges"
  on public.challenges for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- submissions
create policy "Users can view own submissions"
  on public.submissions for select using (auth.uid() = user_id);

create policy "Admins can view all submissions"
  on public.submissions for select
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

create policy "Users can insert own submissions"
  on public.submissions for insert with check (auth.uid() = user_id);

-- hint_unlocks
create policy "Users can view own hint unlocks"
  on public.hint_unlocks for select using (auth.uid() = user_id);

create policy "Users can insert own hint unlocks"
  on public.hint_unlocks for insert with check (auth.uid() = user_id);

-- ─── RPC Functions ────────────────────────────────────────────

-- Atomically deduct points and record a hint unlock
create or replace function public.unlock_hint(
  p_challenge_id  text,
  p_hint_index    integer,
  p_cost          integer
) returns json
language plpgsql security definer as $$
declare
  v_uid   uuid := auth.uid();
  v_score integer;
begin
  if v_uid is null then
    return json_build_object('success', false, 'error', 'Not authenticated');
  end if;

  select score into v_score from public.profiles where id = v_uid;

  if v_score < p_cost then
    return json_build_object('success', false, 'error', 'Insufficient points');
  end if;

  insert into public.hint_unlocks (user_id, challenge_id, hint_index, cost)
  values (v_uid, p_challenge_id, p_hint_index, p_cost);

  if p_cost > 0 then
    update public.profiles set score = score - p_cost where id = v_uid;
  end if;

  return json_build_object('success', true, 'new_score', v_score - p_cost);
exception
  when unique_violation then
    return json_build_object('success', false, 'error', 'Already unlocked');
  when others then
    return json_build_object('success', false, 'error', sqlerrm);
end;
$$;

-- Atomically grade a challenge submission and update the leaderboard score
create or replace function public.submit_challenge(
  p_challenge_id    text,
  p_selected_option integer
) returns json
language plpgsql security definer as $$
declare
  v_uid         uuid := auth.uid();
  v_challenge   public.challenges%rowtype;
  v_hints_cost  integer;
  v_score_earned integer;
  v_is_correct  boolean;
  v_cur_score   integer;
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

  if exists (select 1 from public.submissions where user_id = v_uid and challenge_id = p_challenge_id) then
    return json_build_object('success', false, 'error', 'Already submitted');
  end if;

  select coalesce(sum(cost), 0) into v_hints_cost
  from public.hint_unlocks
  where user_id = v_uid and challenge_id = p_challenge_id;

  v_is_correct   := (p_selected_option = v_challenge.correct_option);
  v_score_earned := case when v_is_correct then greatest(v_challenge.points - v_hints_cost, 0) else 0 end;

  insert into public.submissions (user_id, challenge_id, score_earned, hints_cost)
  values (v_uid, p_challenge_id, v_score_earned, v_hints_cost);

  update public.profiles
  set score = score + v_score_earned
  where id = v_uid
  returning score into v_cur_score;

  return json_build_object(
    'success',        true,
    'correct',        v_is_correct,
    'score_earned',   v_score_earned,
    'correct_option', v_challenge.correct_option,
    'new_score',      v_cur_score
  );
exception
  when others then
    return json_build_object('success', false, 'error', sqlerrm);
end;
$$;

-- ─── Seed: TICKET-0001 ────────────────────────────────────────

insert into public.challenges (
  id, title, scenario, ticket_quote, red_herrings, arch_context,
  server_logs, server_logs_filename,
  mongo_collections,
  hints, question, options, correct_option, points, active
) values (
  'TICKET-0001',
  'The Midnight Cascade',
  'A customer reports intermittent 503 errors devastating their checkout flow, starting at 23:47 UTC. Your monitoring shows a response-time spike but all services appear green. The on-call engineer has been circling for two hours.',
  '"Our customers are getting 503 errors at checkout. This started last night around midnight. We are losing real sales and our own status page says everything is green — so what is actually going on?!"',
  '[
    "CPU utilization on app servers spiked to 78% at 00:12 — well within normal burst limits for this workload",
    "A code deployment was made at 21:30 UTC — three hours before the incident window began",
    "Redis cache hit rate dipped from 94% to 91% — within documented acceptable variance"
  ]',
  'Multi-tenant e-commerce SaaS. Stack: Node.js API cluster (4 instances) behind an AWS ALB, MongoDB Atlas M30 (3-node replica set), Redis 7 for session/cart caching, Stripe for payment processing. Each tenant is isolated to its own MongoDB database within the shared Atlas cluster. Mongoose handles connection pooling per instance (maxPoolSize: 10). Deployment pipeline: GitHub Actions → ECR → ECS Fargate rolling update.',
  '[
    {"ts":"2024-01-15T23:44:01Z","level":"info","service":"api-1","msg":"Health check OK","latency_ms":12},
    {"ts":"2024-01-15T23:47:18Z","level":"warn","service":"api-3","msg":"MongoDB connection wait exceeded 500ms","tenant":"acme-corp","pool_waiting":8},
    {"ts":"2024-01-15T23:47:31Z","level":"warn","service":"api-2","msg":"MongoDB connection wait exceeded 500ms","tenant":"globex","pool_waiting":9},
    {"ts":"2024-01-15T23:47:55Z","level":"error","service":"api-1","msg":"MongoTimeoutError: connection pool exhausted","tenant":"acme-corp","pool_waiting":10,"pool_size":10},
    {"ts":"2024-01-15T23:48:02Z","level":"error","service":"api-3","msg":"MongoTimeoutError: connection pool exhausted","tenant":"globex","pool_waiting":10,"pool_size":10},
    {"ts":"2024-01-15T23:48:10Z","level":"error","service":"api-4","msg":"Request failed: upstream timeout","path":"/api/checkout","status":503},
    {"ts":"2024-01-15T23:48:11Z","level":"error","service":"api-2","msg":"Request failed: upstream timeout","path":"/api/checkout","status":503},
    {"ts":"2024-01-15T23:51:30Z","level":"warn","service":"api-1","msg":"Slow query detected","collection":"connections","duration_ms":4821,"filter":{"tenant_id":"acme-corp"}},
    {"ts":"2024-01-15T23:51:31Z","level":"warn","service":"api-3","msg":"Slow query detected","collection":"connections","duration_ms":5103,"filter":{"tenant_id":"globex"}},
    {"ts":"2024-01-15T23:52:00Z","level":"info","service":"atlas-alerts","msg":"MongoDB Atlas: index scan ratio exceeded threshold — 95% of queries performing full collection scans","database":"shared-cluster"},
    {"ts":"2024-01-15T23:52:45Z","level":"info","service":"atlas-alerts","msg":"MongoDB Atlas: oplog window shrinking — sustained high write load on primary"}
  ]',
  'server-logs.json',
  '[
    {
      "collection": "connections",
      "required_field": "tenant_id",
      "synthetic_docs": [
        {"_id":{"$oid":"65a5c3f200000001"},"tenant_id":"acme-corp","client_ip":"10.0.4.22","opened_at":"2024-01-15T23:46:55Z","query_count":0,"state":"idle","held_ms":187432},
        {"_id":{"$oid":"65a5c3f200000002"},"tenant_id":"acme-corp","client_ip":"10.0.4.22","opened_at":"2024-01-15T23:46:56Z","query_count":0,"state":"idle","held_ms":186991},
        {"_id":{"$oid":"65a5c3f200000003"},"tenant_id":"globex","client_ip":"10.0.4.31","opened_at":"2024-01-15T23:47:01Z","query_count":0,"state":"idle","held_ms":185002},
        {"_id":{"$oid":"65a5c3f200000004"},"tenant_id":"globex","client_ip":"10.0.4.31","opened_at":"2024-01-15T23:47:03Z","query_count":0,"state":"idle","held_ms":184750},
        {"_id":{"$oid":"65a5c3f200000005"},"tenant_id":"acme-corp","client_ip":"10.0.4.22","opened_at":"2024-01-15T23:47:10Z","query_count":1,"state":"idle","held_ms":183441,"last_query":"db.orders.find({tenant_id:\"acme-corp\"})"},
        {"_id":{"$oid":"65a5c3f200000006"},"tenant_id":"acme-corp","client_ip":"10.0.4.55","opened_at":"2024-01-15T23:47:22Z","query_count":0,"state":"idle","held_ms":182018},
        {"_id":{"$oid":"65a5c3f200000007"},"tenant_id":"globex","client_ip":"10.0.4.31","opened_at":"2024-01-15T23:47:30Z","query_count":0,"state":"idle","held_ms":181500},
        {"_id":{"$oid":"65a5c3f200000008"},"tenant_id":"acme-corp","client_ip":"10.0.4.22","opened_at":"2024-01-15T23:47:41Z","query_count":0,"state":"idle","held_ms":180123}
      ]
    }
  ]',
  '[
    {"text":"Look at the Atlas alert logged at 23:52 UTC — it names a specific metric that directly explains why all queries are suddenly slow.","cost":0},
    {"text":"The `connections` collection documents all have a `held_ms` value in the 180,000–187,000 range. A normal connection holds for milliseconds. These are holding for over three minutes while flagged as idle. Why would connections stay open but inactive at that scale?","cost":25},
    {"text":"Root cause: the 21:30 deployment introduced a new checkout code path that calls `mongoose.connection.getConnection()` but never calls `session.endSession()` or returns the connection to the pool. Every checkout request since deployment has been leaking one connection. By 23:47 all 10 slots per instance were exhausted, causing queuing then timeouts.","cost":50}
  ]',
  'What is the root cause of the 503 errors affecting the checkout endpoint?',
  '[
    "A sudden traffic spike overwhelmed the Node.js app servers, causing CPU throttling and downstream request queuing",
    "MongoDB Atlas connections are being exhausted — connections are checked out but never released back to the pool",
    "A Redis cache-miss storm caused excessive direct MongoDB queries, overloading the Atlas replica set primary",
    "The ALB health checks are misconfigured and are incorrectly routing traffic to a single unhealthy instance"
  ]',
  1,
  100,
  true
);
