// Vercel serverless function — api/invite.js
// Sends a Supabase invite email to a new user.
// Only callable by authenticated admins (JWT verified server-side).

const { createClient } = require('@supabase/supabase-js');

module.exports = async (req, res) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin',  process.env.APP_URL || '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { email, role = 'user' } = req.body || {};

  if (!email || typeof email !== 'string' || !email.includes('@')) {
    return res.status(400).json({ error: 'A valid email address is required' });
  }

  // Verify calling user is an authenticated admin
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) {
    return res.status(401).json({ error: 'Missing Authorization header' });
  }

  const adminClient = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  // Validate the caller's JWT
  const { data: { user: caller }, error: authErr } = await adminClient.auth.getUser(token);
  if (authErr || !caller) {
    return res.status(401).json({ error: 'Invalid or expired session' });
  }

  // Check admin role in profiles table
  const { data: profile, error: profileErr } = await adminClient
    .from('profiles')
    .select('role')
    .eq('id', caller.id)
    .single();

  if (profileErr || !profile || profile.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }

  // Send the invite
  const safeRole = role === 'admin' ? 'admin' : 'user';
  const redirectTo = `${process.env.APP_URL || ''}/profile.html`;

  const { data, error: inviteErr } = await adminClient.auth.admin.inviteUserByEmail(email, {
    redirectTo,
    data: { initial_role: safeRole }
  });

  if (inviteErr) {
    console.error('[invite] Supabase error:', inviteErr.message);
    return res.status(400).json({ error: inviteErr.message });
  }

  return res.status(200).json({
    success: true,
    message: `Invite sent to ${email}`,
    user_id: data.user?.id
  });
};
