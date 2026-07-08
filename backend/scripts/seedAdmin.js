// CLI entrypoint for local dev:
//   node scripts/seedAdmin.js --name "Manan" --email admin@yourcompany.com [--password ...]
// (On Render free tier, set ADMIN_EMAIL / ADMIN_NAME / ADMIN_PASSWORD as
// environment variables instead — the server auto-seeds on boot. See README.)
import { pool } from "../src/db.js";
import { seedAdmin } from "../src/seedAdmin.js";

function arg(name, fallback = null) {
  const i = process.argv.indexOf(`--${name}`);
  return i !== -1 ? process.argv[i + 1] : fallback;
}

async function run() {
  const email = arg("email");
  if (!email) {
    console.error('Usage: node scripts/seedAdmin.js --name "Manan" --email admin@yourcompany.com [--password ...]');
    process.exit(1);
  }
  const { generatedPassword } = await seedAdmin(pool, {
    name: arg("name", "Admin"),
    email,
    password: arg("password"),
  });
  console.log(`Admin user ready: ${email}`);
  if (generatedPassword) {
    console.log(`Temporary password: ${generatedPassword}`);
    console.log("Save this now — change it after first login. It will not be shown again.");
  }
  await pool.end();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
