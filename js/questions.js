/**
 * Multi-question progressive reveal, debrief panel, walkthrough, recommended next challenge.
 *
 * Usage:
 *   const q = initQuestions({ challenge, ctx, getSubmitted, submission, getHintsCost, onSubmitClick });
 *   q.renderAll();                                   // initial render
 *   q.showDebrief(gradedArr, scoreEarned, solveMs);  // after submission or restoring solved state
 */

import { escHtml } from './challenge-utils.js';

const LETTERS = ['A', 'B', 'C', 'D'];

export function initQuestions({ challenge, ctx, getSubmitted, submission, getHintsCost, onSubmitClick }) {
  const container    = document.querySelector('#questions-container');
  const btnSubmitAll = document.querySelector('#btn-submit-all');

  // ── Shuffle ───────────────────────────────────────────────────────────────
  function shuffle(q) {
    const opts = [...q.options];
    const map  = opts.map((_, i) => i);
    for (let i = opts.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [opts[i], opts[j]] = [opts[j], opts[i]];
      [map[i],  map[j]]  = [map[j],  map[i]];
    }
    return { ...q, options: opts, correct_option: map.indexOf(q.correct_option), _shuffle_map: map };
  }

  const questions = (challenge.questions || []).map(shuffle);
  const qState    = questions.map(() => ({ selected: -1, checked: false }));

  // Restore state from an existing submission
  if (submission?.answers) {
    submission.answers.forEach(a => {
      if (a.question_idx < qState.length) {
        qState[a.question_idx].selected = a.selected_option;
        qState[a.question_idx].checked  = true;
      }
    });
  }

  // ── Render ────────────────────────────────────────────────────────────────
  function updateProgress() {
    const done = qState.filter(s => s.checked).length;
    document.querySelector('#q-progress').textContent = `${done}/${questions.length} answered`;
  }

  function renderQuestion(qi) {
    const q     = questions[qi];
    const state = qState[qi];
    const locked = getSubmitted() ? false : (qi > 0 && !qState[qi - 1].checked);

    let blockClass = 'question-block';
    if (locked)        blockClass += ' locked';
    if (state.checked) blockClass += state.selected === q.correct_option ? ' answered-correct' : ' answered-wrong';
    if (!state.checked && !getSubmitted()) blockClass += ' q-collapsed';

    const optionsHtml = q.options.map((opt, oi) => {
      let cls = 'mcq-option';
      if (state.checked || getSubmitted()) {
        cls += ' disabled';
        if (oi === q.correct_option) cls += ' correct';
        else if (oi === state.selected && oi !== q.correct_option) cls += ' wrong';
      } else if (oi === state.selected) {
        cls += ' selected';
      }
      return `<div class="${cls}" data-qi="${qi}" data-oi="${oi}">
        <div class="mcq-radio"></div>
        <span class="mcq-letter">${LETTERS[oi]}</span>
        <span class="mcq-label">${escHtml(opt)}</span>
      </div>`;
    }).join('');

    const explanationHtml = (state.checked || getSubmitted()) && q.explanation ? `
      <div class="explanation-block visible ${state.selected === q.correct_option ? 'correct' : 'wrong'}">
        <div class="explanation-label">${state.selected === q.correct_option ? '✓ Correct' : '✗ Incorrect'}</div>
        ${escHtml(q.explanation)}
      </div>` : '';

    const actionHtml = !state.checked && !getSubmitted() ? `
      <div style="margin-top:12px;">
        <button class="btn btn-secondary btn-sm" id="btn-check-${qi}" ${state.selected === -1 ? 'disabled' : ''}>
          Check answer
        </button>
      </div>` : '';

    const reasoningHtml = !locked && !state.checked && !getSubmitted() ? `
      <div class="reasoning-field" style="margin-top:14px;">
        <label for="reasoning-${qi}" style="display:block;font-size:11px;font-family:var(--font-mono);color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:5px;">
          Your reasoning <span style="font-weight:400;opacity:.7;">(optional, not scored)</span>
        </label>
        <textarea id="reasoning-${qi}" rows="2" placeholder="What's your thinking here?"
          style="width:100%;font-size:12px;font-family:var(--font-sans);resize:vertical;background:var(--bg-surface);border:1px solid var(--border);border-radius:var(--radius);padding:7px 9px;color:var(--text-primary);line-height:1.5;"></textarea>
      </div>` : '';

    return `<div class="${blockClass}" id="qblock-${qi}">
      <div class="question-block-header">
        <span class="q-label">${escHtml(q.label || `Question ${qi + 1}`)}</span>
        <span class="q-pts">${q.points || 0} pts</span>
      </div>
      <div class="question-block-body">
        <p style="font-size:14px;line-height:1.6;margin-bottom:12px;">${escHtml(q.question)}</p>
        <div class="mcq-options">${optionsHtml}</div>
        ${reasoningHtml}
        ${actionHtml}
        ${explanationHtml}
      </div>
    </div>`;
  }

  function attachListeners() {
    container.querySelectorAll('.mcq-option[data-qi]').forEach(el => {
      if (el.classList.contains('disabled')) return;
      el.addEventListener('click', () => {
        const qi = parseInt(el.dataset.qi);
        const oi = parseInt(el.dataset.oi);
        if (qState[qi].checked || getSubmitted()) return;
        qState[qi].selected = oi;
        const old         = document.querySelector(`#qblock-${qi}`);
        const wasCollapsed = old?.classList.contains('q-collapsed');
        old.outerHTML = renderQuestion(qi);
        if (!wasCollapsed) document.querySelector(`#qblock-${qi}`)?.classList.remove('q-collapsed');
        attachListeners();
        updateSubmitBtn();
      });
    });
    questions.forEach((_, qi) => {
      document.querySelector(`#btn-check-${qi}`)?.addEventListener('click', () => check(qi));
    });
  }

  function check(qi) {
    if (qState[qi].selected === -1 || qState[qi].checked) return;
    qState[qi].checked = true;
    const block = document.querySelector(`#qblock-${qi}`);
    block.outerHTML = renderQuestion(qi);
    document.querySelector(`#qblock-${qi}`)?.classList.remove('q-collapsed');
    attachListeners();
    if (qi + 1 < questions.length) {
      const next = document.querySelector(`#qblock-${qi + 1}`);
      next.outerHTML = renderQuestion(qi + 1);
      attachListeners();
    }
    updateProgress();
    updateSubmitBtn();
  }

  function updateSubmitBtn() {
    const allChecked = qState.every(s => s.checked);
    btnSubmitAll.style.display = allChecked && !getSubmitted() ? '' : 'none';
    btnSubmitAll.disabled      = false;
    btnSubmitAll.textContent   = 'Submit all answers';
  }

  function renderAll() {
    container.innerHTML = questions.map((_, i) => renderQuestion(i)).join('');
    attachListeners();
    updateProgress();
    updateSubmitBtn();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  btnSubmitAll.addEventListener('click', async () => {
    if (getSubmitted()) return;
    btnSubmitAll.disabled  = true;
    btnSubmitAll.innerHTML = '<span class="spinner"></span> Submitting…';

    const answers = qState.map((s, qi) => ({
      question_idx:    qi,
      selected_option: questions[qi]._shuffle_map
        ? questions[qi]._shuffle_map[s.selected]
        : s.selected
    }));

    await onSubmitClick(answers);
  });

  // ── Debrief ───────────────────────────────────────────────────────────────
  function showDebrief(graded, scoreEarned, solveMs) {
    const panel = document.querySelector('#debrief-panel');
    const body  = document.querySelector('#debrief-body');
    panel.classList.add('visible');
    document.querySelector('#debrief-total').textContent = scoreEarned.toLocaleString() + ' pts';
    body.innerHTML = '';

    (graded || []).forEach(g => {
      const q = questions[g.question_idx];
      if (!q) return;
      const row = document.createElement('div');
      row.className = 'debrief-row';
      row.innerHTML = `
        <span class="debrief-row-label">${escHtml(q.label || `Q${g.question_idx + 1}`)}</span>
        <span class="debrief-row-result ${g.correct ? 'correct' : 'wrong'}">
          ${g.correct ? `+${g.earned} pts` : `0 pts (${LETTERS[g.correct_option]} was correct)`}
        </span>`;
      body.appendChild(row);
    });

    const hintsCost = getHintsCost();
    if (hintsCost > 0) {
      const row = document.createElement('div');
      row.className = 'debrief-row';
      row.innerHTML = `
        <span class="debrief-row-label">Hint penalty</span>
        <span class="debrief-row-result wrong">−${hintsCost} pts</span>`;
      body.appendChild(row);
    }

    if (solveMs != null) {
      const mins = Math.floor(solveMs / 60000);
      const secs = Math.floor((solveMs % 60000) / 1000);
      const row  = document.createElement('div');
      row.className = 'debrief-row';
      row.innerHTML = `
        <span class="debrief-row-label">Time to solve</span>
        <span class="debrief-row-result" style="color:var(--text-secondary);">
          ${mins > 0 ? `${mins}m ${secs}s` : `${secs}s`}
        </span>`;
      body.appendChild(row);
    }

    loadNextChallenge(body);
    showWalkthrough();
  }

  // ── Walkthrough ───────────────────────────────────────────────────────────
  function showWalkthrough() {
    if (!challenge.walkthrough) return;
    const section = document.querySelector('#walkthrough-section');
    const bodyEl  = document.querySelector('#walkthrough-body');
    const estEl   = document.querySelector('#walkthrough-est');
    const chevron = document.querySelector('#walkthrough-chevron');
    const toggle  = document.querySelector('#walkthrough-toggle');

    bodyEl.textContent = challenge.walkthrough;
    if (challenge.est_minutes) estEl.textContent = `~${challenge.est_minutes} min`;
    section.classList.remove('hidden');
    section.scrollIntoView({ behavior: 'smooth', block: 'start' });

    let open = true;
    toggle.addEventListener('click', () => {
      open = !open;
      bodyEl.style.display = open ? '' : 'none';
      chevron.textContent  = open ? '▾' : '▸';
    });
  }

  // ── Recommended next challenge ─────────────────────────────────────────────
  async function loadNextChallenge(appendTo) {
    const [allRes, solvedRes] = await Promise.all([
      _supabase.from('challenges').select('id, title, tags').eq('active', true).neq('id', challenge.id),
      _supabase.from('submissions').select('challenge_id').eq('user_id', ctx.user.id)
    ]);
    if (allRes.error || !allRes.data?.length) return;

    const solvedIds = new Set((solvedRes.data || []).map(s => s.challenge_id));
    const unsolved  = allRes.data.filter(c => !solvedIds.has(c.id));
    if (!unsolved.length) return;

    const myTags = new Set(challenge.tags || []);
    const next   = unsolved.find(c => (c.tags || []).some(t => myTags.has(t))) || unsolved[0];

    const card = document.createElement('div');
    card.className = 'next-challenge-card';
    card.innerHTML = `
      <div class="next-label">Up next</div>
      <div class="next-title">${escHtml(next.title)}</div>
      <div class="next-meta">${escHtml(next.id)}</div>
      <a href="challenge.html?id=${encodeURIComponent(next.id)}" class="btn btn-secondary btn-sm">Open case →</a>`;
    appendTo.appendChild(card);
  }

  return { renderAll, showDebrief };
}
