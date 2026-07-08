import { useState } from "react";
import { Routes, Route, Navigate, useNavigate } from "react-router-dom";
import Login from "./pages/Login.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import Cases from "./pages/Cases.jsx";
import Inquiries from "./pages/Inquiries.jsx";
import CaseDetail from "./pages/CaseDetail.jsx";
import Customers from "./pages/Customers.jsx";
import Users from "./pages/Users.jsx";
import TopBar from "./components/TopBar.jsx";
import Sidebar from "./components/Sidebar.jsx";

function storedUser() {
  try { return JSON.parse(sessionStorage.getItem("user")); } catch { return null; }
}

export default function App() {
  const [user, setUser] = useState(storedUser());
  const authed = !!sessionStorage.getItem("token");
  const isAdmin = user?.role === "admin";
  const navigate = useNavigate();

  function logout() {
    sessionStorage.removeItem("token");
    sessionStorage.removeItem("user");
    setUser(null);
    navigate("/login");
  }

  if (!authed) {
    return (
      <Routes>
        <Route path="/login" element={<Login onLogin={setUser} />} />
        <Route path="*" element={<Navigate to="/login" />} />
      </Routes>
    );
  }

  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar user={user} />
      <div style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0 }}>
        <TopBar user={user} onLogout={logout} title={import.meta.env.VITE_PRODUCT_NAME || "ProposalFlow"} />
        <Routes>
          <Route path="/login" element={<Navigate to="/dashboard" />} />
          <Route path="/dashboard" element={<Dashboard user={user} />} />
          <Route path="/inquiries" element={<Inquiries />} />
          <Route path="/cases" element={<Cases user={user} />} />
          <Route path="/cases/:id" element={<CaseDetail user={user} />} />
          <Route path="/customers" element={<Customers />} />
          <Route path="/users" element={isAdmin ? <Users /> : <Navigate to="/dashboard" />} />
          <Route path="*" element={<Navigate to="/dashboard" />} />
        </Routes>
      </div>
    </div>
  );
}
