import { useEffect, useState } from "react";
import { api } from "../api.js";
import UserForm, { ROLE_OPTIONS } from "../components/UserForm.jsx";

const roleLabel = (v) => ROLE_OPTIONS.find((r) => r.value === v)?.label || v;

export default function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showNewForm, setShowNewForm] = useState(false);
  const [editing, setEditing] = useState(null);
  const [error, setError] = useState("");

  async function refresh() {
    setLoading(true);
    setError("");
    try {
      setUsers(await api.listUsers());
    } catch (err) {
      setError(err.message || "Failed to load users");
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => { refresh(); }, []);

  async function handleCreate(payload) {
    const res = await api.createUser(payload);
    refresh();
    return res; // may include generatedPassword, shown by UserForm
  }

  async function handleUpdate(payload) {
    await api.updateUser(editing.id, payload);
    setEditing(null);
    refresh();
  }

  async function handleRemove(u) {
    setError("");
    if (!window.confirm(`Remove ${u.name}? This can't be undone.`)) return;
    try {
      await api.deleteUser(u.id);
      refresh();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div style={{ maxWidth: 1040, margin: "0 auto", padding: "36px 24px 60px", width: "100%" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: 22 }}>
        <div>
          <div style={{ fontSize: 11, letterSpacing: 0.6, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 4 }}>
            Admin
          </div>
          <h1 style={{ fontSize: 24 }}>Users</h1>
        </div>
        <button className="btn-primary" onClick={() => { setShowNewForm((s) => !s); setEditing(null); }}>
          {showNewForm ? "Cancel" : "+ New user"}
        </button>
      </div>

      {showNewForm && (
        <div style={{ marginBottom: 22 }}>
          <UserForm submitLabel="Create user" onSubmit={handleCreate} onCancel={() => setShowNewForm(false)} />
        </div>
      )}

      {editing && (
        <div style={{ marginBottom: 22 }}>
          <UserForm
            initial={editing}
            isEdit
            submitLabel="Save changes"
            onSubmit={handleUpdate}
            onCancel={() => setEditing(null)}
          />
        </div>
      )}

      {error && (
        <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 14 }}>
          {error}
          {!users.length && !loading && (
            <button className="btn-ghost" onClick={refresh} style={{ marginLeft: 10, padding: "3px 9px", fontSize: 11.5 }}>
              Retry
            </button>
          )}
        </div>
      )}

      <div className="card" style={{ overflow: "hidden" }}>
        {loading ? (
          <div className="empty-state">Loading…</div>
        ) : error && !users.length ? (
          <div className="empty-state">Couldn't load users — see message above.</div>
        ) : !users.length ? (
          <div className="empty-state">No users yet.</div>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ borderBottom: "1px solid var(--line)" }}>
                {["Name", "Email", "Role", "WhatsApp", "Notifications", "Status", ""].map((h) => (
                  <th key={h} style={{
                    textAlign: "left", padding: "12px 16px", fontSize: 11,
                    letterSpacing: 0.5, textTransform: "uppercase", color: "var(--text-faint)", fontWeight: 600,
                  }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id} style={{ borderBottom: "1px solid var(--line-soft)" }}>
                  <td style={{ padding: "12px 16px", fontWeight: 500, fontSize: 13 }}>{u.name}</td>
                  <td style={{ padding: "12px 16px", fontSize: 13 }}>{u.email}</td>
                  <td style={{ padding: "12px 16px", fontSize: 13 }}>{roleLabel(u.role)}</td>
                  <td style={{ padding: "12px 16px", fontSize: 13 }}>{u.whatsapp || "—"}</td>
                  <td style={{ padding: "12px 16px", fontSize: 13 }}>{u.notifications_enabled ? "On" : "Off"}</td>
                  <td style={{ padding: "12px 16px" }}>
                    <span className="stage-pill">
                      <span className="stage-dot" style={{ background: u.status === "active" ? "var(--green)" : "var(--text-faint)" }} />
                      {u.status === "active" ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td style={{ padding: "12px 16px", whiteSpace: "nowrap" }}>
                    <button
                      className="btn-ghost"
                      onClick={() => { setEditing(u); setShowNewForm(false); }}
                      style={{ padding: "5px 10px", fontSize: 11.5, marginRight: 6 }}
                    >
                      Edit
                    </button>
                    <button
                      className="btn-ghost"
                      onClick={() => handleRemove(u)}
                      style={{ padding: "5px 10px", fontSize: 11.5, color: "var(--red)" }}
                    >
                      Remove
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
