# STURNUS — External Services

All third-party services the app depends on, with links to dashboards and docs.

---

## Supabase
**What it does:** Postgres database, authentication, row-level security, serverless RPCs

- [Dashboard](https://supabase.com/dashboard) — manage tables, run SQL, check auth, view logs
- [Docs](https://supabase.com/docs)
- Key areas: Table Editor, SQL Editor, Authentication → Users, Settings → Database (connection string), Settings → API (keys)

---

## Vercel
**What it does:** Static file hosting + `/api/invite` serverless function

- [Dashboard](https://vercel.com/dashboard) — deployments, environment variables, function logs
- [Docs](https://vercel.com/docs)
- Key areas: Project → Settings → Environment Variables (service role key, app URL), Deployments (deploy history), Functions (invite function logs)

---

## Resend
**What it does:** Email delivery for magic links and invite emails

- [Dashboard](https://resend.com) — email logs, API keys, domain verification
- [Docs](https://resend.com/docs)

---

## Sentry
**What it does:** Client-side error monitoring and session replay

- [Dashboard](https://sentry.io) — issues, session replays, alerts
- [Docs](https://docs.sentry.io)
- Key areas: Issues (error feed), Replays (session recordings), Alerts → Alert Rules (notification config)

---

## UptimeRobot
**What it does:** Uptime monitoring — pings the site every 5 minutes and emails if it goes down

- [Dashboard](https://uptimerobot.com) — monitor status, response times, incident history
- [Public status page](https://stats.uptimerobot.com/ALJJrQPvyA)
- [Docs](https://uptimerobot.com/help)

---

## Grafana
**What it does:** Infrastructure monitoring

- [Dashboard](https://grafana.com) — metrics, dashboards, alerts

---

## GitHub
**What it does:** Source control and deployment trigger (push to main → Vercel auto-deploys)

- [Repo](https://github.com/spacerschoicedecaf/support-training-app)
- Vercel is connected to this repo — every push to `main` triggers a production deploy

---

## Summary

| Service | Purpose | Free tier |
|---------|---------|-----------|
| Supabase | Database + Auth | 500MB DB, 50k MAUs |
| Vercel | Hosting + functions | 100GB bandwidth, 100k function invocations |
| Resend | Email | 3,000 emails/mo |
| Sentry | Error monitoring + replays | 5,000 errors/mo, 50 replays/mo |
| UptimeRobot | Uptime checks | 50 monitors, 5-min interval |
| Grafana | Infra monitoring | varies |
| GitHub | Source control | unlimited public/private repos |
