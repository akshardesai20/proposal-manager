import { NavLink, useLocation } from "react-router-dom";
import logo from "../assets/logo.png";
import { SEGMENTS } from "../constants.js";

const COMPANY_NAME = import.meta.env.VITE_COMPANY_NAME || "Your Company Name";

const NAV_ITEMS = [
  { to: "/dashboard", label: "Dashboard", icon: "\uD83D\uDCCA" },
  { to: "/inquiries", label: "Inbox", icon: "\uD83D\uDCE5" },
  { to: "/outbox", label: "Outbox", icon: "\uD83D\uDCE4" },
  {
    to: "/cases",
    label: "Proposals",
    icon: "\uD83D\uDCC1",
    children: [
      ...SEGMENTS.map((s) => ({ to: `/cases?segment=${s.value}`, segment: s.value, label: s.label })),
      { to: "/cases?segment=unassigned", segment: "unassigned", label: "Unassigned" },
    ],
  },
  { to: "/customers", label: "Customers", icon: "\uD83D\uDC65" },
  { to: "/tracker", label: "Tracker", icon: "\uD83D\uDCC8" },
];

const ADMIN_NAV_ITEMS = [
  { to: "/users", label: "Users", icon: "\uD83D\uDD10" },
  { to: "/import", label: "Import Cases", icon: "\uD83D\uDCE5" },
  // Deliberately not shown on customer-facing deployments — this feature
  // costs real OpenAI API usage per use and needs someone who knows the
  // catalog domain reviewing the output, so it's opt-in per instance
  // rather than something every customer's admin account can reach.
  ...(import.meta.env.VITE_CATALOG_IMPORT_ENABLED === "true"
    ? [{ to: "/catalog-import", label: "Catalog Import", icon: "\uD83D\uDCD8" }]
    : []),
];

export default function Sidebar({ user }) {
  const items = user?.role === "admin" ? [...NAV_ITEMS, ...ADMIN_NAV_ITEMS] : NAV_ITEMS;
  const location = useLocation();
  const currentSegment = new URLSearchParams(location.search).get("segment");

  return (
    <aside style={{
      width: 220, flexShrink: 0, background: "var(--sidebar)",
      borderRight: "1px solid var(--line)", display: "flex", flexDirection: "column",
      minHeight: "100vh",
    }}>
      <div style={{ padding: "22px 20px 18px", borderBottom: "1px solid var(--line-soft)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <img src={logo} alt={COMPANY_NAME} style={{ height: 30, width: "auto" }} />
          <div style={{ fontFamily: "var(--display)", fontWeight: 700, fontSize: 14, lineHeight: 1.15 }}>
            {COMPANY_NAME}
          </div>
        </div>
      </div>

      <nav style={{ padding: "16px 12px", flex: 1 }}>
        <div style={{ fontSize: 10.5, letterSpacing: 0.6, textTransform: "uppercase", color: "var(--text-faint)", padding: "0 8px 8px", fontWeight: 600 }}>
          Main
        </div>
        {items.map((item) => (
          <div key={item.to} style={{ marginBottom: 2 }}>
            <NavLink
              to={item.to}
              end={!item.children}
              style={({ isActive }) => ({
                display: "flex", alignItems: "center", gap: 10,
                padding: "9px 10px", borderRadius: 7,
                fontSize: 13.5, fontWeight: 500, textDecoration: "none",
                color: isActive ? "var(--green)" : "var(--text-dim)",
                background: isActive ? "var(--green-ink)" : "transparent",
              })}
            >
              <span aria-hidden="true" style={{ fontSize: 14 }}>{item.icon}</span>
              {item.label}
            </NavLink>

            {item.children && (
              <div style={{ marginTop: 1, marginLeft: 20, borderLeft: "1px solid var(--line-soft)", paddingLeft: 10 }}>
                {item.children.map((child) => {
                  const active = location.pathname === "/cases" && currentSegment === child.segment;
                  return (
                    <NavLink
                      key={child.to}
                      to={child.to}
                      style={{
                        display: "block",
                        padding: "6px 8px",
                        borderRadius: 6,
                        fontSize: 12.5,
                        fontWeight: active ? 600 : 500,
                        textDecoration: "none",
                        color: active ? "var(--green)" : "var(--text-faint)",
                        background: active ? "var(--green-ink)" : "transparent",
                      }}
                    >
                      {child.label}
                    </NavLink>
                  );
                })}
              </div>
            )}
          </div>
        ))}
      </nav>
    </aside>
  );
}
