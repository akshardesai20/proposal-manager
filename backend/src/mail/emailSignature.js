// Builds the sender signature appended to every outbound case email —
// the logged-in user's name/designation/contact details plus the company
// name, with the logo embedded via CID (Content-ID) attachment rather
// than an external image URL. CID embedding means the logo renders
// immediately in the email client without needing to fetch anything
// externally or trigger "load images?" prompts — the standard, reliable
// way email signatures include a logo.
import fs from "fs";
import { LOGO_PATH } from "../pdf/offerPdf.js";
import { companyProfile } from "../config/companyProfile.js";

const LOGO_CID = "company-logo";

function logoAvailable() {
  try { return fs.existsSync(LOGO_PATH); } catch { return false; }
}

function escapeHtml(str) {
  return String(str).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

// sender: { name, designation, phone, email } — typically the logged-in
// user's own record. Falls back to company-level contact details for
// anything missing.
export function buildSignature(sender) {
  const name = sender?.name || companyProfile.name;
  const designation = sender?.designation || "";
  const email = sender?.email || companyProfile.email;
  const phone = sender?.phone || companyProfile.phone;
  const hasLogo = logoAvailable();

  const infoLines = [
    name,
    designation,
    companyProfile.name,
    email ? `Email: ${email}` : null,
    phone ? `Phone: ${phone}` : null,
  ].filter(Boolean).join("\n");
  const text = `\n\n${infoLines}`;

  const html = `
    <div style="margin-top:24px;padding-top:14px;border-top:1px solid #e2e2e2;font-family:Arial,sans-serif;font-size:13px;color:#333;">
      ${hasLogo ? `<img src="cid:${LOGO_CID}" alt="${escapeHtml(companyProfile.name)}" style="height:48px;margin-bottom:8px;display:block;" />` : ""}
      <div style="font-weight:bold;">${escapeHtml(name)}</div>
      ${designation ? `<div>${escapeHtml(designation)}</div>` : ""}
      <div>${escapeHtml(companyProfile.name)}</div>
      ${email ? `<div>Email: ${escapeHtml(email)}</div>` : ""}
      ${phone ? `<div>Phone: ${escapeHtml(phone)}</div>` : ""}
    </div>
  `;

  return {
    text,
    html,
    logoAttachment: hasLogo ? { filename: "logo.jpeg", path: LOGO_PATH, cid: LOGO_CID } : null,
  };
}

// Converts the user's plain-text composed message into basic HTML
// (escaping first, then turning newlines into <br>), so it can sit above
// the HTML signature in the same email body.
export function textToHtml(text) {
  return escapeHtml(text).replace(/\n/g, "<br>");
}
