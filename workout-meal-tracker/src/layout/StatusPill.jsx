import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import * as api from "../api";

// Shows: active workout summary if one is in progress, else today's macro
// progress summary, else nothing.
export const StatusPill = () => {
  const [pill, setPill] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    let cancelled = false;

    const refresh = async () => {
      try {
        const active = await api.getActiveWorkout().catch(() => null);
        if (active && !cancelled) {
          const ex = active.exercises?.[active.current_exercise || 0];
          setPill({
            kind: "active",
            text: `${active.workout_name} · ${ex?.exercise_name ?? "—"}, set ${
              (active.current_set ?? 0) + 1
            } of ${ex?.sets?.length ?? 1}`,
            to: "/train/active",
          });
          return;
        }
      } catch (_) {}

      try {
        const today = new Date().toISOString().slice(0, 10);
        const report = await api.getDailyNutrition(null, today);
        if (cancelled) return;
        const cal = report?.totals?.calories ?? 0;
        const goal = report?.goals?.calories ?? 2000;
        const left = Math.max(0, goal - cal);
        setPill({
          kind: "nutrition",
          text: `${left.toLocaleString()} cal left today`,
          to: "/eat",
        });
      } catch (_) {
        setPill(null);
      }
    };

    refresh();
    const t = setInterval(refresh, 30_000);
    return () => {
      cancelled = true;
      clearInterval(t);
    };
  }, []);

  if (!pill) return null;

  return (
    <button
      onClick={() => navigate(pill.to)}
      className="text-xs px-2.5 py-1 rounded transition-colors hover:opacity-90"
      style={{
        background: pill.kind === "active" ? "var(--accent)" : "var(--surface-2)",
        color:
          pill.kind === "active" ? "var(--accent-text)" : "var(--text-muted)",
        border:
          pill.kind === "active"
            ? "1px solid var(--accent)"
            : "1px solid var(--border)",
      }}
    >
      {pill.text}
    </button>
  );
};
