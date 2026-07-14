import { useEffect, useState } from "react";
import { api } from "../api.js";
import CustomerForm from "../components/CustomerForm.jsx";

export default function Customers() {
  const [customers, setCustomers] = useState([]);
  const [q, setQ] = useState("");
  const [loading, setLoading] = useState(true);
  const [showNewForm, setShowNewForm] = useState(false);
  const [editing, setEditing] = useState(null); // customer object being edited, or null
  const [loadError, setLoadError] = useState("");

  async function refresh(query) {
    setLoading(true);
    setLoadError("");
    try {
      setCustomers(await api.searchCustomers(query ?? q));
    } catch (err) {
      setLoadError(err.message || "Failed to load customers");
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => { refresh(""); }, []);

  useEffect(() => {
    const t = setTimeout(() => refresh(q), 250);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q]);

  async function handleCreate(form) {
    await api.createCustomer(form);
    setShowNewForm(false);
    refresh();
  }

  async function handleUpdate(form) {
    await api.updateCustomer(editing.id, form);
    setEditing(null);
    refresh();
  }

  return (
    <div style={{ maxWidth: 980, margin: "0 auto", padding: "36px 24px 60px", width: "100%" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: 22 }}>
        <div>
          <div style={{ fontSize: 11, letterSpacing: 0.6, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 4 }}>
            Master data
          </div>
          <h1 style={{ fontSize: 24 }}>Customers</h1>
        </div>
        <button className="btn-primary" onClick={() => { setShowNewForm((s) => !s); setEditing(null); }}>
          {showNewForm ? "Cancel" : "+ New customer"}
        </button>
      </div>

      {showNewForm && (
        <div style={{ marginBottom: 22 }}>
          <CustomerForm submitLabel="Save customer" onSubmit={handleCreate} onCancel={() => setShowNewForm(false)} />
        </div>
      )}

      {editing && (
        <div style={{ marginBottom: 22 }}>
          <CustomerForm
            initial={editing}
            submitLabel="Save changes"
            onSubmit={handleUpdate}
            onCancel={() => setEditing(null)}
          />
        </div>
      )}

      <div style={{ marginBottom: 16 }}>
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search by name, code, or GST number…"
        />
      </div>

      <div className="card" style={{ overflowX: "auto", overflowY: "hidden" }}>
        {loading ? (
          <div className="empty-state">Loading…</div>
        ) : loadError ? (
          <div className="empty-state" style={{ color: "var(--red)" }}>
            Couldn't load customers: {loadError}
            <div style={{ marginTop: 10 }}>
              <button className="btn-ghost" onClick={() => refresh(q)}>Retry</button>
            </div>
          </div>
        ) : !customers.length ? (
          <div className="empty-state">
            {q ? "No matching customer." : <>No customers yet. Start with <b style={{ color: "var(--text-dim)" }}>+ New customer</b> above.</>}
          </div>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ borderBottom: "1px solid var(--line)" }}>
                {["Name", "Code", "Contact person", "Phone", "Email", "GST number", ""].map((h) => (
                  <th key={h} style={{
                    textAlign: "left", padding: "12px 16px", fontSize: 11,
                    letterSpacing: 0.5, textTransform: "uppercase", color: "var(--text-faint)", fontWeight: 600,
                  }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {customers.map((c) => (
                <tr key={c.id} style={{ borderBottom: "1px solid var(--line-soft)" }}>
                  <td style={{ padding: "12px 16px", fontWeight: 500, fontSize: 13 }}>{c.name}</td>
                  <td style={{ padding: "12px 16px", fontSize: 12.5 }} className="mono">{c.code || "—"}</td>
                  <td style={{ padding: "12px 16px", fontSize: 13 }}>{c.contact_person || "—"}</td>
                  <td style={{ padding: "12px 16px", fontSize: 13 }}>{c.phone || "—"}</td>
                  <td style={{ padding: "12px 16px", fontSize: 13 }}>{c.email || "—"}</td>
                  <td style={{ padding: "12px 16px", fontSize: 12.5 }} className="mono">{c.gst_number || "—"}</td>
                  <td style={{ padding: "12px 16px" }}>
                    <button
                      className="btn-ghost"
                      onClick={() => { setEditing(c); setShowNewForm(false); }}
                      style={{ padding: "5px 10px", fontSize: 11.5 }}
                    >
                      Edit
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
