import React from "react";

export const Input = ({ label, hint, error, className = "", ...props }) => (
  <label className={`block ${className}`}>
    {label && (
      <span className="block text-xs uppercase tracking-wide text-muted mb-1">
        {label}
      </span>
    )}
    <input
      {...props}
      className="w-full rounded px-3 py-2 outline-none transition-colors focus:border-[var(--accent)]"
      style={{
        background: "var(--surface)",
        color: "var(--text)",
        border: "1px solid var(--border)",
      }}
    />
    {hint && !error && (
      <span className="block text-xs text-muted mt-1">{hint}</span>
    )}
    {error && (
      <span className="block text-xs text-bad mt-1">{error}</span>
    )}
  </label>
);

export const Textarea = ({ label, className = "", rows = 3, ...props }) => (
  <label className={`block ${className}`}>
    {label && (
      <span className="block text-xs uppercase tracking-wide text-muted mb-1">
        {label}
      </span>
    )}
    <textarea
      rows={rows}
      {...props}
      className="w-full rounded px-3 py-2 outline-none transition-colors focus:border-[var(--accent)] resize-y"
      style={{
        background: "var(--surface)",
        color: "var(--text)",
        border: "1px solid var(--border)",
      }}
    />
  </label>
);
