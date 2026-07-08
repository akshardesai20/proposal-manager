import { Router } from "express";
import { pollInbox } from "../mail/pollInbox.js";

const router = Router();

// Not behind requireAuth — an external scheduler (e.g. cron-job.org) hits
// this on a timer and can't do a JWT login. Protected instead by a shared
// secret (INBOX_POLL_SECRET env var), checked as either a query param or
// header so whichever the scheduler supports works.
//
// Accepts GET or POST so it's easy to point almost any free cron/uptime
// service at it. Render's free-tier service sleeps after ~15 minutes idle,
// so this same request also serves to wake the service back up — set the
// scheduler to run every 10 minutes or so.
router.all("/poll-inbox", async (req, res) => {
  const expected = process.env.INBOX_POLL_SECRET;
  if (!expected) {
    return res.status(503).json({ error: "INBOX_POLL_SECRET is not configured on the server" });
  }
  const provided = req.query.secret || req.header("x-poll-secret");
  if (provided !== expected) {
    return res.status(401).json({ error: "Invalid or missing secret" });
  }

  try {
    // A silently-dropped connection (common with firewalls that block
    // rather than reject unfamiliar IPs) can hang well past the internal
    // greetingTimeout/socketTimeout, since those only apply once a TCP
    // connection is already open. This outer race guarantees the request
    // always gets a response within ~20s either way, which also makes a
    // "genuinely stuck" connection distinguishable from a fast failure.
    // (AI analysis of captured emails runs on-demand via the "Analyze"
    // button/endpoint, not during polling, so it never adds to this.)
    const result = await Promise.race([
      pollInbox(),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error(
          "Timed out after 20s waiting for the mail server — this points to a network-level block " +
          "(e.g. a firewall silently dropping the connection) rather than a wrong password or setting. " +
          "Try connecting with the same host/port from a regular email client to confirm, or ask your host " +
          "whether they block connections from cloud-hosting IP ranges."
        )), 20000)
      ),
    ]);
    res.json({ ok: true, ...result });
  } catch (err) {
    console.error("[poll-inbox]", err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

export default router;
