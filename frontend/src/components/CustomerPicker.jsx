import { useEffect, useState } from "react";
import { api } from "../api.js";
import CustomerForm from "./CustomerForm.jsx";

export default function CustomerPicker({ value, onChange }) {
  const [q, setQ] = useState("");
  const [results, setResults] = useState([]);
  const [open, setOpen] = useState(false);
  const [showNewForm, setShowNewForm] = useState(false);

  useEffect(() => {
    if (!q.trim()) { setResults([]); setOpen(false); return; }
    const t = setTimeout(async () => {
      try {
        const r = await api.searchCustomers(q);
        setResults(r);
        setOpen(true);
      } catch { /* ignore, user can retry */ }
    }, 250);
    return () => clearTimeout(t);
  }, [q]);

  async function handleCreate(form) {
    const created = await api.createCustomer(form);
    onChange(created);
    setShowNewForm(false);
  }

  if (value) {
    return (
      <div className="card" style={{ padding: 12, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div>
          <div style={{ fontWeight: 600, fontSize: 13 }}>{value.name}</div>
          <div style={{ fontSize: 11.5, color: "var(--text-faint)" }}>
            {[value.code, value.contact_person, value.gst_number].filter(Boolean).join(" · ") || "No further details on file"}
          </div>
        </div>
        <button type="button" className="btn-ghost" style={{ padding: "5px 10px", fontSize: 11.5 }} onClick={() => onChange(null)}>
          Change
        </button>
      </div>
    );
  }

  if (showNewForm) {
    return (
      <CustomerForm
        note="Adding to the customer master list — this record will be available to pick for any future case."
        submitLabel="Save customer"
        onSubmit={handleCreate}
        onCancel={() => setShowNewForm(false)}
      />
    );
  }

  return (
    <div style={{ position: "relative" }}>
      <div style={{ display: "flex", gap: 8 }}>
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onFocus={() => results.length && setOpen(true)}
          placeholder="Search existing customer by name, code, or GST…"
        />
        <button type="button" className="btn-ghost" onClick={() => setShowNewForm(true)} style={{ whiteSpace: "nowrap" }}>
          + New customer
        </button>
      </div>
      {open && results.length > 0 && (
        <div className="card" style={{
          position: "absolute", zIndex: 10, top: "calc(100% + 4px)", left: 0, right: 0,
          maxHeight: 240, overflowY: "auto",
        }}>
          {results.map((c) => (
            <div
              key={c.id}
              onClick={() => { onChange(c); setOpen(false); setQ(""); }}
              style={{ padding: "9px 12px", cursor: "pointer", borderBottom: "1px solid var(--line-soft)" }}
              onMouseEnter={(e) => (e.currentTarget.style.background = "var(--panel-2)")}
              onMouseLeave={(e) => (e.currentTarget.style.background = "transparent")}
            >
              <div style={{ fontSize: 13, fontWeight: 500 }}>{c.name}</div>
              <div style={{ fontSize: 11, color: "var(--text-faint)" }}>
                {[c.code, c.contact_person, c.gst_number].filter(Boolean).join(" · ")}
              </div>
            </div>
          ))}
        </div>
      )}
      {open && q.trim() && results.length === 0 && (
        <div style={{ fontSize: 12, color: "var(--text-faint)", marginTop: 6 }}>
          No matching customer — use "+ New customer" to add one.
        </div>
      )}
    </div>
  );
}
