import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api.js";
import { SEGMENTS, segmentMeta } from "../constants.js";

const shortDate = (iso) => (iso ? new Date(iso).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "2-digit" }) : "—");

// Whole days between two dates — used for both "days to close" (a fixed
// span, once won/lost) and "days open so far" (a running count against
// today, for cases still in progress).
function daysBetween(startIso, endIso) {
  if (!startIso) return null;
  const start = new Date(startIso);
  const end = endIso ? new Date(endIso) : new Date();
  return Math.max(0, Math.round((end - start) / 86400000));
}

const OUTCOME_FILTERS = [
  { value: "all", label: "All" },
  { value: "open", label: "Open" },
  { value: "won", label: "Won" },
  { value: "lost", label: "Lost" },
];

const COLUMNS = [
  { key: "created_at", label: "Enquiry Received" },
  { key: "costing_completed_at", label: "Costing Completed" },
  { key: "offer_prepared_at", label: "Offer Prepared" },
  { key: "offer_sent_at", label: "Offer Submitted" },
  { key: "negotiation_completed_at", label: "Negotiations Completed" },
  { key: "closed_at", label: "Won / Lost" },
];

export default function Tracker() {
  const navigate = useNavigate();
  const [cases, setCases] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [segmentFilter, setSegmentFilter] = useState("all");
  const [outcomeFilter, setOutcomeFilter] = useState("all");
  const [handlerFilter, setHandlerFilter] = useState("all");
  const [sortKey, setSortKey] = useState("created_at");
  const [sortDir, setSortDir] = useState("desc");

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      setCases(await api.listCases());
    } catch (err) {
      setError(err.message || "Failed to load cases");
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => { refresh(); }, []);

  const handlers = useMemo(
    () => [...new Set(cases.map((c) => c.handled_by_name).filter(Boolean))].sort(),
    [cases]
  );

  const filtered = useMemo(() => {
    let rows = cases;
    if (segmentFilter !== "all") rows = rows.filter((c) => (c.segment || "unassigned") === segmentFilter);
    if (handlerFilter !== "all") rows = rows.filter((c) => c.handled_by_name === handlerFilter);
    if (outcomeFilter === "open") rows = rows.filter((c) => c.stage !== "won" && c.stage !== "lost");
    else if (outcomeFilter === "won") rows = rows.filter((c) => c.stage === "won");
    else if (outcomeFilter === "lost") rows = rows.filter((c) => c.stage === "lost");

    const sorted = [...rows].sort((a, b) => {
      const av = a[sortKey], bv = b[sortKey];
      if (!av && !bv) return 0;
      if (!av) return 1; // rows missing this milestone sort to the bottom regardless of direction
      if (!bv) return -1;
      const cmp = new Date(av) - new Date(bv);
      return sortDir === "asc" ? cmp : -cmp;
    });
    return sorted;
  }, [cases, segmentFilter, handlerFilter, outcomeFilter, sortKey, sortDir]);

  function toggleSort(key) {
    if (sortKey === key) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("desc");
    }
  }

  const th = {
    textAlign: "left", padding: "9px 10px", fontSize: 10.5, whiteSpace: "nowrap",
    letterSpacing: 0.3, textTransform: "uppercase", color: "var(--text-faint)", fontWeight: 600, cursor: "pointer",
  };
  const td = { padding: "9px 10px", fontSize: 12.5, whiteSpace: "nowrap" };

  return (
    <div style={{ width: "100%", padding: "36px 24px 60px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: 20, flexWrap: "wrap", gap: 12 }}>
        <div>
          <div style={{ fontSize: 11, letterSpacing: 0.6, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 4 }}>
            End-to-end view
          </div>
          <h1 style={{ fontSize: 24 }}>Tracker</h1>
          <p style={{ color: "var(--text-dim)", fontSize: 13, marginTop: 6, maxWidth: 640 }}>
            Every case from enquiry through to Won or Lost, with the date each milestone was actually reached.
          </p>
        </div>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <select value={segmentFilter} onChange={(e) => setSegmentFilter(e.target.value)} style={{ width: "auto", padding: "6px 10px", fontSize: 12.5 }}>
            <option value="all">All segments</option>
            {SEGMENTS.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
            <option value="unassigned">Unassigned</option>
          </select>
          <select value={handlerFilter} onChange={(e) => setHandlerFilter(e.target.value)} style={{ width: "auto", padding: "6px 10px", fontSize: 12.5 }}>
            <option value="all">All handlers</option>
            {handlers.map((h) => <option key={h} value={h}>{h}</option>)}
          </select>
          <select value={outcomeFilter} onChange={(e) => setOutcomeFilter(e.target.value)} style={{ width: "auto", padding: "6px 10px", fontSize: 12.5 }}>
            {OUTCOME_FILTERS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
        </div>
      </div>

      <div className="card" style={{ overflow: "auto" }}>
        {loading ? (
          <div className="empty-state">Loading…</div>
        ) : error ? (
          <div className="empty-state" style={{ color: "var(--red)" }}>
            Couldn't load the tracker: {error}
            <div style={{ marginTop: 10 }}>
              <button className="btn-ghost" onClick={refresh}>Retry</button>
            </div>
          </div>
        ) : !filtered.length ? (
          <div className="empty-state">No cases match these filters.</div>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ borderBottom: "1px solid var(--line)" }}>
                <th style={th}>Reference</th>
                <th style={th}>Customer</th>
                <th style={th}>Segment</th>
                <th style={th}>Handled By</th>
                {COLUMNS.map((c) => (
                  <th key={c.key} style={th} onClick={() => toggleSort(c.key)}>
                    {c.label}{sortKey === c.key ? (sortDir === "asc" ? " ↑" : " ↓") : ""}
                  </th>
                ))}
                <th style={th}>Days {`(open/close)`}</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((c) => {
                const isClosed = c.stage === "won" || c.stage === "lost";
                const days = daysBetween(c.created_at, isClosed ? c.closed_at : null);
                return (
                  <tr
                    key={c.id}
                    onClick={() => navigate(`/cases/${c.id}`)}
                    style={{ borderBottom: "1px solid var(--line-soft)", cursor: "pointer" }}
                    onMouseEnter={(e) => (e.currentTarget.style.background = "var(--panel-2)")}
                    onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
                  >
                    <td style={td}>
                      <span className="ref-stamp">{c.reference || `CASE-${String(c.id).padStart(4, "0")}`}</span>
                    </td>
                    <td style={td}>{c.customer_name}</td>
                    <td style={td}>{segmentMeta(c.segment)?.label || "—"}</td>
                    <td style={td}>{c.handled_by_name || "—"}</td>
                    <td style={td}>{shortDate(c.created_at)}</td>
                    <td style={td}>{shortDate(c.costing_completed_at)}</td>
                    <td style={td}>{shortDate(c.offer_prepared_at)}</td>
                    <td style={td}>{shortDate(c.offer_sent_at)}</td>
                    <td style={td}>{shortDate(c.negotiation_completed_at)}</td>
                    <td style={{ ...td, color: c.stage === "won" ? "var(--green)" : c.stage === "lost" ? "var(--red)" : "var(--text-faint)", fontWeight: isClosed ? 600 : 400 }}>
                      {isClosed ? `${c.stage === "won" ? "Won" : "Lost"} · ${shortDate(c.closed_at)}` : "—"}
                    </td>
                    <td style={{ ...td, color: "var(--text-dim)" }}>
                      {days === null ? "—" : isClosed ? `${days}d to close` : `${days}d open`}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
