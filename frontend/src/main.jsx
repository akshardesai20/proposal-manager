import React from "react";
import ReactDOM from "react-dom/client";
import { HashRouter } from "react-router-dom";
import App from "./App.jsx";
import "./styles.css";

// HashRouter (not BrowserRouter) — GitHub Pages serves static files with no
// server-side rewrite support, so client-side routes need to live after a #
// to avoid 404s on refresh/direct links.
ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <HashRouter>
      <App />
    </HashRouter>
  </React.StrictMode>
);
