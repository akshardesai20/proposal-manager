// Shared admin-seed logic. Used by:
//  - scripts/seedAdmin.js (CLI, for local dev)
//  - server.js (auto-run on boot from ADMIN_EMAIL/ADMIN_NAME/ADMIN_PASSWORD
//    env vars, so it works without Shell access on free tier)
//
// IMPORTANT: name and password are only ever set from these env vars at
// TRUE FIRST CREATION of the account. Once the user exists, boot-time env
// vars only ever touch password_hash (and only when ADMIN_PASSWORD is
// explicitly given) — never name. Editing a user's name is done through the
// Users tab from then on; a leftover ADMIN_NAME env var must never be able
// to silently overwrite that on a later restart.
import bcrypt from "bcryptjs";
import crypto from "crypto";

// Returns { email, generatedPassword, created, updated }
// generatedPassword is only set when a brand-new random password was made
// (i.e. first-time creation with no ADMIN_PASSWORD given) — that's the only
// case where the caller needs to print it.
export async function seedAdmin(pool, { name, email, password }) {
  if (!email) throw new Error("email is required");

  const existing = await pool.query("SELECT id FROM users WHERE email = $1", [email]);

  if (existing.rows.length) {
    if (password) {
      const hash = await bcrypt.hash(password, 10);
      await pool.query("UPDATE users SET password_hash = $1 WHERE email = $2", [hash, email]);
      return { email, generatedPassword: null, created: false, updated: true };
    }
    // Already exists, no explicit password given — leave it completely untouched.
    return { email, generatedPassword: null, created: false, updated: false };
  }

  const finalName = name || "Admin";
  const generated = !password;
  const finalPassword = password || crypto.randomBytes(9).toString("base64url");
  const hash = await bcrypt.hash(finalPassword, 10);

  await pool.query(
    `INSERT INTO users (name, email, password_hash, role) VALUES ($1, $2, $3, 'admin')`,
    [finalName, email, hash]
  );

  return { email, generatedPassword: generated ? finalPassword : null, created: true, updated: false };
}
