export default function TopBar({ user, onLogout, title }) {
  return (
    <header style={{
      display: "flex", alignItems: "center", gap: 12,
      padding: "0 28px", height: 56,
      borderBottom: "1px solid var(--line)",
      background: "var(--panel)",
    }}>
      <div style={{ fontSize: 13.5, fontWeight: 600, color: "var(--text-dim)" }}>
        {title}
      </div>
      {user && (
        <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 14 }}>
          <div style={{ textAlign: "right" }}>
            <div style={{ fontSize: 13, fontWeight: 600 }}>{user.name}</div>
            <div style={{ fontSize: 11, color: "var(--text-faint)", textTransform: "capitalize" }}>
              {(user.role || "").replace("_", " ")}
            </div>
          </div>
          <button className="btn-ghost" onClick={onLogout} style={{ padding: "7px 12px", fontSize: 12 }}>
            Sign out
          </button>
        </div>
      )}
    </header>
  );
}
