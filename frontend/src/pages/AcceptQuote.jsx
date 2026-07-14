import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { api } from "../api.js";
import logo from "../assets/logo.png";

const money = (n) => new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 }).format(n || 0);
const fullDate = (iso) => (iso ? new Date(iso).toLocaleDateString("en-IN", { day: "2-digit", month: "long", year: "numeric" }) : "");

export default function AcceptQuote() {
  const { token } = useParams();
  const [offer, setOffer] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [name, setName] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState(null);

  useEffect(() => {
    api.getPublicOffer(token)
      .then(setOffer)
      .catch((err) => setError(err.message || "This link isn't valid."))
      .finally(() => setLoading(false));
  }, [token]);

  async function handleAccept(e) {
    e.preventDefault();
    if (!name.trim()) return;
    setSubmitting(true);
    setError("");
    try {
      const res = await api.acceptPublicOffer(token, name.trim());
      setResult(res);
    } catch (err) {
      setError(err.message || "Something went wrong — please try again or contact us directly.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div style={{
      minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center",
      background: "#f4f5f7", padding: 20, fontFamily: "Inter, Arial, sans-serif",
    }}>
      <div style={{
        background: "#fff", borderRadius: 12, padding: "36px 32px", maxWidth: 440, width: "100%",
        boxShadow: "0 1px 3px rgba(20,24,30,0.08)", border: "1px solid #e5e7eb",
      }}>
        <img src={logo} alt="" style={{ height: 40, marginBottom: 20, display: "block" }} />

        {loading ? (
          <div style={{ color: "#6b7280", fontSize: 14 }}>Loading…</div>
        ) : error && !offer ? (
          <div>
            <div style={{ fontSize: 18, fontWeight: 700, marginBottom: 8 }}>Link not valid</div>
            <div style={{ color: "#6b7280", fontSize: 14 }}>{error}</div>
          </div>
        ) : result || offer?.alreadyAccepted ? (
          <div>
            <div style={{ fontSize: 32, marginBottom: 12 }}>✅</div>
            <div style={{ fontSize: 18, fontWeight: 700, marginBottom: 8 }}>Quote accepted</div>
            <div style={{ color: "#6b7280", fontSize: 14, lineHeight: 1.6 }}>
              Confirmed by <b>{(result || offer).acceptedByName}</b> on{" "}
              {fullDate((result || offer).acceptedAt)}. We'll be in touch shortly to proceed with your order.
            </div>
          </div>
        ) : (
          <div>
            <div style={{ fontSize: 11, letterSpacing: 0.6, textTransform: "uppercase", color: "#9ca3af", marginBottom: 6 }}>
              Quote {offer.ref}
            </div>
            <div style={{ fontSize: 19, fontWeight: 700, marginBottom: 4 }}>{offer.customerName}</div>
            <div style={{ color: "#6b7280", fontSize: 13, marginBottom: 20 }}>
              {offer.itemCount} item{offer.itemCount === 1 ? "" : "s"} · Prepared {fullDate(offer.generatedAt)}
            </div>

            <div style={{
              background: "#f9fafb", border: "1px solid #e5e7eb", borderRadius: 8,
              padding: "14px 16px", marginBottom: 22, display: "flex", justifyContent: "space-between", alignItems: "center",
            }}>
              <span style={{ fontSize: 13, color: "#6b7280" }}>Total Value</span>
              <span style={{ fontSize: 20, fontWeight: 700 }}>{money(offer.total)}</span>
            </div>

            <form onSubmit={handleAccept}>
              <label style={{ fontSize: 12, fontWeight: 600, color: "#374151", display: "block", marginBottom: 6 }}>
                Your name, to confirm acceptance
              </label>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Full name"
                required
                style={{
                  width: "100%", padding: "10px 12px", fontSize: 14, border: "1px solid #d1d5db",
                  borderRadius: 8, marginBottom: 14, boxSizing: "border-box",
                }}
              />
              {error && <div style={{ color: "#dc2626", fontSize: 13, marginBottom: 12 }}>{error}</div>}
              <button
                type="submit"
                disabled={submitting || !name.trim()}
                style={{
                  width: "100%", padding: "11px 0", fontSize: 14, fontWeight: 600, color: "#fff",
                  background: submitting || !name.trim() ? "#9ca3af" : "#0f6b5c", border: "none",
                  borderRadius: 8, cursor: submitting || !name.trim() ? "default" : "pointer",
                }}
              >
                {submitting ? "Confirming…" : "Accept this Quote"}
              </button>
            </form>
            <div style={{ fontSize: 11, color: "#9ca3af", marginTop: 14, textAlign: "center" }}>
              {offer.companyName}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
