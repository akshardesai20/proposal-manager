import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// GitHub Pages serves project sites from /<repo-name>/, not /, so the build
// needs that as its base path. Local dev keeps base at "/". The GH Actions
// workflow sets GITHUB_PAGES=true when building for deployment.
const isGhPages = process.env.GITHUB_PAGES === "true";

export default defineConfig({
  plugins: [react()],
  base: isGhPages ? "/proposal-manager/" : "/",
  server: {
    proxy: { "/api": "http://localhost:4000" },
  },
});
