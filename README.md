# STURNUS
### Simulated Ticket Utility for Root-cause Navigation and User Support

A CTF-style technical support training platform. Trainees work through realistic support tickets, investigate server logs and MongoDB data, and answer diagnostic questions to earn points on a live leaderboard.

Also available as **V.H.S. (Virtual Helpdesk Simulator)** at [bekind.support](https://bekind.support) — same codebase, different audience, retro video store theme.

---

**Status page:** [stats.uptimerobot.com/ALJJrQPvyA](https://stats.uptimerobot.com/ALJJrQPvyA)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Vanilla HTML/CSS/JS — no framework, no build step |
| Backend / Auth | Supabase (Postgres + Auth + RLS) |
| Hosting | Vercel (static files + one serverless function) |
| Email | Resend (SMTP relay for magic links and invites) |

---

## Features

### Challenge flow

Each challenge presents a structured incident investigation:

- **Incident scenario** — narrative context describing what was happening and when
- **Customer ticket** — verbatim escalation text with urgency and business impact
- **Architecture context** — customer's tech stack overview, starts collapsed
- **Red herrings** — observed data points that look suspicious but aren't the cause; identifying them is part of the challenge
- **Server log viewer** — multi-file structured JSON logs with syntax highlighting and copy button
- **MongoDB query console** — simulated Atlas shell supporting `show collections`, `db.X.findOne()`, `db.X.find({filter})`, projections, and `$and`/`$or` operators; supports multi-database setups; tab-autocomplete for collection names; ↑/↓ command history
- **Hints** — escalating specificity; first hint is always free, subsequent hints cost points deducted from score
- **Multi-question progressive reveal** — questions unlock one at a time; each has a Check Answer button and an explanation on the debrief
- **Reasoning textarea** — optional free-text field per question to capture your thinking before checking; not scored
- **Score preview** — live counter showing potential score minus hint penalties
- **Answer shuffling** — options randomize on every load so the correct answer is never in a predictable position
- **Solve timer** — visible elapsed time with pause/play; auto-pauses when you switch tabs or windows; persists across navigation so you can't cheat by refreshing
- **Debrief panel** — score breakdown per question with explanation text after submission
- **Walkthrough** — collapsible post-solve section showing one way to approach the case; written to be suggestive rather than prescriptive
- **Private notes** — per-challenge scratchpad saved to the database; visible only to you; persists across sessions
- **Keyboard shortcuts** — `?` opens a shortcuts modal; `h` reveals next hint; `s` submits if all questions are answered

### Post-solve reflection

After submitting, a post-mortem panel appears:

- **Difficulty rating** — 1–5 stars (Very easy → Very hard) with cumulative hover preview
- **Notes field** — free-text reflection; what would you check first next time?
- Saved to the database; visible to admins in the Reflections tab

### Badges

- **✓ Solved** — shown on all completed challenge cards
- **Initial Response** — awarded to the first user to solve a challenge
- **Hint-free** — completed without unlocking any hints

### Challenge list

- Challenges split into Unsolved and Solved sections with counts
- Sort by ID (curriculum order) or by Points (highest first)
- Tag filter — click any skill tag to filter the list
- Text search — filters by title across both sections
- Community difficulty rating shown on each card (average of all user ratings)
- Recommended next challenge appears after solving

### Leaderboard

- Top 20 users by score, filtered to the current theme
- Admins excluded
- Your own entry highlighted
- Gold/silver/bronze colors for top 3

### Profile page

- **Stats strip** — total score, leaderboard rank, cases solved, hint-free count, current streak
- **Leaderboard** — full theme leaderboard in the right column
- **Case history** — all solved challenges with score, badges, and date; each row links back to the challenge
- **Change handle** — validates uniqueness, updates nav live
- **Change password** — with confirmation field

### MongoDB reference

A dedicated reference page (`/mongo-reference.html`) covering query syntax, operators, projections, and common patterns. Linked from the query console.

### Dual theme system

One codebase and one Supabase project serves two audiences:

- **STURNUS** — restricted to `@murmuration.org` emails, amber/green palette, pixel starling
- **V.H.S.** (`bekind.support`) — open registration, magenta/cyan palette, pixel VHS cassette

Theme is auto-assigned on signup by email domain. Leaderboards are fully isolated — neither audience knows the other platform exists. Hostname detection applies the theme before first paint to prevent flash.

### Variant challenge rotation

Challenges can be grouped into **variant groups** — multiple challenges covering the same root cause with different synthetic data (company names, timestamps, ObjectIds). Rotation works on a 90-day cooldown:

- A user solves a challenge → the whole group hides for 90 days
- After 90 days, a different variant surfaces as a Review challenge
- Already-solved challenges remain visible in the Solved section
- Direct URL access to a non-active variant shows a locked message

---

## Admin Features

Admins access `/admin.html`. Non-admins are redirected.

### Challenges tab

**Add / Edit** — form covering all challenge fields: ID, title, scenario, ticket quote, architecture context, red herrings, server logs (multi-file), MongoDB collections (multi-database), hints, questions, walkthrough, estimated solve time, skill tags, intended difficulty, and variant group.

**Import** — paste a JSON array of challenges (or upload a `.json` file) to bulk-import. Validates structure and auto-assigns the next available `TICKET-NNN` ID to any challenge using the `TICKET-XXXX` placeholder — multiple placeholders in one batch increment sequentially. IDs are still editable in the preview before confirming. All imported challenges default to inactive.

**Challenge table** — sortable by ID, title, difficulty, community rating, or solves. Shows variant group badge, intended difficulty, community difficulty rating, and solve count per challenge.

**Preview** — opens a read-only preview of the challenge as users see it, including walkthrough and estimated time.

**Duplicate** — copies all fields with a suggested new ID, shifts timestamps back 30–90 days randomly, regenerates MongoDB ObjectIds. Starts inactive. Primary workflow for creating variants: duplicate → swap identifying details → set same Variant Group slug → activate.

**Force Variant** — back-dates all group submissions to 92 days ago so the next variant appears immediately. Use to test rotation without waiting 90 days.

**Toggle Active/Inactive** — hide challenges without deleting.

**Bulk activate/deactivate** — checkbox-select multiple challenges and activate or deactivate in one click.

**Reset my attempt** — clears your own submission, hints, and start record for a specific challenge. Useful for testing without affecting other users.

**Delete** — permanent; cascades to submissions and hint unlocks.

### Users tab

Lists all users across both themes with handle, theme badge, score, and challenges solved count.

- **Switch Theme** — move a user between STURNUS and V.H.S.
- **Reset Scores** — wipes score, deletes all submissions and hint unlocks. Disabled for users with no activity.

### Analytics tab

Per-challenge stats: solve count, average score, average time-to-solve, hint unlock rate, and average community difficulty rating. Useful for spotting challenges that are too hard, too easy, or where hints aren't helping.

### Reflections tab

All submitted post-mortems with handle, challenge ID, difficulty rating, and reflection text. Use to gauge which challenges are confusing or need rebalancing.

### Invite Users tab

Send a magic-link invite by email. The recipient sets their handle on first click. Sent via `/api/invite` (Vercel serverless) using the service role key, which never touches the client. Disable email signups in the Supabase dashboard to enforce invite-only access.

---


## Running Locally

```bash
git clone https://github.com/spacerschoicedecaf/support-training-app.git
cd support-training-app
# update js/config.js with your Supabase URL and anon key
python3 -m http.server 8000
# visit http://localhost:8000/splash.html
```

The admin invite feature requires Vercel deployment (the `/api/invite` function needs the service role key as an env var). Everything else works locally.

---

## Database Setup

Migrations are managed by `migrate.js` — a Node.js script that tracks what's been applied and runs only what's new.

**First, add your database connection string to `.env`:**

```
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
```

Find it in Supabase → Settings → Database → Connection string → URI.

**Fresh database:**
```bash
npm install
npm run migrate        # runs all 13 migrations in order
```

**Existing database (first time setting up the runner):**
```bash
npm install
npm run migrate:baseline   # marks existing migrations as applied without re-running
npm run migrate:status     # confirm all show ✓
```

**Going forward** — add new SQL files to `migrations/` with the next number prefix (e.g. `0014_my-change.sql`) and run `npm run migrate`.

**Seed data** — run `seed-challenges.sql` manually in the Supabase SQL Editor after migrating.

**Promote yourself to admin:**
```sql
UPDATE profiles SET role = 'admin' WHERE handle = 'your-handle';
```

---

## Deliberate Tradeoffs

**No staging environment.** Changes go straight to production. The admin Reset Scores and Force Variant buttons exist so the builder can use their own account for testing without permanently polluting the leaderboard.

**Theme assignment is client-enforced at signup, not server-enforced per request.** A determined user could assign themselves the wrong theme. Acceptable because both audiences are trust-based communities.

**Answer shuffle is client-side.** A user could inspect the DOM to find the original option order. The shuffle prevents muscle memory and pattern matching, not cheating — challenges are open-book by design.

**Supabase anon key is in client JS.** Intentional and safe. Supabase documents this pattern. All access control is enforced by Row Level Security. The anon key is not a secret.

**Service role key is Vercel-only.** The invite function requires it; it's set as a Vercel environment variable and never appears in any client-accessible file.

**No email verification on VHS.** Anyone can register with any email on the V.H.S. side. STURNUS verifies domain client-side at profile creation.

**Challenge content stored as JSON in Postgres, not normalized.** Simpler admin form (paste JSON) but no structured query path into individual questions or hints without parsing. A future migration could normalize questions into their own table for richer analytics.
