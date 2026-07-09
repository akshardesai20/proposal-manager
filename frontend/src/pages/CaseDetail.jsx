import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { api } from "../api.js";
import { CASE_PROGRESS_STAGES, STAGE_ORDER } from "../constants.js";
import logo from "../assets/logo.png";

const COMPANY_NAME = import.meta.env.VITE_COMPANY_NAME || "Your Company Name";

const EMAIL_TYPE_META = {
  new_inquiry: { label: "New Inquiry", color: "#1bb8b0" },
  follow_up: { label: "Follow-up", color: "#5d7188" },
  negotiation: { label: "Negotiation", color: "#f2a900" },
  order: { label: "Order", color: "#3fb950" },
  other: { label: "Other", color: "#94a3b8" },
};

const shortDate = (iso) => (iso ? new Date(iso).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "2-digit" }) : null);
const toDateInput = (iso) => (iso ? new Date(iso).toISOString().slice(0, 10) : "");
// The site-wide `input { width: 100%; padding: 10px 11px; ... }` rule in
// styles.css targets every <input>, checkboxes included — without this
// override, checkboxes stretch to fill their flex row and get padding
// meant for text fields, which is what pushed the Case Progress labels
// off to one side. This resets a checkbox back to its natural small size.
const checkboxStyle = { width: 16, height: 16, minWidth: 16, flexShrink: 0, padding: 0, border: "1px solid var(--line)", borderRadius: 4 };

function suggestPrice(list, disc, margin) {
  const l = Number(list) || 0;
  const d = Number(disc) || 0;
  const m = Number(margin) || 0;
  const raw = l * (1 - d / 100) * (1 + m / 100);
  return Math.ceil(raw / 100) * 100;
}

function DecodedNameplate({ result }) {
  if (!result) return null;
  if (!result.matched) {
    return (
      <div style={{ color: "var(--amber)", fontSize: 13, padding: "10px 0" }}>
        {result.message || "No matching family found for this code."}
      </div>
    );
  }
  return (
    <div style={{ marginTop: 10 }}>
      <div style={{ fontSize: 13, marginBottom: 8 }}>
        <span className="ref-stamp" style={{ marginRight: 8 }}>{result.family.base_code}</span>
        <span style={{ color: "var(--text-dim)" }}>{result.family.family} — {result.family.short_name}</span>
      </div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 }}>
        {result.positions.map((p) => (
          <span
            key={p.position_no}
            title={p.name}
            className="mono"
            style={{
              fontSize: 12, padding: "3px 7px", borderRadius: 5,
              background: p.matched ? "var(--teal-ink)" : "var(--amber-ink)",
              color: p.matched ? "var(--teal-deep)" : "var(--amber)",
              border: `1px solid ${p.matched ? "var(--teal-border)" : "#f5cb8f"}`,
            }}
          >
            {p.character ?? "?"}
          </span>
        ))}
      </div>
      {result.bullets.length > 0 && (
        <ul style={{ margin: 0, paddingLeft: 18, fontSize: 12.5, color: "var(--text-dim)" }}>
          {result.bullets.map((b, i) => <li key={i} style={{ marginBottom: 3 }}>{b}</li>)}
        </ul>
      )}
      {result.leftover && (
        <div style={{ fontSize: 12, color: "var(--amber)", marginTop: 6 }}>
          Unrecognized trailing characters: <span className="mono">{result.leftover}</span>
        </div>
      )}
    </div>
  );
}

function PriceFields({ list, setList, disc, setDisc, margin, setMargin, qty, setQty, price, setPrice }) {
  useEffect(() => {
    setPrice(String(suggestPrice(list, disc, margin)));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [list, disc, margin]);

  return (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr 1fr 1fr", gap: 10, marginTop: 12 }}>
      <div>
        <label className="fl">Qty</label>
        <input type="number" min="1" value={qty} onChange={(e) => setQty(e.target.value)} />
      </div>
      <div>
        <label className="fl">List price (₹)</label>
        <input type="number" value={list} onChange={(e) => setList(e.target.value)} placeholder="Siemens portal price" />
      </div>
      <div>
        <label className="fl">Discount %</label>
        <input type="number" value={disc} onChange={(e) => setDisc(e.target.value)} />
      </div>
      <div>
        <label className="fl">Margin %</label>
        <input type="number" value={margin} onChange={(e) => setMargin(e.target.value)} />
      </div>
      <div>
        <label className="fl">Offer unit price (₹)</label>
        <input type="number" value={price} onChange={(e) => setPrice(e.target.value)} />
      </div>
    </div>
  );
}

function FamilyPicker({ onSelect }) {
  const [q, setQ] = useState("");
  const [results, setResults] = useState([]);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    if (!q.trim()) { setResults([]); setOpen(false); return; }
    const t = setTimeout(async () => {
      try {
        const r = await api.searchFamilies(q);
        setResults(r);
        setOpen(true);
      } catch { /* ignore, user can retry */ }
    }, 250);
    return () => clearTimeout(t);
  }, [q]);

  return (
    <div style={{ position: "relative" }}>
      <input
        value={q}
        onChange={(e) => setQ(e.target.value)}
        onFocus={() => results.length && setOpen(true)}
        placeholder="Search family — e.g. LU240, MAG 3100, LT500"
      />
      {open && results.length > 0 && (
        <div className="card" style={{
          position: "absolute", zIndex: 10, top: "calc(100% + 4px)", left: 0, right: 0,
          maxHeight: 240, overflowY: "auto",
        }}>
          {results.map((f) => (
            <div
              key={f.base_code}
              onClick={() => { onSelect(f); setOpen(false); setQ(""); }}
              style={{ padding: "10px 12px", cursor: "pointer", borderBottom: "1px solid var(--line-soft)" }}
              onMouseEnter={(e) => (e.currentTarget.style.background = "var(--panel-2)")}
              onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
            >
              <span className="ref-stamp" style={{ marginRight: 8 }}>{f.base_code}</span>
              <span style={{ fontSize: 13 }}>{f.family}</span>
              <span style={{ fontSize: 11.5, color: "var(--text-faint)", marginLeft: 6 }}>{f.short_name}</span>
            </div>
          ))}
        </div>
      )}
      {open && q.trim() && results.length === 0 && (
        <div style={{ fontSize: 12, color: "var(--text-faint)", marginTop: 6 }}>No matching family.</div>
      )}
    </div>
  );
}

