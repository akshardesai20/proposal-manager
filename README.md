# ProposalFlow — Sales Demo Instance

This is a **demo/sales deployment** of the proposal-management portal — a
separate, standalone copy from the production instance it was forked from.
It's meant to be shown to prospective customers, not used for real business
data. Everything in it is fake, seeded demo data.

## What this is

A multi-user web app covering the full sales-proposal lifecycle: customer
enquiry intake (including automatic capture from email), costing (with an
optional manufacturer catalog decode engine), offer/quote PDF generation,
case tracking through a defined pipeline, follow-up logging, and a
dashboard with per-user and team-wide reporting.

## Stack

- **Backend:** Node.js + Express, PostgreSQL
- **Frontend:** React (Vite), plain CSS
- **Hosting:** Render (backend + Postgres) + GitHub Pages (frontend) — both
  on free tiers; see `render.yaml` and `.github/workflows/deploy-pages.yml`

## Setting this up as a new deployment

1. **Render**: create a new Blueprint from `render.yaml` in this repo. This
   provisions the API service and a Postgres database together.
2. **Environment variables** (Render → your service → Environment):
   | Variable | Purpose |
   |---|---|
   | `COMPANY_NAME` | Shown on the offer PDF letterhead and cover letter |
   | `COMPANY_ADDRESS_LINES` | Pipe-separated, e.g. `Line 1\|Line 2\|City - PIN` |
   | `COMPANY_PHONE`, `COMPANY_EMAIL` | Letterhead contact details |
   | `COMPANY_MANUFACTURER` | The instrument brand this company represents (drives cover-letter wording) |
   | `COMPANY_ESTABLISHED_YEAR` | Used in the cover letter |
   | `COMPANY_PRODUCT_RANGE` | Pipe-separated list of product categories |
   | `DEMO_SEED_SECRET` | Any random string — protects the demo-seed endpoint below |
3. **GitHub Pages**: enable Pages on this repo (Settings → Pages → Source:
   GitHub Actions). Set `VITE_API_BASE`, `VITE_COMPANY_NAME`, and
   `VITE_PRODUCT_NAME` as repository variables/secrets used by
   `.github/workflows/deploy-pages.yml`.
4. **Logo**: replace `frontend/src/assets/logo.png` and
   `backend/src/pdf/assets/logo.jpeg` with real logo files when available —
   placeholders are checked in for now.
5. **Seed demo data**: once deployed, visit (once):
   ```
   https://<your-render-service>.onrender.com/api/internal/seed-demo-data?secret=<DEMO_SEED_SECRET>
   ```
   This creates 3 demo users, 3 fake customers, and 10 cases spanning every
   pipeline stage. It's safe to call more than once — it detects existing
   demo data and no-ops. Login credentials are returned in the response and
   also printed if run via `node scripts/seedDemoData.js` locally.

## Local development

```bash
cd backend && npm install && npm run migrate && npm run dev
cd frontend && npm install && npm run dev
```

## Important: this is a demo instance

- No real customer data should ever go into this deployment.
- Treat it as disposable — it can be reset (drop + recreate the Postgres
  database, re-run migrations, re-run the seed endpoint) at any time.
- Change the demo login passwords before sharing a link with anyone
  outside the company, or ask them to keep the demo strictly for review
  and not to treat any data in it as real.
