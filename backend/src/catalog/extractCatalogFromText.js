// Turns raw extracted text from a manufacturer's datasheet PDF into the
// same structured shape used throughout the catalog migrations: a family,
// its order-code positions and options, suffixes, and standalone addons.
//
// This is meaningfully higher-stakes than the email-analysis AI calls
// elsewhere in this app — a wrong position/option here could mean quoting
// the wrong physical instrument variant. Two things follow from that:
//   1. Uses a separate, more capable model by default (OPENAI_CATALOG_MODEL,
//      defaulting to "gpt-4o" rather than the "gpt-4o-mini" used for cheap
//      email triage) — worth the extra cost for something this infrequent
//      and this consequential.
//   2. The result is NEVER written to the database directly by this
//      module or its caller — see routes/catalogImport.js, which always
//      returns this as a preview for a human to review and correct before
//      anything is committed. Treat every extraction as a first draft.
const MAX_INPUT_CHARS = 60000; // ~15k tokens — generous for a single-family datasheet; if you're hitting this, the PDF is probably a multi-family master catalog and should be split first for better accuracy anyway.

const SYSTEM_PROMPT = `You extract structured product catalog data from instrumentation manufacturer datasheets, for a Siemens process-instrumentation channel partner's internal catalog system.

Respond with ONLY a single JSON object, no other text, no markdown fences. Shape exactly:
{
  "families": [
    {
      "base_code": "the manufacturer's base order code, e.g. '7ML530'. If this manufacturer's ordering scheme doesn't use a separate numeric/alpha prefix distinct from the model name (some brands just use the model name itself, e.g. 'PGS300'), use the model name as base_code — REQUIRED either way, must be unique per family",
      "family": "the family/model name as the manufacturer names it, e.g. 'SITRANS LR100'",
      "short_name": "a short descriptive name, e.g. 'Compact Radar Level Transmitter'",
      "description": "1-3 sentences describing what this instrument is and does, drawn from the datasheet",
      "trade_name": "the short trade name used in casual reference, e.g. 'LR100'",
      "instrument_type": "a general category, e.g. 'Radar Level Transmitter', 'Pressure Transmitter', 'Electromagnetic Flow Sensor'",
      "positions": [
        {
          "position_no": 1,
          "name": "what this position in the order code represents, e.g. 'Process connection'",
          "is_fix": false,
          "is_range": false,
          "options": [
            { "character": "the order-code character(s) for this option, e.g. 'A'", "meaning": "full description of what this option means", "short_label": "a short label if the datasheet gives one, else null" }
          ]
        }
      ],
      "suffixes": [
        { "code": "the suffix order code, e.g. 'Y15'", "meaning": "what this suffix adds/means" }
      ]
    }
  ],
  "addons": [
    { "code": "accessory/addon order code", "name": "short name", "description": "what it is / which family it's for" }
  ],
  "notes": "anything you're uncertain about, couldn't fully extract, or that needs a human to verify — e.g. a table that seemed to be cut off, a position whose full option list wasn't clear, or dependencies between options that this flat structure can't represent. Be specific so the reviewer knows exactly what to double-check. null if nothing to flag."
}

Rules:
- is_fix means this position always has the same fixed value (rare) — is_range means this position represents a numeric range/measurement rather than discrete lettered options (also rare) — default both to false unless the datasheet clearly indicates otherwise.
- If a table is genuinely ambiguous or incomplete in the source text, still include what you're confident about, and describe the gap in "notes" rather than guessing at missing rows.
- Multiple distinct families in one document should each get their own entry in "families". If a document presents several closely related model names sharing one ordering table (e.g. a gauge and an absolute version of the same base instrument), treat each as its own family entry, since they'll typically end up as separate catalog items even though the datasheet describes them together.
- "positions" are the fixed character slots that make up the base order code itself (the datasheet usually shows these as "X XX X X..." with a table of what each slot means). "suffixes" are separate codes appended AFTER the base code as optional extras — often introduced with wording like "add one or more codes after the basic ordering information." Do not force a large block of optional extras into "positions" just because it's large — if the source text describes it as something added on afterward, it belongs in "suffixes" even if there are many of them.
- Datasheets often include numbered footnotes describing which codes are incompatible with which other codes (e.g. "not available with Output code V, W"). This flat schema can't represent those dependencies structurally — do not try to encode them into meaning/description text for every affected option. Instead, note in "notes" that such dependency footnotes exist and should be checked manually before quoting, without attempting to enumerate all of them.
- Do not invent order codes, options, or suffixes that aren't actually present in the source text.`;

function getConfig() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) return { error: "OPENAI_API_KEY not configured" };
  const model = process.env.OPENAI_CATALOG_MODEL || process.env.OPENAI_MODEL || "gpt-4o";
  return { apiKey, model };
}

function safeParseJson(text) {
  const cleaned = (text || "").replace(/```json|```/g, "").trim();
  return JSON.parse(cleaned);
}

// Returns { families, addons, notes } on success, or { error } on
// failure. Never throws.
export async function extractCatalogFromText(rawText) {
  const { apiKey, model, error: configError } = getConfig();
  if (configError) return { error: configError };

  const text = (rawText || "").slice(0, MAX_INPUT_CHARS);
  if (!text.trim()) return { error: "No extractable text found in the document." };

  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${apiKey}` },
      body: JSON.stringify({
        model,
        max_tokens: 16000, // gpt-4o's output ceiling is 16384 — dense datasheets (large "additional ordering" suffix sections especially) can genuinely need this much; the previous 8000 cap risked silent truncation on documents like a 130+-entry ABB pressure transmitter sheet.
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: text },
        ],
      }),
    });

    if (!res.ok) {
      const errBody = await res.text().catch(() => "");
      return { error: `OpenAI API returned ${res.status}: ${errBody.slice(0, 300)}` };
    }

    const data = await res.json();
    const content = data.choices?.[0]?.message?.content || "";
    const parsed = safeParseJson(content);

    return {
      families: Array.isArray(parsed.families) ? parsed.families : [],
      addons: Array.isArray(parsed.addons) ? parsed.addons : [],
      notes: parsed.notes || null,
      error: null,
    };
  } catch (err) {
    return { error: err.message || "Unknown error calling OpenAI API" };
  }
}
