import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { pool } from "./db.js";
import { runMigrations } from "./migrate.js";
import { seedAdmin } from "./seedAdmin.js";
import authRoutes from "./routes/auth.js";
import caseRoutes from "./routes/cases.js";
import catalogRoutes from "./routes/catalog.js";
import customerRoutes from "./routes/customers.js";
import offerRoutes from "./routes/offers.js";
import userRoutes from "./routes/users.js";
import { caseItemsRouter, itemRouter } from "./routes/costingItems.js";
import { caseEmailsRouter } from "./routes/caseEmails.js";
import inquiryRoutes from "./routes/inquiries.js";
import inboxPollRoutes from "./routes/inboxPoll.js";
import dashboardRoutes from "./routes/dashboard.js";
import seedDemoRoutes from "./routes/seedDemo.js";
import caseImportRoutes from "./routes/caseImport.js";

dotenv.config();

async function main() {
  // Runs on every boot. Migrations are idempotent (tracked in
  // schema_migrations), so this is safe to run on every deploy/restart —
  // it's what lets this work without Shell access on Render's free tier.
  console.log("[boot] running migrations…");
  await runMigrations(pool);

  // Optional: auto-create/update the Admin account from env vars, so there's
  // no need for shell access to run a seed script. Set ADMIN_EMAIL (required
  // to trigger this), ADMIN_NAME, and optionally ADMIN_PASSWORD in the
  // service's Environment tab in Render, then redeploy. If ADMIN_PASSWORD
  // isn't set, a temporary one is generated and printed ONCE to these logs.
  if (process.env.ADMIN_EMAIL) {
    console.log("[boot] seeding admin user…");
    const { email, generatedPassword, created, updated } = await seedAdmin(pool, {
      name: process.env.ADMIN_NAME,
      email: process.env.ADMIN_EMAIL,
      password: process.env.ADMIN_PASSWORD,
    });
    if (created) {
      console.log(`[boot] admin created: ${email}`);
    } else if (updated) {
      console.log(`[boot] admin password updated (ADMIN_PASSWORD was set): ${email}`);
    } else {
      console.log(`[boot] admin already exists, left untouched: ${email}`);
    }
    if (generatedPassword) {
      console.log(`[boot] TEMPORARY PASSWORD: ${generatedPassword}`);
      console.log("[boot] Save this now — it will not be shown again. Change it after first login.");
    }
  } else {
    console.log("[boot] ADMIN_EMAIL not set — skipping admin auto-seed.");
  }

  const app = express();
  app.use(cors());
  app.use(express.json());

  app.get("/api/health", (req, res) => res.json({ ok: true }));
  app.use("/api/auth", authRoutes);
  app.use("/api/cases/:caseId/costing", caseItemsRouter);
  app.use("/api/cases/:caseId/emails", caseEmailsRouter);
  app.use("/api/costing", itemRouter);
  app.use("/api/catalog", catalogRoutes);
  app.use("/api/customers", customerRoutes);
  app.use("/api/users", userRoutes);
  app.use("/api/cases", caseRoutes);
  app.use("/api/inquiries", inquiryRoutes);
  app.use("/api/internal", inboxPollRoutes);
  app.use("/api/internal", seedDemoRoutes);
  app.use("/api/dashboard", dashboardRoutes);
  app.use("/api/import", caseImportRoutes);
  // Mounted last and deliberately broad (defines its own full sub-paths
  // like /cases/:id/offer, /offers/:id/pdf) — this must come after every
  // more specific /api/... mount above. offers.js applies requireAuth to
  // everything passed into it with no path filter, so if this were
  // registered earlier, unauthenticated requests to other routes (like
  // the poll-inbox endpoint, which is intentionally not JWT-protected)
  // would hit this blanket auth check first and get rejected before ever
  // reaching their actual intended route.
  app.use("/api", offerRoutes);

  const port = process.env.PORT || 4000;
  app.listen(port, () => console.log(`[boot] API listening on :${port}`));
}

main().catch((err) => {
  console.error("[boot] fatal error during startup:", err);
  process.exit(1);
});
