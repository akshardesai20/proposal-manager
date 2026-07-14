// Extracts plain text from an uploaded catalog PDF, page by page.
// Uses pdfjs-dist's text layer only — no page-to-image rendering, so no
// canvas/native dependency is ever pulled in (the only path that would
// need one is rendering, which this deliberately never does).
import { getDocument } from "pdfjs-dist/legacy/build/pdf.mjs";

// Returns the full extracted text, with a page-break marker between pages
// (helps the AI reason about where a table might have been split awkwardly
// across a page boundary, since that's a common cause of extraction gaps).
export async function extractPdfText(buffer) {
  const data = new Uint8Array(buffer);
  const pdf = await getDocument({ data, useSystemFonts: true }).promise;

  const pages = [];
  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i);
    const content = await page.getTextContent();
    pages.push(content.items.map((item) => item.str).join(" "));
  }

  return {
    text: pages.join("\n\n--- page break ---\n\n"),
    pageCount: pdf.numPages,
  };
}
