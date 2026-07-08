// Calls the OpenAI API to turn a raw inbound email into structured,
// actionable fields for the Inbox review queue: a crisp summary, a guess
// at the industry/segment, an extracted customer name, and a
// classification of what kind of email this is (new inquiry, follow-up,
// negotiation, or order).
//
// This is enrichment, not a dependency — every caller must treat a
// failure here as non-fatal. Email capture itself (the poll cycle) must
// keep working even if this fails entirely or OPENAI_API_KEY isn't set.
//
// Model name: OpenAI's naming/lineup moves fast, so this is configurable
// via OPENAI_MODEL rather than hardcoded. Defaults to "gpt-4o-mini" — a
// long-established, reliably-available identifier. If you get a "model
// not found" style error back in ai_error, check your OpenAI dashboard
// for the current recommended low-cost model (as of mid-2026, OpenAI's
// own docs pointed to their "gpt-5.4-nano" tier for this kind of
// classification/summarization task — worth trying if available on your
// account) and set OPENAI_MODEL to match.
const SEGMENT_VALUES = ["ww", "industries", "instrument_service"];
const EMAIL_TYPE_VALUES = ["new_inquiry", "follow_up", "negotiation", "order", "other"];

const SYSTEM_PROMPT = `You analyze inbound business emails for a Siemens process-instrumentation channel partner's sales team. Given an email's sender, subject, and body, extract structured information to help a salesperson triage it quickly.

Respond with ONLY a single JSON object, no other text, no markdown code fences. Shape exactly:
{
  "summary": "one or two crisp sentences stating the actual requirement or purpose of this email, in plain business language",
  "industry_type": "a short descriptive guess at the sender's industry, e.g. 'Pharmaceutical manufacturing', 'Water & wastewater treatment', 'Textile processing' — or null if genuinely unclear",
  "suggested_segment": "one of: ww, industries, instrument_service — your best guess at which business segment this belongs to (ww = water/wastewater treatment, industries = general industrial/manufacturing, instrument_service = calibration/service/AMC work rather than new equipment) — or null if unclear",
  "suggested_customer_name": "the sender's company name as best you can extract it from the email signature or body — or null if not stated",
  "suggested_customer_phone": "a phone or mobile number from the email signature/body, digits and + only (e.g. '+91 98765 43210') — or null if none is stated",
  "email_type": "one of: new_inquiry, follow_up, negotiation, order, other — new_inquiry = a fresh requirement being raised for the first time; follow_up = checking status on something already discussed; negotiation = discussing price/terms/quantities on an existing offer; order = confirming/placing an order or PO; other = anything else (spam, unrelated correspondence, etc.)"
}

If the email is clearly not a genuine business inquiry (spam, newsletter, unrelated), set email_type to "other" and summary to a brief note saying so.`;

function buildUserMessage({ fromName, fromEmail, subject, bodyText }) {
  return [
    `From: ${fromName || "(no name)"} <${fromEmail || "unknown"}>`,
    `Subject: ${subject || "(no subject)"}`,
    "",
    (bodyText || "").slice(0, 6000), // guard against extremely long emails blowing up token usage
  ].join("\n");
}

function safeParseJson(text) {
  // response_format:json_object should already guarantee clean JSON, but
  // strip markdown fences defensively in case a model/config doesn't
  // honor that.
  const cleaned = (text || "").replace(/```json|```/g, "").trim();
  return JSON.parse(cleaned);
}

// Returns a plain object of the ai_* fields to write to inbound_inquiries,
// or { error } if analysis couldn't run at all (e.g. no API key
// configured, or the API call failed). Never throws — callers should
// still proceed with the rest of their work regardless of what this
// returns.
export async function analyzeInquiry({ fromName, fromEmail, subject, bodyText }) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) return { error: "OPENAI_API_KEY not configured" };

  const model = process.env.OPENAI_MODEL || "gpt-4o-mini";

  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        max_tokens: 400,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: buildUserMessage({ fromName, fromEmail, subject, bodyText }) },
        ],
      }),
    });

    if (!res.ok) {
      const errBody = await res.text().catch(() => "");
      return { error: `OpenAI API returned ${res.status}: ${errBody.slice(0, 300)}` };
    }

    const data = await res.json();
    const text = data.choices?.[0]?.message?.content || "";
    const parsed = safeParseJson(text);

    const segment = SEGMENT_VALUES.includes(parsed.suggested_segment) ? parsed.suggested_segment : null;
    const emailType = EMAIL_TYPE_VALUES.includes(parsed.email_type) ? parsed.email_type : null;

    return {
      summary: parsed.summary || null,
      industry_type: parsed.industry_type || null,
      suggested_segment: segment,
      suggested_customer_name: parsed.suggested_customer_name || null,
      suggested_customer_phone: parsed.suggested_customer_phone || null,
      email_type: emailType,
      analyzed_at: new Date(),
      error: null,
    };
  } catch (err) {
    return { error: err.message || "Unknown error calling OpenAI API" };
  }
}
