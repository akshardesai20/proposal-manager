import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api.js";

const STATUS_META = {
  ok: { label: "OK", color: "#3fb950" },
  warning: { label: "Warning", color: "#f2a900" },
  error: { label: "Error", color: "#ff6b6b" },
};

export default function Import() {
  const navigate = useNavigate();
  const [downloadingTemplate, setDownloadingTemplate] = useState(false);
  const [file, setFile] = useState(null);
  const [preview, setPreview] = useState(null);
  const [previewing, setPreviewing] = useState(false);
  const [previewError, setPreviewError] = useState("");
  const [committing, setCommitting] = useState(false);
  const [commitError, setCommitError] = useState("");
  const [commitResult, setCommitResult] = useState(null);

  async function handleDownloadTemplate() {
    setDownloadingTemplate(true);
    try {
      await api.downloadImportTemplate();
    } catch (err) {
      alert(err.message || "Failed to download template");
    } finally {
      setDownloadingTemplate(false);
    }
  }

  async function handlePreview() {
    if (!file) return;
    setPreviewing(true);
    setPreviewError("");
    setPreview(null);
    setCommitResult(null);
    try {
      const result = await api.previewImport(file);
      setPreview(result);
    } catch (err) {
      setPreviewError(err.message || "Failed to preview the file");
    } finally {
      setPreviewing(false);
    }
  }

  async function handleCommit() {
    if (!preview) return;
    if (!window.confirm(
      `Import ${preview.summary.ok + preview.summary.warning} case(s)? ` +
      `${preview.summary.error} row(s) with errors will be skipped. This creates real records and can't be bulk-undone.`
    )) return;
    setCommitting(true);
    setCommitError("");
    try {
      const result = await api.commitImport(preview.rows, preview.filename);
      setCommitResult(result);
      setPreview(null);
      setFile(null);
    } catch (err) {
      setCommitError(err.message || "Import failed");
    } finally {
      setCommitting(false);
    }
  }

  const importableCount = preview ? preview.summary.ok + preview.summary.warning : 0;

  return (
    <div style={{ width: "100%", padding: "36px 24px 60px", maxWidth: 1100, margin: "0 auto" }}>
      <div style={{ fontSize: 11, letterSpacing: 0.6, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 4 }}>
        Admin
      </div>
      <h1 style={{ fontSize: 24, marginBottom: 8 }}>Import Existing Cases</h1>
      <p style={{ color: "var(--text-dim)", fontSize: 13, marginBottom: 24, maxWidth: 680 }}>
        Bring ongoing cases from a spreadsheet into the portal — useful for migrating cases that already existed
        before this system was set up. Nothing is saved until you review the preview and confirm.
      </p>

      <div className="card" style={{ padding: 20, marginBottom: 20 }}>
        <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 10 }}>Step 1 — Get the template</div>
        <p style={{ fontSize: 12.5, color: "var(--text-dim)", marginBottom: 12 }}>
          Download the template, fill in one row per case, then upload it below. Column headers must match the
          template exactly, but column order doesn't matter.
        </p>
        <button className="btn-ghost" onClick={handleDownloadTemplate} disabled={downloadingTemplate}>
          {downloadingTemplate ? "Downloading…" : "Download Template"}
        </button>
      </div>

      <div className="card" style={{ padding: 20, marginBottom: 20 }}>
        <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 10 }}>Step 2 — Upload and review</div>
        <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
          <input
            type="file"
            accept=".xlsx"
            onChange={(e) => { setFile(e.target.files?.[0] || null); setPreview(null); setCommitResult(null); }}
            style={{ maxWidth: 320 }}
          />
          <button className="btn-primary" onClick={handlePreview} disabled={!file || previewing}>
            {previewing ? "Checking…" : "Preview"}
          </button>
        </div>
        {previewError && <div style={{ color: "var(--red)", fontSize: 12.5, marginTop: 12 }}>{previewError}</div>}
      </div>

      {preview && (
        <div className="card" style={{ padding: 20, marginBottom: 20 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14, flexWrap: "wrap", gap: 10 }}>
            <div style={{ fontSize: 13, fontWeight: 600 }}>
              Preview — {preview.summary.total} row(s):{" "}
              <span style={{ color: STATUS_META.ok.color }}>{preview.summary.ok} OK</span>,{" "}
              <span style={{ color: STATUS_META.warning.color }}>{preview.summary.warning} warning</span>,{" "}
              <span style={{ color: STATUS_META.error.color }}>{preview.summary.error} error</span>
            </div>
            <button className="btn-primary" onClick={handleCommit} disabled={!importableCount || committing}>
              {committing ? "Importing…" : `Confirm Import (${importableCount})`}
            </button>
          </div>
          {commitError && <div style={{ color: "var(--red)", fontSize: 12.5, marginBottom: 12 }}>{commitError}</div>}

          <div style={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12.5 }}>
              <thead>
                <tr style={{ borderBottom: "1px solid var(--line)" }}>
                  <th style={{ textAlign: "left", padding: "8px 10px", fontSize: 10.5, color: "var(--text-faint)", textTransform: "uppercase" }}>Row</th>
                  <th style={{ textAlign: "left", padding: "8px 10px", fontSize: 10.5, color: "var(--text-faint)", textTransform: "uppercase" }}>Status</th>
                  <th style={{ textAlign: "left", padding: "8px 10px", fontSize: 10.5, color: "var(--text-faint)", textTransform: "uppercase" }}>Customer</th>
                  <th style={{ textAlign: "left", padding: "8px 10px", fontSize: 10.5, color: "var(--text-faint)", textTransform: "uppercase" }}>Segment</th>
                  <th style={{ textAlign: "left", padding: "8px 10px", fontSize: 10.5, color: "var(--text-faint)", textTransform: "uppercase" }}>Stage</th>
                  <th style={{ textAlign: "left", padding: "8px 10px", fontSize: 10.5, color: "var(--text-faint)", textTransform: "uppercase" }}>Messages</th>
                </tr>
              </thead>
              <tbody>
                {preview.rows.map((row) => (
                  <tr key={row.rowNumber} style={{ borderBottom: "1px solid var(--line-soft)" }}>
                    <td style={{ padding: "8px 10px" }}>{row.rowNumber}</td>
                    <td style={{ padding: "8px 10px" }}>
                      <span style={{
                        fontSize: 10.5, fontWeight: 600, padding: "2px 8px", borderRadius: 20, color: "#fff",
                        background: STATUS_META[row.status].color,
                      }}>
                        {STATUS_META[row.status].label}
                      </span>
                    </td>
                    <td style={{ padding: "8px 10px" }}>
                      {row.customer.name}
                      {row.customer.willCreate && <span style={{ color: "var(--text-faint)" }}> (new)</span>}
                    </td>
                    <td style={{ padding: "8px 10px" }}>{row.case.segment || "—"}</td>
                    <td style={{ padding: "8px 10px" }}>{row.case.stage || "—"}</td>
                    <td style={{ padding: "8px 10px" }}>
                      {row.messages.map((m, i) => (
                        <div key={i} style={{ color: m.level === "error" ? "var(--red)" : "var(--text-faint)" }}>
                          {m.text}
                        </div>
                      ))}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {commitResult && (
        <div className="card" style={{ padding: 20, borderLeft: "3px solid var(--green)" }}>
          <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 6, color: "var(--green)" }}>
            Imported {commitResult.createdCount} case(s) successfully.
          </div>
          <button className="btn-ghost" onClick={() => navigate("/tracker")} style={{ marginTop: 6 }}>
            View in Tracker
          </button>
        </div>
      )}
    </div>
  );
}
