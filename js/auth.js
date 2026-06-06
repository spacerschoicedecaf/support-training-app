// ─── Auth helpers ─────────────────────────────────────────────────────────────
// Depends on: config.js loaded first (_supabase available globally)

const Auth = (() => {

  // ── Session ──────────────────────────────────────────────────────────────────

  async function getSession() {
    const { data: { session } } = await _supabase.auth.getSession();
    return session;
  }

  async function getUser() {
    const session = await getSession();
    return session ? session.user : null;
  }

  async function getProfile(userId) {
    const { data, error } = await _supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    if (error) return null;
    return data;
  }

  async function signOut() {
    await _supabase.auth.signOut();
    window.location.href = 'login.html';
  }

  // ── Guards ────────────────────────────────────────────────────────────────────
  // Call at the top of each page's DOMContentLoaded handler.

  // Ensures the user is logged in AND has a profile. Redirects otherwise.
  // Returns { user, profile } on success.
  async function requireAuth() {
    const user = await getUser();
    if (!user) {
      window.location.href = 'login.html';
      return null;
    }
    const profile = await getProfile(user.id);
    if (!profile) {
      window.location.href = 'profile.html';
      return null;
    }
    if (typeof applyTheme === 'function') applyTheme(profile.theme || 'vhs');
    return { user, profile };
  }

  // Ensures the user is an admin. Redirects non-admins to index.
  async function requireAdmin() {
    const ctx = await requireAuth();
    if (!ctx) return null;
    if (ctx.profile.role !== 'admin') {
      window.location.href = 'index.html';
      return null;
    }
    return ctx;
  }

  // For login/profile pages — redirect away if already set up.
  async function redirectIfLoggedIn(destination = 'index.html') {
    const user = await getUser();
    if (!user) return;
    const profile = await getProfile(user.id);
    if (profile) {
      window.location.href = destination;
    }
  }

  // ── Nav helpers ───────────────────────────────────────────────────────────────

  // Populate a standard nav element.
  // Expects: <span id="nav-handle">, <span id="nav-score">, <a id="nav-logout">
  function populateNav(profile) {
    const handleEl = document.getElementById('nav-handle');
    const scoreEl  = document.getElementById('nav-score');
    const logoutEl = document.getElementById('nav-logout');
    const adminEl  = document.getElementById('nav-admin');

    if (handleEl) {
      handleEl.textContent = profile.handle;
      handleEl.style.cursor = 'pointer';
      handleEl.title = 'View profile';
      handleEl.addEventListener('click', () => { window.location.href = 'profile.html'; });
    }
    if (scoreEl)  scoreEl.textContent  = (profile.role === 'admin' ? 999 : profile.score).toLocaleString() + ' pts';
    if (logoutEl) logoutEl.addEventListener('click', (e) => { e.preventDefault(); signOut(); });
    if (adminEl) {
      if (profile.role === 'admin') {
        adminEl.style.display = '';
      } else {
        adminEl.style.display = 'none';
      }
    }
  }

  // ── Token helper (for calling /api/invite) ────────────────────────────────────

  async function getAccessToken() {
    const session = await getSession();
    return session ? session.access_token : null;
  }

  return {
    getSession,
    getUser,
    getProfile,
    signOut,
    requireAuth,
    requireAdmin,
    redirectIfLoggedIn,
    populateNav,
    getAccessToken,
  };
})();
