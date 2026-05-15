import React, { useEffect, useRef, useState } from "react";
import { Search } from "lucide-react";

// Minimal command palette. Static list of actions for v1 — fuzzy search later.
const actions = [
  { label: "Log a meal", to: "/eat/log" },
  { label: "Start a workout", to: "/train" },
  { label: "View today's nutrition", to: "/eat" },
  { label: "View workout history", to: "/train/history" },
  { label: "View progress", to: "/progress" },
  { label: "Manage templates", to: "/train/templates" },
  { label: "Change theme", to: "/you#theme" },
  { label: "Edit nutrition goals", to: "/you#goals" },
];

export const CommandPalette = ({ open, onClose, navigate }) => {
  const [q, setQ] = useState("");
  const [cursor, setCursor] = useState(0);
  const inputRef = useRef(null);

  useEffect(() => {
    if (open) {
      setQ("");
      setCursor(0);
      setTimeout(() => inputRef.current?.focus(), 10);
    }
  }, [open]);

  if (!open) return null;

  const filtered = q.trim()
    ? actions.filter((a) => a.label.toLowerCase().includes(q.toLowerCase()))
    : actions;

  const choose = (i) => {
    const a = filtered[i];
    if (!a) return;
    navigate(a.to);
    onClose();
  };

  const onKey = (e) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setCursor((c) => Math.min(filtered.length - 1, c + 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setCursor((c) => Math.max(0, c - 1));
    } else if (e.key === "Enter") {
      e.preventDefault();
      choose(cursor);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center pt-32 px-4"
      onClick={onClose}
      style={{ background: "rgba(0,0,0,0.25)" }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-lg rounded-lg overflow-hidden animate-slide-up"
        style={{
          background: "var(--surface)",
          border: "1px solid var(--border)",
        }}
      >
        <div
          className="flex items-center gap-2 px-4 py-3 border-b"
          style={{ borderColor: "var(--border)" }}
        >
          <Search size={16} className="text-muted" />
          <input
            ref={inputRef}
            value={q}
            onChange={(e) => {
              setQ(e.target.value);
              setCursor(0);
            }}
            onKeyDown={onKey}
            placeholder="What do you want to do?"
            className="flex-1 bg-transparent outline-none text-sm"
            style={{ color: "var(--text)" }}
          />
          <kbd
            className="text-[10px] px-1.5 py-0.5 rounded"
            style={{
              background: "var(--surface-2)",
              border: "1px solid var(--border)",
            }}
          >
            esc
          </kbd>
        </div>
        <div className="max-h-72 overflow-y-auto py-1">
          {filtered.length === 0 && (
            <div className="px-4 py-6 text-sm text-muted text-center">
              Nothing matches.
            </div>
          )}
          {filtered.map((a, i) => (
            <button
              key={a.to}
              onClick={() => choose(i)}
              onMouseEnter={() => setCursor(i)}
              className="w-full text-left px-4 py-2 text-sm transition-colors"
              style={{
                background: i === cursor ? "var(--surface-2)" : "transparent",
                color: "var(--text)",
              }}
            >
              {a.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};
