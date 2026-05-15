import React from "react";

// Tabular stat tile. Number-forward.
export const Stat = ({ label, value, unit, hint, align = "left" }) => (
  <div className={`flex flex-col ${align === "center" ? "items-center" : "items-start"}`}>
    <span className="text-[10px] uppercase tracking-widest text-muted">
      {label}
    </span>
    <span className="num text-2xl leading-tight">
      {value}
      {unit && (
        <span className="text-sm text-muted ml-1 font-sans">{unit}</span>
      )}
    </span>
    {hint && <span className="text-xs text-muted mt-0.5">{hint}</span>}
  </div>
);
