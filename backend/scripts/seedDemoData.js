// CLI entrypoint for local dev:
//   node scripts/seedDemoData.js
// (On Render free tier with no shell access, use the protected HTTP
// endpoint instead — see src/routes/seedDemo.js. This CLI form is for
// running locally against a database you can reach directly, e.g. during
// initial setup and testing.)
import { pool } from "../src/db.js";
import { seedDemoData } from "../src/demo/seedDemoData.js";

seedDemoData(pool)
  .then(() => pool.end())
  .catch(async (err) => {
    console.error(err);
    await pool.end();
    process.exit(1);
  });
