-- ============================================================
-- Test challenge: TICKET-TEST-01 "The Phantom Session"
-- Drop directly into Supabase SQL editor to preview all fields
-- ============================================================

INSERT INTO public.challenges (
  id,
  title,
  scenario,
  ticket_quote,
  arch_context,
  red_herrings,
  server_logs,
  server_logs_filename,
  log_files,
  screenshots,
  mongo_collections,
  hints,
  questions,
  tags,
  variant_group,
  active
) VALUES (
  'TICKET-TEST-01',

  'The Phantom Session',

  'Over a 4-hour window on a Thursday afternoon, roughly 15% of logged-in users across multiple organizations were silently dropped from their sessions mid-use. Affected users had to re-authenticate. No errors were surfaced in the UI — sessions simply expired without warning. The issue resolved itself around 6pm PT with no intervention, but customer tickets continued arriving the next morning.',

  'Hi, our entire team keeps getting logged out randomly throughout the day. We were in the middle of a live demo with a prospect and it kicked everyone out at the same time. This is completely unacceptable — we pay for enterprise support and this has now happened twice this week. We need an explanation and a fix NOW.',

  'Node.js API servers (x4, autoscaled) behind an ALB. Sessions stored in Redis 6.x (ElastiCache, cache.t3.medium, 1.37 GB). MongoDB Atlas for persistent data. JWTs are NOT used — server-side sessions only, keyed by session ID stored in a cookie. Redis is shared between sessions, rate-limiting counters, and a feature-flag cache layer added 3 weeks ago.',

  -- red_herrings
  '[
    "A routine deployment went out 6 hours before the incident window — no session-related changes in the diff",
    "API server CPU averaged 38% during the incident, well within normal range",
    "One customer reported the issue only happens on Tuesdays — their data is consistent with the broader incident window",
    "MongoDB Atlas showed elevated read latency (P99 ~180ms) during the same window, unrelated to sessions",
    "Three users reported the issue but had Safari privacy settings blocking third-party cookies — their sessions were already broken before the incident"
  ]'::jsonb,

  -- server_logs (legacy single-log field — backfilled from log_files[0])
  '[
    {"ts": "2024-03-14T21:02:11.441Z", "level": "warn",  "msg": "Session lookup miss", "session_id": "sess_8x2kPqR", "user_id": "u_19284"},
    {"ts": "2024-03-14T21:02:14.883Z", "level": "warn",  "msg": "Session lookup miss", "session_id": "sess_mN3vLwY", "user_id": "u_77341"},
    {"ts": "2024-03-14T21:03:01.002Z", "level": "error", "msg": "Unauthenticated request to protected route", "path": "/api/v2/tickets", "user_id": null, "ip": "203.0.113.42"},
    {"ts": "2024-03-14T21:03:01.889Z", "level": "warn",  "msg": "Session lookup miss", "session_id": "sess_Qp8RtXz", "user_id": "u_50012"},
    {"ts": "2024-03-14T21:05:22.114Z", "level": "info",  "msg": "User forced re-auth", "user_id": "u_19284", "reason": "session_not_found"},
    {"ts": "2024-03-14T21:08:47.339Z", "level": "error", "msg": "Unauthenticated request to protected route", "path": "/api/v2/organizations", "user_id": null, "ip": "198.51.100.17"},
    {"ts": "2024-03-14T21:11:03.772Z", "level": "warn",  "msg": "Session lookup miss", "session_id": "sess_Zq1AbMn", "user_id": "u_30458"},
    {"ts": "2024-03-14T21:12:59.001Z", "level": "info",  "msg": "User forced re-auth", "user_id": "u_77341", "reason": "session_not_found"}
  ]'::jsonb,

  'app-server.log',

  -- log_files (new multi-log field)
  '[
    {
      "filename": "app-server.log",
      "logs": [
        {"ts": "2024-03-14T21:02:11.441Z", "level": "warn",  "msg": "Session lookup miss", "session_id": "sess_8x2kPqR", "user_id": "u_19284"},
        {"ts": "2024-03-14T21:02:14.883Z", "level": "warn",  "msg": "Session lookup miss", "session_id": "sess_mN3vLwY", "user_id": "u_77341"},
        {"ts": "2024-03-14T21:03:01.002Z", "level": "error", "msg": "Unauthenticated request to protected route", "path": "/api/v2/tickets", "user_id": null, "ip": "203.0.113.42"},
        {"ts": "2024-03-14T21:03:01.889Z", "level": "warn",  "msg": "Session lookup miss", "session_id": "sess_Qp8RtXz", "user_id": "u_50012"},
        {"ts": "2024-03-14T21:05:22.114Z", "level": "info",  "msg": "User forced re-auth", "user_id": "u_19284", "reason": "session_not_found"},
        {"ts": "2024-03-14T21:08:47.339Z", "level": "error", "msg": "Unauthenticated request to protected route", "path": "/api/v2/organizations", "user_id": null, "ip": "198.51.100.17"},
        {"ts": "2024-03-14T21:11:03.772Z", "level": "warn",  "msg": "Session lookup miss", "session_id": "sess_Zq1AbMn", "user_id": "u_30458"},
        {"ts": "2024-03-14T21:12:59.001Z", "level": "info",  "msg": "User forced re-auth", "user_id": "u_77341", "reason": "session_not_found"}
      ]
    },
    {
      "filename": "redis-monitor.log",
      "logs": [
        {"ts": "2024-03-14T20:58:03.001Z", "level": "warn",  "msg": "Memory usage at 89% of maxmemory", "used_memory_human": "1.22gb", "maxmemory_human": "1.37gb"},
        {"ts": "2024-03-14T20:59:41.774Z", "level": "warn",  "msg": "Eviction triggered", "policy": "allkeys-lru", "evicted_key": "flags:org_552:feature_dark_mode", "type": "feature-flag"},
        {"ts": "2024-03-14T21:00:12.338Z", "level": "warn",  "msg": "Eviction triggered", "policy": "allkeys-lru", "evicted_key": "sess_8x2kPqR", "type": "session"},
        {"ts": "2024-03-14T21:00:14.009Z", "level": "warn",  "msg": "Eviction triggered", "policy": "allkeys-lru", "evicted_key": "sess_mN3vLwY", "type": "session"},
        {"ts": "2024-03-14T21:01:55.221Z", "level": "warn",  "msg": "Memory usage at 97% of maxmemory", "used_memory_human": "1.33gb", "maxmemory_human": "1.37gb"},
        {"ts": "2024-03-14T21:02:03.887Z", "level": "warn",  "msg": "Eviction triggered", "policy": "allkeys-lru", "evicted_key": "sess_Qp8RtXz", "type": "session"},
        {"ts": "2024-03-14T21:02:09.113Z", "level": "warn",  "msg": "Eviction triggered", "policy": "allkeys-lru", "evicted_key": "ratelimit:ip:203.0.113.42", "type": "rate-limit"},
        {"ts": "2024-03-14T21:04:44.552Z", "level": "warn",  "msg": "Eviction triggered", "policy": "allkeys-lru", "evicted_key": "sess_Zq1AbMn", "type": "session"},
        {"ts": "2024-03-14T21:04:50.001Z", "level": "info",  "msg": "Memory pressure easing", "used_memory_human": "1.19gb", "maxmemory_human": "1.37gb"}
      ]
    }
  ]'::jsonb,

  -- screenshots (swap these for real URLs — Google Drive won't work, Imgur/Cloudinary/GitHub raw will)
  '[
    {
      "url": "https://placehold.co/800x400/1a1a1a/8fbc5a?text=ElastiCache+Memory+Graph+(replace+me)",
      "caption": "ElastiCache CloudWatch dashboard showing memory spike to 97% during the incident window"
    },
    {
      "url": "https://placehold.co/800x300/1a1a1a/d4b483?text=Redis+CONFIG+GET+maxmemory-policy+(replace+me)",
      "caption": "Redis CONFIG GET output showing allkeys-lru policy — sessions have no TTL and compete with unbounded feature-flag cache"
    }
  ]'::jsonb,

  -- mongo_collections
  '[
    {
      "collection": "sessions",
      "required_field": "userId",
      "synthetic_docs": [
        {
          "_id": {"$oid": "65f3a1b2c4d5e6f7a8b9c0d1"},
          "userId": "u_19284",
          "createdAt": {"$date": "2024-03-14T18:30:00.000Z"},
          "lastActive": {"$date": "2024-03-14T20:58:44.000Z"},
          "ip": "203.0.113.42",
          "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
        },
        {
          "_id": {"$oid": "65f3a1b2c4d5e6f7a8b9c0d2"},
          "userId": "u_77341",
          "createdAt": {"$date": "2024-03-14T19:15:22.000Z"},
          "lastActive": {"$date": "2024-03-14T20:59:01.000Z"},
          "ip": "198.51.100.17",
          "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        }
      ]
    },
    {
      "collection": "feature_flags",
      "required_field": "orgId",
      "synthetic_docs": [
        {
          "_id": {"$oid": "65f3a1b2c4d5e6f7a8b9c0d3"},
          "orgId": "org_552",
          "flag": "feature_dark_mode",
          "enabled": true,
          "rollout_pct": 100,
          "cached_at": {"$date": "2024-03-14T17:00:00.000Z"},
          "ttl_seconds": null
        },
        {
          "_id": {"$oid": "65f3a1b2c4d5e6f7a8b9c0d4"},
          "orgId": "org_881",
          "flag": "feature_ai_suggested_replies",
          "enabled": false,
          "rollout_pct": 0,
          "cached_at": {"$date": "2024-03-14T17:00:00.000Z"},
          "ttl_seconds": null
        }
      ]
    },
    {
      "collection": "audit_logs",
      "required_field": "actor_id",
      "synthetic_docs": [
        {
          "_id": {"$oid": "65f3a1b2c4d5e6f7a8b9c0d5"},
          "actor_id": "admin_003",
          "action": "redis_config_update",
          "target": "elasticache-prod-01",
          "changes": {"maxmemory-policy": {"from": "volatile-lru", "to": "allkeys-lru"}},
          "reason": "cache eviction too aggressive for feature flags — switched to allkeys",
          "ts": {"$date": "2024-02-21T14:33:00.000Z"}
        },
        {
          "_id": {"$oid": "65f3a1b2c4d5e6f7a8b9c0d6"},
          "actor_id": "deploy_bot",
          "action": "deploy",
          "target": "api-server",
          "version": "v2.14.1",
          "ts": {"$date": "2024-03-14T15:02:00.000Z"},
          "notes": "Adds feature-flag cache layer to Redis. No maxmemory changes."
        }
      ]
    }
  ]'::jsonb,

  -- hints
  '[
    {
      "cost": 0,
      "text": "The app-server logs tell you what happened to users. The redis-monitor logs tell you why. Read both — the timestamps line up."
    },
    {
      "cost": 25,
      "text": "Redis eviction policies matter. allkeys-lru evicts ANY key when memory is full — including active session keys with no TTL. volatile-lru only evicts keys that have an expiry set."
    },
    {
      "cost": 50,
      "text": "Check the audit_logs collection. Something changed in Redis about 3 weeks before the incident — right around when a new caching layer was introduced."
    }
  ]'::jsonb,

  -- questions
  '[
    {
      "label": "Root Cause",
      "question": "What is the root cause of users being randomly logged out?",
      "options": [
        "JWT tokens were expiring too aggressively due to a misconfigured TTL in the auth service",
        "Redis evicted active session keys because allkeys-lru policy competed sessions against unbounded feature-flag cache",
        "The ALB was not configured for sticky sessions, routing requests to nodes without the session in memory",
        "A MongoDB Atlas read timeout caused the session lookup fallback to fail silently"
      ],
      "correct_option": 1,
      "points": 150,
      "explanation": "The redis-monitor log clearly shows eviction events for sess_ keys. The allkeys-lru policy (set 3 weeks prior) makes Redis evict any key regardless of TTL — including active session keys — when memory fills up. The feature-flag cache added in v2.14.1 consumed the headroom on the t3.medium instance."
    },
    {
      "label": "Immediate Mitigation",
      "question": "What is the fastest safe mitigation that does not require a deployment or data loss?",
      "options": [
        "Flush all Redis keys to free memory, then restart the API servers",
        "Switch Redis maxmemory-policy from allkeys-lru to volatile-lru so only TTL-bearing keys are eligible for eviction",
        "Increase the ALB idle timeout to keep connections alive longer",
        "Scale the API server autoscaling group to reduce per-instance session load"
      ],
      "correct_option": 1,
      "points": 100,
      "explanation": "Changing maxmemory-policy to volatile-lru is a live Redis CONFIG SET — no deploy, no restart, no data loss. It immediately protects session keys (which have no TTL) from eviction while still allowing stale cache entries (which should have TTLs set) to be evicted normally. Flushing Redis would log everyone out instantly — worse than the incident."
    },
    {
      "label": "Long-term Fix",
      "question": "Which combination of changes prevents this class of incident from recurring?",
      "options": [
        "Add TTLs to all session keys and set TTLs on all feature-flag cache entries, then upsize the Redis instance",
        "Move sessions to MongoDB to remove Redis dependency entirely",
        "Enable Redis persistence (AOF) so evicted keys can be recovered on restart",
        "Separate Redis instances for sessions and cache, and add a CloudWatch alarm on memory utilization"
      ],
      "correct_option": 3,
      "points": 100,
      "explanation": "Separating the Redis instances means session eviction can never be caused by cache growth. A CloudWatch alarm on memory gives early warning before the instance hits the eviction threshold. Adding TTLs helps but doesn''t solve the root architectural issue of shared memory between critical (sessions) and non-critical (flags) data."
    }
  ]'::jsonb,

  -- tags
  '["redis", "session-management", "caching", "elasticache", "incident-response"]'::jsonb,

  -- variant_group
  NULL,

  -- active
  false  -- set to true once you''ve verified it looks right
);