function ModelBuilder({ onAdd }) {
  const [family, setFamily] = useState(null);
  const [detail, setDetail] = useState(null);
  const [selections, setSelections] = useState({});
  const [suffixSel, setSuffixSel] = useState([]);
  const [loadError, setLoadError] = useState("");
  const [instrumentName, setInstrumentName] = useState("");
  const [productName, setProductName] = useState("");
  const [list, setList] = useState("0");
  const [disc, setDisc] = useState("60");
  const [margin, setMargin] = useState("30");
  const [qty, setQty] = useState("1");
  const [price, setPrice] = useState("0");

  async function selectFamily(f) {
    setLoadError("");
    try {
      const d = await api.getFamily(f.base_code);
      const sorted = [...d.positions].sort((a, b) => a.position_no - b.position_no);
      const defaults = {};
      sorted.forEach((p) => { defaults[p.position_no] = p.is_fix ? (p.options[0]?.character || "") : ""; });
      setDetail({ ...d, positions: sorted });
      setFamily(f);
      setSelections(defaults);
      setSuffixSel([]);
      setInstrumentName(d.instrument_type || "");
      setProductName(d.trade_name || "");
    } catch (err) {
      setLoadError(err.message);
    }
  }

  function reset() {
    setFamily(null); setDetail(null); setSelections({}); setSuffixSel([]);
    setInstrumentName(""); setProductName("");
    setList("0"); setPrice("0");
  }

  useEffect(() => { setPrice(String(suggestPrice(list, disc, margin))); }, [list, disc, margin]);

  if (!family) {
    return (
      <div>
        <label className="fl">Select Siemens family</label>
        <FamilyPicker onSelect={selectFamily} />
        {loadError && <div style={{ color: "var(--red)", fontSize: 12.5, marginTop: 8 }}>{loadError}</div>}
      </div>
    );
  }

  const allChosen = detail.positions.every((p) => selections[p.position_no]);

  const code = detail.base_code
    + detail.positions.map((p) => selections[p.position_no] || "\u00b7").join("")
    + (suffixSel.length ? "-Z " + suffixSel.join(" ") : "");

  const bullets = detail.positions
    .filter((p) => !p.is_fix && selections[p.position_no])
    .map((p) => {
      const opt = p.options.find((o) => o.character === selections[p.position_no]);
      return opt ? `${p.name}: ${opt.meaning}` : null;
    })
    .filter(Boolean)
    .concat(
      suffixSel
        .map((code) => detail.suffixes.find((s) => s.code === code)?.meaning)
        .filter(Boolean)
    );

  const description = [detail.description, ...bullets].filter(Boolean).join(" ");

  const rangePosition = detail.positions.find((p) => p.is_range && selections[p.position_no]);
  const rangeOpt = rangePosition && rangePosition.options.find((o) => o.character === selections[rangePosition.position_no]);
  const rangeValue = rangeOpt ? (rangeOpt.short_label || rangeOpt.meaning) : "";

  function add() {
    if (!allChosen) return;
    onAdd({
      source: "catalog", model_code: code, family: detail.base_code, description,
      instrument_name: instrumentName, product_name: productName, range_value: rangeValue,
      config_bullets: bullets, addons: [],
      qty: Number(qty) || 1, list_price: Number(list) || 0,
      discount_pct: Number(disc) || 0, margin_pct: Number(margin) || 0,
      final_unit_price: Number(price) || 0,
    });
    reset();
  }

  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
        <div>
          <span className="ref-stamp" style={{ marginRight: 8 }}>{family.base_code}</span>
          <span style={{ fontSize: 13, color: "var(--text-dim)" }}>{family.family} — {family.short_name}</span>
        </div>
        <button className="btn-ghost" onClick={reset} style={{ padding: "5px 10px", fontSize: 11.5 }}>Change family</button>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 12 }}>
        <div>
          <label className="fl">Name of instrument (offer label)</label>
          <input value={instrumentName} onChange={(e) => setInstrumentName(e.target.value)} placeholder="e.g. Pressure Transmitter" />
        </div>
        <div>
          <label className="fl">Product (short name)</label>
          <input value={productName} onChange={(e) => setProductName(e.target.value)} placeholder="e.g. LU240" />
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
        {detail.positions.map((p) => (
          <div key={p.position_no}>
            <label className="fl">{p.name}{p.is_fix ? " (fixed)" : ""}</label>
            <select
              value={selections[p.position_no] || ""}
              disabled={p.is_fix}
              onChange={(e) => setSelections((s) => ({ ...s, [p.position_no]: e.target.value }))}
            >
              {!p.is_fix && <option value="" disabled>Choose…</option>}
              {p.options.map((o) => (
                <option key={o.character} value={o.character}>{o.character} — {o.meaning}</option>
              ))}
            </select>
          </div>
        ))}
      </div>

      {detail.suffixes.length > 0 && (
        <div style={{ marginTop: 16 }}>
          <label className="fl">Options / approvals (optional)</label>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
            {detail.suffixes.map((s) => {
              const checked = suffixSel.includes(s.code);
              return (
                <label
                  key={s.code}
                  title={s.meaning}
                  className="mono"
                  style={{
                    fontSize: 11.5, padding: "5px 9px", borderRadius: 6, cursor: "pointer",
                    border: `1px solid ${checked ? "var(--teal-border)" : "var(--line)"}`,
                    background: checked ? "var(--teal-ink)" : "var(--panel-2)",
                    color: checked ? "var(--teal-deep)" : "var(--text-dim)",
                  }}
                >
                  <input
                    type="checkbox" checked={checked} style={{ ...checkboxStyle, marginRight: 5 }}
                    onChange={() => setSuffixSel((sel) => (checked ? sel.filter((c) => c !== s.code) : [...sel, s.code]))}
                  />
                  {s.code}
                </label>
              );
            })}
          </div>
        </div>
      )}

      <div style={{ marginTop: 16, padding: 12, background: "var(--panel-2)", borderRadius: 8 }}>
        <div className="mono" style={{ fontSize: 13, color: "var(--teal)", marginBottom: 6 }}>{code}</div>
        {rangeValue && (
          <div style={{ fontSize: 12, color: "var(--text-dim)", marginBottom: bullets.length ? 8 : 0 }}>
            Range: <span className="mono">{rangeValue}</span>
          </div>
        )}
        {bullets.length > 0 && (
          <ul style={{ margin: 0, paddingLeft: 18, fontSize: 12.5, color: "var(--text-dim)" }}>
            {bullets.map((b, i) => <li key={i} style={{ marginBottom: 3 }}>{b}</li>)}
          </ul>
        )}
      </div>

      <PriceFields {...{ list, setList, disc, setDisc, margin, setMargin, qty, setQty, price, setPrice }} />
      <button className="btn-primary" onClick={add} disabled={!allChosen} style={{ marginTop: 14 }}>
        Add line item
      </button>
    </div>
  );
}

