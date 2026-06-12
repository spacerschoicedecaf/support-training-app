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

### Playwright E2E smoke suite
Automated browser tests covering: login, challenge load, question flow, submission, debrief, admin form save. Currently deferred pending stable manual testing. Worth revisiting once the feature set stabilizes.

### Accessibility audit
Screen reader pass, keyboard navigation, focus management, color contrast checks. The modal focus trap pattern is in place but the rest is untested.

### Learning path / structured curriculum
Multi-week onboarding tracks with prerequisites — complete these 3 challenges before unlocking the next tier. More structured than tags alone. Requires a curriculum data model and progress tracking separate from XP.

### Admin challenge preview in import flow
Show a rendered preview of what the challenge will look like to users before confirming the bulk import. Currently admins see the raw field values in the preview table; a full render would catch formatting issues earlier.
