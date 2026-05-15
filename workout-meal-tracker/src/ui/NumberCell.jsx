import React, { useState, useEffect, useRef } from "react";

// Big tap-to-edit number cell, used heavily on the Active Workout screen.
// Renders as a static number until clicked; then becomes an inline input.
export const NumberCell = ({
  label,
  value,
  onChange,
  step = 1,
  min = 0,
  max,
  width = "w-28",
  suffix,
}) => {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(value);
  const inputRef = useRef(null);

  useEffect(() => {
    if (editing && inputRef.current) {
      inputRef.current.focus();
      inputRef.current.select();
    }
  }, [editing]);

  useEffect(() => {
    setDraft(value);
  }, [value]);

  const commit = () => {
    const next = parseFloat(draft);
    if (!Number.isNaN(next)) onChange(next);
    setEditing(false);
  };

  const cancel = () => {
    setDraft(value);
    setEditing(false);
  };

  return (
    <div
      className={`${width} text-center select-none gb-card`}
      style={{ padding: "10px 12px" }}
    >
      <div className="text-[10px] uppercase tracking-widest text-muted mb-1">
        {label}
      </div>
      {editing ? (
        <input
          ref={inputRef}
          type="number"
          step={step}
          min={min}
          max={max}
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onBlur={commit}
          onKeyDown={(e) => {
            if (e.key === "Enter") commit();
            if (e.key === "Escape") cancel();
            if (e.key === "ArrowUp") {
              e.preventDefault();
              setDraft((d) => (parseFloat(d) || 0) + step);
            }
            if (e.key === "ArrowDown") {
              e.preventDefault();
              setDraft((d) => Math.max(min, (parseFloat(d) || 0) - step));
            }
          }}
          className="num text-3xl font-medium text-center w-full bg-transparent outline-none"
          style={{ color: "var(--text)" }}
        />
      ) : (
        <button
          onClick={() => setEditing(true)}
          className="num text-3xl font-medium w-full"
          style={{ color: "var(--text)" }}
          title="Tap to edit"
        >
          {value}
          {suffix && (
            <span className="text-sm text-muted ml-0.5">{suffix}</span>
          )}
        </button>
      )}
    </div>
  );
};
