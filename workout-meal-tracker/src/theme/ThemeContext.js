import React, { createContext, useContext, useEffect, useState, useCallback } from "react";
import { themes, defaultThemeId, getTheme } from "./themes";
import * as api from "../api";

const ThemeContext = createContext(null);

function applyTheme(themeId) {
  const t = getTheme(themeId);
  const root = document.documentElement;
  root.style.setProperty("--bg", t.bg);
  root.style.setProperty("--surface", t.surface);
  root.style.setProperty("--surface-2", t.surface2);
  root.style.setProperty("--text", t.text);
  root.style.setProperty("--text-muted", t.textMuted);
  root.style.setProperty("--border", t.border);
  root.style.setProperty("--accent", t.accent);
  root.style.setProperty("--accent-text", t.accentText);
  root.style.setProperty("--good", t.good);
  root.style.setProperty("--warn", t.warn);
  root.style.setProperty("--bad", t.bad);
  root.style.setProperty("--neutral", t.neutral);
  root.setAttribute("data-theme", themeId);
}

export const ThemeProvider = ({ children }) => {
  const [themeId, setThemeIdState] = useState(() => {
    return localStorage.getItem("theme") || defaultThemeId;
  });

  useEffect(() => {
    applyTheme(themeId);
    localStorage.setItem("theme", themeId);
  }, [themeId]);

  const setThemeId = useCallback(async (id) => {
    if (!themes[id]) return;
    setThemeIdState(id);
    // Persist server-side. Fail silently — local storage is the source of truth
    // in offline / pre-login states.
    try {
      const token = localStorage.getItem("token");
      if (token) await api.updateProfile(null, { theme: id });
    } catch (_) {}
  }, []);

  return (
    <ThemeContext.Provider value={{ themeId, setThemeId, theme: getTheme(themeId) }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error("useTheme must be used inside ThemeProvider");
  return ctx;
};
