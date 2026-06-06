# STURNUS
### Simulated Ticket Utility for Root-cause Navigation and User Support

A CTF-style technical support training app. Trainees work through realistic support tickets, investigate server logs and MongoDB data, and answer diagnostic questions to earn points on a live leaderboard.

Also available as **V.H.S. (Virtual Helpdesk Simulator)** at [bekind.support](https://bekind.support) — same app, different audience, different theme.

---

## What It Does

Each challenge presents a real-world support scenario: a customer ticket, server logs, and a live MongoDB query console pointing at synthetic data. Trainees must:

1. Read the scenario and customer escalation
2. Identify red herrings in the observed data points
3. Review server logs (viewable and downloadable)
4. Query the MongoDB console to cross-reference collections
5. Use progressive hints (first free, later ones cost points)
6. Answer multi-part questions:
   - **Root Cause** — what actually happened and why
   - **Customer Response** — which message is clear, honest, and actionable vs. too technical, wrong, or a false promise

Scores persist on a public leaderboard. The leaderboard is theme-isolated — STURNUS users only see STURNUS scores, V.H.S. users only see V.H.S. scores.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Vanilla HTML/CSS/JS — no framework, no build step |
| Backend / Auth | Supabase (Postgres + Auth + RLS) |
| Hosting | Vercel (static files + one serverless function) |
| Email | Resend (SMTP relay for magic link emails) |
| Repo | GitHub |

The app runs entirely in the browser. All database access goes through Supabase's JS SDK with Row Level Security enforcing what each user can read or write. The only server-side code is a single Vercel serverless function (`api/invite.js`) that handles admin-initiated invites using the Supabase service role key.

There is no build process. Local development is:

```bash
python3 -m http.server 8000
# visit http://localhost:8000/splash.html
```

---

## Dual Theme System (STURNUS / V.H.S.)

The app serves two separate audiences from a single codebase and a single Supabase project:

- **STURNUS** (`support-training-app.vercel.app`) — internal team, restricted to `@murmuration.org` emails
- **V.H.S.** (`bekind.support`) — external friends and testers, open registration

Theme is assigned automatically on signup based on email domain and stored in the user's profile. It controls:

- CSS color palette (amber/green retro terminal vs. neon magenta/cyan 80s video store)
- Brand name and pixel art icon (starling vs. VHS cassette)
- Leaderboard visibility (each theme only sees its own users)

Theme detection uses the hostname — any domain ending in `bekind.support` loads the V.H.S. theme before the first paint, preventing flash. The theme CSS loads from a separate `theme-vhs.css` file via a blocking inline script in `<head>`.

Admins can manually reassign a user's theme from the Admin → All Scores tab.

---

## How to Play

1. Visit [support-training-app.vercel.app](https://support-training-app.vercel.app) (STURNUS) or [bekind.support](https://bekind.support) (V.H.S.)
2. Enter your email and click **Email me a magic link**
3. Click the link in your inbox → set your anonymous handle
4. Pick a challenge from the dashboard
5. Read the scenario, ticket quote, and architecture context
6. View the server logs and run MongoDB queries in the terminal
7. Reveal hints if you need them (first hint free, later hints cost points)
8. Answer the Root Cause and Customer Response questions
9. See your score breakdown and explanation in the debrief panel

**MongoDB console commands:**
- `show collections` — list all queryable collections
- `db.<name>.findOne()` — inspect the schema of a collection
- `db.<name>.find({ field: "value" })` — retrieve documents

---

## Challenge Design

Each challenge is stored as a JSON row in Postgres. The structure was designed to mirror real Tier 2 support workflows:

- **Scenario** — the incident description (third person, factual)
- **Ticket quote** — verbatim customer words, often frustrated or vague
- **Red herrings** — 2–3 plausible-looking data points that don't explain the root cause
- **Architecture context** — the tech stack and available query patterns
- **Server logs** — realistic structured log output from the relevant service
- **MongoDB collections** — 2–4 collections, some relevant and some distractor
- **Hints** — escalating specificity; hint 1 free, hint 2 costs 25 pts, hint 3 costs 50 pts
- **Questions** — multi-part, each with label, 4 options, correct index, points, and an explanation shown in the debrief

The `questions` array supports any number of questions per challenge. Current challenges use:
- Root Cause (100 pts) — what went wrong and why
- Customer Response (50 pts) — how to communicate it

A third question type (Escalation Notes) is planned.

---

## Admin Features

- Invite users via email (serverless function, deployed only — not available locally)
- Add, edit, delete, toggle active/inactive challenges via a JSON form
- View all scores across both themes with per-user theme badges
- Switch a user's theme with one click
- Reset a user's scores, submissions, and hint unlocks (useful for testing)

---

## How It Was Built

This project was built in a single extended session using **Claude** (Anthropic's AI) as a pair programming collaborator in Cowork mode. The workflow was conversational rather than code-first:

**What I brought:**
- Domain expertise — real support workflows, real MongoDB query patterns, real escalation scenarios based on actual tickets
- Product decisions — who the audience is, what the training should accomplish, how hard the challenges should be
- Content — the challenge scenarios, log data, MongoDB documents, and answer options were all grounded in real support experience
- Feedback loops — noticing when things were wrong (e.g., the `@@` email error explanation), when the design was off, when the UX felt unclear

**What Claude handled:**
- Translating product decisions into working code
- Suggesting architecture tradeoffs (e.g., single codebase vs. two deployments for the dual theme)
- Writing and debugging SQL, RLS policies, Postgres RPCs
- Iterating on the pixel art splash screen across multiple rounds of feedback
- Deployment troubleshooting (Vercel config, Supabase auth settings, DNS)

**Key iterations during the build:**

The original design had one MongoDB panel per collection. Midway through we redesigned it to a single realistic terminal with `show collections`, `findOne()`, and `find()` commands — making the investigation feel more like actual MongoDB work.

The scoring system was refactored from a single question per challenge to a `questions[]` array, enabling multiple question types per challenge and an explanation debrief panel.

The dual theme system started as a "separate branch" idea and evolved into a single-codebase hostname-detection approach with CSS variable overrides and localStorage persistence.

**What AI-assisted development felt like:**

Fast iteration on implementation, but the quality of the output was directly proportional to the quality of the decisions going in. When the product direction was clear, the code was right the first time. When it was vague ("make it more bird-like"), we went through multiple rounds. The domain expertise — knowing what a Tier 2 support investigation actually looks like — was irreplaceable and came entirely from the human side.

---

## Running Locally

```bash
git clone https://github.com/spacerschoicedecaf/support-training-app.git
cd support-training-app
```

Update `js/config.js` with your Supabase URL and anon key, then:

```bash
python3 -m http.server 8000
```

Visit `http://localhost:8000/splash.html`

The admin invite feature requires Vercel deployment (it uses the service role key via serverless function). Everything else works locally.

---

## Database Setup

Run these in Supabase SQL Editor in order:

1. `schema.sql` — tables, RLS policies, RPCs
2. `migrate-questions.sql` — questions column migration
3. `migrate-theme.sql` — theme column
4. `migrate-admin-reset.sql` — admin reset RPC
5. `seed-challenges.sql` — TICKET-001, TICKET-002, TICKET-003

Then promote yourself to admin:
```sql
UPDATE profiles SET role = 'admin' WHERE handle = 'your-handle';
```
