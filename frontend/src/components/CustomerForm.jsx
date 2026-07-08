import { useState } from "react";

const BLANK = { name: "", code: "", contact_person: "", email: "", phone: "", address: "", gst_number: "" };

export default function CustomerForm({ initial, onSubmit, onCancel, submitLabel, note }) {
  const [form, setForm] = useState({ ...BLANK, ...(initial || {}) });
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  async function submit(e) {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      await onSubmit(form);
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={submit} className="card" style={{ padding: 16 }}>
      {note && <div style={{ fontSize: 12.5, color: "var(--text-faint)", marginBottom: 12 }}>{note}</div>}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 12 }}>
        <div>
          <label className="fl">Customer name *</label>
          <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required autoFocus />
        </div>
        <div>
          <label className="fl">Customer code</label>
          <input value={form.code || ""} onChange={(e) => setForm({ ...form, code: e.target.value })} placeholder="e.g. SAHAJANAND" />
        </div>
        <div>
          <label className="fl">Contact person</label>
          <input value={form.contact_person || ""} onChange={(e) => setForm({ ...form, contact_person: e.target.value })} />
        </div>
        <div>
          <label className="fl">Phone</label>
          <input value={form.phone || ""} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
        </div>
        <div>
          <label className="fl">Email</label>
          <input type="email" value={form.email || ""} onChange={(e) => setForm({ ...form, email: e.target.value })} />
        </div>
        <div>
          <label className="fl">GST number</label>
          <input value={form.gst_number || ""} onChange={(e) => setForm({ ...form, gst_number: e.target.value })} />
        </div>
      </div>
      <div style={{ marginBottom: 14 }}>
        <label className="fl">Address</label>
        <textarea rows={2} value={form.address || ""} onChange={(e) => setForm({ ...form, address: e.target.value })} />
      </div>
      {error && <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 12 }}>{error}</div>}
      <div style={{ display: "flex", gap: 8 }}>
        <button type="submit" className="btn-primary" disabled={saving}>{saving ? "Saving…" : submitLabel || "Save"}</button>
        {onCancel && <button type="button" className="btn-ghost" onClick={onCancel}>Cancel</button>}
      </div>
    </form>
  );
}
