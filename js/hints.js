/**
 * Hint rendering and unlock logic.
 *
 * Usage:
 *   const hints = initHints({ challenge, ctx, getSubmitted, onUnlocked });
 *   hints.seed(unlockedSet, existingCost);  // call once after loading existing state
 *   hints.revealNext();                     // keyboard shortcut 'h'
 */

import { escHtml } from './challenge-utils.js';

export function initHints({ challenge, ctx, getSubmitted, onUnlocked }) {
  const listEl      = document.querySelector('#hints-list');
  const unlockedSet = new Set();
  let   hintsCost   = 0;

  function seed(existingUnlocked, existingCost) {
    existingUnlocked.forEach(i => unlockedSet.add(i));
    hintsCost = existingCost;
    render();
  }

  function render() {
    listEl.innerHTML = '';
    challenge.hints.forEach((hint, i) => {
      const unlocked = unlockedSet.has(i);
      const div = document.createElement('div');
      div.className = 'hint-item';

      if (unlocked || getSubmitted()) {
        div.innerHTML = `
          <div class="hint-unlocked${hint.cost === 0 ? ' free' : ''}">
            <div class="hint-number">Hint ${i + 1}</div>
            ${escHtml(hint.text)}
          </div>`;
      } else {
        div.innerHTML = `
          <div class="hint-locked">
            <span class="hint-locked-label">Hint ${i + 1}</span>
            <div style="display:flex;align-items:center;gap:8px;">
              <span class="hint-cost${hint.cost === 0 ? ' free' : ''}">
                ${hint.cost === 0 ? 'Free' : `-${hint.cost} pts`}
              </span>
              <button class="btn btn-ghost btn-sm" data-hint-idx="${i}" data-hint-cost="${hint.cost}">
                ${hint.cost === 0 ? 'Reveal' : 'Unlock'}
              </button>
            </div>
          </div>`;
      }
      listEl.appendChild(div);
    });

    listEl.querySelectorAll('[data-hint-idx]').forEach(btn => {
      btn.addEventListener('click', () => unlock(parseInt(btn.dataset.hintIdx), parseInt(btn.dataset.hintCost)));
    });
  }

  async function unlock(idx, cost) {
    if (getSubmitted()) return;
    const score = ctx.profile.role === 'admin' ? 999 : ctx.profile.score - hintsCost;
    if (cost > 0 && score < cost) { alert('Not enough points to unlock this hint.'); return; }

    const { data, error } = await _supabase.rpc('unlock_hint', {
      p_challenge_id: challenge.id,
      p_hint_index:   idx,
      p_cost:         cost
    });

    if (error || !data.success) {
      if (data?.error === 'Already unlocked') { unlockedSet.add(idx); render(); return; }
      alert(data?.error || error?.message || 'Failed to unlock hint');
      return;
    }

    unlockedSet.add(idx);
    hintsCost += cost;
    if (data.new_score !== undefined) {
      document.querySelector('#nav-score').textContent = data.new_score.toLocaleString() + ' pts';
      ctx.profile.score = data.new_score;
    }
    onUnlocked(hintsCost);
    render();
  }

  // Reveal the next locked hint — called by the 'h' keyboard shortcut
  function revealNext() {
    if (getSubmitted()) return;
    const nextIdx = challenge.hints.findIndex((_, i) => !unlockedSet.has(i));
    if (nextIdx !== -1) unlock(nextIdx, challenge.hints[nextIdx].cost);
  }

  function getCost() { return hintsCost; }

  return { seed, render, revealNext, getCost };
}
