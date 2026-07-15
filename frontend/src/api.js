// Local dev: Vite's dev-server proxy forwards /api to localhost:4000 (see vite.config.js).
// Production: frontend and backend are separate Render services, so the frontend
// build needs to know the backend's real URL — set VITE_API_BASE at build time.
const BASE = (import.meta.env.VITE_API_BASE || "") + "/api";

function authHeaders() {
  const token = sessionStorage.getItem("token");
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function handle(res) {
  if (res.status === 401) {
    // Any expired/invalid token, anywhere in the app, forces a clean
    // sign-out and redirect — rather than every page quietly stalling
    // on "Loading…" and leaving the person guessing why.
    sessionStorage.removeItem("token");
    sessionStorage.removeItem("user");
    if (!location.hash.startsWith("#/login")) {
      location.hash = "#/login";
      location.reload();
    }
    throw new Error("Your session has expired — please log in again.");
  }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || "Request failed");
  return data;
}

export const api = {
  getMyProfile: () =>
    fetch(`${BASE}/auth/me`, { headers: authHeaders() }).then(handle),

  getMyDashboard: () =>
    fetch(`${BASE}/dashboard/me`, { headers: authHeaders() }).then(handle),

  // Admin-only — 403s for anyone else.
  getTeamDashboard: () =>
    fetch(`${BASE}/dashboard/team`, { headers: authHeaders() }).then(handle),

  login: (email, password) =>
    fetch(`${BASE}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    }).then(handle),

  listCases: () =>
    fetch(`${BASE}/cases`, { headers: authHeaders() }).then(handle),

  getCase: (id) =>
    fetch(`${BASE}/cases/${id}`, { headers: authHeaders() }).then(handle),

  createCase: (payload) =>
    fetch(`${BASE}/cases`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  updateStage: (id, stage, note) =>
    fetch(`${BASE}/cases/${id}/stage`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify({ stage, note }),
    }).then(handle),

  updateCaseNotes: (id, notes) =>
    fetch(`${BASE}/cases/${id}/notes`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify({ notes }),
    }).then(handle),

  searchFamilies: (q) =>
    fetch(`${BASE}/catalog/families?q=${encodeURIComponent(q || "")}`, { headers: authHeaders() }).then(handle),

  getFamily: (baseCode) =>
    fetch(`${BASE}/catalog/families/${encodeURIComponent(baseCode)}`, { headers: authHeaders() }).then(handle),

  decodeModel: (code) =>
    fetch(`${BASE}/catalog/decode`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify({ code }),
    }).then(handle),

  listCosting: (caseId) =>
    fetch(`${BASE}/cases/${caseId}/costing`, { headers: authHeaders() }).then(handle),

  addCosting: (caseId, payload) =>
    fetch(`${BASE}/cases/${caseId}/costing`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  updateCosting: (id, payload) =>
    fetch(`${BASE}/costing/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  deleteCosting: (id) =>
    fetch(`${BASE}/costing/${id}`, { method: "DELETE", headers: authHeaders() }).then((r) => {
      if (!r.ok) throw new Error("Failed to delete");
    }),

  searchCustomers: (q) =>
    fetch(`${BASE}/customers?q=${encodeURIComponent(q || "")}`, { headers: authHeaders() }).then(handle),

  getCustomer: (id) =>
    fetch(`${BASE}/customers/${id}`, { headers: authHeaders() }).then(handle),

  createCustomer: (payload) =>
    fetch(`${BASE}/customers`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  updateCustomer: (id, payload) =>
    fetch(`${BASE}/customers/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  generateOffer: (caseId) =>
    fetch(`${BASE}/cases/${caseId}/offer`, { method: "POST", headers: authHeaders() }).then(handle),

  listOffers: (caseId) =>
    fetch(`${BASE}/cases/${caseId}/offers`, { headers: authHeaders() }).then(handle),

  // Opens the PDF in a new tab. Uses fetch (not a plain <a href>) because
  // the endpoint needs the auth header, which a plain link can't send.
  // Triggers a real browser download (not just opening a tab) with the
  // filename set directly on a temporary <a download> element — the
  // Content-Disposition header the backend sends is NOT honored by browsers
  // for a client-side Blob URL like this, only for native navigations, so
  // the filename has to be set here instead.
  downloadOfferPdf: async (offerId, ref) => {
    const res = await fetch(`${BASE}/offers/${offerId}/pdf`, { headers: authHeaders() });
    if (!res.ok) throw new Error("Failed to generate PDF");
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const filename = `${(ref || `offer-${offerId}`).replace(/\//g, "-")}.pdf`;
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  },

  deleteOffer: (offerId) =>
    fetch(`${BASE}/offers/${offerId}`, { method: "DELETE", headers: authHeaders() }).then((r) => {
      if (!r.ok) throw new Error("Failed to delete offer");
    }),

  updateCaseReference: (id, reference) =>
    fetch(`${BASE}/cases/${id}/reference`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify({ reference }),
    }).then(handle),

  updateCaseDetails: (id, payload) =>
    fetch(`${BASE}/cases/${id}/details`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  // Admin-only: edit the customer link / requirement text set at creation.
  updateCase: (id, payload) =>
    fetch(`${BASE}/cases/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  // Admin-only: hard delete a case and everything under it.
  deleteCase: (id) =>
    fetch(`${BASE}/cases/${id}`, { method: "DELETE", headers: authHeaders() }).then((r) => {
      if (!r.ok) throw new Error("Failed to delete case");
    }),

  // Same Blob + temporary <a download> pattern as downloadOfferPdf, for
  // the same reason: Content-Disposition isn't honored for blob: URLs.
  // sheetName (usually the latest offer's ref) is also sent as ?sheet= so
  // the workbook's internal tab name matches the downloaded filename.
  downloadCostingExcel: async (caseId, sheetName) => {
    const name = sheetName || `costing-${caseId}`;
    const res = await fetch(`${BASE}/cases/${caseId}/costing/export?sheet=${encodeURIComponent(name)}`, {
      headers: authHeaders(),
    });
    if (!res.ok) throw new Error("Failed to export costing to Excel");
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${name.replace(/\//g, "-")}.xlsx`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  },

  listFollowups: (caseId) =>
    fetch(`${BASE}/cases/${caseId}/followups`, { headers: authHeaders() }).then(handle),

  downloadImportTemplate: async () => {
    const res = await fetch(`${BASE}/import/template`, { headers: authHeaders() });
    if (!res.ok) throw new Error("Failed to download the import template");
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "case-import-template.xlsx";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  },

  // multipart upload — deliberately not using the JSON `handle()` helper
  // since this sends FormData, not a JSON body.
  previewImport: async (file) => {
    const form = new FormData();
    form.append("file", file);
    const res = await fetch(`${BASE}/import/preview`, { method: "POST", headers: authHeaders(), body: form });
    return handle(res);
  },

  commitImport: (rows, filename) =>
    fetch(`${BASE}/import/commit`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify({ rows, filename }),
    }).then(handle),

  addFollowup: (caseId, payload) =>
    fetch(`${BASE}/cases/${caseId}/followups`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  deleteFollowup: (followupId) =>
    fetch(`${BASE}/cases/followups/${followupId}`, { method: "DELETE", headers: authHeaders() }).then((r) => {
      if (!r.ok) throw new Error("Failed to delete follow-up");
    }),

  listCaseEmails: (caseId) =>
    fetch(`${BASE}/cases/${caseId}/emails`, { headers: authHeaders() }).then(handle),

  // payload: { to, subject, body, offer_id? } — offer_id attaches that
  // offer's PDF fresh at send time.
  sendCaseEmail: (caseId, payload) =>
    fetch(`${BASE}/cases/${caseId}/emails/send`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  analyzeCaseEmail: (caseId, emailId) =>
    fetch(`${BASE}/cases/${caseId}/emails/${emailId}/analyze`, { method: "POST", headers: authHeaders() }).then(handle),

  getOutbox: () =>
    fetch(`${BASE}/outbox`, { headers: authHeaders() }).then(handle),

  // No auth needed — these are hit by a customer with no login, via a
  // link in the offer email.
  getPublicOffer: (token) =>
    fetch(`${BASE}/public/offers/${token}`).then(handle),

  acceptPublicOffer: (token, name) =>
    fetch(`${BASE}/public/offers/${token}/accept`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name }),
    }).then(handle),

  listManufacturers: () =>
    fetch(`${BASE}/catalog-import/manufacturers`, { headers: authHeaders() }).then(handle),

  addManufacturer: (name) =>
    fetch(`${BASE}/catalog-import/manufacturers`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify({ name }),
    }).then(handle),

  extractCatalog: async (file) => {
    const form = new FormData();
    form.append("file", file);
    const res = await fetch(`${BASE}/catalog-import/extract`, { method: "POST", headers: authHeaders(), body: form });
    return handle(res);
  },

  commitCatalog: (manufacturerId, families, addons) =>
    fetch(`${BASE}/catalog-import/commit`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify({ manufacturerId, families, addons }),
    }).then(handle),

  browseCatalog: () =>
    fetch(`${BASE}/catalog-import/browse`, { headers: authHeaders() }).then(handle),

  exportManufacturerCatalog: async (manufacturerId, manufacturerName) => {
    const res = await fetch(`${BASE}/catalog-import/export/${manufacturerId}`, { headers: authHeaders() });
    if (!res.ok) throw new Error("Failed to export catalog");
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `catalog_${(manufacturerName || "export").toLowerCase().replace(/[^a-z0-9]+/g, "_")}.sql`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  },

  listInquiries: (status = "pending") =>
    fetch(`${BASE}/inquiries?status=${encodeURIComponent(status)}`, { headers: authHeaders() }).then(handle),

  convertInquiry: (id, payload) =>
    fetch(`${BASE}/inquiries/${id}/convert`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  dismissInquiry: (id) =>
    fetch(`${BASE}/inquiries/${id}/dismiss`, { method: "POST", headers: authHeaders() }).then(handle),

  analyzeInquiry: (id) =>
    fetch(`${BASE}/inquiries/${id}/analyze`, { method: "POST", headers: authHeaders() }).then(handle),

  listUsers: () => fetch(`${BASE}/users`, { headers: authHeaders() }).then(handle),

  createUser: (payload) =>
    fetch(`${BASE}/users`, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  updateUser: (id, payload) =>
    fetch(`${BASE}/users/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", ...authHeaders() },
      body: JSON.stringify(payload),
    }).then(handle),

  deleteUser: (id) =>
    fetch(`${BASE}/users/${id}`, { method: "DELETE", headers: authHeaders() }).then(async (r) => {
      if (!r.ok) {
        const data = await r.json().catch(() => ({}));
        throw new Error(data.error || "Failed to remove user");
      }
    }),
};
