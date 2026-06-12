# STURNUS — Manual Test Plan

Run these before any significant push. Use your own admin account for the admin section; use a separate test account (or incognito) for the user section so you're not working from a pre-solved state.

---

## Auth

- [ ] Visit a protected page while logged out → redirected to `login.html`
- [ ] Request a magic link → click link in email → land on profile setup form
- [ ] Complete setup with a valid handle → redirected to `index.html`
- [ ] Visit `profile.html` when already set up → load profile dashboard, not setup form
- [ ] Sign out → redirected to `login.html`
- [ ] Attempt signup with a non-murmuration email on the STURNUS domain → error: "restricted to murmuration.org"
- [ ] Attempt signup with a duplicate handle → error: "handle already taken"

---

## Challenge List (index.html)

- [ ] Unsolved challenges appear in the Unsolved section
- [ ] Solved challenges appear in the Solved section
- [ ] Solved X / Y counter reflects actual counts
- [ ] Sort by Points → highest-value challenge first
- [ ] Sort by ID → TICKET-001, TICKET-002, etc.
- [ ] Click a skill tag → list filters to matching challenges only; click again to clear
- [ ] Type in search box → filters by title across both sections
- [ ] ✓ Solved badge shows on completed challenge cards
- [ ] Initial Response badge shows on your first-blood solve
- [ ] Hint-free badge shows when you solved without any hints
- [ ] Community difficulty rating (stars) shows on cards where ratings exist
- [ ] Leaderboard excludes admins
- [ ] Leaderboard shows only same-theme users

---

## Challenge Page (challenge.html)

### Setup
- [ ] Architecture context section starts collapsed; clicking label toggles it
- [ ] Red herrings section starts collapsed; clicking label toggles it
- [ ] Skill tags show as badges under the title

### Log viewer
- [ ] Clicking a log file tab loads that file's entries with syntax highlighting
- [ ] Copy button copies log contents to clipboard

### MongoDB console
- [ ] `show collections` lists available collection names
- [ ] `db.X.findOne()` returns the first document with formatting
- [ ] `db.X.find({})` returns all documents with a count
- [ ] `db.X.find({ field: "value" })` filters correctly
- [ ] `db.X.find({}, { field: 1 })` applies projection
- [ ] Unknown collection name returns a MongoNamespaceError
- [ ] Tab key autocompletes collection names
- [ ] ↑ / ↓ arrow keys cycle through command history
- [ ] `clear` clears the terminal output
- [ ] Export JSON button downloads the last query result

### Hints
- [ ] First hint shows as "Free" with a Reveal button
- [ ] Revealing a paid hint deducts points from the score preview
- [ ] Already-unlocked hints show their text on reload without requiring another unlock

### Questions
- [ ] Questions are locked until the previous one is answered
- [ ] Reasoning textarea appears per question (optional, not scored)
- [ ] Selecting an option enables the Check Answer button
- [ ] Checking an answer locks that question, reveals the explanation, and unlocks the next
- [ ] Submit button appears only after all questions are checked
- [ ] Answer options appear in a different order on each fresh load (shuffle)

### Timer
- [ ] Timer starts when the page loads
- [ ] Pause button stops the timer; play button resumes it
- [ ] Switching to another tab pauses the timer automatically
- [ ] Returning to the tab resumes the timer
- [ ] Switching to another app/window pauses the timer
- [ ] Navigating away and returning does not count away time toward your solve time

### Submission and debrief
- [ ] Submitting shows the debrief panel with per-question score breakdown
- [ ] Hint penalty appears in the debrief if hints were used
- [ ] First-blood alert appears if you were the first to solve
- [ ] Reloading after submission shows the answered/locked state
- [ ] Recommended next challenge appears after submission

### Walkthrough
- [ ] Walkthrough section appears after submission (if the challenge has one)
- [ ] Walkthrough is collapsed by default; clicking the header toggles it
- [ ] Estimated solve time shows next to the walkthrough header

### Post-solve reflection
- [ ] Reflection panel appears after submission
- [ ] Hovering star 3 highlights stars 1, 2, 3
- [ ] Clicking star 4 locks in stars 1–4 (stays after mouse leaves)
- [ ] Save post-mortem → "Saved." feedback
- [ ] Reload page → saved rating and text are restored

### Private notes
- [ ] Notes textarea is visible on the challenge page
- [ ] Typing and saving persists the note
- [ ] Reload → note is restored
- [ ] Notes are not visible to other users

