# STURNUS
### Simulated Ticket Utility for Root-cause Navigation and User Support

A CTF-style technical support training app. Trainees work through realistic support tickets, investigate server logs and MongoDB data, and answer diagnostic questions to earn points on a live leaderboard.

Also available as **V.H.S. (Virtual Helpdesk Simulator)** at [bekind.support](https://bekind.support) — same codebase, different audience, retro video store theme.

---

## What It Does

Each challenge presents a real support scenario: a customer ticket, server logs, and a live MongoDB query console. Trainees must read the incident, identify red herrings, investigate evidence, use hints strategically, and work through a series of diagnostic questions. After submitting, a debrief explains why each answer was right or wrong. A post-solve reflection captures difficulty rating and notes for spaced repetition.

Scores persist on a leaderboard that is fully isolated by theme — STURNUS users only ever see STURNUS scores, V.H.S. users only see V.H.S. scores. Neither audience knows the other platform exists.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Vanilla HTML/CSS/JS — no framework, no build step |
| Backend / Auth | Supabase (Postgres + Auth + RLS) |
| Hosting | Vercel (static files + one serverless function) |
| Email | Resend (SMTP relay for magic links and invites) |

No build process. Local development: `python3 -m http.server 8000`

---

## Feature Overview

### Challenge flow

- **Incident scenario** — collapsible section with the narrative context
- **Customer ticket** — verbatim escalation text
- **Architecture context** — tech stack overview, starts collapsed
- **Observed data points** — mix of real and irrelevant evidence; part of the challenge is identifying what actually matters
- **Server log viewer** — structured JSON logs in a modal with syntax highlighting and download button
- **MongoDB query console** — simulated Atlas shell: `show collections`, `db.X.findOne()`, `db.X.find({})`, with export to JSON
- **Hints** — escalating specificity; first hint is always free, subsequent hints cost points deducted from your score
- **Multi-question progressive reveal** — questions unlock one at a time; each has a Check Answer button and an explanation in the debrief
- **Score preview** — live counter showing potential score minus hint penalties
- **Answer shuffling** — options are randomized on every load so the correct answer is never in a predictable position
- **Debrief panel** — score breakdown per question with explanation text after submission

### Post-solve reflection

After submitting, a post-mortem panel appears:

- **Difficulty rating** — 1–5 stars (Very easy → Very hard); cumulative hover preview shows all stars up to the hovered value
- **Notes field** — free-text reflection: what would you check first next time? what was misleading?
- Saved to the database; visible to admins in the Reflections tab

### Badges

Three badges can appear on solved challenge cards and in case history:

- **✓ Solved** — always shown on completed challenges
- **Initial Response** — awarded to the first user to solve a challenge; antenna icon
- **Hint-free** — completed without unlocking any hints

### Leaderboard

- Shows top 20 users by score, filtered to the current theme
- Admins are excluded
- Your own entry is highlighted
- Ranked 1st, 2nd, 3rd entries get gold, silver, bronze colors

### Profile page

Accessible by clicking your handle in the nav from any page:

- **Stats strip** — total score, leaderboard rank, cases solved, hint-free count
- **Case history** — table of all solved challenges with score earned, badges, and date; each row links back to the challenge
- **Change handle** — validated, checks uniqueness, updates nav live without page reload
- **Change password** — with confirmation field

### Dual theme system

A single codebase and Supabase project serves two audiences:

- **STURNUS** — restricted to `@murmuration.org` emails, amber/green palette, pixel starling
- **V.H.S.** (`bekind.support`) — open registration, magenta/cyan palette, pixel VHS cassette

Theme is auto-assigned on signup by email domain and controls colors, brand name, icon, and leaderboard scope. Hostname detection applies the correct theme before first paint using a blocking `<link>` tag to prevent flash. Admins can manually reassign themes from the All Scores tab.

### Variant challenge rotation

Challenges can be grouped into **variant groups** — multiple challenges with the same root cause but different synthetic data (different company names, log timestamps, MongoDB ObjectIds). Variants rotate on a 90-day cooldown:

- A user completes a challenge → the whole group hides for 90 days
- After 90 days, a **different variant** surfaces as a Review challenge
- Already-solved challenges always remain visible in the Solved section
- Direct URL access to non-active variants shows a locked message

### Sorting and organization

The challenge list has two sort modes (toggle buttons at the top):

- **By ID** — default, preserves intended curriculum order
- **By Points** — highest value first, useful for score-hunting

Challenges are split into Unsolved and Solved sections with counts.

---

## Admin Features

### Invite Users tab

Send a magic-link invite by email. The recipient sets their handle and optional password on first click. Invite emails are sent via the `/api/invite` Vercel serverless function using the service role key, which never touches the client. Disable email signups in the Supabase dashboard to enforce invite-only access.

### Challenges tab

**Add / Edit** — full form for all challenge fields. Required: ID, title, scenario, ticket quote, server logs filename, server logs JSON, MongoDB collections JSON, hints JSON, questions JSON. Optional: Variant Group slug, skill tags JSON.

**Skill tags** — freeform tags displayed on the challenge page (e.g. `["log-analysis","smtp","mongodb"]`). Shown as badges under the challenge title to set expectations about what skills the challenge tests.

**Duplicate** — copies all fields from an existing challenge with a suggested new ID (e.g. TICKET-001-B). Timestamps shift back 30–90 days randomly and MongoDB ObjectIds are regenerated. Starts inactive. Primary workflow for creating variant challenges: duplicate, swap identifying details, set the same Variant Group slug, activate when ready.

**Force Variant** — visible on any challenge with a Variant Group set. Back-dates all group submissions to 92 days ago so the next variant appears immediately for all users. Use this to test rotation without waiting 90 days.

**Toggle Active/Inactive** — hide challenges without deleting them.

**Delete** — permanent; cascades to submissions and hint unlocks.

### All Scores tab

Lists all users across both themes with handle, theme badge, score, and challenges solved count.

**Switch Theme** — move a user between STURNUS and V.H.S. Takes effect on their next page load.

**Reset Scores** — wipes score to 0, deletes all submissions and hint unlocks. Disabled for users with no activity.

### Reflections tab

Lists all submitted post-mortems with handle, challenge ID, difficulty rating, and reflection text. Useful for gauging which challenges are too hard, too easy, or confusing.

---

## Deliberate Tradeoffs

These are known limitations that were consciously left in place:

**No staging environment.** Changes go straight to production. The admin Reset Scores button and Force Variant button exist specifically so the builder can use their own account for testing without polluting the leaderboard permanently.

**Theme assignment is client-enforced at signup, not server-enforced on every request.** A determined user could modify a request to assign themselves the wrong theme. This is acceptable because the two audiences are trust-based communities, not adversarial ones.

**Answer shuffle happens client-side.** A user could inspect the shuffled DOM to reverse-engineer the original option order. The shuffle exists to prevent muscle memory and pattern matching, not to prevent cheating — the challenges are open-book by design.

**Supabase anon key is in client JS.** This is intentional and safe — Supabase documents this pattern. All access control is enforced by Row Level Security policies on the database. The anon key is not a secret.

**Service role key is Vercel-only.** The invite function (`/api/invite`) requires the service role key, which is set as a Vercel environment variable and never appears in any client-accessible file. Invites cannot be sent from a local dev environment.

**No email verification on VHS.** Anyone can register with any email on the V.H.S. side. STURNUS verifies domain client-side at profile creation. Neither enforces email verification through Supabase's confirm email flow.

**Challenge content is stored as JSON in Postgres, not normalized.** This makes the admin form simpler (paste JSON) but means there's no structured query path into individual questions or hints. A future migration could normalize questions into their own table for analytics.

---

## Manual Test Plan

### Auth flow

| Test | Expected |
|------|----------|
| Visit any protected page while logged out | Redirect to login.html |
| Request magic link → click link in email | Land on profile.html setup form |
| Complete setup with a valid handle | Redirect to index.html |
| Visit profile.html when already set up | Load profile dashboard, not setup form |
| Sign out | Redirect to login.html |
| Non-murmuration email on STURNUS domain | Error: "restricted to murmuration.org" |
| Duplicate handle on signup | Error: "handle already taken" |

### Challenge list (index.html)

| Test | Expected |
|------|----------|
| Unsolved challenges appear in Unsolved section | ✓ |
| Solved challenges move to Solved section | ✓ |
| Sort by Points — highest first | ✓ |
| Sort by ID — TICKET-001, TICKET-002, etc. | ✓ |
| Solved badge shows ✓ Solved | ✓ |
| Initial Response badge shows on first-blood solve | ✓ |
| Hint-free badge shows when no hints were unlocked | ✓ |
| Leaderboard excludes admins | ✓ |
| Leaderboard only shows same-theme users | ✓ |

### Challenge page

| Test | Expected |
|------|----------|
| Architecture context and red herrings start collapsed | ✓ |
| Clicking section label toggles collapse | ✓ |
| `show collections` in mongo terminal lists collection names | ✓ |
| `db.X.findOne()` returns first document with syntax | ✓ |
| `db.X.find({})` returns all documents with count | ✓ |
| Unknown collection name returns MongoNamespaceError | ✓ |
| Export JSON button downloads last query result | ✓ |
| First hint shows as "Free" / Reveal button | ✓ |
| Unlocking a paid hint deducts points from score preview | ✓ |
| Already-unlocked hints show text on reload | ✓ |
| Questions are locked until previous question is checked | ✓ |
| Selecting an option enables Check answer | ✓ |
| Checking answer reveals explanation and unlocks next question | ✓ |
| Submit all appears only after all questions checked | ✓ |
| Debrief panel shows per-question breakdown and hint penalty | ✓ |
| First blood alert appears if you were first | ✓ |
| Reload after submission shows answered state | ✓ |
| Answer options in a different order on each fresh load | ✓ (shuffle) |
| Variant-locked challenge shows locked message, not challenge | ✓ |

### Post-solve reflection

| Test | Expected |
|------|----------|
| Reflection panel appears after submission | ✓ |
| Hovering star 3 highlights stars 1, 2, 3 | ✓ |
| Clicking star 4 locks in stars 1–4 (stays after mouse leaves) | ✓ |
| Save post-mortem → "Saved." feedback | ✓ |
| Reload page → saved rating and text restored | ✓ |
| Reflection appears in admin Reflections tab | ✓ |

### Profile page

| Test | Expected |
|------|----------|
| Click handle in nav → profile dashboard | ✓ |
| Stats reflect actual score and submission count | ✓ |
| Rank matches leaderboard position | ✓ |
| Case history shows all solved challenges | ✓ |
| Each history row links to the challenge | ✓ |
| First blood and hint-free badges appear in history | ✓ |
| Change handle → nav updates immediately | ✓ |
| Duplicate handle → "already taken" error | ✓ |
| Change password → confirm mismatch → error | ✓ |
| Change password → valid → success message | ✓ |

### Admin features

| Test | Expected |
|------|----------|
| Non-admin visiting admin.html | Redirect to index.html |
| Admin nav score shows 999 pts | ✓ |
| Invite sends email and invite link works | ✓ |
| Add challenge with all fields → appears in list | ✓ |
| Edit existing challenge → changes saved | ✓ |
| Toggle inactive → challenge hidden from users | ✓ |
| Duplicate → new challenge pre-filled, timestamps shifted | ✓ |
| Force Variant → variant appears on index for test user | ✓ |
| Delete challenge → gone from list and user submissions | ✓ |
| Reset Scores → user score 0, history empty | ✓ |
| Switch Theme → user appears on other theme's leaderboard | ✓ |
| Reflections tab shows submitted post-mortems | ✓ |

### Dual theme / VHS

| Test | Expected |
|------|----------|
| Visit bekind.support → VHS theme (magenta/cyan) | ✓ |
| Visit STURNUS domain → STURNUS theme (amber/green) | ✓ |
| Reload any page → no flash between themes | ✓ |
| VHS leaderboard contains only VHS users | ✓ |
| STURNUS user cannot see VHS leaderboard | ✓ |

---

## Running Locally

```bash
git clone https://github.com/spacerschoicedecaf/support-training-app.git
cd support-training-app
# update js/config.js with your Supabase URL and anon key
python3 -m http.server 8000
# visit http://localhost:8000/splash.html
```

The admin invite feature requires Vercel deployment (needs service role key). Everything else works locally.

---

## Database Setup

Run migrations in Supabase SQL Editor in order:

1. `schema.sql`
2. `migrate-questions.sql`
3. `migrate-theme.sql`
4. `migrate-admin-reset.sql`
5. `migrate-variant-groups.sql`
6. `migrate-force-variant.sql`
7. `migrate-reflection.sql`
8. `migrate-tags-firstblood.sql`
9. `seed-challenges.sql`

Then promote yourself to admin:
```sql
UPDATE profiles SET role = 'admin' WHERE handle = 'your-handle';
```
