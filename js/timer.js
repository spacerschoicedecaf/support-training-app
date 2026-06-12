/**
 * Solve timer for challenge.html.
 *
 * Handles:
 * - Visible elapsed time display with pause/resume button
 * - Auto-pause when switching tabs or app windows (visibilitychange + blur/focus)
 * - Away-time recovery across full page navigations (beforeunload + localStorage)
 *
 * Usage:
 *   const timer = createTimer({ challengeId, userId, pageLoadTime, returnedAt, getSubmitted });
 *   timer.start();          // show timer, attach listeners
 *   timer.stop();           // hide timer, clear interval, remove localStorage key
 *   timer.getElapsedMs();   // net ms excluding all paused time
 */

export function createTimer({ challengeId, userId, pageLoadTime, returnedAt, getSubmitted }) {
  const awayKey     = `sturnus_away_${challengeId}_${userId}`;
  let timerPaused   = false;
  let timerPausedAt = null;
  let timerPausedMs = 0;
  let timerInterval = null;

  // Recover time spent away during a full-page navigation.
  // On beforeunload we save {leftAt}; here we add the gap to timerPausedMs
  // so it's excluded from getElapsedMs(). Uses returnedAt (captured before
  // any async awaits) to avoid counting page-load time as away time.
  if (!getSubmitted()) {
    const raw = localStorage.getItem(awayKey);
    if (raw) {
      try {
        const { leftAt } = JSON.parse(raw);
        if (leftAt) timerPausedMs += Math.max(0, returnedAt - leftAt);
      } catch {}
      localStorage.removeItem(awayKey);
    }
  }

  function getElapsedMs() {
    const pausedSoFar = timerPaused ? Date.now() - timerPausedAt : 0;
    return Date.now() - pageLoadTime - timerPausedMs - pausedSoFar;
  }

  function fmtTimer(ms) {
    const s = Math.max(0, Math.floor(ms / 1000));
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
  }

  function start() {
    if (getSubmitted()) return;
    const card    = document.querySelector('#solve-timer-card');
    const display = document.querySelector('#solve-timer-display');
    const btn     = document.querySelector('#solve-timer-btn');
    card.style.display = 'flex';

    timerInterval = setInterval(() => {
      if (!timerPaused) display.textContent = fmtTimer(getElapsedMs());
    }, 500);

    function pause() {
      if (timerPaused) return;
      timerPaused = true; timerPausedAt = Date.now();
      btn.textContent = '▶';
      btn.title = 'Resume timer';
      btn.setAttribute('aria-label', 'Resume timer');
    }

    function resume() {
      if (!timerPaused) return;
      timerPausedMs += Date.now() - timerPausedAt;
      timerPaused = false; timerPausedAt = null;
      btn.textContent = '⏸';
      btn.title = 'Pause timer';
      btn.setAttribute('aria-label', 'Pause timer');
    }

    btn.addEventListener('click', () => timerPaused ? resume() : pause());

    document.addEventListener('visibilitychange', () => {
      if (getSubmitted()) return;
      document.hidden ? pause() : resume();
    });
    window.addEventListener('blur',  () => { if (!getSubmitted()) pause(); });
    window.addEventListener('focus', () => { if (!getSubmitted()) resume(); });
    window.addEventListener('beforeunload', () => {
      if (!getSubmitted()) localStorage.setItem(awayKey, JSON.stringify({ leftAt: Date.now() }));
    });
  }

  function stop() {
    clearInterval(timerInterval);
    timerInterval = null;
    localStorage.removeItem(awayKey);
    const card = document.querySelector('#solve-timer-card');
    if (card) card.style.display = 'none';
  }

  return { start, stop, getElapsedMs };
}
