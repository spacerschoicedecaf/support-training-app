# Contributing a Challenge

Challenges are the core content of STURNUS. Each one is a simulated support incident: a customer ticket, log files, optional MongoDB data, and questions that reveal the root cause.

**Everything is created through the admin panel UI.** You don't need database access or any tools outside a browser.

---

## Prerequisites

You need an admin account. Ask Carson to invite you and flag your account as admin.

The admin panel is at `/admin` on the app URL. All challenge work happens in the **Challenges** tab.

---

## Challenge anatomy

| Field | What it is |
|---|---|
| **ID** | Unique slug, e.g. `TICKET-0004`. Use the next number in sequence. |
| **Title** | One short phrase — the incident name, e.g. *The Midnight Cascade* |
| **Scenario** | 2–4 sentences setting the scene. No spoilers. |
| **Customer Ticket** | The verbatim escalation message from the (fictional) customer. |
| **Architecture Context** | A brief description of the affected system stack. |
| **Red Herrings** | Plausible-but-irrelevant data points that appear in the incident. |
| **Log Files** | One or more JSON log files the trainee investigates. |
| **Screenshots** | Optional images (error pages, dashboards, etc.). Direct URLs only — Imgur and Cloudinary work well. |
| **MongoDB Collections** | Optional in-shell query data. |
| **Hints** | Progressive hints. First one should always be free. |
| **Questions** | 2–4 multiple-choice questions that test understanding of the root cause. |
| **Tags** | Skill labels, e.g. `log-analysis`, `smtp`, `session-management`. |

---

## Step-by-step

### 1. Write the story first

Before opening the form, sketch out:

- What actually went wrong (the root cause)
- What the customer saw and complained about
- What the logs show that proves it
- 2–3 things that look suspicious but aren't the cause (red herrings)
- What someone should understand after solving it (this becomes your questions)

Writing the questions before the log files makes it much easier to decide what evidence to include.

### 2. Create the log files

In the **Log Files** section of the form, click **+ Add log file**, give it a filename, and paste in a JSON array of log-line objects. Each entry should have at least a timestamp and a message — structure them however fits the system you're simulating.

```json
[
  { "ts": "2024-03-14T02:11:43Z", "level": "info",  "msg": "Worker started", "pid": 4821 },
  { "ts": "2024-03-14T02:11:51Z", "level": "error", "msg": "Redis connection timeout after 5000ms", "pid": 4821 },
  { "ts": "2024-03-14T02:11:52Z", "level": "warn",  "msg": "Session store unavailable, falling back", "pid": 4821 }
]
```

**Tips:**
- 30–80 log lines is a good range. Too few and there's nothing to investigate; too many and it becomes noise.
- Bury the important lines — don't put the smoking gun in the first five entries.
- Mix in plausible noise: routine INFO lines, unrelated warnings.
- Timestamps should be consistent and span a real incident window.
- If the incident involves multiple services, use a separate log file for each.

### 3. Add screenshots (optional)

In the **Screenshots** section, paste a direct image URL and an optional caption. The image must be a publicly accessible direct link — Imgur, Cloudinary, and GitHub raw URLs all work. Google Drive links will not embed.

### 4. Set up MongoDB collections (optional)

If the investigation involves querying a database, add collections in the **MongoDB Collections** field. Each entry in the JSON array needs:

- `database` — which DB the trainee must `use` to find this collection
- `collection` — the collection name
- `required_field` — the field they'll likely query on
- `synthetic_docs` — the fake documents

```json
[
  {
    "database": "accounts",
    "collection": "organizations",
    "required_field": "orgId",
    "synthetic_docs": [
      { "_id": { "$oid": "65f3a1b2c4d5e6f7a8b9c0d1" }, "orgId": "abc123", "plan": "enterprise" }
    ]
  }
]
```

Use `{ "$oid": "..." }` for ObjectId fields and `{ "$date": "..." }` for timestamps so they compare correctly in the shell. See the [Query Reference](mongo-reference.html) for supported operators.

If the challenge spans multiple databases (e.g. `accounts` and `profile_db`), add them as separate entries with different `database` values.

### 5. Write the hints

Hints are revealed on demand. The first hint should always be free (`cost: 0`) and point the trainee toward the right log file or query. Later hints can cost 5–15 points each and get progressively more specific.

Don't give away the answer — give the next step.

### 6. Write the questions

Each question has:
- **Label** — short category, e.g. *Root Cause*, *Contributing Factor*
- **Question** — a clear, unambiguous question about the incident
- **4 options** — one correct answer, three plausible wrong answers
- **Points** — typically 10–25 per question
- **Explanation** — shown after answering regardless of outcome; explain *why* the correct answer is right

**Tips:**
- Questions should build on each other: Q1 tests the immediate cause, Q2 tests the underlying reason, Q3 tests what should change.
- Wrong answers should be things a reasonable person might suspect given the red herrings.
- Explanations are where the learning happens — write them carefully.

### 7. Add tags

Use existing tags where they fit. Create new ones in `kebab-case` if nothing matches. Aim for 3–5 tags per challenge.

Current tags: `log-analysis`, `smtp`, `email-delivery`, `mongodb`, `indexing`, `query-performance`, `authentication`, `oauth`, `session-management`

### 8. Preview before activating

Save with **Active** unchecked. Then click **Preview** in the challenge table to see exactly what trainees will see — all fields rendered, questions listed with correct answers highlighted green.

Check:
- Scenario and ticket read naturally with no spoilers
- Log files open and the JSON is valid
- Questions are unambiguous
- Explanations are complete and correct

Once you're satisfied, click the status pill in the table to flip it to **Active**.

---

## Naming conventions

| Thing | Convention | Example |
|---|---|---|
| Challenge ID | `TICKET-XXXX` (4-digit, next in sequence) | `TICKET-0005` |
| Log filenames | `service-name.log` or `service-name.json` | `api-server.log` |
| Tags | `kebab-case`, describing the skill being tested | `log-analysis` |
| Variant group | `kebab-case`, shared across all variants of the same incident | `email-from-error` |

---

## Variants (advanced)

If you want multiple versions of the same incident — same scenario, different root cause — set the same **Variant Group** slug on all of them. The system rotates which version each user sees and resets after 90 days. This prevents spoilers between teammates who talk about a challenge.

---

## Pre-publish checklist

- [ ] Challenge ID follows `TICKET-XXXX` format and is the next in sequence
- [ ] Scenario doesn't reveal the root cause
- [ ] At least one log file with 30+ realistic entries
- [ ] Red herrings are plausible, not obviously irrelevant
- [ ] First hint is free (`cost: 0`)
- [ ] All questions have exactly 4 options, one correct
- [ ] All explanations are written
- [ ] Previewed in the admin panel and looks correct
- [ ] 3–5 tags added
- [ ] Active is **off** until you've QA'd it
