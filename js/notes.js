/**
 * Private per-challenge notes, auto-saved to Supabase on a debounced 1.2s timer.
 * Notes are visible only to the current user (enforced by RLS).
 */

export function initNotes({ challengeId, initialText }) {
  const textarea = document.querySelector('#notes-text');
  const statusEl = document.querySelector('#notes-saved-label');
  if (!textarea) return;

  textarea.value = initialText || '';
  let saveTimer = null;

  async function saveNote() {
    statusEl.textContent = 'Saving…';
    const { error } = await _supabase.rpc('save_challenge_note', {
      p_challenge_id: challengeId,
      p_note_text:    textarea.value
    });
    if (error) {
      statusEl.textContent = 'Save failed';
      statusEl.style.color = 'var(--error, #e06c75)';
    } else {
      statusEl.textContent = 'Saved';
      statusEl.style.color = 'var(--text-muted)';
      setTimeout(() => { statusEl.textContent = ''; }, 2000);
    }
  }

  textarea.addEventListener('input', () => {
    clearTimeout(saveTimer);
    statusEl.textContent = '…';
    saveTimer = setTimeout(saveNote, 1200);
  });
}
