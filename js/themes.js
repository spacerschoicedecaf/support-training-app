// ─── Theme definitions ────────────────────────────────────────────────────────
// Loaded on every page before auth.js.
// applyTheme(themeName) is called by auth.js after the profile loads.

// ── Shared pixel-art rect strings ─────────────────────────────────────────────

// STURNUS bird — 20×14 grid, matches favicon-sturnus.svg exactly
const BIRD_RECTS = '<rect x="5" y="0" width="5" height="1"/><rect x="4" y="1" width="7" height="1"/><rect x="2" y="2" width="5" height="1"/><rect x="8" y="2" width="4" height="1"/><rect x="1" y="3" width="12" height="1"/><rect x="2" y="4" width="14" height="1"/><rect x="3" y="5" width="15" height="1"/><rect x="4" y="6" width="15" height="1"/><rect x="4" y="7" width="15" height="1"/><rect x="4" y="8" width="12" height="1"/><rect x="5" y="9" width="8" height="1"/><rect x="6" y="10" width="5" height="1"/><rect x="7" y="11" width="1" height="1"/><rect x="10" y="11" width="1" height="1"/><rect x="7" y="12" width="1" height="1"/><rect x="10" y="12" width="1" height="1"/><rect x="6" y="13" width="3" height="1"/><rect x="10" y="13" width="2" height="1"/>';

// VHS cassette — 20×13 grid, matches favicon-vhs.svg exactly
const VHS_RECTS = '<rect x="0" y="0" width="20" height="1"/><rect x="0" y="1" width="1" height="1"/><rect x="19" y="1" width="1" height="1"/><rect x="0" y="2" width="1" height="1"/><rect x="19" y="2" width="1" height="1"/><rect x="0" y="3" width="1" height="1"/><rect x="2" y="3" width="4" height="1"/><rect x="12" y="3" width="4" height="1"/><rect x="19" y="3" width="1" height="1"/><rect x="0" y="4" width="1" height="1"/><rect x="2" y="4" width="1" height="1"/><rect x="5" y="4" width="1" height="1"/><rect x="12" y="4" width="1" height="1"/><rect x="15" y="4" width="1" height="1"/><rect x="19" y="4" width="1" height="1"/><rect x="0" y="5" width="1" height="1"/><rect x="2" y="5" width="1" height="1"/><rect x="5" y="5" width="1" height="1"/><rect x="12" y="5" width="1" height="1"/><rect x="15" y="5" width="1" height="1"/><rect x="19" y="5" width="1" height="1"/><rect x="0" y="6" width="1" height="1"/><rect x="2" y="6" width="4" height="1"/><rect x="12" y="6" width="4" height="1"/><rect x="19" y="6" width="1" height="1"/><rect x="0" y="7" width="1" height="1"/><rect x="19" y="7" width="1" height="1"/><rect x="0" y="8" width="1" height="1"/><rect x="19" y="8" width="1" height="1"/><rect x="0" y="9" width="20" height="1"/><rect x="2" y="10" width="16" height="1"/><rect x="2" y="11" width="16" height="1"/><rect x="4" y="12" width="12" height="1"/>';

const THEMES = {

  sturnus: {
    name:     'STURNUS',
    subtitle: 'Technical Support Training',

    // Nav icon: currentColor inherits from .nav-brand, crispEdges for pixel-perfect render
    navIcon: `<svg class="nav-brand-icon" viewBox="0 0 20 14" fill="currentColor" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg">${BIRD_RECTS}</svg>`,

    // Auth card logo: hardcoded brand green, explicit px dimensions
    authIcon: `<svg viewBox="0 0 20 14" width="30" height="21" fill="#8fbc5a" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg">${BIRD_RECTS}</svg>`,

    // No CSS variable overrides — app.css defaults are the STURNUS theme
    vars: {}
  },

  vhs: {
    name:     'V.H.S.',
    subtitle: 'Virtual Helpdesk Simulator',

    navIcon: `<svg class="nav-brand-icon" viewBox="0 0 20 13" fill="currentColor" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg">${VHS_RECTS}</svg>`,

    authIcon: `<svg viewBox="0 0 20 13" width="30" height="20" fill="#e040fb" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg">${VHS_RECTS}</svg>`,

    // 80s video store palette — neon magenta + cyan on deep purple-black
    vars: {
      '--bg-canvas':    '#0d0015',
      '--bg-surface':   '#1a0030',
      '--bg-overlay':   '#240048',
      '--bg-inset':     '#08000f',
      '--border':       '#4a1a80',
      '--border-muted': '#2d0f60',

      '--text-primary':   '#f0e8ff',
      '--text-secondary': '#c0a8e8',
      '--text-muted':     '#9070d0',   // 4.5:1 on #0d0015
      '--text-link':      '#ea80fc',   // magenta — brand colour
      '--text-danger':    '#ff6b6b',
      '--text-success':   '#00e5ff',   // cyan — scores, success
      '--text-warning':   '#ffab40',
      '--text-purple':    '#ea80fc',

      '--accent':        '#7c2fbf',
      '--accent-hover':  '#9c4de8',
      '--accent-subtle': 'rgba(124,47,191,0.15)',

      '--success-bg':    'rgba(0,229,255,0.08)',
      '--danger-bg':     'rgba(255,107,107,0.10)',
      '--warning-bg':    'rgba(255,171,64,0.08)',

      '--btn-primary':       '#2d0060',
      '--btn-primary-hover': '#45008a',
      '--btn-danger':        '#5a0020',
      '--btn-danger-hover':  '#7a0030',
    }
  }

};

// ── Apply a theme ─────────────────────────────────────────────────────────────

function applyTheme(themeName) {
  const t = THEMES[themeName] || THEMES.vhs;
  const root = document.documentElement;

  // 1. CSS file swap (fast, no-flash when loaded from head)
  const link = document.getElementById('theme-css');
  if (link) link.href = themeName === 'vhs' ? 'css/theme-vhs.css' : '';

  // 2. CSS variables (also set inline for dynamic switches mid-session)
  Object.entries(t.vars).forEach(([prop, val]) => root.style.setProperty(prop, val));
  if (themeName === 'sturnus') {
    // Clear any VHS overrides so app.css defaults take over
    Object.keys(THEMES.vhs.vars).forEach(prop => root.style.removeProperty(prop));
  }

  // 3. Remove loading flag — nav brand becomes visible
  delete root.dataset.themeLoading;

  // 4. Nav brand icon (replace the wrapper contents)
  document.querySelectorAll('.nav-brand-icon-wrap').forEach(el => {
    el.innerHTML = t.navIcon;
  });

  // 5. Nav brand name
  document.querySelectorAll('.nav-brand-name').forEach(el => {
    el.textContent = t.name;
  });

  // 6. Auth card logo (login / profile pages)
  const authIcon = document.querySelector('.auth-logo-icon');
  if (authIcon) authIcon.innerHTML = t.authIcon;

  const authText = document.querySelector('.auth-logo-text');
  if (authText) authText.textContent = t.name;

  const authSub = document.querySelector('.auth-logo-sub');
  if (authSub && t.subtitle) authSub.textContent = t.subtitle;

  // 7. Page title
  document.title = document.title.replace(/STURNUS|V\.H\.S\./g, t.name);

  // 8. Persist in localStorage so login page can apply the right theme on return
  try { localStorage.setItem('lastTheme', themeName); } catch(e) {}
}