function PasteCodeEntry({ onAdd }) {
  const [code, setCode] = useState("");
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [instrumentName, setInstrumentName] = useState("");
  const [productName, setProductName] = useState("");
  const [list, setList] = useState("0");
  const [disc, setDisc] = useState("60");
  const [margin, setMargin] = useState("30");
  const [qty, setQty] = useState("1");
  const [price, setPrice] = useState("0");

  async function decode() {
    if (!code.trim()) return;
    setLoading(true);
    setError("");
    try {
      const r = await api.decodeModel(code);
      setResult(r);
      if (r.matched) {
        setInstrumentName(r.family.instrument_type || "");
        setProductName(r.family.trade_name || "");
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  function add() {
    if (!result || !result.matched) return;
    onAdd({
      source: "catalog",
      model_code: code.trim(),
      family: result.family.base_code,
      description: result.description,
      instrument_name: instrumentName, product_name: productName, range_value: result.range_value || "",
      config_bullets: result.bullets,
      addons: [],
      qty: Number(qty) || 1,
      list_price: Number(list) || 0,
      discount_pct: Number(disc) || 0,
      margin_pct: Number(margin) || 0,
      final_unit_price: Number(price) || 0,
    });
    setCode(""); setResult(null); setList("0"); setPrice("0");
  }

  return (
    <div>
      <label className="fl">Model code</label>
      <div style={{ display: "flex", gap: 8 }}>
        <input
          value={code} onChange={(e) => setCode(e.target.value)}
          placeholder="e.g. 7ML5111-0B... or 7ME6310-2Y..."
          onKeyDown={(e) => e.key === "Enter" && decode()}
          className="mono"
        />
        <button className="btn-ghost" onClick={decode} disabled={loading} style={{ whiteSpace: "nowrap" }}>
          {loading ? "Decoding…" : "Decode"}
        </button>
      </div>
      {error && <div style={{ color: "var(--red)", fontSize: 12.5, marginTop: 8 }}>{error}</div>}
      <DecodedNameplate result={result} />
      {result?.matched && (
        <>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 12 }}>
            <div>
              <label className="fl">Name of instrument (offer label)</label>
              <input value={instrumentName} onChange={(e) => setInstrumentName(e.target.value)} />
            </div>
            <div>
              <label className="fl">Product (short name)</label>
              <input value={productName} onChange={(e) => setProductName(e.target.value)} />
            </div>
          </div>
          <PriceFields {...{ list, setList, disc, setDisc, margin, setMargin, qty, setQty, price, setPrice }} />
          <button className="btn-primary" onClick={add} style={{ marginTop: 14 }}>Add line item</button>
        </>
      )}
    </div>
  );
}

function ManualEntry({ onAdd }) {
  const [instrumentName, setInstrumentName] = useState("");
  const [modelCode, setModelCode] = useState("");
  const [productName, setProductName] = useState("");
  const [rangeValue, setRangeValue] = useState("");
  const [description, setDescription] = useState("");
  const [list, setList] = useState("0");
  const [disc, setDisc] = useState("60");
  const [margin, setMargin] = useState("30");
  const [qty, setQty] = useState("1");
  const [price, setPrice] = useState("0");

  function add() {
    if (!instrumentName.trim() && !description.trim()) return;
    onAdd({
      source: "manual",
      model_code: modelCode.trim() || null,
      description: description.trim() || instrumentName.trim(),
      instrument_name: instrumentName.trim(),
      product_name: productName.trim(),
      range_value: rangeValue.trim(),
      config_bullets: [],
      addons: [],
      qty: Number(qty) || 1,
      list_price: Number(list) || 0,
      discount_pct: Number(disc) || 0,
      margin_pct: Number(margin) || 0,
      final_unit_price: Number(price) || 0,
    });
    setInstrumentName(""); setModelCode(""); setProductName(""); setRangeValue("");
    setDescription(""); setList("0"); setPrice("0");
  }

  return (
    <div>
      <div style={{ fontSize: 12, color: "var(--text-faint)", marginBottom: 12 }}>
        For items not yet in the catalog (e.g. Pressure Transmitters, other product lines) — fill in what you have.
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 12 }}>
        <div>
          <label className="fl">Name of instrument</label>
          <input value={instrumentName} onChange={(e) => setInstrumentName(e.target.value)} placeholder="e.g. Pressure Transmitter" />
        </div>
        <div>
          <label className="fl">Model no.</label>
          <input value={modelCode} onChange={(e) => setModelCode(e.target.value)} className="mono" placeholder="e.g. 7MF0300-1QE01-5AM2-ZE00+H01" />
        </div>
        <div>
          <label className="fl">Product (short name)</label>
          <input value={productName} onChange={(e) => setProductName(e.target.value)} placeholder="e.g. PT-320" />
        </div>
        <div>
          <label className="fl">Range</label>
          <input value={rangeValue} onChange={(e) => setRangeValue(e.target.value)} placeholder="e.g. 16Bar" />
        </div>
      </div>
      <label className="fl">Description (internal notes, optional)</label>
      <textarea rows={2} value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Any extra spec detail" />
      <PriceFields {...{ list, setList, disc, setDisc, margin, setMargin, qty, setQty, price, setPrice }} />
      <button className="btn-primary" onClick={add} style={{ marginTop: 14 }}>Add line item</button>
    </div>
  );
}