### Keyboard shortcuts
- [ ] `?` opens the keyboard shortcuts modal
- [ ] `h` reveals the next available hint
- [ ] `s` submits if all questions are answered
- [ ] Modal closes on `Escape` or clicking outside

### Variant locking
- [ ] Navigating directly to a challenge in a solved variant group shows a locked message, not the challenge

---

## Profile Page (profile.html)

- [ ] Clicking your handle in the nav goes to the profile dashboard
- [ ] Stats strip shows correct score, rank, cases solved, hint-free count, and streak
- [ ] Case history lists all solved challenges with score earned, badges, and date
- [ ] Each history row links back to the challenge page
- [ ] First-blood and hint-free badges appear in history where earned
- [ ] Leaderboard in the right column shows all same-theme users; your row is highlighted
- [ ] Change handle → nav updates immediately without page reload
- [ ] Duplicate handle → "already taken" error
- [ ] Change password → mismatched confirmation → error
- [ ] Change password → valid → success message

---

## Admin — Challenges Tab (admin.html)

### Table
- [ ] Challenges table loads with ID, title, difficulty badge, community rating, and solve count
- [ ] Variant group badge shows for challenges in a group
- [ ] Clicking a column header sorts the table by that column
- [ ] Active/inactive toggle on each row updates without page reload

### Add / Edit
- [ ] Add a challenge with all required fields → appears in the table
- [ ] Edit an existing challenge → changes save correctly
- [ ] Intended difficulty field saves and shows in the table
- [ ] Walkthrough and est. minutes fields save and appear in preview

### Preview
- [ ] Preview button opens a read-only modal showing scenario, questions, walkthrough, and estimated time

### Duplicate
- [ ] Duplicate creates a new challenge pre-filled with all fields
- [ ] Suggested ID has a suffix (e.g., TICKET-001-B)
- [ ] Duplicate starts inactive

### Variant tools
- [ ] Force Variant → variant appears immediately for your test user on the challenge list

### Bulk operations
- [ ] Checkbox-select multiple challenges → bulk activate/deactivate works
- [ ] Reset my attempt → clears your submission, hints, and start record for that challenge; you can re-solve it

### Delete
- [ ] Delete a challenge → it's gone from the list; associated submissions are removed

### Import
- [ ] Click Import → panel opens with textarea and file upload
- [ ] Paste valid JSON array → Parse button shows preview table
- [ ] Upload a `.json` file → same preview
- [ ] TICKET-XXXX placeholder IDs are flagged as conflicts
- [ ] Editing a conflict ID to a non-conflicting value clears the flag
- [ ] Confirm import → challenges appear in the table as inactive
- [ ] Invalid JSON (missing required field) → validation error, no import

---

## Admin — Users Tab

- [ ] All users list with handle, theme badge, score, and solve count
- [ ] Switch Theme → user appears on the other theme's leaderboard on next load
- [ ] Reset Scores → user score goes to 0; their case history empties
- [ ] Reset Scores button is disabled for users with no activity

---

## Admin — Analytics Tab

- [ ] Each challenge shows solve count, average score, average time-to-solve, and average community difficulty rating
- [ ] Data updates after you complete or reset a solve

---

## Admin — Reflections Tab

- [ ] Submitted post-mortems appear with handle, challenge ID, difficulty rating, and text
- [ ] New reflection from a test solve appears here after save

---

## Admin — Invite Users Tab

- [ ] Send an invite to a valid email → recipient receives the magic link
- [ ] Clicking the link loads the profile setup form
- [ ] Inviting a non-murmuration address to the STURNUS domain → appropriate error (or block at Supabase level)

---

## Dual Theme / VHS

- [ ] Visit `bekind.support` → VHS theme (magenta/cyan palette, VHS branding)
- [ ] Visit STURNUS domain → STURNUS theme (amber/green palette, starling branding)
- [ ] Reload any page → no flash between themes before styles load
- [ ] VHS leaderboard shows only VHS users
- [ ] STURNUS leaderboard shows only STURNUS users

---

## Variant Rotation (full flow)

- [ ] Solve all challenges in a variant group
- [ ] Variant group disappears from Unsolved on the challenge list
- [ ] Use Force Variant in admin → variant reappears as a Review challenge
- [ ] The variant shown is different from the one you originally solved
- [ ] Solved section still shows the original solved challenge
