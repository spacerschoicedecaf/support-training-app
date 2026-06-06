# STURNUS
### Simulated Ticket Utility for Root-cause Navigation and User Support

A CTF-style technical support training app. Trainees work through realistic support tickets, investigate server logs and MongoDB data, and answer diagnostic questions to earn points on a live leaderboard.

Also available as **V.H.S. (Virtual Helpdesk Simulator)** at [bekind.support](https://bekind.support) — same codebase, different audience, different theme.

---

## What It Does

Each challenge presents a real support scenario: a customer ticket, server logs, and a live MongoDB query console. Trainees must read the incident, identify red herrings, investigate the evidence, use hints strategically (first free, later ones cost points), and answer two questions:

- **Root Cause** — what actually happened and why
- **Customer Response** — which message is clear, honest, and actionable vs. too technical, wrong, or a false promise

After submitting, a debrief panel explains why each answer was right or wrong. Scores persist on a theme-isolated leaderboard — STURNUS users only see STURNUS scores, V.H.S. users only see V.H.S. scores.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Vanilla HTML/CSS/JS — no framework, no build step |
| Backend / Auth | Supabase (Postgres + Auth + RLS) |
| Hosting | Vercel (static files + one serverless function) |
| Email | Resend (SMTP relay for magic link emails) |

No build process. Local development: `python3 -m http.server 8000`

---

## Dual Theme System

A single codebase and Supabase project serves two audiences:

- **STURNUS** — internal team, restricted to `@murmuration.org` emails
- **V.H.S.** (`bekind.support`) — external users, open registration

Theme is auto-assigned on signup by email domain and controls the color palette, brand name, pixel art icon, and leaderboard visibility. Hostname detection applies the theme before first paint to prevent flash. Admins can manually reassign themes from the scores tab.

---

## Variant Challenge Rotation

Challenges can be grouped into **variant groups** — multiple challenges with the same root cause but different synthetic data (different companies, different log patterns, different MongoDB collections). Variants rotate on a 90-day cooldown:

- A user completes a challenge → the whole group hides for 90 days
- After 90 days, a **different variant** reappears with new data
- Answer options shuffle randomly on every load so the correct answer isn't always the same letter
- Direct URL access to non-active variants is blocked

In the admin Challenges tab, any challenge with a variant group shows a **Force Variant** button that back-dates all group submissions to 92 days ago — making the next variant appear immediately for all users (useful for testing).

---

## How to Play

1. Visit the app and request a magic link
2. Set your anonymous handle (shown on the leaderboard instead of your email)
3. Open a challenge — read the scenario and customer ticket
4. View server logs, run MongoDB queries in the terminal (`show collections`, `db.X.findOne()`, `db.X.find({...})`)
5. Unlock hints if needed — first hint free, later ones cost points
6. Expand the Analysis section and answer the Root Cause and Customer Response questions
7. See your score breakdown in the debrief

---

## Challenge Structure

Each challenge is a Postgres JSON row:

- **Scenario + ticket quote** — the incident and verbatim customer escalation
- **Red herrings** — plausible-looking data points that don't explain the root cause
- **Architecture context** — tech stack and available query patterns
- **Server logs** — realistic structured log output (viewable, downloadable)
- **MongoDB collections** — 2–4 collections, some relevant, some distractor
- **Hints** — `[{text, cost}]` — escalating specificity
- **Questions** — `[{label, question, options[4], correct_option, points, explanation}]`
- **Variant group** — optional slug linking variants of the same root cause

---

## Admin Features

- Invite users by email
- Add/edit/delete/toggle challenges with full JSON form
- View all scores with per-user theme badges and one-click theme switching
- Reset individual user scores (wipes submissions and hint unlocks)
- **Force Variant** — immediately triggers the next variant for a group (bypasses 90-day cooldown)

---

## How It Was Built

Built in a single session using Claude (Anthropic) as a collaborator in Cowork mode. The workflow was conversational — product decisions and domain expertise came from the human side, implementation came from Claude.

**Key iterations:**

- MongoDB went from one panel per collection → a single realistic terminal (`show collections`, `findOne()`, `find()`) that mirrors actual Atlas workflow
- Scoring went from one question per challenge → a `questions[]` array with multi-part questions and an explanation debrief
- Theming went from "two separate deployments" → a single codebase with hostname detection, CSS variable overrides, and localStorage persistence
- Answer options shuffle randomly on each load so variants can't be pattern-matched by position
- Collapsible sections were added to manage page length — scenario and ticket are open by default, architecture and red herrings start collapsed

The domain expertise — knowing what a real support investigation looks like, what counts as a red herring, what makes a customer response good or bad — came entirely from the builder's background in Tier 2/3 support. The code was generated, the content was not.

---

## Running Locally

```bash
git clone https://github.com/spacerschoicedecaf/support-training-app.git
cd support-training-app
# update js/config.js with your Supabase URL and anon key
python3 -m http.server 8000
# visit http://localhost:8000/splash.html
```

The admin invite feature requires Vercel deployment. Everything else works locally.

---

## Database Setup

Run in Supabase SQL Editor in order:

1. `schema.sql`
2. `migrate-questions.sql`
3. `migrate-theme.sql`
4. `migrate-admin-reset.sql`
5. `migrate-variant-groups.sql`
6. `migrate-force-variant.sql`
7. `seed-challenges.sql`

Then promote yourself to admin:
```sql
UPDATE profiles SET role = 'admin' WHERE handle = 'your-handle';
```
