# STURNUS — Future Features

Features worth building, roughly in priority order. None of these are commitments.

---

## Near-term

### Learning path / "Start here" tags
Mark beginner challenges explicitly so new hires know where to start. Could be a tag (`beginner`, `start-here`) surfaced as a badge on the challenge card and a filtered view or dedicated section on the dashboard. Helps with onboarding without requiring a separate curriculum document.

### Explicit retry messaging for variant rotation
When a user has already solved a challenge and gets rotated to a variant, the UI should explain what's happening — something like "You've solved this case before. Here's a variant with different evidence." Currently there's no messaging and it can feel like a bug.

### Infrastructure glossary page
A reference page explaining key concepts used across challenges — what a COLLSCAN is, how MongoDB indexing works, what a 403 vs 401 means, etc. Lowers the floor for users who are newer to the stack. Similar in format to the existing mongo-reference.html.

---

## Medium-term

### Team activity feed on dashboard
A recent activity panel on index.html showing what teammates have been solving — "Alex solved The Midnight Cascade · 2h ago". Builds social pressure and visibility without being a full leaderboard. Requires a shared activity table or a view over submissions.

### Email digest
Weekly summary email to each user: challenges solved that week, current streak, leaderboard position, a nudge if they haven't logged in. Low-frequency, opt-in. Needs a scheduled Vercel function + SendGrid or Resend integration.

### Code/query validation questions
Currently all questions are multiple choice. A free-response question type where the answer is a MongoDB query, a regex, or a shell command that gets validated against expected output. Opens up a richer class of challenges. Significant front-end and backend work.

### Comments / discussion on challenges (post-solve)
After solving, users can leave a note visible to others — "the red herring about the deploy really got me." Useful once there's enough user volume for discussion to feel active. Requires a `challenge_comments` table and a comments panel in the post-solve view.

---

## Long-term / speculative

### Multi-tenancy
Currently STURNUS is a single-tenant app — one organization, one challenge library, one leaderboard. Expanding to other teams (data managers, account managers, etc.) would require:

- **Org/team scoping** — a `teams` table, challenges tagged to a team, leaderboards isolated by team. Similar to how the STURNUS/VHS theme split works today but generalized.
- **Challenge library isolation** — teams likely want their own incident types. A support engineering challenge about MongoDB indexing isn't useful for an account manager. Challenges would need to be scoped to a team or marked as shared.
- **Domain-agnostic onboarding** — the current @murmuration.org restriction is hardcoded. Multi-tenant would need per-team domain rules or invite-only enrollment per team.
- **Admin scoping** — team admins should only manage their own team's challenges and users, not see other teams' data.
- **Content strategy** — each team needs a meaningful challenge library before the platform is useful to them. The skill + bulk import flow helps, but someone still has to build the content.

The cleanest implementation path is probably a separate deploy per team (reuse the codebase, different Supabase project, different Vercel project) until the user base justifies a shared multi-tenant architecture. Lower engineering risk, faster to ship, easier to sunset if a team stops using it.



### Playwright E2E smoke suite
Automated browser tests covering: login, challenge load, question flow, submission, debrief, admin form save. Currently deferred pending stable manual testing. Worth revisiting once the feature set stabilizes.

### Accessibility audit
Screen reader pass, keyboard navigation, focus management, color contrast checks. The modal focus trap pattern is in place but the rest is untested.

### Learning path / structured curriculum
Multi-week onboarding tracks with prerequisites — complete these 3 challenges before unlocking the next tier. More structured than tags alone. Requires a curriculum data model and progress tracking separate from XP.

### Admin challenge preview in import flow
Show a rendered preview of what the challenge will look like to users before confirming the bulk import. Currently admins see the raw field values in the preview table; a full render would catch formatting issues earlier.

---

## Technical Debt & Engineering Improvements

These aren't features — they're places where the implementation is a known shortcut that could cause pain at scale or make the codebase harder to maintain.

### ~~Migration runner~~ ✓ resolved
~~There are 13 `.sql` files that have to be run by hand in order in the Supabase SQL editor.~~ Migrations now live in `migrations/` with numeric prefixes and are tracked by `migrate.js`. Run `npm run migrate` to apply pending migrations; `npm run migrate:status` to see what's applied.

### Normalize challenge content out of JSON blobs
Questions, hints, and options are stored as JSON inside Postgres columns. This makes the admin form simple but means you can't write SQL queries against individual fields — "which challenges have a hint that costs 20 points?" isn't askable without parsing. Normalizing questions into their own table would unlock real analytics and make the data model more honest.

### Client-side domain enforcement
The @murmuration.org restriction is enforced in client-side JavaScript at signup. A user could bypass it in devtools. Acceptable for a trust-based internal audience, but worth noting as a gap if access ever needs to be meaningfully enforced.

### Admin destructive actions
A single admin can wipe everyone's scores with one click — confirmation is a browser `confirm()` dialog. No audit log, no undo. At minimum, score resets should be logged to a table. At some point, role granularity (admin vs. super-admin) would help.

### Bulk import rollback
There's no way to undo a bad import — you'd have to delete each challenge manually. An import history table (or soft-delete with a batch ID) would let you reverse a bad batch in one action.

### No rate limiting on invite endpoint
The `/api/invite` Vercel function has no rate limiting. Low risk for an internal tool, but worth adding if the endpoint ever becomes more exposed.

### Update dashboard URLs in SERVICES.md
Several dashboard links in SERVICES.md are placeholder URLs — verify and update them with the actual deep links for Supabase, Vercel, Resend, Sentry, Grafana, and UptimeRobot once you know the correct paths for your accounts.

### Monitoring gaps
Grafana covers infrastructure metrics but several gaps remain:

- **Client-side JS errors** — uncaught exceptions in the browser are invisible. Sentry is the right fix: one CDN snippet added to each HTML file, captures errors with stack traces and the page they occurred on. Free tier is sufficient.
- **Vercel function errors** — `/api/invite` failures are silent unless a user reports them. Sentry's Node SDK can cover this, or wire Vercel log drains into Grafana.
- **Uptime alerting** — no ping-based check that fires if the site goes down. UptimeRobot (free) or Better Uptime would cover this in minutes.
- **Supabase logs** — auth errors, RLS rejections, and slow queries are available in the Supabase dashboard logs explorer but not surfaced anywhere proactively.

### Server-side timer
The solve timer is computed client-side and persisted via localStorage + DB. It works, but it's ultimately self-reported — a user could manipulate it. A proper solution records `started_at` server-side and computes elapsed on submission. The current approach is fine for a training tool where gaming the timer has no meaningful consequence.
