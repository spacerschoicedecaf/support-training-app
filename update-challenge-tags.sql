-- ============================================================
-- Populate skill tags on existing challenges
-- Run in Supabase SQL editor
-- Adjust tag arrays to match your actual challenge content
-- ============================================================

-- View current state first (sanity check)
SELECT id, title, tags FROM public.challenges ORDER BY id;

-- ── UPDATE each challenge ────────────────────────────────────

-- TICKET-001: adjust tags to match your actual challenge content
UPDATE public.challenges
SET tags = '["log-analysis", "smtp", "email-delivery"]'::jsonb
WHERE id = 'TICKET-001' AND (tags IS NULL OR tags = '[]'::jsonb);

-- TICKET-002
UPDATE public.challenges
SET tags = '["mongodb", "indexing", "query-performance"]'::jsonb
WHERE id = 'TICKET-002' AND (tags IS NULL OR tags = '[]'::jsonb);

-- TICKET-003
UPDATE public.challenges
SET tags = '["authentication", "oauth", "session-management"]'::jsonb
WHERE id = 'TICKET-003' AND (tags IS NULL OR tags = '[]'::jsonb);

-- Add more as needed — copy the pattern above:
-- UPDATE public.challenges
-- SET tags = '["tag1", "tag2"]'::jsonb
-- WHERE id = 'TICKET-XXX' AND (tags IS NULL OR tags = '[]'::jsonb);

-- ── Verify ────────────────────────────────────────────────────
SELECT id, title, tags FROM public.challenges ORDER BY id;
