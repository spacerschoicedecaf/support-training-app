// ─── Grafana Faro RUM Instrumentation ─────────────────────────────────────────
// Real User Monitoring via Grafana Cloud Frontend Observability.
//
// SETUP (one-time):
//   1. Sign in to grafana.com → your Cloud stack
//   2. Go to Observability → Frontend → Create new
//   3. App name: "sturnus" (or "vhs" — or create one app for both)
//   4. CORS Allowed Origins: https://bekind.support, https://YOUR-STURNUS-DOMAIN
//   5. Copy the collector URL — looks like:
//        https://faro-collector-prod-us-east-0.grafana.net/collect/XXXXXXXXXXXX
//   6. Paste it into FARO_COLLECTOR_URL below
//   7. Add <script src="js/faro.js"></script> to the <head> of every HTML page,
//      BEFORE config.js and auth.js so errors during auth are captured too.
//
// WHAT THIS COLLECTS (automatically, no extra code):
//   - JavaScript errors and unhandled promise rejections
//   - Page load performance (LCP, FID/INP, CLS, TTFB)
//   - Navigation timing (time between page loads)
//   - Console errors and warnings
//   - Resource load failures (failed script/CSS fetches)
//   - Network requests (XHR / fetch) — timing and errors
//   - Session context (user journeys across pages)
//
// WHAT THIS DOES NOT COLLECT:
//   - PII — no user handles, emails, or IDs are sent unless you call
//     faro.api.setUser() explicitly (not done here intentionally)
//   - Supabase query contents — only request timing and HTTP status
//
// ─── Configuration ────────────────────────────────────────────────────────────

(function () {
  'use strict';

  // REQUIRED: paste your Grafana Cloud collector URL here after setup.
  // Format: https://faro-collector-prod-<region>.grafana.net/collect/<app-key>
  var FARO_COLLECTOR_URL = 'https://faro-collector-prod-us-east-2.grafana.net/collect/9930343d3f187ef4bac6cb7858333eda';

  // Derive app name and environment from hostname so both STURNUS and VHS
  // report to Grafana with distinct labels — useful if you create one app
  // for the whole project instead of two separate ones.
  var hostname = window.location.hostname;
  var isVHS = hostname.includes('vhs') || hostname.endsWith('bekind.support');
  var isLocal = hostname === 'localhost' || hostname === '127.0.0.1';

  var APP_NAME    = isVHS ? 'vhs'     : 'sturnus';
  var ENVIRONMENT = isLocal ? 'local' : 'production';

  // Skip sending telemetry in local dev — avoids polluting your Grafana data
  // with test clicks. Remove this check if you want local data too.
  if (isLocal) {
    console.debug('[faro] Local environment detected — RUM disabled.');
    return;
  }

  // Guard: if the collector URL hasn't been filled in yet, bail with a clear
  // error rather than silently sending nothing or logging confusing network errors.
  if (FARO_COLLECTOR_URL.startsWith('PASTE_')) {
    console.warn('[faro] Collector URL not configured. Edit js/faro.js to enable RUM.');
    return;
  }

  // ─── Load Faro SDK from CDN ──────────────────────────────────────────────────
  // Uses the IIFE bundle so no build step is required. The onload callback
  // fires after the SDK is fully parsed and ready.
  //
  // Version is pinned to ^1 (latest stable 1.x). If Faro releases a breaking
  // v2, you'd pin explicitly here, e.g. @1.7.0.

  var script = document.createElement('script');

  script.onload = function () {
    initFaro();
  };

  script.onerror = function () {
    // CDN load failure — could be an ad-blocker or network issue. Not fatal.
    console.warn('[faro] Failed to load Faro SDK from CDN. RUM will not run.');
  };

  script.src = 'https://unpkg.com/@grafana/faro-web-sdk@^1.0.0/dist/bundle/faro-web-sdk.iife.js';

  // async=false keeps the load synchronous-ish relative to other head scripts.
  // The SDK is small (~50KB gzipped) and loads fast; this ensures errors on
  // the very first page render are captured rather than missed during async load.
  script.async = false;

  document.head.appendChild(script);

  // ─── Faro Initialization ─────────────────────────────────────────────────────

  function initFaro() {
    var sdk = window.GrafanaFaroWebSdk;

    if (!sdk || typeof sdk.initializeFaro !== 'function') {
      console.warn('[faro] SDK loaded but initializeFaro not found. Version mismatch?');
      return;
    }

    var faro = sdk.initializeFaro({
      url: FARO_COLLECTOR_URL,

      app: {
        name:        APP_NAME,
        version:     '1.0.0',    // bump this when you deploy notable changes
        environment: ENVIRONMENT,
      },

      // ── Instrumentations ────────────────────────────────────────────────────
      // The default set is reasonable. We add the full list explicitly so it's
      // clear what's active and easy to comment out individual items.
      instrumentations: [
        // Captures unhandled JS errors and promise rejections.
        new sdk.ErrorsInstrumentation(),

        // Web Vitals: LCP, INP (replaces FID), CLS, TTFB, FCP.
        new sdk.WebVitalsInstrumentation(),

        // Captures fetch() and XMLHttpRequest timing + status codes.
        // Useful for seeing Supabase RPC latency in Grafana.
        new sdk.FetchInstrumentation(),
        new sdk.XHRInstrumentation(),

        // Captures console.warn and console.error calls as log events.
        new sdk.ConsoleInstrumentation({
          disabledLevels: ['log', 'debug', 'info'], // only warn + error
        }),

        // Captures page view transitions (navigation between HTML pages).
        new sdk.NavigationsInstrumentation(),

        // Captures resource load failures (scripts, stylesheets, images).
        new sdk.ResourcesInstrumentation(),
      ],

      // ── Sampling ────────────────────────────────────────────────────────────
      // 100% of sessions — fine for a low-traffic training app. If you ever
      // scale to thousands of daily users, drop this to 0.5 (50%) to stay
      // well under the free tier's session limits.
      sessionTrackingConfig: {
        samplingRate: 1,
      },

      // ── Batching ────────────────────────────────────────────────────────────
      // Buffer events and send in batches to reduce network overhead.
      // Default batch interval is 250ms; 2s is fine for a training app.
      batchConfig: {
        sendTimeout: 2000,
      },
    });

    // ── Tag with current page name ─────────────────────────────────────────────
    // Grafana will show page-level breakdowns using this attribute.
    // Strips the leading slash and .html extension for clean labels,
    // e.g. "challenge" instead of "/challenge.html".
    var pageName = window.location.pathname
      .split('/').pop()
      .replace(/\.html$/, '') || 'index';

    faro.api.pushEvent('page_view', { page: pageName });

    // ── Expose globally for optional manual instrumentation ────────────────────
    // Other scripts can call window._faro.api.pushEvent(...) to send custom
    // events. See the examples in GRAFANA-SETUP.md.
    window._faro = faro;
  }

})();
