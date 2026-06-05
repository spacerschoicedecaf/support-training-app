-- ============================================================
-- Challenge Seeds — TICKET-001, TICKET-002, TICKET-003
-- Run AFTER:
--   TRUNCATE public.challenges, public.submissions, public.hint_unlocks RESTART IDENTITY CASCADE;
--   (also run migrate-questions.sql first if you haven't already)
--
-- Platform context: generic B2B engagement/analytics SaaS.
-- No political or civic tech terminology.
-- ============================================================


-- ─── TICKET-001: Zero Sent ───────────────────────────────────────────────────
-- Root cause: fromEmail field was saved as "j.hartwell@" (no domain).
-- The platform concatenated it with the sending domain → double @@ → SMTP 501.

INSERT INTO public.challenges (
  id, title, scenario, ticket_quote, red_herrings, arch_context,
  server_logs, server_logs_filename,
  mongo_collections,
  hints, questions, active
) VALUES (
  'TICKET-001',
  'Zero Sent',

  $$A customer reported that an email campaign sent on May 15th shows 0 emails delivered in the dashboard, even though the audience had 142 contacts. A follow-up campaign sent to the same audience the following day went out successfully to 135 recipients. The issue wasn't caught until a week later when the customer flagged it during a check-in call.$$,

  $$Hi — one of our email campaigns from last week is showing 0 emails sent, but we know the audience had over 140 contacts in it. We sent another email to the same audience the next day and that one delivered fine to 135 people. We're not sure what happened to the first one. Can you look into this?$$,

  $$["The campaign status shows Sent in the dashboard even though the delivered count is 0 — this could indicate a reporting or display bug rather than a real delivery failure.", "The follow-up campaign sent the next day to the same audience only reached 135 of the 142 contacts, suggesting the audience itself may have had problems."]$$::jsonb,

  $$When an email campaign is launched, the Emailing Service queues one message per contact and delivers each through the platform's SMTP provider. The From Email address is assembled from two parts: a local name typed manually by the user and a sending domain selected from a verified-domain dropdown. These are joined automatically at send time.

Campaign records are stored in the emailEfforts collection. Verified sending domains are stored in the emailDomains collection. Audience lists are stored in the segments collection. Email design templates are stored in the emailTemplates collection.

Available queries:
- db.emailEfforts.find({ organizationId: "<id>" })
- db.emailDomains.find({ organizationId: "<id>" })
- db.segments.find({ organizationId: "<id>" })
- db.emailTemplates.find({ organizationId: "<id>" })

The organization ID is visible in the server logs.$$,

  $$[
    {"timestamp":"2026-05-15T20:55:14.334Z","level":"info","service":"emailing-service","message":"Email effort job started.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","emailEffortId":"7c4e2f1a8b3d9e6c5f1a2b03","effortName":"May Newsletter - Final Send"}},
    {"timestamp":"2026-05-15T20:55:16.881Z","level":"info","service":"emailing-service","message":"Profiles prepared for sending.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","emailEffortId":"7c4e2f1a8b3d9e6c5f1a2b03","profileCount":95}},
    {"timestamp":"2026-05-15T20:55:31.114Z","level":"info","service":"emailing-service","message":"Queue batches built and seeded.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","emailEffortId":"7c4e2f1a8b3d9e6c5f1a2b03","batchCount":1,"emailCount":95}},
    {"timestamp":"2026-05-15T20:55:44.221Z","level":"info","service":"emailing-service","message":"Sending Email :: {\"subject\":\"May Newsletter - Final Send\",\"from\":\"Clearwater Direct <contact@mail.clearwaterdirect.com>\",\"to\":\"sample@example.com\"}","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","emailEffortId":"7c4e2f1a8b3d9e6c5f1a2b03"}},
    {"timestamp":"2026-05-15T20:58:44.229Z","level":"info","service":"emailing-service","message":"Email effort job completed.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","emailEffortId":"7c4e2f1a8b3d9e6c5f1a2b03","sentCount":95,"sentFailed":0}},
    {"timestamp":"2026-05-15T21:00:12.104Z","level":"info","service":"emailing-service","message":"Email effort job started.","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05","effortName":"Q3 Campaign - Final Reminder"}},
    {"timestamp":"2026-05-15T21:00:14.887Z","level":"info","service":"emailing-service","message":"Profiles prepared for sending.","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05","profileCount":142}},
    {"timestamp":"2026-05-15T21:00:31.203Z","level":"info","service":"emailing-service","message":"Queue batches built and seeded.","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05","batchCount":2,"emailCount":142}},
    {"timestamp":"2026-05-15T21:04:27.362Z","level":"info","service":"emailing-service","message":"Sending Email :: {\"subject\":\"Don't Miss Our Q3 Product Launch!\",\"from\":\"Hartwell & Associates <j.hartwell@@mail.hartwellassoc.com>\",\"to\":\"t.walker@yahoo.com\"}","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:27.439Z","level":"warn","service":"emailing-service","message":"Error Sending Queue Item with error \"Mail command failed: 501 5.5.2 MAIL FROM syntax error\" -- retrying","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:27.586Z","level":"info","service":"emailing-service","message":"Sending Email :: {\"subject\":\"Don't Miss Our Q3 Product Launch!\",\"from\":\"Hartwell & Associates <j.hartwell@@mail.hartwellassoc.com>\",\"to\":\"m.chen@gmail.com\"}","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:27.634Z","level":"warn","service":"emailing-service","message":"Error Sending Queue Item with error \"Mail command failed: 501 5.5.2 MAIL FROM syntax error\" -- retrying","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:27.821Z","level":"info","service":"emailing-service","message":"Sending Email :: {\"subject\":\"Don't Miss Our Q3 Product Launch!\",\"from\":\"Hartwell & Associates <j.hartwell@@mail.hartwellassoc.com>\",\"to\":\"d.okafor@outlook.com\"}","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:27.905Z","level":"warn","service":"emailing-service","message":"Error Sending Queue Item with error \"Mail command failed: 501 5.5.2 MAIL FROM syntax error\" -- retrying","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:28.112Z","level":"info","service":"emailing-service","message":"Sending Email :: {\"subject\":\"Don't Miss Our Q3 Product Launch!\",\"from\":\"Hartwell & Associates <j.hartwell@@mail.hartwellassoc.com>\",\"to\":\"k.johnson@hotmail.com\"}","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:28.219Z","level":"warn","service":"emailing-service","message":"Error Sending Queue Item with error \"Mail command failed: 501 5.5.2 MAIL FROM syntax error\" -- retrying","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:31.445Z","level":"warn","service":"emailing-service","message":"Retry limit reached for batch. Marking all items failed.","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05","batchFailCount":71}},
    {"timestamp":"2026-05-15T21:04:44.112Z","level":"info","service":"emailing-service","message":"Sending Email :: {\"subject\":\"Don't Miss Our Q3 Product Launch!\",\"from\":\"Hartwell & Associates <j.hartwell@@mail.hartwellassoc.com>\",\"to\":\"r.santos@gmail.com\"}","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:44.221Z","level":"warn","service":"emailing-service","message":"Error Sending Queue Item with error \"Mail command failed: 501 5.5.2 MAIL FROM syntax error\" -- retrying","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05"}},
    {"timestamp":"2026-05-15T21:04:47.334Z","level":"warn","service":"emailing-service","message":"Retry limit reached for batch. Marking all items failed.","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05","batchFailCount":71}},
    {"timestamp":"2026-05-15T21:04:48.002Z","level":"info","service":"emailing-service","message":"Email effort job completed.","metadata":{"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","emailEffortId":"6b3f2a1c9d4e5f6a7b8c9d05","sentCount":0,"sentFailed":142}},
    {"timestamp":"2026-05-15T21:05:22.114Z","level":"info","service":"emailing-service","message":"Email effort job started.","metadata":{"organizationId":"66960837bb74e876062d7726","emailEffortId":"7c4e2f1a8b3d9e6c5f1a2b04","effortName":"May Product Update"}},
    {"timestamp":"2026-05-15T21:05:24.441Z","level":"info","service":"emailing-service","message":"Profiles prepared for sending.","metadata":{"organizationId":"66960837bb74e876062d7726","emailEffortId":"7c4e2f1a8b3d9e6c5f1a2b04","profileCount":203}},
    {"timestamp":"2026-05-15T21:05:52.334Z","level":"info","service":"emailing-service","message":"Sending Email :: {\"subject\":\"May Product Update\",\"from\":\"Pinnacle Solutions <news@mail.pinnaclesolutions.io>\",\"to\":\"member@example.com\"}","metadata":{"organizationId":"66960837bb74e876062d7726","emailEffortId":"7c4e2f1a8b3d9e6c5f1a2b04"}},
    {"timestamp":"2026-05-15T21:09:11.334Z","level":"info","service":"emailing-service","message":"Email effort job completed.","metadata":{"organizationId":"66960837bb74e876062d7726","emailEffortId":"7c4e2f1a8b3d9e6c5f1a2b04","sentCount":203,"sentFailed":0}}
  ]$$::jsonb,

  'emailing-service-logs.json',

  $$[
    {
      "collection": "emailEfforts",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"6b1a2c3d4e5f6a7b8c9d0e01"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Q3 Campaign - Announcement","status":"SENT","fromName":"Hartwell & Associates","fromEmail":"j.hartwell@mail.hartwellassoc.com","domainId":"6b2e4f1a9c3d7e5f8a2b4c02","subject":"Big news from Hartwell & Associates","effortStats":{"sentCount":201,"sentFailed":0,"processBatchEmailCount":201},"createdAt":{"$date":"2026-04-10T09:00:00.000Z"},"startedAt":{"$date":"2026-04-12T14:00:00.000Z"}},
        {"_id":{"$oid":"6b3f2a1c9d4e5f6a7b8c9d05"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Q3 Campaign - Final Reminder","status":"SENT","fromName":"Hartwell & Associates","fromEmail":"j.hartwell@","domainId":"6b2e4f1a9c3d7e5f8a2b4c02","subject":"Don't Miss Our Q3 Product Launch!","effortStats":{"sentCount":0,"sentFailed":142,"processBatchEmailCount":142},"createdAt":{"$date":"2026-05-14T18:32:11.000Z"},"startedAt":{"$date":"2026-05-15T21:00:12.000Z"}},
        {"_id":{"$oid":"6b3f2a1c9d4e5f6a7b8c9d06"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Q3 Campaign - Day Of","status":"SENT","fromName":"Hartwell & Associates","fromEmail":"j.hartwell@mail.hartwellassoc.com","domainId":"6b2e4f1a9c3d7e5f8a2b4c02","subject":"Today's the Day — Our Q3 Launch is Live!","effortStats":{"sentCount":135,"sentFailed":0,"processBatchEmailCount":135},"createdAt":{"$date":"2026-05-15T19:00:00.000Z"},"startedAt":{"$date":"2026-05-16T14:00:00.000Z"}},
        {"_id":{"$oid":"6b1a2c3d4e5f6a7b8c9d0e02"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Year-End Wrap-Up","status":"SENT","fromName":"Hartwell & Associates","fromEmail":"j.hartwell@mail.hartwellassoc.com","domainId":"6b2e4f1a9c3d7e5f8a2b4c02","subject":"Our Year in Review","effortStats":{"sentCount":312,"sentFailed":0,"processBatchEmailCount":312},"createdAt":{"$date":"2025-12-10T10:00:00.000Z"},"startedAt":{"$date":"2025-12-15T14:00:00.000Z"}},
        {"_id":{"$oid":"6b1a2c3d4e5f6a7b8c9d0e03"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Q4 Preview","status":"DRAFT","fromName":"Hartwell & Associates","fromEmail":"j.hartwell@mail.hartwellassoc.com","domainId":"6b2e4f1a9c3d7e5f8a2b4c02","subject":"What's Coming in Q4","effortStats":{"sentCount":0,"sentFailed":0,"processBatchEmailCount":0},"createdAt":{"$date":"2026-05-20T11:00:00.000Z"},"startedAt":null}
      ]
    },
    {
      "collection": "emailDomains",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"6b2e4f1a9c3d7e5f8a2b4c02"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","hostname":"mail.hartwellassoc.com","status":"ACTIVE","dkimStatus":"VERIFIED","spfStatus":"VERIFIED","createdAt":{"$date":"2025-09-03T12:14:00.000Z"}},
        {"_id":{"$oid":"6b2e4f1a9c3d7e5f8a2b4c03"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","hostname":"hartwellassoc.com","status":"ACTIVE","dkimStatus":"VERIFIED","spfStatus":"VERIFIED","createdAt":{"$date":"2024-11-15T08:00:00.000Z"}}
      ]
    },
    {
      "collection": "emailTemplates",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"6c1d2e3f4a5b6c7d8e9f0a01"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Product Launch Template","subject":"Something exciting is coming","previewText":"We've been working on something big...","status":"ACTIVE","createdAt":{"$date":"2026-03-01T10:00:00.000Z"}},
        {"_id":{"$oid":"6c1d2e3f4a5b6c7d8e9f0a02"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Reminder - 1 Day","subject":"Tomorrow's the big day!","previewText":"We can't wait to show you...","status":"ACTIVE","createdAt":{"$date":"2026-03-01T10:00:00.000Z"}},
        {"_id":{"$oid":"6c1d2e3f4a5b6c7d8e9f0a03"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Year-End Recap","subject":"Looking back on a great year","previewText":"It's been quite a year...","status":"ACTIVE","createdAt":{"$date":"2025-11-01T09:00:00.000Z"}},
        {"_id":{"$oid":"6c1d2e3f4a5b6c7d8e9f0a04"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"General Outreach","subject":"Staying in touch","previewText":"A quick update from our team...","status":"ARCHIVED","createdAt":{"$date":"2024-08-01T08:00:00.000Z"}}
      ]
    },
    {
      "collection": "segments",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"6e2f3a4b5c6d7e8f9a0b1c01"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Q3 Launch Audience","profileCount":142,"status":"ACTIVE","createdAt":{"$date":"2026-04-05T09:00:00.000Z"}},
        {"_id":{"$oid":"6e2f3a4b5c6d7e8f9a0b1c02"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"All Active Contacts","profileCount":1204,"status":"ACTIVE","createdAt":{"$date":"2024-09-01T08:00:00.000Z"}},
        {"_id":{"$oid":"6e2f3a4b5c6d7e8f9a0b1c03"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Year-End Subscribers","profileCount":312,"status":"ACTIVE","createdAt":{"$date":"2025-11-20T10:00:00.000Z"}},
        {"_id":{"$oid":"6e2f3a4b5c6d7e8f9a0b1c04"},"organizationId":"6b2e4f1a9c3d7e5f8a2b4c01","name":"Lapsed Contacts","profileCount":87,"status":"ARCHIVED","createdAt":{"$date":"2024-12-01T08:00:00.000Z"}}
      ]
    }
  ]$$::jsonb,

  $$[
    {"cost":0,"text":"The campaign status shows Sent and 142 contacts were queued — but look at the effortStats carefully. Does the delivery count match what the dashboard is reporting?"},
    {"cost":10,"text":"The server logs contain an ID that maps directly to the campaign record. Use it to look up the effort in MongoDB and inspect the sender configuration fields."},
    {"cost":20,"text":"Open the emailEfforts document and read every field in the sender section carefully. One of them isn't a valid email address."}
  ]$$::jsonb,

  $$[
    {
      "label": "Root Cause",
      "question": "What prevented the \"Q3 Campaign - Final Reminder\" from delivering any emails?",
      "options": [
        "The sending domain's DKIM and SPF records had expired, causing the email provider to reject the batch.",
        "The From Email address was missing the domain — it was saved as 'j.hartwell@' with no domain name, causing the SMTP server to reject every message with a syntax error.",
        "The audience segment had a data issue that prevented valid recipient addresses from being resolved.",
        "The emailing service hit a provider rate limit and marked all 142 messages as failed before delivery was attempted."
      ],
      "correct_option": 1,
      "points": 100,
      "explanation": "The emailEfforts document for the failed campaign shows fromEmail: 'j.hartwell@' — the domain is missing. When the platform assembled the From address, it joined 'j.hartwell@' with the sending domain and produced 'j.hartwell@@mail.hartwellassoc.com' — two @ symbols. This is visible in the server logs in the 'from' field of every Sending Email entry. The SMTP server returned '501 5.5.2 MAIL FROM syntax error' for every message. The emailDomains collection confirms the domain itself is fully VERIFIED — it's not a domain configuration issue."
    },
    {
      "label": "Customer Response",
      "question": "Which of the following is the best response to send to the customer?",
      "options": [
        "We found the issue — the From Email address on the campaign was saved as 'j.hartwell@' without a domain name. When the platform sent the campaign, it assembled an invalid From address which caused every message to be rejected by the mail server. The campaign that worked the next day used the correct address. To fix this, you'll need to create a new campaign with a correctly formatted From Email. I'm happy to walk you through that.",
        "The submitEmailCampaign job failed because the fromEmail field in the emailEfforts document was persisted without a domain component, causing the SMTP envelope construction to produce a malformed MAIL FROM address that the MTA rejected with a 501 5.5.2 response code.",
        "This looks like it may be related to your sending domain configuration. DKIM and SPF settings occasionally need to be refreshed, which can cause campaigns to fail. I'd recommend checking your domain settings and resending.",
        "There was a temporary issue with our email delivery provider on May 15th that affected a small number of campaigns. Your emails have been flagged for automatic resend and your contacts should receive them within 24 hours."
      ],
      "correct_option": 0,
      "points": 50,
      "explanation": "Option A is correct: it explains what happened in plain language the customer can act on, correctly identifies the cause without blaming the customer, and gives a clear next step. Option B is accurate but full of internal jargon (SMTP, MAIL FROM, MTA, 501 5.5.2) that a non-technical customer won't understand. Option C is wrong — the domains are VERIFIED and DKIM/SPF are not the issue. Option D is false — there was no provider outage, and emails will not be automatically resent."
    }
  ]$$::jsonb,

  true
);


-- ─── TICKET-002: Submit and Next ─────────────────────────────────────────────
-- Root cause: recently created accounts return resolvedValue: null in the Call
-- Service identity lookup, preventing queue item retrieval and submission.

INSERT INTO public.challenges (
  id, title, scenario, ticket_quote, red_herrings, arch_context,
  server_logs, server_logs_filename,
  mongo_collections,
  hints, questions, active
) VALUES (
  'TICKET-002',
  'Submit and Next',

  $$A customer reported that some of their representatives are hitting a blank screen when trying to submit call survey responses. The support team reproduced a GraphQL error on submission but could not identify why only some representatives were affected — others on the same team were submitting calls without any issues.$$,

  $$Hi — some of my team members are having a problem during our outreach calls. When they finish a call and click submit, the screen just goes blank and nothing gets saved. Other people on the team are doing fine. We can't figure out what's different. Can you look into this?$$,

  $$["One of the affected representatives mentioned they were running Ubuntu Linux and had seen some general browser sluggishness earlier in the session.", "The call disposition recorded at the time of the errors was 'No Answer,' while most successful submissions show 'Contacted' or 'Left Voicemail.'"]$$::jsonb,

  $$When a representative submits a call survey response, the Call Service records the attempt and advances the queue to the next contact. Each attempt is stored in the calls collection, linked to the representative by userId and to the campaign by callCampaignId. Representative accounts are stored in the users collection. Active outreach campaigns are tracked in the callCampaigns collection. The contacts being called are stored in the contacts collection.

Available queries:
- db.calls.find({ organizationId: "<id>" })
- db.users.find({ "organizations.organizationId": "<id>" })
- db.contacts.find({ organizationId: "<id>" })
- db.callCampaigns.find({ organizationId: "<id>" })

The organization ID is visible in the server logs.$$,

  $$[
    {"timestamp":"2026-05-27T23:58:04.221Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f01","resolvedValue":"7b2c3d4e5f6a7b8c9d0e1f01"}},
    {"timestamp":"2026-05-27T23:58:04.889Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f01","outcome":"success"}},
    {"timestamp":"2026-05-27T23:58:46.112Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f02","resolvedValue":"7b2c3d4e5f6a7b8c9d0e1f02"}},
    {"timestamp":"2026-05-27T23:58:46.771Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f02","outcome":"success"}},
    {"timestamp":"2026-05-28T00:01:12.301Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c01","resolvedValue":"5fce7a21b3d4e891a2340c01"}},
    {"timestamp":"2026-05-28T00:01:12.408Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c01","outcome":"success"}},
    {"timestamp":"2026-05-28T00:02:33.614Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c02","resolvedValue":"5fce7a21b3d4e891a2340c02"}},
    {"timestamp":"2026-05-28T00:02:33.891Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c02","outcome":"success"}},
    {"timestamp":"2026-05-28T00:03:15.009Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f01","resolvedValue":"7b2c3d4e5f6a7b8c9d0e1f01"}},
    {"timestamp":"2026-05-28T00:03:15.334Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f01","outcome":"success"}},
    {"timestamp":"2026-05-28T00:04:37.891Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"6a2f8b3cd5e7f920b3451d02","resolvedValue":null}},
    {"timestamp":"2026-05-28T00:04:38.498Z","level":"error","service":"call-service","message":"The queue item does not exist. Please check and try again.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"6a2f8b3cd5e7f920b3451d02","errorCode":"SUBMIT_CALL","outcome":"failure"}},
    {"timestamp":"2026-05-28T00:05:02.441Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f02","resolvedValue":"7b2c3d4e5f6a7b8c9d0e1f02"}},
    {"timestamp":"2026-05-28T00:05:03.102Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f02","outcome":"success"}},
    {"timestamp":"2026-05-28T00:06:18.774Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c01","resolvedValue":"5fce7a21b3d4e891a2340c01"}},
    {"timestamp":"2026-05-28T00:06:19.221Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c01","outcome":"success"}},
    {"timestamp":"2026-05-28T00:07:21.014Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"69b5c3d1e8f0a741c2560e03","resolvedValue":null}},
    {"timestamp":"2026-05-28T00:07:22.103Z","level":"error","service":"call-service","message":"The queue item does not exist. Please check and try again.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"69b5c3d1e8f0a741c2560e03","errorCode":"SUBMIT_CALL","outcome":"failure"}},
    {"timestamp":"2026-05-28T00:08:04.889Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f01","resolvedValue":"7b2c3d4e5f6a7b8c9d0e1f01"}},
    {"timestamp":"2026-05-28T00:08:05.334Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f01","outcome":"success"}},
    {"timestamp":"2026-05-28T00:08:44.112Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c02","resolvedValue":"5fce7a21b3d4e891a2340c02"}},
    {"timestamp":"2026-05-28T00:08:44.881Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c02","outcome":"success"}},
    {"timestamp":"2026-05-28T00:09:11.441Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"6c3a9e4fd6f1b852e4672e04","resolvedValue":null}},
    {"timestamp":"2026-05-28T00:09:12.008Z","level":"error","service":"call-service","message":"The queue item does not exist. Please check and try again.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"6c3a9e4fd6f1b852e4672e04","errorCode":"SUBMIT_CALL","outcome":"failure"}},
    {"timestamp":"2026-05-28T00:10:03.221Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f02","resolvedValue":"7b2c3d4e5f6a7b8c9d0e1f02"}},
    {"timestamp":"2026-05-28T00:10:03.889Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f02","outcome":"success"}},
    {"timestamp":"2026-05-28T00:11:05.334Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c02","resolvedValue":"5fce7a21b3d4e891a2340c02"}},
    {"timestamp":"2026-05-28T00:11:05.779Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"5ead4678f1b2c3d4e5f60001","userId":"5fce7a21b3d4e891a2340c02","outcome":"success"}},
    {"timestamp":"2026-05-28T00:12:18.441Z","level":"info","service":"call-service","message":"Resolving user identity for call submission.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f01","resolvedValue":"7b2c3d4e5f6a7b8c9d0e1f01"}},
    {"timestamp":"2026-05-28T00:12:19.002Z","level":"info","service":"call-service","message":"Queue item found. Submitting call attempt.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","userId":"7b2c3d4e5f6a7b8c9d0e1f01","outcome":"success"}}
  ]$$::jsonb,

  'call-service-logs.json',

  $$[
    {
      "collection": "calls",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"6d4b1e5f7e2c963a5f783f01"},"organizationId":"5ead4678f1b2c3d4e5f60001","callCampaignId":"5f1a2b3c4d5e6f7a8b9c0d01","userId":"5fce7a21b3d4e891a2340c01","contactId":"7f6d3e2c1b0a9f8e7d6c5b4a","status":"submitted","disposition":"No Answer","attemptDuration":23,"createdAt":{"$date":"2026-05-28T00:01:15.000Z"}},
        {"_id":{"$oid":"6d4b1e5f7e2c963a5f783f02"},"organizationId":"5ead4678f1b2c3d4e5f60001","callCampaignId":"5f1a2b3c4d5e6f7a8b9c0d01","userId":"5fce7a21b3d4e891a2340c02","contactId":"7f6d3e2c1b0a9f8e7d6c5b4b","status":"submitted","disposition":"Contacted","attemptDuration":147,"createdAt":{"$date":"2026-05-28T00:02:33.000Z"}},
        {"_id":{"$oid":"6d4b1e5f7e2c963a5f783f03"},"organizationId":"5ead4678f1b2c3d4e5f60001","callCampaignId":"5f1a2b3c4d5e6f7a8b9c0d01","userId":"6a2f8b3cd5e7f920b3451d02","contactId":"7f6d3e2c1b0a9f8e7d6c5b4c","status":"error","disposition":"No Answer","attemptDuration":8,"errorCode":"SUBMIT_CALL","createdAt":{"$date":"2026-05-28T00:04:38.000Z"}},
        {"_id":{"$oid":"6d4b1e5f7e2c963a5f783f04"},"organizationId":"5ead4678f1b2c3d4e5f60001","callCampaignId":"5f1a2b3c4d5e6f7a8b9c0d01","userId":"69b5c3d1e8f0a741c2560e03","contactId":"7f6d3e2c1b0a9f8e7d6c5b4d","status":"error","disposition":"Contacted","attemptDuration":89,"errorCode":"SUBMIT_CALL","createdAt":{"$date":"2026-05-28T00:07:22.000Z"}},
        {"_id":{"$oid":"6d4b1e5f7e2c963a5f783f05"},"organizationId":"5ead4678f1b2c3d4e5f60001","callCampaignId":"5f1a2b3c4d5e6f7a8b9c0d01","userId":"6c3a9e4fd6f1b852e4672e04","contactId":"7f6d3e2c1b0a9f8e7d6c5b4e","status":"error","disposition":"No Answer","attemptDuration":14,"errorCode":"SUBMIT_CALL","createdAt":{"$date":"2026-05-28T00:09:11.000Z"}},
        {"_id":{"$oid":"6d4b1e5f7e2c963a5f783f06"},"organizationId":"5ead4678f1b2c3d4e5f60001","callCampaignId":"5f1a2b3c4d5e6f7a8b9c0d01","userId":"5fce7a21b3d4e891a2340c02","contactId":"7f6d3e2c1b0a9f8e7d6c5b4f","status":"submitted","disposition":"Left Voicemail","attemptDuration":56,"createdAt":{"$date":"2026-05-28T00:11:05.000Z"}}
      ]
    },
    {
      "collection": "users",
      "required_field": "organizations.organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"5fce7a21b3d4e891a2340c01"},"email":"morgan@clearstoneresearch.com","status":"Active","createdAt":{"$date":"2025-10-02T14:02:54.411Z"},"updatedAt":{"$date":"2026-05-28T00:01:14.000Z"},"auth0UserId":"auth0|5fce7a22c1a039abcd123456","firstName":"Morgan","lastName":"Callahan","organizations":[{"organizationId":"5ead4678f1b2c3d4e5f60001","organizationName":"Clearstone Research","status":"Active","roleName":"Admin","hasOrgLevelAccess":true,"lastLogin":{"$date":"2026-05-28T00:01:00.000Z"}}]},
        {"_id":{"$oid":"5fce7a21b3d4e891a2340c02"},"email":"j.reyes@clearstoneresearch.com","status":"Active","createdAt":{"$date":"2025-11-15T09:22:31.000Z"},"updatedAt":{"$date":"2026-05-28T00:11:04.000Z"},"auth0UserId":"auth0|5fce7a21b3d4e891a2340c99","firstName":"Jamie","lastName":"Reyes","organizations":[{"organizationId":"5ead4678f1b2c3d4e5f60001","organizationName":"Clearstone Research","status":"Active","roleName":"Representative","hasOrgLevelAccess":true,"lastLogin":{"$date":"2026-05-28T00:02:00.000Z"}}]},
        {"_id":{"$oid":"6a2f8b3cd5e7f920b3451d02"},"email":"tkowalski@gmail.com","status":"Active","createdAt":{"$date":"2026-05-27T00:24:49.802Z"},"updatedAt":{"$date":"2026-05-28T00:04:37.000Z"},"auth0UserId":"auth0|6a2f8b3de9b154bcde234567","firstName":"Taylor","lastName":"Kowalski","organizations":[{"organizationId":"5ead4678f1b2c3d4e5f60001","organizationName":"Clearstone Research","status":"Active","roleName":"Representative","hasOrgLevelAccess":true,"lastLogin":{"$date":"2026-05-27T01:31:35.000Z"}}]},
        {"_id":{"$oid":"69b5c3d1e8f0a741c2560e03"},"email":"rperez@example.com","status":"Active","createdAt":{"$date":"2026-04-22T11:14:03.519Z"},"updatedAt":{"$date":"2026-05-28T00:07:21.000Z"},"auth0UserId":"auth0|69b5c3d2f7c265cdef345678","firstName":"Rafael","lastName":"Perez","organizations":[{"organizationId":"5ead4678f1b2c3d4e5f60001","organizationName":"Clearstone Research","status":"Active","roleName":"Representative","hasOrgLevelAccess":true,"lastLogin":{"$date":"2026-04-22T14:00:00.000Z"}}]},
        {"_id":{"$oid":"6c3a9e4fd6f1b852e4672e04"},"email":"d.williams@gmail.com","status":"Active","createdAt":{"$date":"2026-05-15T16:33:21.000Z"},"updatedAt":{"$date":"2026-05-28T00:09:10.000Z"},"auth0UserId":"auth0|6c3a9e4fd6f1b852e4672e99","firstName":"Destiny","lastName":"Williams","organizations":[{"organizationId":"5ead4678f1b2c3d4e5f60001","organizationName":"Clearstone Research","status":"Active","roleName":"Representative","hasOrgLevelAccess":true,"lastLogin":{"$date":"2026-05-15T17:00:00.000Z"}}]}
      ]
    },
    {
      "collection": "callCampaigns",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"5f1a2b3c4d5e6f7a8b9c0d01"},"organizationId":"5ead4678f1b2c3d4e5f60001","name":"Q2 Customer Feedback Survey","status":"ACTIVE","profileCount":142,"createdById":"5fce7a21b3d4e891a2340c01","startedAt":{"$date":"2026-05-27T23:00:00.000Z"},"completedAt":null,"createdAt":{"$date":"2026-05-20T10:15:00.000Z"}},
        {"_id":{"$oid":"5f1a2b3c4d5e6f7a8b9c0d02"},"organizationId":"5ead4678f1b2c3d4e5f60001","name":"Q1 NPS Follow-Up","status":"COMPLETED","profileCount":89,"createdById":"5fce7a21b3d4e891a2340c01","startedAt":{"$date":"2026-04-10T18:00:00.000Z"},"completedAt":{"$date":"2026-04-12T22:00:00.000Z"},"createdAt":{"$date":"2026-04-08T09:00:00.000Z"}},
        {"_id":{"$oid":"5f1a2b3c4d5e6f7a8b9c0d03"},"organizationId":"5ead4678f1b2c3d4e5f60001","name":"Product Usage Study 2026","status":"COMPLETED","profileCount":234,"createdById":"5fce7a21b3d4e891a2340c01","startedAt":{"$date":"2026-03-01T17:00:00.000Z"},"completedAt":{"$date":"2026-03-05T21:00:00.000Z"},"createdAt":{"$date":"2026-02-28T11:00:00.000Z"}},
        {"_id":{"$oid":"5f1a2b3c4d5e6f7a8b9c0d04"},"organizationId":"5ead4678f1b2c3d4e5f60001","name":"Q3 Pilot Survey","status":"DRAFT","profileCount":0,"createdById":"5fce7a21b3d4e891a2340c01","startedAt":null,"completedAt":null,"createdAt":{"$date":"2026-05-25T14:00:00.000Z"}}
      ]
    },
    {
      "collection": "contacts",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"7f6d3e2c1b0a9f8e7d6c5b4a"},"organizationId":"5ead4678f1b2c3d4e5f60001","firstName":"Marcus","lastName":"Jenkins","phone":"+12125550141","email":"m.jenkins@example.com","status":"Active","lastContactedAt":{"$date":"2026-05-28T00:01:15.000Z"}},
        {"_id":{"$oid":"7f6d3e2c1b0a9f8e7d6c5b4b"},"organizationId":"5ead4678f1b2c3d4e5f60001","firstName":"Sandra","lastName":"Okonkwo","phone":"+13475550288","email":"s.okonkwo@example.com","status":"Active","lastContactedAt":{"$date":"2026-05-28T00:02:33.000Z"}},
        {"_id":{"$oid":"7f6d3e2c1b0a9f8e7d6c5b4c"},"organizationId":"5ead4678f1b2c3d4e5f60001","firstName":"Damon","lastName":"Reyes","phone":"+17185550334","email":null,"status":"Active","lastContactedAt":{"$date":"2026-05-28T00:04:38.000Z"}},
        {"_id":{"$oid":"7f6d3e2c1b0a9f8e7d6c5b4d"},"organizationId":"5ead4678f1b2c3d4e5f60001","firstName":"Yolanda","lastName":"Ferreira","phone":"+16465550412","email":"y.ferreira@example.com","status":"Active","lastContactedAt":{"$date":"2026-05-28T00:07:22.000Z"}},
        {"_id":{"$oid":"7f6d3e2c1b0a9f8e7d6c5b4e"},"organizationId":"5ead4678f1b2c3d4e5f60001","firstName":"Terrence","lastName":"Washington","phone":"+12015550567","email":"t.washington@example.com","status":"Unsubscribed","lastContactedAt":{"$date":"2026-04-15T14:22:00.000Z"}}
      ]
    }
  ]$$::jsonb,

  $$[
    {"cost":0,"text":"The error affects some representatives but not others. Don't get distracted by the device type or the call disposition — focus on what the failing submissions have in common."},
    {"cost":25,"text":"The calls collection shows you which userIds are hitting errors. Use one of those userIds to look up the corresponding user record directly."},
    {"cost":50,"text":"Compare the createdAt dates on the user records tied to failed calls versus the ones tied to successful calls."}
  ]$$::jsonb,

  $$[
    {
      "label": "Root Cause",
      "question": "What should the support agent document when escalating this ticket to engineering?",
      "options": [
        "The call submission mutation is failing for all representatives in the organization regardless of account age.",
        "The call submission mutation is failing only for representatives whose accounts were created recently — older accounts in the same organization are submitting successfully.",
        "The call submission mutation is failing because representatives using the 'No Answer' disposition are hitting an unsupported response path.",
        "The call submission mutation is failing for representatives on Ubuntu due to a browser compatibility issue."
      ],
      "correct_option": 1,
      "points": 100,
      "explanation": "Cross-referencing the calls collection with the users collection reveals the pattern: Morgan Callahan (createdAt: October 2025) and Jamie Reyes (November 2025) submit successfully. Taylor Kowalski (May 27, 2026), Rafael Perez (April 22, 2026), and Destiny Williams (May 15, 2026) all fail. The server logs confirm that resolvedValue is null for the failing userIds — the Call Service can't resolve their identity, so the queue item lookup fails. This is a bug affecting accounts created after a certain date, not a browser or disposition issue."
    },
    {
      "label": "Customer Response",
      "question": "Which of the following is the best response to send to the customer?",
      "options": [
        "We've identified the issue — it affects representatives whose accounts were created recently. Accounts created before a certain date are working fine; newer accounts aren't being recognized correctly by the call submission system. We've escalated this to engineering as a bug. Until a fix is deployed, the affected representatives won't be able to submit calls. I'll send you a follow-up as soon as we have a timeline.",
        "We've reviewed the logs and found that the submitCallAttempt mutation is returning a queue lookup failure because resolvedValue is null for recently provisioned userIds. Engineering has been notified and is investigating the identity resolution service.",
        "The issue seems to be related to the specific call dispositions your team is selecting. Try having the affected representatives choose a different disposition when they experience the blank screen — this should allow the submission to go through.",
        "All representatives in your account are currently experiencing submission errors due to a platform-wide service disruption. Our team is working on it and all affected submissions will be automatically restored."
      ],
      "correct_option": 0,
      "points": 50,
      "explanation": "Option A is correct: it explains the scope clearly (recent accounts affected, older ones working fine), gives the customer the right expectation (no workaround, waiting for a fix), commits to a follow-up, and uses language the customer can understand. Option B is accurate but full of internal technical terminology inappropriate for a customer-facing message. Option C is wrong — the disposition is a red herring, errors happen on 'No Answer' AND 'Contacted' calls. Option D overstates the scope — it's not all representatives, only recently created ones."
    }
  ]$$::jsonb,

  true
);


