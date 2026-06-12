-- Performance indexes for common query patterns

-- Challenge page loads submissions(user_id, challenge_id) on every visit
CREATE INDEX IF NOT EXISTS idx_submissions_user_challenge
  ON submissions(user_id, challenge_id);

-- Same pattern for hint unlocks and notes
CREATE INDEX IF NOT EXISTS idx_hint_unlocks_user_challenge
  ON hint_unlocks(user_id, challenge_id);

CREATE INDEX IF NOT EXISTS idx_challenge_notes_user_challenge
  ON challenge_notes(user_id, challenge_id);

-- Leaderboard and profile queries sort by score
CREATE INDEX IF NOT EXISTS idx_profiles_score
  ON profiles(score DESC);
