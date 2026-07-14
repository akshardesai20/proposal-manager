import { useEffect, useState } from "react";
import { api } from "../api.js";

export default function CatalogImport() {
  const [manufacturers, setManufacturers] = useState([]);
  const [manufacturerId, setManufacturerId] = useState("");
  const [newMfgName, setNewMfgName] = useState("");
  const [addingMfg, setAddingMfg] = useState(false);

  const [file, setFile] = useState(null);
  const [extracting, setExtracting] = useState(false);
  const [extractError, setExtractError] = useState("");
  const [extracted, setExtracted] = useState(null); // { families, addons, notes }
  const [jsonMode, setJsonMode] = useState(false);
  const [jsonText, setJsonText] = useState("");
  const [jsonError, setJsonError] = useState("");

  const [committing, setCommitting] = useState(false);
  const [commitError, setCommitError] = useState("");
  const [commitResult, setCommitResult] = useState(null);

  useEffect(() => {
    api.listManufacturers().then((rows) => {
      setManufacturers(rows);
      if (rows.length) setManufacturerId(String(rows[0].id));
    });
  }, []);

  async function handleAddManufacturer() {
    if (!newMfgName.trim()) return;
    setAddingMfg(true);
    try {
      const created = await api.addManufacturer(newMfgName.trim());
      setManufacturers((prev) => [...prev, created].sort((a, b) => a.name.localeCompare(b.name)));
      setManufacturerId(String(created.id));
      setNewMfgName("");
    } catch (err) {
      alert(err.message || "Failed to add manufacturer");
    } finally {
      setAddingMfg(false);
    }
  }

  async function handleExtract() {
    if (!file) return;
    setExtracting(true);
    setExtractError("");
    setExtracted(null);
    setCommitResult(null);
    try {
      const result = await api.extractCatalog(file);
      setExtracted(result);
      setJsonText(JSON.stringify({ families: result.families, addons: result.addons }, null, 2));
    } catch (err) {
      setExtractError(err.message || "Extraction failed");
    } finally {
      setExtracting(false);
    }
  }

  function applyJsonEdits() {
    try {
      const parsed = JSON.parse(jsonText);
      setExtracted((prev) => ({ ...prev, families: parsed.families || [], addons: parsed.addons || [] }));
      setJsonError("");
      setJsonMode(false);
    } catch (err) {
      setJsonError("That's not valid JSON: " + err.message);
    }
  }

  async function handleCommit() {
    if (!extracted || !manufacturerId) return;
    const familyNames = extracted.families.map((f) => f.family).join(", ");
    if (!window.confirm(
      `Save ${extracted.families.length} famil${extracted.families.length === 1 ? "y" : "ies"} (${familyNames}) to the catalog? ` +
      `This writes directly to your live catalog.`
    )) return;
    setCommitting(true);
    setCommitError("");
    try {
      const result = await api.commitCatalog(Number(manufacturerId), extracted.families, extracted.addons);
      setCommitResult(result);
      setExtracted(null);
      setFile(null);
    } catch (err) {
      setCommitError(err.message || "Failed to save");
    } finally {
      setCommitting(false);
    }
  }

  return (
    <div style={{ width: "100%", padding: "36px 24px 60px", maxWidth: 900, margin: "0 auto" }}>
      <div style={{ fontSize: 11, letterSpacing: 0.6, textTransform: "uppercase", color: "var(--text-faint)", marginBottom: 4 }}>
        Admin
      </div>
      <h1 style={{ fontSize: 24, marginBottom: 8 }}>Catalog Import</h1>
      <p style={{ color: "var(--text-dim)", fontSize: 13, marginBottom: 24, maxWidth: 640 }}>
        Upload a manufacturer's datasheet PDF (ideally one product family per document) and AI will extract the
        order-code structure. <b>Nothing is saved until you review it below</b> — always check the position/option
        tables carefully before saving, especially anything flagged in the notes.
      </p>

      <div className="card" style={{ padding: 20, marginBottom: 20 }}>
        <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 12 }}>Manufacturer</div>
        <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
          <select value={manufacturerId} onChange={(e) => setManufacturerId(e.target.value)} style={{ width: "auto", minWidth: 180 }}>
            {manufacturers.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
          </select>
          <span style={{ color: "var(--text-faint)", fontSize: 12.5 }}>or</span>
          <input
            value={newMfgName}
            onChange={(e) => setNewMfgName(e.target.value)}
            placeholder="New manufacturer name"
            style={{ width: 200 }}
          />
          <button className="btn-ghost" onClick={handleAddManufacturer} disabled={addingMfg || !newMfgName.trim()}>
            {addingMfg ? "Adding…" : "+ Add"}
          </button>
        </div>
      </div>

      <div className="card" style={{ padding: 20, marginBottom: 20 }}>
        <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 12 }}>Upload datasheet</div>
        <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
          <input type="file" accept=".pdf" onChange={(e) => { setFile(e.target.files?.[0] || null); setExtracted(null); }} />
          <button className="btn-primary" onClick={handleExtract} disabled={!file || extracting}>
            {extracting ? "Extracting… (can take a minute)" : "Extract with AI"}
          </button>
        </div>
        {extractError && <div style={{ color: "var(--red)", fontSize: 12.5, marginTop: 12 }}>{extractError}</div>}
      </div>

      {extracted && (
        <div className="card" style={{ padding: 20, marginBottom: 20 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
            <div style={{ fontSize: 13, fontWeight: 600 }}>
              Review before saving — {extracted.families.length} famil{extracted.families.length === 1 ? "y" : "ies"}, {extracted.addons.length} addon(s)
            </div>
            <button className="btn-ghost" onClick={() => setJsonMode((v) => !v)} style={{ fontSize: 11.5, padding: "4px 10px" }}>
              {jsonMode ? "Show structured view" : "Edit as JSON"}
            </button>
          </div>

          {extracted.notes && (
            <div style={{
              fontSize: 12.5, color: "#92400e", background: "#fffbeb", border: "1px solid #fde68a",
              borderRadius: 8, padding: "10px 12px", marginBottom: 16,
            }}>
              <b>AI flagged for review:</b> {extracted.notes}
            </div>
          )}

          {jsonMode ? (
            <div>
              <textarea
                value={jsonText}
                onChange={(e) => setJsonText(e.target.value)}
                rows={20}
                style={{ width: "100%", fontFamily: "monospace", fontSize: 12, boxSizing: "border-box" }}
              />
              {jsonError && <div style={{ color: "var(--red)", fontSize: 12.5, marginTop: 8 }}>{jsonError}</div>}
              <button className="btn-primary" onClick={applyJsonEdits} style={{ marginTop: 10 }}>Apply Changes</button>
            </div>
          ) : (
            extracted.families.map((fam, fi) => (
              <div key={fi} style={{ borderTop: fi > 0 ? "1px solid var(--line-soft)" : "none", paddingTop: fi > 0 ? 16 : 0, marginTop: fi > 0 ? 16 : 0 }}>
                <div style={{ display: "flex", alignItems: "baseline", gap: 8, marginBottom: 4 }}>
                  <span className="ref-stamp">{fam.base_code}</span>
                  <span style={{ fontSize: 14, fontWeight: 700 }}>{fam.family}</span>
                  <span style={{ fontSize: 12, color: "var(--text-faint)" }}>{fam.instrument_type}</span>
                </div>
                <div style={{ fontSize: 12.5, color: "var(--text-dim)", marginBottom: 10 }}>{fam.description}</div>

                {(fam.positions || []).map((pos) => (
                  <div key={pos.position_no} style={{ marginBottom: 8 }}>
                    <div style={{ fontSize: 12, fontWeight: 600, color: "var(--text-dim)" }}>
                      Position {pos.position_no}: {pos.name}
                    </div>
                    <div style={{ fontSize: 12, color: "var(--text-faint)", paddingLeft: 12 }}>
                      {(pos.options || []).map((opt) => (
                        <div key={opt.character}>{opt.character} — {opt.meaning}</div>
                      ))}
                    </div>
                  </div>
                ))}

                {!!(fam.suffixes || []).length && (
                  <div style={{ fontSize: 12, color: "var(--text-faint)", marginTop: 6 }}>
                    Suffixes: {fam.suffixes.map((s) => `${s.code} (${s.meaning})`).join(", ")}
                  </div>
                )}
              </div>
            ))
          )}

          {commitError && <div style={{ color: "var(--red)", fontSize: 12.5, marginTop: 14 }}>{commitError}</div>}
          <button className="btn-primary" onClick={handleCommit} disabled={committing || !manufacturerId} style={{ marginTop: 16 }}>
            {committing ? "Saving…" : "Save to Catalog"}
          </button>
        </div>
      )}

      {commitResult && (
        <div className="card" style={{ padding: 20, borderLeft: "3px solid var(--green)" }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: "var(--green)" }}>
            Saved — {commitResult.familiesCreated} new famil{commitResult.familiesCreated === 1 ? "y" : "ies"} added
            {commitResult.familiesSkipped > 0 && `, ${commitResult.familiesSkipped} already existed (skipped)`}.
          </div>
        </div>
      )}
    </div>
  );
}
