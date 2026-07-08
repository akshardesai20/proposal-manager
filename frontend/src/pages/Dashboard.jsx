import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api.js";
import { CASE_PROGRESS_STAGES, SEGMENTS } from "../constants.js";

const inr = (n) => `₹${Number(n || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;
const shortDate = (iso) => (iso ? new Date(iso).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "2-digit" }) : "—");
const daysAgo = (iso) => {
  if (!iso) return null;
  const diff = Date.now() - new Date(iso).getTime();
  return Math.floor(diff / 86400000);
};

const SEGMENT_LIST = [...SEGMENTS, { value: "unassigned", label: "Unassigned" }];

function StatCard({ label, value, accent }) {
  return (
    <div className="card" style={{ padding: "16px 18px", borderLeft: `3px solid ${accent || "var(--teal)"}` }}>
      <div style={{ fontSize: 11, letterSpacing: 0.4, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 6, fontWeight: 600 }}>
        {label}
      </div>
      <div style={{ fontSize: 22, fontWeight: 700 }}>{value}</div>
    </div>
  );
}

function SectionCard({ title, children, style }) {
  return (
    <div style={{ marginBottom: 22, ...style }}>
      <h2 style={{ fontSize: 15, marginBottom: 12 }}>{title}</h2>
      <div className="card" style={{ padding: 20 }}>{children}</div>
    </div>
  );
}

function CaseLinkRow({ c, navigate, right }) {
  return (
    <div
      onClick={() => navigate(`/cases/${c.id}`)}
      style={{
        display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12,
        padding: "9px 0", borderTop: "1px solid var(--line-soft)", cursor: "pointer", fontSize: 13,
      }}
    >
      <div style={{ minWidth: 0 }}>
        <span className="ref-stamp" style={{ marginRight: 8 }}>{c.reference || `CASE-${String(c.id).padStart(4, "0")}`}</span>
        {c.customer_name}
      </div>
      <div style={{ color: "var(--text-faint)", fontSize: 12, whiteSpace: "nowrap" }}>{right}</div>
    </div>
  );
}

function TeamPipelineTable({ team }) {
  const th = { textAlign: "left", padding: "8px 10px", fontSize: 10.5, textTransform: "uppercase", letterSpacing: 0.3, color: "var(--text-faint)", fontWeight: 600, whiteSpace: "nowrap" };
  const td = { padding: "8px 10px", fontSize: 12.5, whiteSpace: "nowrap" };

  if (!team.length) {
    return <div style={{ fontSize: 12.5, color: "var(--text-faint)" }}>No active users with assigned cases yet.</div>;
  }

  return (
    <div style={{ overflowX: "auto" }}>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr style={{ borderBottom: "1px solid var(--line)" }}>
            <th style={th}>User</th>
            <th style={th}>Total</th>
            <th style={th}>Open</th>
            {CASE_PROGRESS_STAGES.map((p) => <th key={p.stage} style={th}>{p.label}</th>)}
            <th style={{ ...th, color: "var(--green)" }}>Won</th>
            <th style={{ ...th, color: "var(--red)" }}>Lost</th>
            <th style={th}>On-time %</th>
          </tr>
        </thead>
        <tbody>
          {team.map((u) => (
            <tr key={u.user_id} style={{ borderBottom: "1px solid var(--line-soft)" }}>
              <td style={{ ...td, fontWeight: 500 }}>{u.user_name}</td>
              <td style={{ ...td, fontWeight: 600 }}>{u.total}</td>
              <td style={td}>{u.open}</td>
              {CASE_PROGRESS_STAGES.map((p) => <td key={p.stage} style={td}>{u[p.stage] || 0}</td>)}
              <td style={{ ...td, color: "var(--green)", fontWeight: 600 }}>{u.won}</td>
              <td style={{ ...td, color: "var(--red)", fontWeight: 600 }}>{u.lost}</td>
              <td style={td}>
                {u.punctuality_pct === null
                  ? <span style={{ color: "var(--text-faint)" }}>—</span>
                  : `${u.punctuality_pct}% (${u.punctuality_on_time}/${u.punctuality_measured})`}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function Dashboard({ user }) {
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const isAdmin = user?.role === "admin";
  const [teamData, setTeamData] = useState(null);
  const [teamError, setTeamError] = useState("");
  const [teamLoading, setTeamLoading] = useState(isAdmin);

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      setData(await api.getMyDashboard());
    } catch (err) {
      setError(err.message || "Failed to load dashboard");
    } finally {
      setLoading(false);
    }
  }
  async function refreshTeam() {
    setTeamLoading(true);
    setTeamError("");
    try {
      setTeamData(await api.getTeamDashboard());
    } catch (err) {
      setTeamError(err.message || "Failed to load team dashboard");
    } finally {
      setTeamLoading(false);
    }
  }
  useEffect(() => { refresh(); if (isAdmin) refreshTeam(); }, []);

  return (
    <div style={{ maxWidth: 1040, margin: "0 auto", padding: "36px 24px 60px", width: "100%" }}>
      <div style={{ fontSize: 11, letterSpacing: 0.6, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 4 }}>
        Overview
      </div>
      <h1 style={{ fontSize: 24, marginBottom: 20 }}>
        {user?.name ? `Welcome, ${user.name}` : "Dashboard"}
      </h1>

      {loading ? (
        <div className="card" style={{ padding: 32, textAlign: "center" }}>
          <div style={{ fontSize: 13, color: "var(--text-faint)" }}>Loading…</div>
        </div>
      ) : error ? (
        <div className="card" style={{ padding: 24 }}>
          <div style={{ color: "var(--red)", fontSize: 13, marginBottom: 10 }}>Couldn't load your dashboard: {error}</div>
          <button className="btn-ghost" onClick={refresh}>Retry</button>
        </div>
      ) : (
        <>
          {/* Orders received — count + value, this month and current FY */}
          <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 14, marginBottom: 22 }}>
            <StatCard label="Open cases" value={data.open_cases} accent="#5d7188" />
            <StatCard label="Orders this month" value={data.orders_received.month.count} accent="#3fb950" />
            <StatCard label="Value this month" value={inr(data.orders_received.month.value)} accent="#3fb950" />
            <StatCard label="Orders this FY" value={data.orders_received.fy.count} accent="#1bb8b0" />
            <StatCard label="Value this FY" value={inr(data.orders_received.fy.value)} accent="#1bb8b0" />
          </div>

          {isAdmin && (
            <SectionCard title="Team pipeline (admin)">
              {teamLoading ? (
                <div style={{ fontSize: 12.5, color: "var(--text-faint)" }}>Loading…</div>
              ) : teamError ? (
                <div>
                  <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 10 }}>Couldn't load team data: {teamError}</div>
                  <button className="btn-ghost" onClick={refreshTeam}>Retry</button>
                </div>
              ) : (
                <TeamPipelineTable team={teamData || []} />
              )}
            </SectionCard>
          )}

          {/* Pipeline — current stage distribution of open cases */}
          <SectionCard title="Your pipeline">
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ flex: 1, fontSize: 13, fontWeight: 600 }}>Total Cases</span>
                <span style={{ fontSize: 13, fontWeight: 700 }}>{data.pipeline.total || 0}</span>
              </div>
              <div style={{ borderTop: "1px solid var(--line-soft)", margin: "2px 0" }} />
              {CASE_PROGRESS_STAGES.map((p) => {
                const count = data.pipeline[p.stage] || 0;
                return (
                  <div key={p.stage} style={{ display: "flex", alignItems: "center", gap: 10 }}>
                    <span style={{ flex: 1, fontSize: 13 }}>{p.label}</span>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{count}</span>
                  </div>
                );
              })}
              <div style={{ borderTop: "1px solid var(--line-soft)", margin: "6px 0" }} />
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ flex: 1, fontSize: 13, fontWeight: 600, color: "var(--green)" }}>Order Won</span>
                <span style={{ fontSize: 13, fontWeight: 600 }}>{data.pipeline.won || 0}</span>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ flex: 1, fontSize: 13, fontWeight: 600, color: "var(--red)" }}>Order Lost</span>
                <span style={{ fontSize: 13, fontWeight: 600 }}>{data.pipeline.lost || 0}</span>
              </div>
            </div>
          </SectionCard>

          {/* Segment breakdown, this user's cases only */}
          <SectionCard title="Segment breakdown">
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {SEGMENT_LIST.map((s) => (
                <div key={s.value} style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span style={{ flex: 1, fontSize: 13 }}>{s.label}</span>
                  <span style={{ fontSize: 13, fontWeight: 600 }}>{data.segments[s.value] || 0}</span>
                </div>
              ))}
            </div>
          </SectionCard>

          {/* Order-close forecast */}
          <SectionCard title="Order-close forecast">
            {!data.forecast.overdue.length && !data.forecast.next_7_days.length && !data.forecast.next_30_days.length ? (
              <div style={{ fontSize: 12.5, color: "var(--text-faint)" }}>
                No open cases have an expected order finalization date set.
              </div>
            ) : (
              <>
                {data.forecast.overdue.length > 0 && (
                  <div style={{ marginBottom: 16 }}>
                    <div style={{ fontSize: 11, fontWeight: 600, color: "var(--red)", textTransform: "uppercase", letterSpacing: 0.4 }}>
                      Overdue ({data.forecast.overdue.length})
                    </div>
                    {data.forecast.overdue.map((c) => (
                      <CaseLinkRow key={c.id} c={c} navigate={navigate} right={`Expected ${shortDate(c.expected_order_date)}`} />
                    ))}
                  </div>
                )}
                {data.forecast.next_7_days.length > 0 && (
                  <div style={{ marginBottom: 16 }}>
                    <div style={{ fontSize: 11, fontWeight: 600, color: "var(--text-faint)", textTransform: "uppercase", letterSpacing: 0.4 }}>
                      Next 7 days ({data.forecast.next_7_days.length})
                    </div>
                    {data.forecast.next_7_days.map((c) => (
                      <CaseLinkRow key={c.id} c={c} navigate={navigate} right={shortDate(c.expected_order_date)} />
                    ))}
                  </div>
                )}
                {data.forecast.next_30_days.length > 0 && (
                  <div>
                    <div style={{ fontSize: 11, fontWeight: 600, color: "var(--text-faint)", textTransform: "uppercase", letterSpacing: 0.4 }}>
                      Next 30 days ({data.forecast.next_30_days.length})
                    </div>
                    {data.forecast.next_30_days.map((c) => (
                      <CaseLinkRow key={c.id} c={c} navigate={navigate} right={shortDate(c.expected_order_date)} />
                    ))}
                  </div>
                )}
              </>
            )}
          </SectionCard>

          {/* Needs follow-up */}
          <SectionCard title={`Needs follow-up (no update in ${data.needs_followup_threshold_days}+ days)`}>
            {!data.needs_followup.length ? (
              <div style={{ fontSize: 12.5, color: "var(--text-faint)" }}>Nothing overdue for follow-up — you're on top of it.</div>
            ) : (
              data.needs_followup.map((c) => (
                <CaseLinkRow key={c.id} c={c} navigate={navigate} right={`${daysAgo(c.last_contact)} days since last contact`} />
              ))
            )}
          </SectionCard>
        </>
      )}
    </div>
  );
}
