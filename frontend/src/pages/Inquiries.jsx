import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api.js";
import CustomerPicker from "../components/CustomerPicker.jsx";
import { INQUIRY_TYPES, SEGMENTS, segmentMeta } from "../constants.js";

const fullDate = (iso) => (iso ? new Date(iso).toLocaleString("en-IN", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" }) : "—");

const EMAIL_TYPE_META = {
  new_inquiry: { label: "New Inquiry", color: "#1bb8b0" },
  follow_up: { label: "Follow-up", color: "#5d7188" },
  negotiation: { label: "Negotiation", color: "#f2a900" },
  order: { label: "Order", color: "#3fb950" },
  other: { label: "Other", color: "#94a3b8" },
};

function ConvertForm({ inquiry, onDone, onCancel }) {
  const [customer, setCustomer] = useState(null);
  const [loadingCustomer, setLoadingCustomer] = useState(!!inquiry.matched_customer_id);
  const [requirement, setRequirement] = useState(inquiry.ai_summary || inquiry.body_text || "");
  const [segment, setSegment] = useState(inquiry.ai_suggested_segment || "");
  const [inquiryType, setInquiryType] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [applyingFuzzyMatch, setApplyingFuzzyMatch] = useState(false);

  // An exact match (by sender email) is fetched in full — the picker
  // shows placeholder text like "No further details on file" if only an
  // {id, name} pair is passed in, so this loads the real record (code,
  // GST, address, contact person) to actually display it.
  useEffect(() => {
    if (inquiry.matched_customer_id) {
      api.getCustomer(inquiry.matched_customer_id)
        .then(setCustomer)
        .catch(() => setCustomer({ id: inquiry.matched_customer_id, name: inquiry.matched_customer_name }))
        .finally(() => setLoadingCustomer(false));
    }
  }, [inquiry.matched_customer_id]);

  async function useFuzzyMatch() {
    setApplyingFuzzyMatch(true);
    try {
      const full = await api.getCustomer(inquiry.ai_matched_customer_id);
      setCustomer(full);
    } catch {
      setCustomer({ id: inquiry.ai_matched_customer_id, name: inquiry.ai_matched_customer_name });
    } finally {
      setApplyingFuzzyMatch(false);
    }
  }

  async function submit(e) {
    e?.preventDefault();
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

  const showFuzzySuggestion = !inquiry.matched_customer_id && inquiry.ai_matched_customer_id && !customer;
  const isNewCustomer = !inquiry.matched_customer_id && !inquiry.ai_matched_customer_id;

  return (
    <div className="card" style={{ padding: 18, marginTop: 10 }}>
      <div style={{ marginBottom: 14 }}>
        <label className="fl">Customer</label>
        {loadingCustomer ? (
          <div style={{ fontSize: 12.5, color: "var(--text-faint)" }}>Loading matched customer…</div>
        ) : (
          <CustomerPicker
            value={customer}
            onChange={setCustomer}
            initialNewCustomer={
              isNewCustomer
                ? {
                    name: inquiry.ai_suggested_customer_name || "",
                    email: inquiry.from_email || "",
                    phone: inquiry.ai_suggested_customer_phone || "",
                  }
                : undefined
            }
          />
        )}
        {inquiry.matched_customer_id && !customer && !loadingCustomer && (
          <div style={{ fontSize: 11.5, color: "var(--text-faint)", marginTop: 4 }}>
            Matched by sender email to an existing customer — cleared because you changed it.
          </div>
        )}
        {showFuzzySuggestion && (
          <div style={{
            fontSize: 11.5, color: "var(--text-dim)", marginTop: 6, padding: "8px 10px",
            background: "var(--teal-ink)", border: "1px solid var(--teal-border)", borderRadius: 8,
            display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10,
          }}>
            <span>
              AI thinks this might already be <b>{inquiry.ai_matched_customer_name}</b> on file
              (extracted name: "{inquiry.ai_suggested_customer_name}") — check before assuming it's new.
            </span>
            <button type="button" className="btn-ghost" onClick={useFuzzyMatch} disabled={applyingFuzzyMatch} style={{ whiteSpace: "nowrap", padding: "4px 10px", fontSize: 11 }}>
              {applyingFuzzyMatch ? "Loading…" : "Use this customer"}
            </button>
          </div>
        )}
        {isNewCustomer && inquiry.ai_suggested_customer_name && !customer && (
          <div style={{ fontSize: 11.5, color: "var(--text-faint)", marginTop: 4 }}>
            No match found on file — "+ New customer" above is pre-filled from the email (name, email, phone). Review before saving.
          </div>
        )}
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14, marginBottom: 14 }}>
        <div>
          <label className="fl">Segment{inquiry.ai_suggested_segment && segment === inquiry.ai_suggested_segment ? " (AI-suggested)" : ""}</label>
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
        <label className="fl">Requirement{inquiry.ai_summary ? " (AI summary — edit as needed)" : ""}</label>
        <textarea rows={4} value={requirement} onChange={(e) => setRequirement(e.target.value)} placeholder="Pulled from the email body — edit as needed" />
      </div>
      {error && <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 12 }}>{error}</div>}
      <div style={{ display: "flex", gap: 8 }}>
        <button type="button" onClick={submit} className="btn-primary" disabled={saving}>
          {saving ? "Creating…" : "Create case"}
        </button>
        <button type="button" className="btn-ghost" onClick={onCancel}>Cancel</button>
      </div>
    </div>
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

  const [analyzingId, setAnalyzingId] = useState(null);

  async function handleAnalyze(id) {
    setActionError("");
    setAnalyzingId(id);
    try {
      const updated = await api.analyzeInquiry(id);
      setInquiries((prev) => prev.map((i) => (i.id === id ? updated : i)));
    } catch (err) {
      setActionError(`Analysis failed for that email: ${err.message}`);
    } finally {
      setAnalyzingId(null);
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
                      <div style={{ fontSize: 13.5, fontWeight: 600, display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
                        {inq.from_name || inq.from_email || "Unknown sender"}
                        {inq.ai_email_type && EMAIL_TYPE_META[inq.ai_email_type] && (
                          <span style={{
                            fontSize: 10.5, fontWeight: 600, padding: "2px 8px", borderRadius: 20,
                            color: "#fff", background: EMAIL_TYPE_META[inq.ai_email_type].color,
                          }}>
                            {EMAIL_TYPE_META[inq.ai_email_type].label}
                          </span>
                        )}
                        {inq.matched_customer_name && (
                          <span className="ref-stamp" style={{ fontWeight: 500 }}>
                            matched: {inq.matched_customer_name}
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: 11.5, color: "var(--text-faint)", marginTop: 2 }}>
                        {inq.from_email} · {fullDate(inq.received_at)}
                      </div>
                      {inq.subject && <div style={{ fontSize: 13, marginTop: 6, fontWeight: 500 }}>{inq.subject}</div>}

                      {inq.ai_summary ? (
                        <div style={{ marginTop: 6 }}>
                          <div style={{ fontSize: 12.5, color: "var(--text-dim)" }}>{inq.ai_summary}</div>
                          <div style={{ display: "flex", gap: 14, flexWrap: "wrap", marginTop: 3 }}>
                            {inq.ai_industry_type && (
                              <div style={{ fontSize: 11, color: "var(--text-faint)" }}>
                                Industry (AI guess): {inq.ai_industry_type}
                              </div>
                            )}
                            {inq.ai_suggested_segment && (
                              <div style={{ fontSize: 11, color: "var(--text-faint)" }}>
                                Suggested segment: <b>{segmentMeta(inq.ai_suggested_segment)?.label || inq.ai_suggested_segment}</b>
                              </div>
                            )}
                            {inq.ai_suggested_customer_name && !inq.matched_customer_name && (
                              <div style={{ fontSize: 11, color: "var(--text-faint)" }}>
                                Suggested customer: <b>{inq.ai_suggested_customer_name}</b>
                                {inq.ai_matched_customer_name && (
                                  <span style={{ color: "var(--teal-deep)" }}> — likely existing: {inq.ai_matched_customer_name}</span>
                                )}
                              </div>
                            )}
                          </div>
                        </div>
                      ) : inq.ai_error ? (
                        <div style={{ fontSize: 11.5, color: "var(--text-faint)", marginTop: 6, fontStyle: "italic" }}>
                          AI analysis unavailable: {inq.ai_error}
                        </div>
                      ) : null}

                      <div style={{ fontSize: 12.5, color: "var(--text-dim)", marginTop: inq.ai_summary ? 8 : 6, whiteSpace: "pre-wrap" }}>
                        {expanded ? inq.body_text : snippet}
                        {!expanded && (inq.body_text || "").length > 220 && "…"}
                      </div>
                      <div style={{ display: "flex", gap: 10, alignItems: "center", marginTop: 6 }}>
                        {(inq.body_text || "").length > 220 && (
                          <button
                            className="btn-ghost"
                            onClick={() => setExpandedId(expanded ? null : inq.id)}
                            style={{ padding: "3px 8px", fontSize: 11 }}
                          >
                            {expanded ? "Show less" : "Show full email"}
                          </button>
                        )}
                        <button
                          className="btn-ghost"
                          onClick={() => handleAnalyze(inq.id)}
                          disabled={analyzingId === inq.id}
                          style={{ padding: "3px 8px", fontSize: 11 }}
                        >
                          {analyzingId === inq.id ? "Analyzing…" : inq.ai_analyzed_at ? "Re-analyze" : "Analyze with AI"}
                        </button>
                      </div>
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
