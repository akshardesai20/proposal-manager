import { useState } from "react";

export const ROLE_OPTIONS = [
  { value: "admin", label: "Admin" },
  { value: "sales", label: "Sales" },
  { value: "proposal", label: "Proposal" },
  { value: "service", label: "Service" },
  { value: "store", label: "Store" },
  { value: "account", label: "Account" },
];

const BLANK = { name: "", email: "", role: "sales", whatsapp: "", notifications_enabled: true, status: "active", password: "" };

export default function UserForm({ initial, onSubmit, onCancel, submitLabel, isEdit }) {
  const [form, setForm] = useState({ ...BLANK, ...(initial || {}), password: "" });
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [result, setResult] = useState(null); // holds generatedPassword after creating

  async function submit(e) {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      const payload = { ...form };
      if (!payload.password) delete payload.password; // don't overwrite existing password with blank
      const res = await onSubmit(payload);
      if (res && res.generatedPassword) {
        setResult(res);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }

  if (result) {
    return (
      <div className="card" style={{ padding: 16 }}>
        <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 8 }}>User created: {result.email}</div>
        <div style={{ fontSize: 12.5, color: "var(--text-dim)", marginBottom: 6 }}>
          Temporary password (shown once — copy it now and share it with them):
        </div>
        <div className="mono" style={{ fontSize: 14, padding: "8px 10px", background: "var(--panel-2)", borderRadius: 6, marginBottom: 14 }}>
          {result.generatedPassword}
        </div>
        <button className="btn-primary" onClick={onCancel}>Done</button>
      </div>
    );
  }

  return (
    <form onSubmit={submit} className="card" style={{ padding: 16 }}>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 12 }}>
        <div>
          <label className="fl">Name *</label>
          <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required autoFocus />
        </div>
        <div>
          <label className="fl">Email *</label>
          <input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} required />
        </div>
        <div>
          <label className="fl">Role</label>
          <select value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })}>
            {ROLE_OPTIONS.map((r) => <option key={r.value} value={r.value}>{r.label}</option>)}
          </select>
        </div>
        <div>
          <label className="fl">Status</label>
          <select value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })}>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
        <div>
          <label className="fl">WhatsApp</label>
          <input value={form.whatsapp || ""} onChange={(e) => setForm({ ...form, whatsapp: e.target.value })} placeholder="e.g. 9909979823" />
        </div>
        <div>
          <label className="fl">{isEdit ? "Reset password (optional)" : "Password (optional — auto-generated if blank)"}</label>
          <input type="text" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} className="mono" placeholder={isEdit ? "Leave blank to keep current" : "Leave blank to auto-generate"} />
        </div>
      </div>
      <label style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, marginBottom: 14, cursor: "pointer" }}>
        <input
          type="checkbox"
          checked={!!form.notifications_enabled}
          onChange={(e) => setForm({ ...form, notifications_enabled: e.target.checked })}
          style={{ width: "auto" }}
        />
        Email notifications enabled
      </label>
      {error && <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 12 }}>{error}</div>}
      <div style={{ display: "flex", gap: 8 }}>
        <button type="submit" className="btn-primary" disabled={saving}>{saving ? "Saving…" : submitLabel || "Save"}</button>
        {onCancel && <button type="button" className="btn-ghost" onClick={onCancel}>Cancel</button>}
      </div>
    </form>
  );
}