export default function CaseDetail({ user }) {
  const { id } = useParams();
  const [caseData, setCaseData] = useState(null);
  const [items, setItems] = useState([]);
  const [offers, setOffers] = useState([]);
  const [mode, setMode] = useState("catalog");
  const [catalogSubMode, setCatalogSubMode] = useState("build");
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [offerError, setOfferError] = useState("");
  const [notes, setNotes] = useState("");
  const [notesSaved, setNotesSaved] = useState(true);
  const [savingNotes, setSavingNotes] = useState(false);
  const [followups, setFollowups] = useState([]);
  const [followupDate, setFollowupDate] = useState("");
  const [followupText, setFollowupText] = useState("");
  const [followupError, setFollowupError] = useState("");
  const [addingFollowup, setAddingFollowup] = useState(false);
  const [expectedOrderDate, setExpectedOrderDate] = useState("");
  const [emails, setEmails] = useState([]);
  const [analyzingEmailId, setAnalyzingEmailId] = useState(null);

  async function handleAnalyzeCaseEmail(emailId) {
    setAnalyzingEmailId(emailId);
    try {
      const updated = await api.analyzeCaseEmail(id, emailId);
      setEmails((prev) => prev.map((e) => (e.id === emailId ? updated : e)));
    } catch (err) {
      alert(err.message || "Failed to analyze this email");
    } finally {
      setAnalyzingEmailId(null);
    }
  }
  const [myProfile, setMyProfile] = useState(null);
  useEffect(() => { api.getMyProfile().then(setMyProfile).catch(() => {}); }, []);
  const [composeFor, setComposeFor] = useState(null); // { offerId, offerRef } for an offer send, or "followup" for a general email, or null
  const [composeTo, setComposeTo] = useState("");
  const [composeSubject, setComposeSubject] = useState("");
  const [composeBody, setComposeBody] = useState("");
  const [composeError, setComposeError] = useState("");
  const [sendingEmail, setSendingEmail] = useState(false);

  async function refresh() {
    const [c, i, o, em] = await Promise.all([api.getCase(id), api.listCosting(id), api.listOffers(id), api.listCaseEmails(id)]);
    setCaseData(c);
    setItems(i);
    setOffers(o);
    setEmails(em);
    setNotes(c.notes || "");
    setNotesSaved(true);
    setFollowups(c.followups || []);
    setExpectedOrderDate(toDateInput(c.expected_order_date));
    setLoading(false);
  }
  useEffect(() => { refresh(); }, [id]);

  function openComposeForOffer(offer) {
    setComposeFor({ offerId: offer.id, offerRef: offer.ref });
    setComposeTo(caseData?.customer_email || "");
    // Match the subject of the email that originated this case, so this
    // lands as part of the same conversation in the customer's inbox
    // rather than a brand-new thread. Falls back to a generic subject if
    // this case wasn't created from an inbound email.
    setComposeSubject(caseData?.origin_email_subject || `Offer ${offer.ref} — ${caseData?.customer_name || ""}`);
    setComposeBody(
      `Dear Sir,\n\nPlease find attached our offer ${offer.ref} for your requirement.\n\n` +
      `Please let us know if you have any questions.\n\nRegards,`
    );
    setComposeError("");
  }

  function openComposeFollowup() {
    setComposeFor("followup");
    setComposeTo(caseData?.customer_email || "");
    setComposeSubject(caseData?.origin_email_subject || `Following up — ${caseData?.reference || `CASE-${String(caseData?.id).padStart(4, "0")}`}`);
    setComposeBody(`Dear Sir,\n\nFollowing up on our earlier conversation regarding your requirement.\n\nRegards,`);
    setComposeError("");
  }

  function closeCompose() {
    setComposeFor(null);
    setComposeError("");
  }

  async function handleSendEmail() {
    setComposeError("");
    if (!composeTo.trim()) { setComposeError("Recipient email is required"); return; }
    if (!composeSubject.trim()) { setComposeError("Subject is required"); return; }
    if (!composeBody.trim()) { setComposeError("Email body is required"); return; }
    setSendingEmail(true);
    try {
      const payload = {
        to: composeTo.trim(), subject: composeSubject.trim(), body: composeBody,
        offer_id: composeFor && composeFor !== "followup" ? composeFor.offerId : null,
        // Threads as a reply to the original inquiry email, if this case
        // came from one — sets the actual In-Reply-To/References headers,
        // which is what real email clients use to group a conversation
        // (the matching subject line alone only helps cosmetically).
        in_reply_to: caseData?.origin_email_message_id || null,
      };
      const sent = await api.sendCaseEmail(id, payload);
      setEmails((prev) => [...prev, sent]);
      setComposeFor(null);
    } catch (err) {
      setComposeError(err.message || "Failed to send email");
    } finally {
      setSendingEmail(false);
    }
  }

  async function handleAdd(payload) {
    await api.addCosting(id, payload);
    refresh();
  }

  async function handleDelete(itemId) {
    await api.deleteCosting(itemId);
    refresh();
  }

  async function saveNotes() {
    setSavingNotes(true);
    try {
      await api.updateCaseNotes(id, notes);
      setNotesSaved(true);
    } finally {
      setSavingNotes(false);
    }
  }

  async function handleGenerateOffer() {
    setOfferError("");
    setGenerating(true);
    try {
      if (!notesSaved) {
        await api.updateCaseNotes(id, notes);
        setNotesSaved(true);
      }
      await api.generateOffer(id);
      refresh();
    } catch (err) {
      setOfferError(err.message);
    } finally {
      setGenerating(false);
    }
  }

  async function handleDeleteOffer(offerId) {
    if (!window.confirm("Delete this offer revision? This can't be undone.")) return;
    setOfferError("");
    try {
      await api.deleteOffer(offerId);
      refresh();
    } catch (err) {
      setOfferError(err.message);
    }
  }

  async function handleExportExcel() {
    const latestRef = offers[0]?.ref || caseData.reference || `CASE-${String(caseData.id).padStart(4, "0")}`;
    try {
      await api.downloadCostingExcel(id, latestRef);
    } catch (err) {
      alert(err.message || "Failed to export costing to Excel");
    }
  }

  async function moveStage(stage) {
    await api.updateStage(id, stage);
    refresh();
  }

  // A progress checkbox is "checked" if the case's current stage has
  // reached at least that milestone in the fixed order — so checking
  // "Negotiations Completed" also shows Costing/Offer Prepared/Offer
  // Submitted as checked, which is correct (you can't skip ahead).
  function isProgressChecked(stage) {
    return STAGE_ORDER.indexOf(caseData.stage) >= STAGE_ORDER.indexOf(stage);
  }

  async function toggleProgress(stage, checked) {
    if (checked) {
      if (!isProgressChecked(stage)) await moveStage(stage);
      return;
    }
    // Unchecking moves the stage back one step — to whatever came right
    // before this milestone in the order.
    const idx = STAGE_ORDER.indexOf(stage);
    const prevStage = STAGE_ORDER[Math.max(idx - 1, 0)];
    await moveStage(prevStage);
  }

  // Order Won / Order Lost are mutually exclusive outcomes, not sequential
  // steps — checking one always overrides the other. Unchecking either
  // reverts to "Negotiations Completed" as the last known-good milestone.
  async function toggleOutcome(outcome, checked) {
    if (checked) {
      await moveStage(outcome === "won" ? "won" : "lost");
    } else {
      await moveStage("negotiation_complete");
    }
  }

  async function saveExpectedOrderDate(value) {
    setExpectedOrderDate(value);
    const updated = await api.updateCaseDetails(id, { expected_order_date: value || null });
    setCaseData((prev) => ({ ...prev, expected_order_date: updated.expected_order_date }));
  }

  async function handleAddFollowup(e) {
    e.preventDefault();
    setFollowupError("");
    if (!followupDate) { setFollowupError("Pick a date for this follow-up"); return; }
    if (!followupText.trim()) { setFollowupError("Add a short update"); return; }
    setAddingFollowup(true);
    try {
      const created = await api.addFollowup(id, { followup_date: followupDate, update_text: followupText.trim() });
      setFollowups((prev) => [created, ...prev]);
      setFollowupDate("");
      setFollowupText("");
    } catch (err) {
      setFollowupError(err.message);
    } finally {
      setAddingFollowup(false);
    }
  }

  async function handleDeleteFollowup(followupId) {
    if (!window.confirm("Remove this follow-up entry? This can't be undone.")) return;
    try {
      await api.deleteFollowup(followupId);
      setFollowups((prev) => prev.filter((f) => f.id !== followupId));
    } catch (err) {
      setFollowupError(err.message);
    }
  }

  const total = items.reduce((sum, it) => sum + Number(it.final_unit_price) * Number(it.qty), 0);

  if (loading) return <div style={{ padding: 40, textAlign: "center", color: "var(--text-faint)" }}>Loading…</div>;

  return (
    <div style={{ maxWidth: 980, margin: "0 auto", padding: "36px 24px 60px", width: "100%" }}>
      <Link to="/cases" style={{ fontSize: 12.5, color: "var(--text-faint)", textDecoration: "none" }}>&larr; Back to proposals</Link>

      <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "10px 0 6px" }}>
        <span className="ref-stamp">{caseData.reference || `CASE-${String(caseData.id).padStart(4, "0")}`}</span>
        <h1 style={{ fontSize: 22 }}>{caseData.customer_name}</h1>
      </div>
      {caseData.requirement_text && (
        <p style={{ color: "var(--text-dim)", fontSize: 13.5, maxWidth: 700 }}>{caseData.requirement_text}</p>
      )}

      <h2 style={{ fontSize: 15, marginTop: 30, marginBottom: 12 }}>Case progress</h2>
      <div className="card" style={{ padding: 20, marginBottom: 20 }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 10, paddingBottom: 8, marginBottom: 8,
          borderBottom: "1px solid var(--line-soft)",
          fontSize: 10.5, letterSpacing: 0.4, textTransform: "uppercase", color: "var(--text-faint)", fontWeight: 600,
        }}>
          <span style={{ width: 16, minWidth: 16, flexShrink: 0 }} />
          <span style={{ flex: 1 }}>Milestone</span>
          <span>Date of Completion</span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {CASE_PROGRESS_STAGES.map((p) => {
            const checked = isProgressChecked(p.stage);
            const date = caseData[p.dateKey];
            return (
              <label key={p.stage} style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 13.5, cursor: "pointer" }}>
                <input type="checkbox" checked={checked} onChange={(e) => toggleProgress(p.stage, e.target.checked)} style={checkboxStyle} />
                <span style={{ flex: 1 }}>{p.label}</span>
                {checked && date && <span style={{ fontSize: 11.5, color: "var(--text-faint)" }}>{shortDate(date)}</span>}
              </label>
            );
          })}

          <div style={{ borderTop: "1px solid var(--line-soft)", margin: "4px 0" }} />

          <label style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 13.5, cursor: "pointer" }}>
            <input type="checkbox" checked={caseData.stage === "won"} onChange={(e) => toggleOutcome("won", e.target.checked)} style={checkboxStyle} />
            <span style={{ flex: 1, fontWeight: 600, color: "var(--green)" }}>Order Won</span>
            {caseData.stage === "won" && caseData.closed_at && <span style={{ fontSize: 11.5, color: "var(--text-faint)" }}>{shortDate(caseData.closed_at)}</span>}
          </label>
          <label style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 13.5, cursor: "pointer" }}>
            <input type="checkbox" checked={caseData.stage === "lost"} onChange={(e) => toggleOutcome("lost", e.target.checked)} style={checkboxStyle} />
            <span style={{ flex: 1, fontWeight: 600, color: "var(--red)" }}>Order Lost</span>
            {caseData.stage === "lost" && caseData.closed_at && <span style={{ fontSize: 11.5, color: "var(--text-faint)" }}>{shortDate(caseData.closed_at)}</span>}
          </label>
        </div>

        <div style={{ marginTop: 18, paddingTop: 16, borderTop: "1px solid var(--line-soft)" }}>
          <label className="fl">Expected order finalization date</label>
          <input
            type="date"
            value={expectedOrderDate}
            onChange={(e) => saveExpectedOrderDate(e.target.value)}
            style={{ maxWidth: 200 }}
          />
          <div style={{ fontSize: 11.5, color: "var(--text-faint)", marginTop: 5 }}>
            Target date for when you expect this order to close — feeds the dashboard forecast. This is separate from the actual Won/Lost date above, which is stamped automatically when you check one of those boxes.
          </div>
        </div>
      </div>

      <h2 style={{ fontSize: 15, marginTop: 30, marginBottom: 12 }}>Costing</h2>

      <div className="card" style={{ padding: 20, marginBottom: 20 }}>
        <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
          <button
            onClick={() => setMode("catalog")}
            className={mode === "catalog" ? "btn-primary" : "btn-ghost"}
            style={{ padding: "7px 14px", fontSize: 12.5 }}
          >Catalog-assisted</button>
          <button
            onClick={() => setMode("manual")}
            className={mode === "manual" ? "btn-primary" : "btn-ghost"}
            style={{ padding: "7px 14px", fontSize: 12.5 }}
          >Manual entry</button>
          <button
            onClick={handleExportExcel}
            className="btn-ghost"
            disabled={!items.length}
            style={{ padding: "7px 14px", fontSize: 12.5, marginLeft: "auto" }}
            title={!items.length ? "Add at least one costing line first" : "Download all costing lines as an Excel file"}
          >Export to Excel</button>
        </div>
        {mode === "catalog" ? (
          <>
            <div style={{ display: "flex", gap: 6, marginBottom: 16 }}>
              <button
                onClick={() => setCatalogSubMode("build")}
                style={{
                  padding: "5px 11px", fontSize: 11.5, borderRadius: 6, border: "1px solid var(--line)",
                  background: catalogSubMode === "build" ? "var(--panel-3)" : "transparent",
                  color: catalogSubMode === "build" ? "var(--text)" : "var(--text-faint)",
                }}
              >Build from options</button>
              <button
                onClick={() => setCatalogSubMode("paste")}
                style={{
                  padding: "5px 11px", fontSize: 11.5, borderRadius: 6, border: "1px solid var(--line)",
                  background: catalogSubMode === "paste" ? "var(--panel-3)" : "transparent",
                  color: catalogSubMode === "paste" ? "var(--text)" : "var(--text-faint)",
                }}
              >Paste a code</button>
            </div>
            {catalogSubMode === "build" ? <ModelBuilder onAdd={handleAdd} /> : <PasteCodeEntry onAdd={handleAdd} />}
          </>
        ) : (
          <ManualEntry onAdd={handleAdd} />
        )}
      </div>

      <div className="card" style={{ overflow: "hidden" }}>
        {!items.length ? (
          <div className="empty-state">No costing lines yet.</div>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ borderBottom: "1px solid var(--line)" }}>
                {["Instrument", "Model No.", "Product", "Range", "Qty", "Unit price", "Total", ""].map((h) => (
                  <th key={h} style={{
                    textAlign: "left", padding: "10px 14px", fontSize: 11,
                    letterSpacing: 0.5, textTransform: "uppercase", color: "var(--text-faint)", fontWeight: 600,
                  }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {items.map((it) => (
                <tr key={it.id} style={{ borderBottom: "1px solid var(--line-soft)" }}>
                  <td style={{ padding: "10px 14px" }}>
                    <div style={{ fontSize: 13 }}>{it.instrument_name || it.description}</div>
                  </td>
                  <td style={{ padding: "10px 14px" }}>
                    {it.model_code ? <span className="mono" style={{ fontSize: 11.5, color: "var(--text-dim)" }}>{it.model_code}</span> : "—"}
                  </td>
                  <td style={{ padding: "10px 14px", fontSize: 13 }}>{it.product_name || "—"}</td>
                  <td style={{ padding: "10px 14px", fontSize: 13 }}>{it.range_value || "—"}</td>
                  <td style={{ padding: "10px 14px", fontSize: 13 }}>{it.qty}</td>
                  <td style={{ padding: "10px 14px", fontSize: 13 }}>₹{Number(it.final_unit_price).toLocaleString("en-IN")}</td>
                  <td style={{ padding: "10px 14px", fontSize: 13, fontWeight: 600 }}>
                    ₹{(Number(it.final_unit_price) * Number(it.qty)).toLocaleString("en-IN")}
                  </td>
                  <td style={{ padding: "10px 14px" }}>
                    <button className="btn-ghost" onClick={() => handleDelete(it.id)} style={{ padding: "5px 10px", fontSize: 11.5 }}>
                      Remove
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <td colSpan={6} style={{ padding: "12px 14px", textAlign: "right", fontSize: 12.5, color: "var(--text-faint)" }}>
                  Total
                </td>
                <td colSpan={2} style={{ padding: "12px 14px", fontSize: 15, fontWeight: 700, color: "var(--teal)" }}>
                  ₹{total.toLocaleString("en-IN")}
                </td>
              </tr>
            </tfoot>
          </table>
        )}
      </div>

      <h2 style={{ fontSize: 15, marginTop: 30, marginBottom: 12 }}>Note for offer</h2>
      <div className="card" style={{ padding: 20, marginBottom: 8 }}>
        <div style={{ fontSize: 12.5, color: "var(--text-faint)", marginBottom: 10 }}>
          Optional — printed at the bottom of the quotation page (e.g. "Installation accessories are not included in our scope of supply").
          Leave blank for no note.
        </div>
        <textarea
          rows={2}
          value={notes}
          onChange={(e) => { setNotes(e.target.value); setNotesSaved(false); }}
          placeholder="e.g. Installation accessories are not included in our scope of supply in this offer."
        />
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginTop: 10 }}>
          <button className="btn-ghost" onClick={saveNotes} disabled={notesSaved || savingNotes} style={{ padding: "6px 14px", fontSize: 12 }}>
            {savingNotes ? "Saving…" : notesSaved ? "Saved" : "Save note"}
          </button>
        </div>
      </div>

      <h2 style={{ fontSize: 15, marginTop: 30, marginBottom: 12 }}>Offer</h2>
      <div className="card" style={{ padding: 20 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: offers.length ? 16 : 0 }}>
          <div style={{ fontSize: 12.5, color: "var(--text-faint)" }}>
            {items.length
              ? "Generates a PDF from the current costing lines above, prepared under your login."
              : "Add at least one costing line before generating an offer."}
          </div>
          <button
            className="btn-primary"
            onClick={handleGenerateOffer}
            disabled={!items.length || generating}
            style={{ whiteSpace: "nowrap" }}
          >
            {generating ? "Generating…" : offers.length ? "Generate revision" : "Generate offer"}
          </button>
        </div>
        {offerError && <div style={{ color: "var(--red)", fontSize: 12.5, marginTop: 10 }}>{offerError}</div>}

        {offers.length > 0 && (
          <div style={{ marginTop: 4 }}>
            {offers.map((o) => (
              <div key={o.id} style={{
                display: "flex", justifyContent: "space-between", alignItems: "center",
                padding: "10px 0", borderTop: "1px solid var(--line-soft)",
              }}>
                <div>
                  <span className="ref-stamp" style={{ marginRight: 10 }}>{o.ref}</span>
                  <span style={{ fontSize: 12, color: "var(--text-faint)" }}>
                    {o.prepared_by_name} · {new Date(o.generated_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })}
                  </span>
                </div>
                <div>
                  <button className="btn-ghost" onClick={() => api.downloadOfferPdf(o.id, o.ref)} style={{ padding: "6px 12px", fontSize: 12 }}>
                    Download PDF
                  </button>
                  <button className="btn-primary" onClick={() => openComposeForOffer(o)} style={{ padding: "6px 12px", fontSize: 12, marginLeft: 6 }}>
                    Send to Customer
                  </button>
                  {user?.role === "admin" && (
                    <button
                      className="btn-ghost"
                      onClick={() => handleDeleteOffer(o.id)}
                      style={{ padding: "6px 12px", fontSize: 12, marginLeft: 6, color: "var(--red)" }}
                    >
                      Delete
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {composeFor && (
        <div className="card" style={{ padding: 20, marginTop: 12 }}>
          <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 12 }}>
            {composeFor === "followup" ? "Compose follow-up email" : `Send offer ${composeFor.offerRef} to customer`}
          </div>
          <div style={{ marginBottom: 12 }}>
            <label className="fl">To</label>
            <input value={composeTo} onChange={(e) => setComposeTo(e.target.value)} placeholder="customer@example.com" />
          </div>
          <div style={{ marginBottom: 12 }}>
            <label className="fl">Subject</label>
            <input value={composeSubject} onChange={(e) => setComposeSubject(e.target.value)} />
          </div>
          <div style={{ marginBottom: 12 }}>
            <label className="fl">Message{composeFor !== "followup" ? " (PDF will be attached automatically)" : ""}</label>
            <textarea rows={6} value={composeBody} onChange={(e) => setComposeBody(e.target.value)} />
          </div>

          <div style={{ marginBottom: 12 }}>
            <div style={{ fontSize: 11, letterSpacing: 0.4, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 6, fontWeight: 600 }}>
              Signature (added automatically — not editable here)
            </div>
            <div style={{ border: "1px dashed var(--line)", borderRadius: 8, padding: "12px 14px", background: "var(--panel-2)" }}>
              <img src={logo} alt={COMPANY_NAME} style={{ height: 40, width: "auto", display: "block", marginBottom: 8 }} />
              <div style={{ fontSize: 13, fontWeight: 700 }}>{myProfile?.name || "Loading…"}</div>
              {myProfile?.designation && <div style={{ fontSize: 12.5 }}>{myProfile.designation}</div>}
              <div style={{ fontSize: 12.5 }}>{COMPANY_NAME}</div>
              {myProfile?.email && <div style={{ fontSize: 12.5 }}>Email: {myProfile.email}</div>}
              {myProfile?.phone && <div style={{ fontSize: 12.5 }}>Phone: {myProfile.phone}</div>}
            </div>
          </div>

          {composeError && <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 12 }}>{composeError}</div>}
          <div style={{ display: "flex", gap: 8 }}>
            <button className="btn-primary" onClick={handleSendEmail} disabled={sendingEmail}>
              {sendingEmail ? "Sending…" : "Send Email"}
            </button>
            <button className="btn-ghost" onClick={closeCompose}>Cancel</button>
          </div>
        </div>
      )}

      <h2 style={{ fontSize: 15, marginTop: 30, marginBottom: 12 }}>Emails</h2>
      <div className="card" style={{ padding: 20, marginBottom: 20 }}>
        <div style={{ marginBottom: emails.length ? 16 : 0 }}>
          <button className="btn-ghost" onClick={openComposeFollowup} style={{ padding: "6px 12px", fontSize: 12 }}>
            Compose email
          </button>
        </div>
        {!emails.length ? (
          <div style={{ fontSize: 12.5, color: "var(--text-faint)" }}>No emails sent or received on this case yet.</div>
        ) : (
          emails.map((em) => (
            <div key={em.id} style={{ padding: "10px 0", borderTop: "1px solid var(--line-soft)" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{
                    fontSize: 10.5, fontWeight: 600, padding: "2px 8px", borderRadius: 20, color: "#fff",
                    background: em.direction === "outbound" ? "#1bb8b0" : "#5d7188",
                  }}>
                    {em.direction === "outbound" ? "Sent" : "Received"}
                  </span>
                  {em.ai_email_type && EMAIL_TYPE_META[em.ai_email_type] && (
                    <span style={{
                      fontSize: 10.5, fontWeight: 600, padding: "2px 8px", borderRadius: 20, color: "#fff",
                      background: EMAIL_TYPE_META[em.ai_email_type].color,
                    }}>
                      {EMAIL_TYPE_META[em.ai_email_type].label}
                    </span>
                  )}
                </div>
                <span style={{ fontSize: 11, color: "var(--text-faint)", marginLeft: "auto" }}>
                  {new Date(em.created_at).toLocaleString("en-IN", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" })}
                </span>
              </div>
              <div style={{ fontSize: 13, fontWeight: 500, marginTop: 6 }}>{em.subject}</div>
              <div style={{ fontSize: 11.5, color: "var(--text-faint)", marginTop: 2 }}>
                {em.direction === "outbound" ? `To: ${em.to_email}` : `From: ${em.from_email}`}
                {em.created_by_name && ` · ${em.created_by_name}`}
              </div>
              <div style={{ fontSize: 12.5, color: "var(--text-dim)", marginTop: 6, whiteSpace: "pre-wrap" }}>{em.body}</div>

              {em.ai_summary && (
                <div style={{ fontSize: 12, color: "var(--text-dim)", marginTop: 6, fontStyle: "italic" }}>
                  AI summary: {em.ai_summary}
                </div>
              )}

              {em.direction === "inbound" && !em.ai_analyzed_at && (
                <button
                  className="btn-ghost"
                  onClick={() => handleAnalyzeCaseEmail(em.id)}
                  disabled={analyzingEmailId === em.id}
                  style={{ padding: "4px 10px", fontSize: 11, marginTop: 8 }}
                >
                  {analyzingEmailId === em.id ? "Analyzing…" : "Analyze with AI"}
                </button>
              )}

              {em.ai_email_type === "order" && caseData.stage !== "won" && caseData.stage !== "lost" && (
                <div style={{
                  marginTop: 8, padding: "8px 10px", background: "var(--green-ink)",
                  border: "1px solid var(--teal-border)", borderRadius: 8,
                  display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10, flexWrap: "wrap",
                }}>
                  <span style={{ fontSize: 12, color: "var(--green)" }}>
                    This looks like an order-related email — confirm the outcome:
                  </span>
                  <div style={{ display: "flex", gap: 6 }}>
                    <button
                      className="btn-primary"
                      onClick={() => toggleOutcome("won", true)}
                      style={{ padding: "4px 12px", fontSize: 11.5, whiteSpace: "nowrap" }}
                    >
                      Mark case as Won
                    </button>
                    <button
                      className="btn-ghost"
                      onClick={() => toggleOutcome("lost", true)}
                      style={{ padding: "4px 12px", fontSize: 11.5, whiteSpace: "nowrap", color: "var(--red)" }}
                    >
                      Mark case as Lost
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))
        )}
      </div>

      <h2 style={{ fontSize: 15, marginTop: 30, marginBottom: 12 }}>Follow-ups</h2>
      <div className="card" style={{ padding: 20, marginBottom: 20 }}>
        <form onSubmit={handleAddFollowup} style={{ display: "flex", gap: 10, alignItems: "flex-end", marginBottom: 18, flexWrap: "wrap" }}>
          <div>
            <label className="fl">Date</label>
            <input type="date" value={followupDate} onChange={(e) => setFollowupDate(e.target.value)} style={{ width: 150 }} />
          </div>
          <div style={{ flex: 1, minWidth: 220 }}>
            <label className="fl">Update</label>
            <input
              value={followupText}
              onChange={(e) => setFollowupText(e.target.value)}
              placeholder="e.g. Called customer, awaiting budget approval"
            />
          </div>
          <button type="submit" className="btn-primary" disabled={addingFollowup} style={{ padding: "8px 16px", whiteSpace: "nowrap" }}>
            {addingFollowup ? "Adding…" : "Add follow-up"}
          </button>
        </form>
        {followupError && <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 14 }}>{followupError}</div>}

        {!followups.length ? (
          <div style={{ fontSize: 12.5, color: "var(--text-faint)" }}>No follow-ups logged yet.</div>
        ) : (
          <div>
            {followups.map((f) => (
              <div
                key={f.id}
                style={{
                  display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 12,
                  padding: "10px 0", borderTop: "1px solid var(--line-soft)",
                }}
              >
                <div>
                  <div style={{ fontSize: 11.5, color: "var(--text-faint)", marginBottom: 3 }}>
                    {shortDate(f.followup_date)}{f.created_by_name ? ` · ${f.created_by_name}` : ""}
                  </div>
                  <div style={{ fontSize: 13 }}>{f.update_text}</div>
                </div>
                <button className="btn-ghost" onClick={() => handleDeleteFollowup(f.id)} style={{ padding: "4px 9px", fontSize: 11, whiteSpace: "nowrap" }}>
                  Remove
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
