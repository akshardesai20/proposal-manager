import { Router } from "express";
import { query } from "../db.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

const router = Router();
router.use(requireAuth);

const NEEDS_FOLLOWUP_DAYS = 14;
const FORECAST_SOON_DAYS = 7;
const FORECAST_UPCOMING_DAYS = 30;

// India runs an April–March financial year, so "current FY" here means
// that, not the calendar year — adjust if deploying for a business that
// runs a different fiscal calendar.
function currentFYBounds(now = new Date()) {
  const y = now.getUTCMonth() >= 3 ? now.getUTCFullYear() : now.getUTCFullYear() - 1;
  return {
    start: new Date(Date.UTC(y, 3, 1)),
    end: new Date(Date.UTC(y + 1, 2, 31, 23, 59, 59, 999)),
  };
}
function currentMonthBounds(now = new Date()) {
  return {
    start: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)),
    end: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0, 23, 59, 59, 999)),
  };
}

// Sum of qty * final_unit_price across every costing line on cases this
// user won and closed within [start, end]. Uses the case's current
// costing_items (live), not a frozen offer snapshot — simplest source of
// truth, though it means editing costing after a case is won will shift
// this number. Flagging that assumption; easy to switch to the winning
// offer's items_snapshot instead if that's not what's wanted.
async function wonOrdersInRange(userId, start, end) {
  const { rows } = await query(
    `SELECT c.id, COALESCE(SUM(ci.qty * ci.final_unit_price), 0) AS value
     FROM cases c
     LEFT JOIN costing_items ci ON ci.case_id = c.id
     WHERE c.assigned_sales_engineer = $1 AND c.stage = 'won' AND c.closed_at BETWEEN $2 AND $3
     GROUP BY c.id`,
    [userId, start, end]
  );
  return {
    count: rows.length,
    value: rows.reduce((sum, r) => sum + Number(r.value), 0),
  };
}

// GET /api/dashboard/me — everything the logged-in user's personal
// dashboard needs, in one call.
router.get("/me", async (req, res) => {
  const userId = req.user.id;
  const now = new Date();

  // 1. Pipeline: cumulative milestone counts, matching the exact same
  //    "reached at least this stage" logic as the Case Progress checklist
  //    on the case detail page — a case sitting at Offer Submitted counts
  //    toward Costing Completed and Offer Prepared too, not just its own
  //    current stage. Only the 4 checklist milestones + Won/Lost are
  //    shown; the in-progress-only stage values (enquiry, costing,
  //    negotiation) have no checkbox anywhere else in the app, so they're
  //    left out here for consistency.
  const STAGE_ORDER = ["enquiry", "costing", "costing_complete", "offer_prepared", "offer_sent", "negotiation", "negotiation_complete", "won", "lost"];
  const MILESTONES = ["costing_complete", "offer_prepared", "offer_sent", "negotiation_complete"];
  const stageRows = (await query(
    `SELECT stage FROM cases WHERE assigned_sales_engineer = $1`,
    [userId]
  )).rows;
  const pipeline = {};
  for (const milestone of MILESTONES) {
    const idx = STAGE_ORDER.indexOf(milestone);
    pipeline[milestone] = stageRows.filter((r) => STAGE_ORDER.indexOf(r.stage) >= idx).length;
  }
  pipeline.won = stageRows.filter((r) => r.stage === "won").length;
  pipeline.lost = stageRows.filter((r) => r.stage === "lost").length;
  pipeline.total = stageRows.length;
  const openCases = stageRows.filter((r) => r.stage !== "won" && r.stage !== "lost").length;

  // 2. Segment breakdown, this user's cases only.
  const segmentRows = (await query(
    `SELECT COALESCE(segment, 'unassigned') AS segment, COUNT(*)::int AS count
     FROM cases WHERE assigned_sales_engineer = $1 GROUP BY COALESCE(segment, 'unassigned')`,
    [userId]
  )).rows;
  const segments = Object.fromEntries(segmentRows.map((r) => [r.segment, r.count]));

  // 3. Order-close forecast: open cases with an expected date, bucketed.
  const forecastRows = (await query(
    `SELECT c.id, c.reference, c.expected_order_date, cu.name AS customer_name
     FROM cases c JOIN customers cu ON cu.id = c.customer_id
     WHERE c.assigned_sales_engineer = $1 AND c.stage NOT IN ('won','lost')
       AND c.expected_order_date IS NOT NULL
     ORDER BY c.expected_order_date ASC`,
    [userId]
  )).rows;
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const soonCutoff = new Date(today.getTime() + FORECAST_SOON_DAYS * 86400000);
  const upcomingCutoff = new Date(today.getTime() + FORECAST_UPCOMING_DAYS * 86400000);
  const forecast = { overdue: [], next_7_days: [], next_30_days: [], later: [] };
  for (const row of forecastRows) {
    const due = new Date(row.expected_order_date);
    if (due < today) forecast.overdue.push(row);
    else if (due <= soonCutoff) forecast.next_7_days.push(row);
    else if (due <= upcomingCutoff) forecast.next_30_days.push(row);
    else forecast.later.push(row);
  }

  // 4. Needs follow-up: open cases where the most recent follow-up (or
  //    case creation, if none logged yet) is older than the threshold.
  const needsFollowup = (await query(
    `SELECT c.id, c.reference, cu.name AS customer_name,
            COALESCE(MAX(f.followup_date), c.created_at::date) AS last_contact
     FROM cases c
     JOIN customers cu ON cu.id = c.customer_id
     LEFT JOIN case_followups f ON f.case_id = c.id
     WHERE c.assigned_sales_engineer = $1 AND c.stage NOT IN ('won', 'lost')
     GROUP BY c.id, cu.name
     HAVING COALESCE(MAX(f.followup_date), c.created_at::date) < (CURRENT_DATE - $2::int)
     ORDER BY last_contact ASC`,
    [userId, NEEDS_FOLLOWUP_DAYS]
  )).rows;

  // 5. Orders received: count + value, this month and current FY.
  const monthBounds = currentMonthBounds(now);
  const fyBounds = currentFYBounds(now);
  const [ordersThisMonth, ordersThisFY] = await Promise.all([
    wonOrdersInRange(userId, monthBounds.start, monthBounds.end),
    wonOrdersInRange(userId, fyBounds.start, fyBounds.end),
  ]);

  res.json({
    pipeline,
    open_cases: openCases,
    segments,
    forecast,
    needs_followup: needsFollowup,
    needs_followup_threshold_days: NEEDS_FOLLOWUP_DAYS,
    orders_received: { month: ordersThisMonth, fy: ordersThisFY },
  });
});

