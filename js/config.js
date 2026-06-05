// ─── Supabase Configuration ───────────────────────────────────────────────────
// Replace these two values with your project's URL and anon key.
// The anon key is safe to commit — Supabase RLS enforces all access control.
// Find both in: Supabase Dashboard → Project Settings → API

const SUPABASE_URL      = 'https://cveusavcrfqgqpcalwez.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_MAuvOhCLi12n8TOm0wxkNQ_uGhzWVQI';

// Supabase client singleton — imported by all pages via <script src="js/config.js">
const _supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    autoRefreshToken: true,
    persistSession:   true,
    detectSessionInUrl: true   // handles magic-link / invite token in URL hash
  }
});
