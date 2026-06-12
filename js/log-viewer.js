/**
 * Log file viewer modal.
 * Handles: open by index, syntax highlighting, copy to clipboard, download JSON, close.
 *
 * Returns { close } so the orchestrator can bind ESC to it alongside other modals.
 */

export function initLogViewer({ logFiles }) {
  const modal   = document.querySelector('#logs-modal');
  let activeLog = null;

  // Log file cards are rendered by the orchestrator; listen via delegation
  document.querySelector('#log-files-list').addEventListener('click', e => {
    const btn = e.target.closest('.btn-view-log');
    if (btn) openLog(parseInt(btn.dataset.logIdx));
  });

  function openLog(idx) {
    activeLog    = logFiles[idx];
    const raw    = JSON.stringify(activeLog.logs, null, 2);
    const codeEl = document.querySelector('#log-code');
    codeEl.textContent = raw;
    codeEl.removeAttribute('data-highlighted');
    hljs.highlightElement(codeEl);
    const count = Array.isArray(activeLog.logs) ? activeLog.logs.length : 1;
    document.querySelector('#modal-filename').textContent  = activeLog.filename;
    document.querySelector('#log-entry-count').textContent = `${count} log entr${count === 1 ? 'y' : 'ies'}`;
    modal.classList.add('open');
  }

  function close() { modal.classList.remove('open'); }

  document.querySelector('#close-logs-modal').addEventListener('click', close);
  modal.addEventListener('click', e => { if (e.target === modal) close(); });

  document.querySelector('#btn-copy-logs').addEventListener('click', async () => {
    if (!activeLog) return;
    const text = JSON.stringify(activeLog.logs, null, 2);
    const btn  = document.querySelector('#btn-copy-logs');
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      // Fallback for browsers that block clipboard outside a direct user gesture
      const ta = document.createElement('textarea');
      ta.value = text; ta.style.cssText = 'position:fixed;opacity:0;';
      document.body.appendChild(ta); ta.select();
      document.execCommand('copy'); document.body.removeChild(ta);
    }
    const orig = btn.textContent;
    btn.textContent = 'Copied!';
    setTimeout(() => { btn.textContent = orig; }, 1500);
  });

  document.querySelector('#btn-download-logs').addEventListener('click', () => {
    if (!activeLog) return;
    const blob = new Blob([JSON.stringify(activeLog.logs, null, 2)], { type: 'application/json' });
    const url  = URL.createObjectURL(blob);
    const a    = Object.assign(document.createElement('a'), { href: url, download: activeLog.filename });
    a.click(); URL.revokeObjectURL(url);
  });

  return { close };
}
