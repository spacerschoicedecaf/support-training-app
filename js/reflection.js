/**
 * Post-solve reflection panel: 1–5 difficulty stars + free-text notes.
 * Shows after submission; restored from DB when re-viewing a solved challenge.
 */

export function initReflection({ challengeId, existingReflection, existingRating }) {
  const panel = document.querySelector('#reflection-panel');
  panel.classList.remove('hidden');

  const STAR_LABELS = ['', 'Very easy', 'Easy', 'About right', 'Hard', 'Very hard'];
  let selectedRating = 0;

  if (existingReflection) document.querySelector('#reflection-text').value = existingReflection;
  if (existingRating)     setRating(existingRating);

  // Stars: cumulative hover highlight, click to lock in
  const starBtns = [...document.querySelector('#star-rating').querySelectorAll('.star-btn')];
  starBtns.forEach(btn => {
    btn.addEventListener('mouseenter', () => {
      const v = parseInt(btn.dataset.val);
      starBtns.forEach(b => b.classList.toggle('star-hover', parseInt(b.dataset.val) <= v));
    });
    btn.addEventListener('click', () => setRating(parseInt(btn.dataset.val)));
  });
  document.querySelector('#star-rating').addEventListener('mouseleave', () => {
    starBtns.forEach(b => b.classList.remove('star-hover'));
  });

  document.querySelector('#btn-save-reflection').addEventListener('click', async () => {
    const text = document.querySelector('#reflection-text').value.trim();
    const btn  = document.querySelector('#btn-save-reflection');
    btn.disabled = true; btn.textContent = 'Saving…';

    const { data, error } = await _supabase.rpc('save_reflection', {
      p_challenge_id:      challengeId,
      p_reflection:        text || null,
      p_difficulty_rating: selectedRating || null
    });

    btn.disabled = false; btn.textContent = 'Save post-mortem';
    const fb = document.querySelector('#reflection-feedback');
    if (error || !data?.success) {
      fb.textContent = 'Could not save — ' + (data?.error || error?.message);
    } else {
      fb.textContent = 'Saved.';
      setTimeout(() => { fb.textContent = ''; }, 3000);
    }
  });

  function setRating(val) {
    selectedRating = parseInt(val);
    document.querySelector('#star-rating').querySelectorAll('.star-btn').forEach(b => {
      b.classList.toggle('active', parseInt(b.dataset.val) <= selectedRating);
    });
    document.querySelector('#star-label').textContent = STAR_LABELS[selectedRating] || '—';
  }
}
