// CLI entrypoint for local dev: `npm run migrate`
// (On Render free tier, migrations now also run automatically on server boot —
// see src/server.js — so this script isn't required there, just for local use.)
import { pool } from "../src/db.js";
import { runMigrations } from "../src/migrate.js";

runMigrations(pool)
  .then(() => pool.end())
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
