/**
 * MongoDB shell terminal: query execution, history, tab autocomplete, shortcuts modal.
 *
 * Usage:
 *   const term = initTerminal({ mongoCollections });
 *   // Returns { closeShortcuts } — call from the global ESC handler
 */

import {
  getPath,
  matchesFilter,
  applySort,
  applyProjection,
  projectDoc,
  parseCommand,
} from './mongo-engine.js';

export function initTerminal({ mongoCollections }) {
  // ── Build db map ────────────────────────────────────────────────────────────
  const dbMap = {};
  (mongoCollections || []).forEach(col => {
    const db = col.database || 'cluster0';
    if (!dbMap[db]) dbMap[db] = [];
    dbMap[db].push(col);
  });
  const allDbs    = Object.keys(dbMap).sort();
  let   currentDb = allDbs[0] || 'cluster0';

  // ── DOM refs ────────────────────────────────────────────────────────────────
  const outputEl  = document.getElementById('mongo-output');
  const queryEl   = document.getElementById('mongo-query');
  const exportBtn = document.getElementById('btn-export-json');
  let   lastResult = null;

  // ── Helpers ─────────────────────────────────────────────────────────────────
  function updateDbTitle() {
    const el = document.getElementById('mongo-db-title');
    if (el) el.textContent = `Atlas Shell — ${currentDb}`;
  }
  updateDbTitle();

  function currentCols() { return dbMap[currentDb] || []; }
  function getCol(name)   { return currentCols().find(c => c.collection === name) || null; }

  function appendLine(text, type = 'result') {
    const el = document.createElement('div');
    if      (type === 'command') { el.className = 'mongo-line mongo-line-command'; el.textContent = '> ' + text; }
    else if (type === 'count')   { el.className = 'mongo-line mongo-line-count';   el.textContent = text; }
    else if (type === 'error')   { el.className = 'mongo-line mongo-line-error';   el.textContent = text; }
    else if (type === 'system')  { el.className = 'mongo-line mongo-line-system';  el.innerHTML   = text; }
    else                         { el.className = 'mongo-line mongo-line-result';  el.textContent = text; }
    outputEl.appendChild(el);
    outputEl.scrollTop = outputEl.scrollHeight;
  }

  function colError(name) {
    appendLine(
      `MongoNamespaceError: collection '${name}' not found in database '${currentDb}'. Run db.getCollectionNames() to list available collections.`,
      'error'
    );
  }

  // ── Query execution ─────────────────────────────────────────────────────────
  function runMongoQuery() {
    const raw = queryEl.value.trim();
    if (!raw) return;
    pushHistory(raw);
    appendLine(raw, 'command');
    queryEl.value = '';

    const p = parseCommand(raw);

    if (p.cmd === 'clear') {
      outputEl.innerHTML = `<div class="mongo-line mongo-line-system">Terminal cleared. Current database: <strong>${currentDb}</strong></div>`;
      return;
    }

    if (p.cmd === 'show_dbs') {
      if (!allDbs.length) { appendLine('(no databases defined)', 'system'); return; }
      allDbs.forEach(db => appendLine(db + (db === currentDb ? '\t(current)' : ''), 'result'));
      return;
    }

    if (p.cmd === 'use') {
      currentDb = p.dbName;
      updateDbTitle();
      const cols = currentCols();
      appendLine(
        `switched to db ${p.dbName}${cols.length ? '' : ' (no collections defined for this database)'}`,
        'system'
      );
      return;
    }

    if (p.cmd === 'getcollectionnames') {
      appendLine(JSON.stringify(currentCols().map(c => c.collection)), 'result');
      return;
    }

    if (p.cmd === 'error')   { appendLine(p.msg, 'error'); return; }
    if (p.cmd === 'unknown') {
      appendLine('Unrecognized command. See query reference ↗ for all supported commands.', 'error');
      return;
    }

    const col  = getCol(p.colName);
    if (!col) { colError(p.colName); return; }
    const docs = col.synthetic_docs || [];

    if (p.cmd === 'find') {
      let results = docs.filter(d => matchesFilter(d, p.filter));
      if (p.sort)  results = applySort(results, p.sort);
      if (p.limit) results = results.slice(0, p.limit);
      results = applyProjection(results, p.projection);
      const hasFilter = Object.keys(p.filter || {}).length;
      appendLine(`// ${results.length} document${results.length !== 1 ? 's' : ''}${hasFilter ? ' matching filter' : ''}`, 'count');
      if (results.length) {
        appendLine(JSON.stringify(results, null, 2), 'result');
        lastResult = { filename: `${col.collection}.json`, data: results };
        exportBtn.disabled = false;
      } else {
        appendLine('// (no documents matched)', 'count');
      }
      return;
    }

    if (p.cmd === 'findone') {
      let results = docs.filter(d => matchesFilter(d, p.filter));
      if (p.sort) results = applySort(results, p.sort);
      const doc = results[0] ? projectDoc(results[0], p.projection) : null;
      if (!doc) { appendLine('null', 'result'); return; }
      appendLine(JSON.stringify(doc, null, 2), 'result');
      lastResult = { filename: `${col.collection}-findOne.json`, data: doc };
      exportBtn.disabled = false;
      return;
    }

    if (p.cmd === 'countdocuments') {
      appendLine(String(docs.filter(d => matchesFilter(d, p.filter)).length), 'result');
      return;
    }

    if (p.cmd === 'distinct') {
      if (!p.fieldArg) {
        appendLine(`distinct requires a quoted field name, e.g. db.${col.collection}.distinct("status")`, 'error');
        return;
      }
      const values = [...new Set(docs.map(d => getPath(d, p.fieldArg)).filter(v => v !== undefined))];
      appendLine(JSON.stringify(values, null, 2), 'result');
      return;
    }

    appendLine(`Method '${p.cmd}' not supported. See query reference ↗ for all supported methods.`, 'error');
  }

  exportBtn.addEventListener('click', () => {
    if (!lastResult) return;
    const blob = new Blob([JSON.stringify(lastResult.data, null, 2)], { type: 'application/json' });
    const url  = URL.createObjectURL(blob);
    Object.assign(document.createElement('a'), { href: url, download: lastResult.filename }).click();
    URL.revokeObjectURL(url);
  });

  document.getElementById('btn-run-query').addEventListener('click', runMongoQuery);
  document.getElementById('btn-clear-terminal').addEventListener('click', () => {
    outputEl.innerHTML = `<div class="mongo-line mongo-line-system">Terminal cleared. Current database: <strong>${currentDb}</strong></div>`;
  });

  // ── Command history ─────────────────────────────────────────────────────────
  const cmdHistory = [];
  let   historyIdx = -1;

  function pushHistory(cmd) {
    const trimmed = cmd.trim();
    if (!trimmed) return;
    if (cmdHistory[cmdHistory.length - 1] !== trimmed) cmdHistory.push(trimmed);
    historyIdx = -1;
  }

  // ── Tab autocomplete ────────────────────────────────────────────────────────
  const SHELL_METHODS = ['find', 'findOne', 'countDocuments', 'distinct'];
  let tabCandidates = [];
  let tabIdx = -1;

  function tryAutocomplete() {
    const val = queryEl.value;

    // db.<partial> — complete collection name
    const colMatch = val.match(/^(db\.)(\w*)$/);
    if (colMatch) {
      const prefix  = colMatch[1];
      const partial = colMatch[2].toLowerCase();
      const names   = currentCols().map(c => c.collection);
      const matches = names.filter(n => n.toLowerCase().startsWith(partial));
      if (!matches.length) return false;
      if (tabCandidates.join('\0') !== matches.join('\0')) { tabCandidates = matches; tabIdx = 0; }
      else tabIdx = (tabIdx + 1) % tabCandidates.length;
      queryEl.value = prefix + tabCandidates[tabIdx] + '.';
      return true;
    }

    // db.<col>.<partial> — complete method name
    const methMatch = val.match(/^(db\.\w+\.)(\w*)$/);
    if (methMatch) {
      const prefix  = methMatch[1];
      const partial = methMatch[2].toLowerCase();
      const matches = SHELL_METHODS.filter(m => m.toLowerCase().startsWith(partial));
      if (!matches.length) return false;
      if (tabCandidates.join('\0') !== matches.join('\0')) { tabCandidates = matches; tabIdx = 0; }
      else tabIdx = (tabIdx + 1) % tabCandidates.length;
      queryEl.value = prefix + tabCandidates[tabIdx] + '(';
      return true;
    }

    return false;
  }

  queryEl.addEventListener('keydown', e => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') { e.preventDefault(); runMongoQuery(); return; }

    if (e.key === 'Tab') {
      e.preventDefault();
      tryAutocomplete();
      return;
    }

    if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (!cmdHistory.length) return;
      if (historyIdx === -1) historyIdx = cmdHistory.length - 1;
      else if (historyIdx > 0) historyIdx--;
      queryEl.value = cmdHistory[historyIdx];
      setTimeout(() => queryEl.setSelectionRange(queryEl.value.length, queryEl.value.length), 0);
      return;
    }

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (historyIdx === -1) return;
      if (historyIdx < cmdHistory.length - 1) { historyIdx++; queryEl.value = cmdHistory[historyIdx]; }
      else { historyIdx = -1; queryEl.value = ''; }
      return;
    }

    if (!['Shift', 'Control', 'Meta', 'Alt', 'Tab'].includes(e.key)) {
      historyIdx    = -1;
      tabCandidates = [];
      tabIdx        = -1;
    }
  });

  // ── Shortcuts modal ─────────────────────────────────────────────────────────
  const shortcutsModal = document.querySelector('#shortcuts-modal');
  let shortcutsTrigger = null;

  function openShortcuts(trigger) {
    shortcutsTrigger = trigger || document.activeElement;
    shortcutsModal.classList.add('open');
    shortcutsModal.querySelector('.shortcuts-modal')?.focus();
  }

  function closeShortcuts() {
    shortcutsModal.classList.remove('open');
    if (shortcutsTrigger) { shortcutsTrigger.focus(); shortcutsTrigger = null; }
  }

  // Focus trap
  shortcutsModal.addEventListener('keydown', e => {
    if (!shortcutsModal.classList.contains('open') || e.key !== 'Tab') return;
    const focusable = [...shortcutsModal.querySelectorAll('button, [href], input, [tabindex]:not([tabindex="-1"])')];
    if (!focusable.length) return;
    const first = focusable[0], last = focusable[focusable.length - 1];
    if (e.shiftKey) { if (document.activeElement === first) { e.preventDefault(); last.focus(); } }
    else            { if (document.activeElement === last)  { e.preventDefault(); first.focus(); } }
  });

  document.querySelector('#btn-shortcuts').addEventListener('click', () => openShortcuts(document.querySelector('#btn-shortcuts')));
  document.querySelector('#close-shortcuts-modal').addEventListener('click', closeShortcuts);
  shortcutsModal.addEventListener('click', e => { if (e.target === shortcutsModal) closeShortcuts(); });

  // Global '?' shortcut (not when typing in terminal)
  document.addEventListener('keydown', e => {
    if (e.key === '?' && document.activeElement !== queryEl) {
      e.preventDefault();
      shortcutsModal.classList.contains('open') ? closeShortcuts() : openShortcuts();
    }
  });

  return { closeShortcuts };
}
