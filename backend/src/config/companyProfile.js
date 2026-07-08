// Every field here used to be hardcoded as a specific company's name /
// their specific address, phone, and cover-letter wording directly inside
// offerPdf.js. Pulling it out here does two things at once: makes the
// per-deployment demo/rebrand possible, and is a real first step toward
// this being a genuinely multi-tenant product later (this module is what
// would eventually be replaced by a per-organization row in the database).
//
// Every field has a fallback so nothing breaks if an env var is missing —
// but for a real deployment (demo or otherwise), set these via Render's
// Environment tab rather than relying on the defaults below.
export const companyProfile = {
  name: process.env.COMPANY_NAME || "Your Company Name",
  addressLines: (process.env.COMPANY_ADDRESS_LINES || "Address Line 1|Address Line 2|City - PIN").split("|"),
  phone: process.env.COMPANY_PHONE || "+91 00000 00000",
  email: process.env.COMPANY_EMAIL || "sales@example.com",

  // The manufacturer this company represents — drives the cover-letter
  // wording ("we are representative of M/s <manufacturer>..."). Genuinely
  // configurable so this isn't Siemens-only if a future customer sells a
  // different instrumentation brand.
  manufacturer: process.env.COMPANY_MANUFACTURER || "Siemens",
  establishedYear: process.env.COMPANY_ESTABLISHED_YEAR || "2000",
  productRangeLines: (process.env.COMPANY_PRODUCT_RANGE ||
    "Differential Pressure Transmitters|Pressure Transmitters|Level Transmitters|Temperature Transmitters (Field/Panel Mounted)|Flow Sensors - Electromagnetic/Ultrasonic"
  ).split("|"),
};
