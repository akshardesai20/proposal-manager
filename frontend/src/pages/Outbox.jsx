import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api.js";

const fullDate = (iso) => (iso ? new Date(iso).toLocaleString("en-IN", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" }) : "—");

const STATUS_META = {
  sent: { label: "Sent", color: "#3fb950" },
  failed: { label: "Failed", color: "#ff6b6b" },
};

export default function Outbox() {
  const [emails, setEmails] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      setEmails(await api.getOutbox());
    } catch (err) {
      setError(err.message || "Failed to load the outbox");
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => { refresh(); }, []);

  const filtered = statusFilter === "all" ? emails : emails.filter((e) => e.status === statusFilter);
  const failedCount = emails.filter((e) => e.status === "failed").length;

  return (
    <div style={{ width: "100%", padding: "36px 24px 60px", maxWidth: 1000, margin: "0 auto" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: 20, flexWrap: "wrap", gap: 12 }}>
        <div>
          <div style={{ fontSize: 11, letterSpacing: 0.6, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 4 }}>
            Outbound email
          </div>
          <h1 style={{ fontSize: 24 }}>Outbox</h1>
          <p style={{ color: "var(--text-dim)", fontSize: 13, marginTop: 6, maxWidth: 640 }}>
            Every email sent from a case — offers, follow-ups, and replies — in one place, across every case.
            {failedCount > 0 && (
              <span style={{ color: "var(--red)", fontWeight: 600 }}> {failedCount} failed to send.</span>
            )}
          </p>
        </div>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} style={{ width: "auto", padding: "6px 10px", fontSize: 12.5 }}>
          <option value="all">All ({emails.length})</option>
          <option value="sent">Sent ({emails.filter((e) => e.status === "sent").length})</option>
          <option value="failed">Failed ({failedCount})</option>
        </select>
      </div>

      <div className="card" style={{ overflowX: "auto", overflowY: "hidden" }}>
        {loading ? (
          <div className="empty-state">Loading…</div>
        ) : error ? (
          <div className="empty-state" style={{ color: "var(--red)" }}>
            Couldn't load the outbox: {error}
            <div style={{ marginTop: 10 }}>
              <button className="btn-ghost" onClick={refresh}>Retry</button>
            </div>
          </div>
        ) : !filtered.length ? (
          <div className="empty-state">
            {statusFilter === "all" ? "No emails sent yet." : `No ${statusFilter} emails.`}
          </div>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ borderBottom: "1px solid var(--line)" }}>
                <th style={th}>Status</th>
                <th style={th}>Case</th>
                <th style={th}>Customer</th>
                <th style={th}>Subject</th>
                <th style={th}>To</th>
                <th style={th}>Sent By</th>
                <th style={th}>Date</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((e) => (
                <tr key={e.id} style={{ borderBottom: "1px solid var(--line-soft)" }}>
                  <td style={td}>
                    <span style={{
                      fontSize: 10.5, fontWeight: 600, padding: "2px 8px", borderRadius: 20, color: "#fff",
                      background: STATUS_META[e.status]?.color || "#94a3b8",
                    }}>
                      {STATUS_META[e.status]?.label || e.status}
                    </span>
                    {e.status === "failed" && e.error_message && (
                      <div style={{ fontSize: 10.5, color: "var(--red)", marginTop: 4, maxWidth: 180 }}>{e.error_message}</div>
                    )}
                  </td>
                  <td style={td}>
                    <Link to={`/cases/${e.case_id}`} className="ref-stamp" style={{ textDecoration: "none" }}>
                      {e.reference || `CASE-${String(e.case_id).padStart(4, "0")}`}
                    </Link>
                  </td>
                  <td style={td}>{e.customer_name}</td>
                  <td style={{ ...td, maxWidth: 260, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{e.subject}</td>
                  <td style={td}>{e.to_email}</td>
                  <td style={td}>{e.created_by_name || "—"}</td>
                  <td style={{ ...td, color: "var(--text-faint)", whiteSpace: "nowrap" }}>{fullDate(e.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

const th = {
  textAlign: "left", padding: "9px 10px", fontSize: 10.5, whiteSpace: "nowrap",
  letterSpacing: 0.3, textTransform: "uppercase", color: "var(--text-faint)", fontWeight: 600,
};
const td = { padding: "9px 10px", fontSize: 12.5, verticalAlign: "top" };
