import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api.js";
import CustomerPicker from "../components/CustomerPicker.jsx";
import { INQUIRY_TYPES, SEGMENTS } from "../constants.js";

const fullDate = (iso) => (iso ? new Date(iso).toLocaleString("en-IN", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" }) : "—");

function ConvertForm({ inquiry, onDone, onCancel }) {
  const [customer, setCustomer] = useState(
    inquiry.matched_customer_id ? { id: inquiry.matched_customer_id, name: inquiry.matched_customer_name } : null
  );
  const [requirement, setRequirement] = useState(inquiry.body_text || "");
  const [segment, setSegment] = useState("");
  const [inquiryType, setInquiryType] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  async function submit(e) {
    e.preventDefault();
    setError("");
    if (!customer) { setError("Select or add a customer first"); return; }
    if (!segment) { setError("Select a segment (WW, Industries, or Instrument Service)"); return; }
    setSaving(true);
    try {
      const created = await api.convertInquiry(inquiry.id, {
        customer: { id: customer.id },
        requirement_text: requirement,
        inquiry_type: inquiryType || null,
        segment,
      });
      onDone(created);
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={submit} className="card" style={{ padding: 18, marginTop: 10 }}>
      <div style={{ marginBottom: 14 }}>
        <label className="fl">Customer</label>
        <CustomerPicker value={customer} onChange={setCustomer} />
        {inquiry.matched_customer_id && !customer && (
          <div style={{ fontSize: 11.5, color: "var(--text-faint)", marginTop: 4 }}>
            Matched by sender email to an existing customer — cleared because you changed it.
          </div>
        )}
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14, marginBottom: 14 }}>
        <div>
          <label className="fl">Segment</label>
          <select value={segment} onChange={(e) => setSegment(e.target.value)} required>
            <option value="">Select segment…</option>
            {SEGMENTS.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
          </select>
        </div>
        <div>
          <label className="fl">Type of inquiry</label>
          <select value={inquiryType} onChange={(e) => setInquiryType(e.target.value)}>
            <option value="">Not set</option>
            {INQUIRY_TYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
          </select>
        </div>
      </div>
      <div style={{ marginBottom: 14 }}>
        <label className="fl">Requirement</label>
        <textarea rows={4} value={requirement} onChange={(e) => setRequirement(e.target.value)} placeholder="Pulled from the email body — edit as needed" />
      </div>
      {error && <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 12 }}>{error}</div>}
      <div style={{ display: "flex", gap: 8 }}>
        <button type="submit" className="btn-primary" disabled={saving}>
          {saving ? "Creating…" : "Create case"}
        </button>
        <button type="button" className="btn-ghost" onClick={onCancel}>Cancel</button>
      </div>
    </form>
  );
}

export default function Inquiries() {
  const navigate = useNavigate();
  const [inquiries, setInquiries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [expandedId, setExpandedId] = useState(null);
  const [convertingId, setConvertingId] = useState(null);
  const [actionError, setActionError] = useState("");

  async function refresh() {
    setLoadError("");
    try {
      setInquiries(await api.listInquiries("pending"));
    } catch (err) {
      setLoadError(err.message || "Failed to load inquiries");
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => { refresh(); }, []);

  async function handleDismiss(id) {
    if (!window.confirm("Dismiss this inquiry? It won't become a case.")) return;
    setActionError("");
    try {
      await api.dismissInquiry(id);
      setInquiries((prev) => prev.filter((i) => i.id !== id));
    } catch (err) {
      setActionError(err.message);
    }
  }

  function handleConverted(inquiryId, createdCase) {
    setInquiries((prev) => prev.filter((i) => i.id !== inquiryId));
    setConvertingId(null);
    navigate(`/cases/${createdCase.id}`);
  }

  return (
    <div style={{ width: "100%", padding: "36px 24px 60px", maxWidth: 900, margin: "0 auto" }}>
      <div style={{ marginBottom: 22 }}>
        <div style={{ fontSize: 11, letterSpacing: 0.6, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 4 }}>
          Email inquiries
        </div>
        <h1 style={{ fontSize: 24 }}>Inbox</h1>
        <p style={{ color: "var(--text-dim)", fontSize: 13, marginTop: 6, maxWidth: 640 }}>
          New emails pulled from your inbox land here first. Review each one, confirm or pick the customer,
          then convert it into a real case — or dismiss it if it isn't a genuine inquiry.
        </p>
      </div>

      {actionError && <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 14 }}>{actionError}</div>}

      <div className="card" style={{ overflow: "hidden" }}>
        {loading ? (
          <div className="empty-state">Loading…</div>
        ) : loadError ? (
          <div className="empty-state" style={{ color: "var(--red)" }}>
            Couldn't load inquiries: {loadError}
            <div style={{ marginTop: 10 }}>
              <button className="btn-ghost" onClick={() => { setLoading(true); refresh(); }}>Retry</button>
            </div>
          </div>
        ) : !inquiries.length ? (
          <div className="empty-state">No pending inquiries. New emails will show up here automatically.</div>
        ) : (
          <div>
            {inquiries.map((inq) => {
              const expanded = expandedId === inq.id;
              const snippet = (inq.body_text || "").slice(0, 220);
              return (
                <div key={inq.id} style={{ padding: "16px 18px", borderBottom: "1px solid var(--line-soft)" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 12 }}>
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 13.5, fontWeight: 600 }}>
                        {inq.from_name || inq.from_email || "Unknown sender"}
                        {inq.matched_customer_name && (
                          <span className="ref-stamp" style={{ marginLeft: 8, fontWeight: 500 }}>
                            matched: {inq.matched_customer_name}
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: 11.5, color: "var(--text-faint)", marginTop: 2 }}>
                        {inq.from_email} · {fullDate(inq.received_at)}
                      </div>
                      {inq.subject && <div style={{ fontSize: 13, marginTop: 6, fontWeight: 500 }}>{inq.subject}</div>}
                      <div style={{ fontSize: 12.5, color: "var(--text-dim)", marginTop: 6, whiteSpace: "pre-wrap" }}>
                        {expanded ? inq.body_text : snippet}
                        {!expanded && (inq.body_text || "").length > 220 && "…"}
                      </div>
                      {(inq.body_text || "").length > 220 && (
                        <button
                          className="btn-ghost"
                          onClick={() => setExpandedId(expanded ? null : inq.id)}
                          style={{ padding: "3px 8px", fontSize: 11, marginTop: 6 }}
                        >
                          {expanded ? "Show less" : "Show full email"}
                        </button>
                      )}
                    </div>
                    <div style={{ display: "flex", gap: 6, flexShrink: 0 }}>
                      <button
                        className="btn-primary"
                        onClick={() => setConvertingId(convertingId === inq.id ? null : inq.id)}
                        style={{ padding: "6px 12px", fontSize: 12, whiteSpace: "nowrap" }}
                      >
                        Convert to case
                      </button>
                      <button
                        className="btn-ghost"
                        onClick={() => handleDismiss(inq.id)}
                        style={{ padding: "6px 12px", fontSize: 12, whiteSpace: "nowrap" }}
                      >
                        Dismiss
                      </button>
                    </div>
                  </div>

                  {convertingId === inq.id && (
                    <ConvertForm
                      inquiry={inq}
                      onDone={(createdCase) => handleConverted(inq.id, createdCase)}
                      onCancel={() => setConvertingId(null)}
                    />
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