// GET /api/dashboard/team — admin-only. Per-user milestone pipeline
// (same cumulative logic as /me) plus proposal punctuality: of the
// user's cases that have BOTH a Schedule Date and an Actual Date
// (offer_prepared_at), what percentage had the actual on or before the
// scheduled date. Cases missing either date aren't counted toward
// punctuality — there's nothing to compare yet.
router.get("/team", requireRole("admin"), async (req, res) => {
  const STAGE_ORDER = ["enquiry", "costing", "costing_complete", "offer_prepared", "offer_sent", "negotiation", "negotiation_complete", "won", "lost"];
  const MILESTONES = ["costing_complete", "offer_prepared", "offer_sent", "negotiation_complete"];

  const users = (await query(
    `SELECT id, name FROM users WHERE status = 'active' ORDER BY name ASC`
  )).rows;
  const caseRows = (await query(
    `SELECT assigned_sales_engineer AS user_id, stage, scheduled_offer_date, offer_prepared_at
     FROM cases WHERE assigned_sales_engineer IS NOT NULL`
  )).rows;

  const casesByUser = {};
  for (const c of caseRows) {
    (casesByUser[c.user_id] ||= []).push(c);
  }

  const team = users.map((u) => {
    const cases = casesByUser[u.id] || [];
    const pipeline = {};
    for (const milestone of MILESTONES) {
      const idx = STAGE_ORDER.indexOf(milestone);
      pipeline[milestone] = cases.filter((c) => STAGE_ORDER.indexOf(c.stage) >= idx).length;
    }
    const won = cases.filter((c) => c.stage === "won").length;
    const lost = cases.filter((c) => c.stage === "lost").length;
    const total = cases.length;
    const open = total - won - lost;

    // Compare date portions only — offer_prepared_at is a timestamp,
    // scheduled_offer_date is a plain date, so an offer prepared later on
    // the scheduled day itself must still count as on-time.
    const measured = cases.filter((c) => c.scheduled_offer_date && c.offer_prepared_at);
    const onTime = measured.filter((c) =>
      new Date(c.offer_prepared_at).toISOString().slice(0, 10) <= new Date(c.scheduled_offer_date).toISOString().slice(0, 10)
    );

    return {
      user_id: u.id,
      user_name: u.name,
      total,
      open,
      ...pipeline,
      won,
      lost,
      punctuality_pct: measured.length ? Math.round((onTime.length / measured.length) * 100) : null,
      punctuality_measured: measured.length,
      punctuality_on_time: onTime.length,
    };
  });

  res.json(team);
});

export default router;
