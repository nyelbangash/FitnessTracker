import React from "react";

export const Chip = ({ children, onClick, tone = "default", className = "" }) => {
  let style = {
    background: "var(--surface-2)",
    color: "var(--text)",
    border: "1px solid var(--border)",
  };
  if (tone === "muted") {
    style = { ...style, color: "var(--text-muted)" };
  }
  if (tone === "accent") {
    style = {
      background: "var(--accent)",
      color: "var(--accent-text)",
      border: "1px solid var(--accent)",
    };
  }

  const Tag = onClick ? "button" : "span";
  return (
    <Tag
      onClick={onClick}
      className={`inline-flex items-center gap-1.5 rounded px-2 py-1 text-xs transition-colors ${onClick ? "hover:opacity-80" : ""} ${className}`}
      style={style}
    >
      {children}
    </Tag>
  );
};