-- ─── TICKET-003: Stuck in Progress ───────────────────────────────────────────
-- Root cause: the profile-service worker failed to locate the contact list by
-- jobId on both its initial attempt and its single retry. The export record
-- remains in InProgress indefinitely.

INSERT INTO public.challenges (
  id, title, scenario, ticket_quote, red_herrings, arch_context,
  server_logs, server_logs_filename,
  mongo_collections,
  hints, questions, active
) VALUES (
  'TICKET-003',
  'Stuck in Progress',

  $$A customer reported that a contact list export they launched the previous afternoon was still showing In Progress the following morning with no file available for download. Other exports run by the same account on the same day completed successfully within minutes. Support investigated and identified an active error pattern in the export processing pipeline affecting a specific job, with the failure logged across multiple retries.$$,

  $$Hey — our export has been stuck since yesterday afternoon and still isn't done. It just shows In Progress and nothing downloads. We need this list for outreach today — can someone look into this?$$,

  $$["The stuck export was submitted later in the afternoon than the other completed exports from the same account, which could suggest a time-based queue issue or rate limiting rather than a pipeline bug.", "The stuck export's source segment is larger than the other segments the account exported that day, which could suggest a timeout caused by record volume."]$$::jsonb,

  $$When a user triggers a contact list export, the Export Service creates an ExportFile record with a status of InProgress and submits a job to the processing pipeline via a unique jobId. A background worker in the Profile Service picks up the job, resolves the associated contact list by jobId, and builds the export batch. When processing completes, the record updates to Complete with a record count. If the worker cannot find the contact list, the job cannot proceed and the ExportFile record remains stuck in InProgress.

Export records are stored in the exportFiles collection. Source segments are stored in the segments collection. Organization account records are stored in the organizations collection.

Available queries:
- db.exportFiles.find({ organizationId: "<id>" })
- db.segments.find({ organizationId: "<id>" })
- db.organizations.find({ organizationId: "<id>" })

The organization ID and jobId are both visible in the server logs.$$,

  $$[
    {"timestamp":"2026-04-14T21:18:04.112Z","level":"info","service":"export-service","message":"Export job created and submitted to processing pipeline.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","jobId":"324e6011-6a8a-4299-89ba-30ea8c8f9176","sourceType":"Segment"}},
    {"timestamp":"2026-04-14T21:18:05.334Z","level":"info","service":"profile-service","message":"Worker received export job event.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","jobId":"324e6011-6a8a-4299-89ba-30ea8c8f9176"}},
    {"timestamp":"2026-04-14T21:18:05.891Z","level":"info","service":"profile-service","message":"Contact list resolved for export job.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","jobId":"324e6011-6a8a-4299-89ba-30ea8c8f9176"}},
    {"timestamp":"2026-04-14T21:18:06.204Z","level":"info","service":"profile-service","message":"Batch job submitted successfully.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","jobId":"324e6011-6a8a-4299-89ba-30ea8c8f9176"}},
    {"timestamp":"2026-04-14T21:18:44.771Z","level":"info","service":"export-service","message":"Export job completed.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","jobId":"324e6011-6a8a-4299-89ba-30ea8c8f9176","records":2322}},
    {"timestamp":"2026-04-14T21:19:03.558Z","level":"info","service":"export-service","message":"Export job created and submitted to processing pipeline.","metadata":{"organizationId":"66960837bb74e876062d7726","jobId":"ae195e37-e58f-4aee-a43f-4890e0089604","sourceType":"Segment"}},
    {"timestamp":"2026-04-14T21:19:04.102Z","level":"info","service":"profile-service","message":"Worker received export job event.","metadata":{"organizationId":"66960837bb74e876062d7726","jobId":"ae195e37-e58f-4aee-a43f-4890e0089604"}},
    {"timestamp":"2026-04-14T21:19:04.619Z","level":"info","service":"profile-service","message":"Contact list resolved for export job.","metadata":{"organizationId":"66960837bb74e876062d7726","jobId":"ae195e37-e58f-4aee-a43f-4890e0089604"}},
    {"timestamp":"2026-04-14T21:19:05.003Z","level":"info","service":"profile-service","message":"Batch job submitted successfully.","metadata":{"organizationId":"66960837bb74e876062d7726","jobId":"ae195e37-e58f-4aee-a43f-4890e0089604"}},
    {"timestamp":"2026-04-14T21:20:12.950Z","level":"info","service":"export-service","message":"Export job created and submitted to processing pipeline.","metadata":{"organizationId":"683f42490ab6408e84607d8c","exportFileId":"69deaf8ca53769ba5be5bb1c","jobId":"86288176-5b4e-4e40-8a12-e93125489562","sourceType":"Segment"}},
    {"timestamp":"2026-04-14T21:20:13.201Z","level":"info","service":"profile-service","message":"Worker received export job event.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"86288176-5b4e-4e40-8a12-e93125489562"}},
    {"timestamp":"2026-04-14T21:20:13.445Z","level":"info","service":"profile-service","message":"Resolving contact list for export job.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"86288176-5b4e-4e40-8a12-e93125489562","segmentId":"69dea9d52eb7cc1f62020b30"}},
    {"timestamp":"2026-04-14T21:20:13.512Z","level":"warn","service":"profile-service","message":"Contact list not found by job ID: 86288176-5b4e-4e40-8a12-e93125489562","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"86288176-5b4e-4e40-8a12-e93125489562"}},
    {"timestamp":"2026-04-14T21:20:13.601Z","level":"error","service":"profile-service","message":"Error submitting batch job. Contact list could not be resolved.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"86288176-5b4e-4e40-8a12-e93125489562"}},
    {"timestamp":"2026-04-14T21:20:14.112Z","level":"info","service":"profile-service","message":"Retrying export job (attempt 2 of 2).","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"86288176-5b4e-4e40-8a12-e93125489562"}},
    {"timestamp":"2026-04-14T21:20:31.447Z","level":"info","service":"export-service","message":"Export job completed.","metadata":{"organizationId":"66960837bb74e876062d7726","jobId":"ae195e37-e58f-4aee-a43f-4890e0089604","records":554}},
    {"timestamp":"2026-04-14T21:20:49.883Z","level":"info","service":"export-service","message":"Export job created and submitted to processing pipeline.","metadata":{"organizationId":"667480f3c8682b970d5b4bcd","jobId":"d7a57acb-06a3-47e1-9175-537706395beb","sourceType":"Import"}},
    {"timestamp":"2026-04-14T21:20:50.312Z","level":"info","service":"profile-service","message":"Worker received export job event.","metadata":{"organizationId":"667480f3c8682b970d5b4bcd","jobId":"d7a57acb-06a3-47e1-9175-537706395beb"}},
    {"timestamp":"2026-04-14T21:20:50.771Z","level":"info","service":"profile-service","message":"Contact list resolved for export job.","metadata":{"organizationId":"667480f3c8682b970d5b4bcd","jobId":"d7a57acb-06a3-47e1-9175-537706395beb"}},
    {"timestamp":"2026-04-14T21:20:51.089Z","level":"info","service":"profile-service","message":"Batch job submitted successfully.","metadata":{"organizationId":"667480f3c8682b970d5b4bcd","jobId":"d7a57acb-06a3-47e1-9175-537706395beb"}},
    {"timestamp":"2026-04-14T21:21:44.889Z","level":"warn","service":"profile-service","message":"Contact list not found by job ID: 86288176-5b4e-4e40-8a12-e93125489562","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"86288176-5b4e-4e40-8a12-e93125489562"}},
    {"timestamp":"2026-04-14T21:21:45.003Z","level":"error","service":"profile-service","message":"Error submitting batch job. Retry limit reached.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"86288176-5b4e-4e40-8a12-e93125489562"}},
    {"timestamp":"2026-04-14T21:21:45.201Z","level":"warn","service":"profile-service","message":"Export job exhausted all retries. ExportFile record will remain in InProgress state.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"86288176-5b4e-4e40-8a12-e93125489562"}},
    {"timestamp":"2026-04-14T21:21:52.334Z","level":"info","service":"export-service","message":"Export job completed.","metadata":{"organizationId":"68d471bc9dfdd2fb471b157f","jobId":"f95e7d3a-0c5b-4367-9095-822bdad9e321","records":3868}},
    {"timestamp":"2026-04-14T21:22:05.119Z","level":"info","service":"export-service","message":"Export job created and submitted to processing pipeline.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"a00a3b13-df8c-480d-b989-2544b3813942","sourceType":"Segment"}},
    {"timestamp":"2026-04-14T21:22:06.447Z","level":"info","service":"profile-service","message":"Worker received export job event.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"a00a3b13-df8c-480d-b989-2544b3813942"}},
    {"timestamp":"2026-04-14T21:22:10.445Z","level":"info","service":"export-service","message":"Segment profile count resolved.","metadata":{"organizationId":"683f42490ab6408e84607d8c","segmentId":"69dea9d52eb7cc1f62020b30","profileCount":3847}},
    {"timestamp":"2026-04-14T21:22:10.891Z","level":"info","service":"profile-service","message":"Contact list resolved for export job.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"a00a3b13-df8c-480d-b989-2544b3813942"}},
    {"timestamp":"2026-04-14T21:22:11.204Z","level":"info","service":"profile-service","message":"Batch job submitted successfully.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"a00a3b13-df8c-480d-b989-2544b3813942"}},
    {"timestamp":"2026-04-14T21:22:47.662Z","level":"info","service":"export-service","message":"Export job completed.","metadata":{"organizationId":"683f42490ab6408e84607d8c","jobId":"a00a3b13-df8c-480d-b989-2544b3813942","records":6177}}
  ]$$::jsonb,

  'profile-service-logs.json',

  $$[
    {
      "collection": "exportFiles",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"69de6b5e4097e87b3ecd31cc"},"organizationId":"683f42490ab6408e84607d8c","name":"Enterprise Accounts - Q1","audience":"Enterprise Accounts Q1 2026","sourceId":"69de6b253a5b97d4e287bb4e","sourceType":"Segment","dataType":"Profile","groupProfilesBy":"NotGrouped","status":"Complete","jobId":"468bdde4-3c2a-48a8-b924-2c479cdbe505","records":11215,"priority":"Low","createdAt":{"$date":"2026-04-14T16:29:18.529Z"},"updatedAt":{"$date":"2026-04-14T16:32:59.188Z"}},
        {"_id":{"$oid":"69de69d44097e87b3ecd31c4"},"organizationId":"683f42490ab6408e84607d8c","name":"Q2 Regional Prospects","audience":"Q2 Regional Segment","sourceId":"69c6b3a02ba0d52110aa5081","sourceType":"Segment","dataType":"Profile","groupProfilesBy":"NotGrouped","status":"Complete","jobId":"a00a3b13-df8c-480d-b989-2544b3813942","records":6177,"priority":"Low","createdAt":{"$date":"2026-04-14T16:22:44.565Z"},"updatedAt":{"$date":"2026-04-14T16:26:38.462Z"}},
        {"_id":{"$oid":"69deaf8ca53769ba5be5bb1c"},"organizationId":"683f42490ab6408e84607d8c","name":"Q2 Enterprise Prospects","audience":"Q2 Enterprise Prospect List","sourceId":"69dea9d52eb7cc1f62020b30","sourceType":"Segment","dataType":"Profile","groupProfilesBy":"NotGrouped","status":"InProgress","jobId":"86288176-5b4e-4e40-8a12-e93125489562","records":null,"priority":"Low","createdAt":{"$date":"2026-04-14T21:20:12.950Z"},"updatedAt":{"$date":"2026-04-14T21:20:28.528Z"}},
        {"_id":{"$oid":"69df8fee034b202975c5186b"},"organizationId":"683f42490ab6408e84607d8c","name":"SMB Follow-Up List","audience":"SMB Accounts Q2","sourceId":"69df8e7263e704d9c47f0912","sourceType":"Segment","dataType":"Profile","groupProfilesBy":"NotGrouped","status":"Complete","jobId":"3aacaffa-3ce0-4c9f-b276-131a4b21bbd0","records":133,"priority":"Low","createdAt":{"$date":"2026-04-15T13:17:34.037Z"},"updatedAt":{"$date":"2026-04-15T13:20:52.285Z"}}
      ]
    },
    {
      "collection": "segments",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"69de6b253a5b97d4e287bb4e"},"organizationId":"683f42490ab6408e84607d8c","name":"Enterprise Accounts Q1 2026","description":null,"profileCount":11842,"status":"Active","createdById":"6667415f276e4e3b1b4ae30e","createdAt":{"$date":"2026-04-14T16:28:01.114Z"},"updatedAt":{"$date":"2026-04-14T16:32:59.188Z"}},
        {"_id":{"$oid":"69dea9d52eb7cc1f62020b30"},"organizationId":"683f42490ab6408e84607d8c","name":"Q2 Enterprise Prospect List","description":null,"profileCount":3847,"status":"Active","createdById":"6667415f276e4e3b1b4ae30e","createdAt":{"$date":"2026-04-14T20:55:49.302Z"},"updatedAt":{"$date":"2026-04-14T20:55:49.302Z"}},
        {"_id":{"$oid":"69c6b3a02ba0d52110aa5081"},"organizationId":"683f42490ab6408e84607d8c","name":"Q2 Regional Segment","description":null,"profileCount":6503,"status":"Active","createdById":"6667415f276e4e3b1b4ae30e","createdAt":{"$date":"2026-04-01T11:14:22.771Z"},"updatedAt":{"$date":"2026-04-14T16:26:38.462Z"}},
        {"_id":{"$oid":"69df8e7263e704d9c47f0912"},"organizationId":"683f42490ab6408e84607d8c","name":"SMB Accounts Q2","description":null,"profileCount":155,"status":"Active","createdById":"6667415f276e4e3b1b4ae30e","createdAt":{"$date":"2026-04-15T13:10:04.881Z"},"updatedAt":{"$date":"2026-04-15T13:10:04.881Z"}}
      ]
    },
    {
      "collection": "organizations",
      "required_field": "organizationId",
      "synthetic_docs": [
        {"_id":{"$oid":"7a1f3e8b2c4d9f6a5e2b4c01"},"organizationId":"7a1f3e8b2c4d9f6a5e2b4c01","name":"Meridian Analytics","organizationType":"Enterprise","status":"Active","adminEmail":"admin@meridiananalytics.io","goodStanding":true,"products":["Contacts","ContactsImport","ContactsExport","Segments","Outreach"],"createdAt":{"$date":"2024-08-12T14:22:10.000Z"},"updatedAt":{"$date":"2026-03-18T09:44:31.000Z"},"users":[{"userId":"7a1f3e8b2c4d9f6a5e2b4c02","firstName":"Dara","lastName":"Okonkwo","roleName":"Admin","status":"Active","lastLogin":{"$date":"2026-03-18T09:44:31.000Z"}},{"userId":"7a1f3e8b2c4d9f6a5e2b4c03","firstName":"Miles","lastName":"Cardenas","roleName":"Manager","status":"Active","lastLogin":{"$date":"2026-02-07T16:12:05.000Z"}}]},
        {"_id":{"$oid":"683f42490ab6408e84607d8c"},"organizationId":"683f42490ab6408e84607d8c","name":"Apex Data Solutions","organizationType":"Enterprise","status":"Active","adminEmail":"mwebb@apexdatasolutions.com","goodStanding":true,"products":["Contacts","ContactsImport","ContactsExport","Segments","Outreach","Analytics","AnalyticsExplorer"],"createdAt":{"$date":"2024-11-03T10:15:44.000Z"},"updatedAt":{"$date":"2026-04-15T10:04:22.000Z"},"users":[{"userId":"6667415f276e4e3b1b4ae30e","firstName":"Marcus","lastName":"Webb","roleName":"Admin","status":"Active","lastLogin":{"$date":"2026-04-15T09:04:01.000Z"}},{"userId":"6667415f276e4e3b1b4ae30f","firstName":"Dana","lastName":"Fielding","roleName":"Admin","status":"Active","lastLogin":{"$date":"2026-04-13T14:22:18.000Z"}},{"userId":"6667415f276e4e3b1b4ae310","firstName":"Priya","lastName":"Nair","roleName":"Manager","status":"Active","lastLogin":{"$date":"2026-04-14T21:19:55.000Z"}}]},
        {"_id":{"$oid":"66960837bb74e876062d7726"},"organizationId":"66960837bb74e876062d7726","name":"Northern Insights","organizationType":"Professional","status":"Active","adminEmail":"admin@northerninsights.co","goodStanding":true,"products":["Contacts","ContactsImport","ContactsExport","Segments","Outreach"],"createdAt":{"$date":"2024-06-15T08:30:00.000Z"},"updatedAt":{"$date":"2026-04-14T17:51:52.000Z"},"users":[{"userId":"66b0e038ee76d2bf2482ad2b","firstName":"Tomas","lastName":"Vega","roleName":"Admin","status":"Active","lastLogin":{"$date":"2026-04-14T17:48:00.000Z"}},{"userId":"66b0e038ee76d2bf2482ad2c","firstName":"Kezia","lastName":"Owusu","roleName":"Manager","status":"Active","lastLogin":{"$date":"2026-03-22T11:05:44.000Z"}}]}
      ]
    }
  ]$$::jsonb,

  $$[
    {"cost":0,"text":"An export stuck in InProgress means the processing pipeline never completed the job. Start by finding the specific export record — the organization ID and jobId are both visible in the server logs."},
    {"cost":25,"text":"Look at the exportFiles collection and compare the stuck record to the completed ones. Pay close attention to the records field and the updatedAt timestamp — what is different about the stuck export compared to the ones that completed?"},
    {"cost":50,"text":"The logs show two warnings for the same jobId about 90 seconds apart. The worker tried twice and hit the same error both times. The issue is not the segment or its size — it's the pipeline's ability to locate the contact list by jobId."}
  ]$$::jsonb,

  $$[
    {
      "label": "Root Cause",
      "question": "What is the correct root cause to document when escalating this ticket to engineering?",
      "options": [
        "The export stalled because the source segment (Q2 Enterprise Prospect List) was too large to process within the pipeline timeout window.",
        "The export processing worker failed to locate the contact list associated with the jobId on both its initial attempt and its single retry, leaving the ExportFile record permanently stuck in InProgress.",
        "The export failed because it was submitted later in the day than other exports, placing it in a lower-priority queue that does not process jobs after peak hours.",
        "The export stalled because the organization account was not in good standing, preventing the pipeline from completing the request."
      ],
      "correct_option": 1,
      "points": 100,
      "explanation": "The server logs are the key here: two warn-level entries for jobId 86288176-5b4e-4e40-8a12-e93125489562 both say 'Contact list not found by job ID,' logged roughly 90 seconds apart — the initial attempt and its retry. After the second failure, the worker logs 'Export job exhausted all retries. ExportFile record will remain in InProgress state.' The exportFiles document confirms it: status is InProgress, records is null, and updatedAt stopped shortly after the job was created. Critically, the same segment (69dea9d5) was used successfully in the Q2 Regional Prospects export (jobId a00a3b13) — so the segment itself is not the problem. The account is in good standing, and a subsequent export from the same account the next day completed fine."
    },
    {
      "label": "Customer Response",
      "question": "Which of the following is the best response to send to the customer?",
      "options": [
        "We found the issue — there's a bug in our export processing pipeline that caused the job to fail silently and leave your export stuck in In Progress. The segment itself and your account are both fine. I'm going to trigger a fresh export for you right now using the same segment, and you should see it complete within a few minutes. I'll also flag this to engineering so the underlying bug gets fixed.",
        "The profile-service worker failed to resolve the contact list from the jobId on both its initial attempt and the retry, which caused the ExportFile document to remain in the InProgress state indefinitely. The pipeline will need to be patched to handle this lookup failure more gracefully.",
        "The export is taking longer than expected because your Q2 Enterprise Prospect List segment contains 3,847 records, which exceeds the typical size for quick-turnaround exports. We recommend splitting the segment into two smaller ones and combining the output files afterward.",
        "Your export should complete automatically — our system detected the delay and has re-queued the job. You should see the file available for download within the next 2–4 hours without any action on your part."
      ],
      "correct_option": 0,
      "points": 50,
      "explanation": "Option A is correct: it tells the customer what happened without using internal jargon, correctly scopes the problem (pipeline bug, not their segment or account), takes action immediately (re-triggering), and commits to a follow-up on the fix. Option B is technically accurate but is written for an engineer, not a customer. Option C is wrong — the segment size is a red herring; the error is about jobId resolution, not record volume, and the same-size segment exported fine on a subsequent job. Option D is false — the job will not automatically re-queue; the logs explicitly say the record will remain stuck."
    }
  ]$$::jsonb,

  true
);
