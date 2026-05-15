import React, { useEffect, useState, useCallback, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Check, SkipForward, Square, RotateCcw } from "lucide-react";
import { Button, Bar, NumberCell } from "../ui";
import * as api from "../api";

const fmtClock = (totalSec) => {
  if (totalSec == null) return "—";
  const s = Math.max(0, Math.round(totalSec));
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${m}:${String(r).padStart(2, "0")}`;
};

export const ActiveWorkoutPage = () => {
  const navigate = useNavigate();
  const [workout, setWorkout] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [, setElapsedTick] = useState(0);
  const [submitting, setSubmitting] = useState(false);

  // Per-set draft values (reps/weight/rpe) that the user edits before
  // pressing "Complete set". Keyed by `${exerciseIdx}:${setIdx}`.
  const [drafts, setDrafts] = useState({});

  const completeSetRef = useRef(null);
  const skipRef = useRef(null);

  const refresh = useCallback(async () => {
    try {
      const w = await api.getActiveWorkout();
      setWorkout(w);
      setError(null);
    } catch (err) {
      if (err?.response?.status === 404) {
        setError("no_active");
      } else {
        setError("load_failed");
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  // Tick once a second so elapsed + rest timer redraw.
  useEffect(() => {
    const t = setInterval(() => setElapsedTick((n) => n + 1), 1000);
    return () => clearInterval(t);
  }, []);

  // Keyboard shortcuts must be installed unconditionally (hook rules).
  // The handlers themselves no-op if there's no workout.
  useKeyboard({
    Space: () => completeSetRef.current && completeSetRef.current(),
    s: () => skipRef.current && skipRef.current(),
    S: () => skipRef.current && skipRef.current(),
  });

  if (loading) {
    return <div className="text-muted text-sm">Loading…</div>;
  }

  if (error === "no_active") {
    return (
      <div className="max-w-md mx-auto text-center mt-20 space-y-3">
        <h2 className="text-2xl">No workout in progress</h2>
        <p className="text-muted text-sm">
          Pick a template to start a session.
        </p>
        <Button onClick={() => navigate("/train")}>Go to Train</Button>
      </div>
    );
  }

  if (!workout) return null;

  const exIdx = workout.current_exercise ?? 0;
  const setIdx = workout.current_set ?? 0;
  const exercise = workout.exercises?.[exIdx];
  const nextExercise = workout.exercises?.[exIdx + 1];
  const sortedSets = exercise
    ? [...(exercise.sets || [])].sort((a, b) => a.id - b.id)
    : [];
  const currentSet = sortedSets[setIdx];

  const draftKey = `${exIdx}:${setIdx}`;
  const draft = drafts[draftKey] ?? {
    reps: currentSet?.reps || exercise?.target_reps || 0,
    weight: currentSet?.weight || exercise?.target_weight || 0,
    rpe: currentSet?.rpe || exercise?.rpe_target || 8,
  };

  const updateDraft = (key, value) => {
    setDrafts((prev) => ({ ...prev, [draftKey]: { ...draft, [key]: value } }));
  };

  const isWorkoutDone =
    workout.exercises?.every((ex) =>
      (ex.sets || []).every((s) => s.completed_at)
    );

  const completeSet = async () => {
    if (submitting || isWorkoutDone) return;
    setSubmitting(true);
    try {
      const w = await api.completeSet(null, {
        reps: parseFloat(draft.reps) || 0,
        weight: parseFloat(draft.weight) || 0,
        rpe: parseFloat(draft.rpe) || 0,
      });
      setWorkout(w);
      setDrafts((prev) => {
        const { [draftKey]: _, ...rest } = prev;
        return rest;
      });
    } catch (e) {
      // surface server validation errors
      console.error(e);
    } finally {
      setSubmitting(false);
    }
  };

  const skip = async () => {
    if (submitting) return;
    setSubmitting(true);
    try {
      const w = await api.skipExercise();
      setWorkout(w);
    } finally {
      setSubmitting(false);
    }
  };

  const endWorkout = async () => {
    if (submitting) return;
    setSubmitting(true);
    try {
      await api.endWorkout();
      navigate("/train/history");
    } finally {
      setSubmitting(false);
    }
  };

  completeSetRef.current = completeSet;
  skipRef.current = skip;

  // Elapsed since start
  const startedAt = workout.start_time ? new Date(workout.start_time) : null;
  const elapsedSec = startedAt
    ? Math.max(0, Math.floor((Date.now() - startedAt.getTime()) / 1000))
    : 0;

  // Rest timer
  const restEndAt = workout.rest_timer_end
    ? new Date(workout.rest_timer_end)
    : null;
  const restRemaining = restEndAt
    ? Math.max(0, Math.floor((restEndAt.getTime() - Date.now()) / 1000))
    : 0;
  const restTotal = exercise?.rest_time || 90;
  const restElapsed = Math.max(0, restTotal - restRemaining);

  return (
    <div className="max-w-3xl mx-auto space-y-4 md:space-y-5 animate-fade-in pb-28 md:pb-0">
      {/* Header strip */}
      <header className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h1 className="text-xl md:text-2xl leading-tight truncate">
            {workout.workout_name}
          </h1>
          <div className="text-xs text-muted mt-1">
            Ex <span className="num">{exIdx + 1}</span>/
            <span className="num">{workout.exercises?.length || 0}</span> ·{" "}
            <span className="num">{fmtClock(elapsedSec)}</span> ·{" "}
            <span className="num">
              {Math.round(workout.total_volume || 0).toLocaleString()}
            </span>
            <span className="hidden md:inline"> kg total</span>
            <span className="md:hidden"> kg</span>
          </div>
        </div>
        <Button variant="ghost" size="sm" onClick={endWorkout}>
          <Square size={14} />
          <span className="hidden md:inline">End workout</span>
          <span className="md:hidden">End</span>
        </Button>
      </header>

      {/* Set card — the focal point */}
      <section
        className="gb-card p-5 md:p-8 text-center space-y-5 md:space-y-6"
      >
        {isWorkoutDone ? (
          <div className="space-y-4 py-8">
            <h2 className="text-3xl">Session complete</h2>
            <div className="flex justify-center gap-8">
              <div>
                <div className="text-xs uppercase tracking-widest text-muted">Volume</div>
                <div className="num text-3xl">
                  {Math.round(workout.total_volume || 0).toLocaleString()}
                </div>
              </div>
              <div>
                <div className="text-xs uppercase tracking-widest text-muted">Avg RPE</div>
                <div className="num text-3xl">
                  {(workout.average_rpe || 0).toFixed(1)}
                </div>
              </div>
              <div>
                <div className="text-xs uppercase tracking-widest text-muted">Time</div>
                <div className="num text-3xl">{fmtClock(elapsedSec)}</div>
              </div>
            </div>
            <Button variant="primary" size="xl" onClick={endWorkout}>
              <Check size={18} /> Finish workout
            </Button>
          </div>
        ) : (
          <>
            <div>
              <div className="font-serif-h text-2xl md:text-3xl">
                {exercise?.exercise_name}
              </div>
              <div className="text-xs text-muted mt-2">
                Set <span className="num">{setIdx + 1}</span> of{" "}
                <span className="num">{sortedSets.length}</span>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-2 md:gap-4 md:flex md:items-center md:justify-center">
              <NumberCell
                label="Reps"
                value={draft.reps}
                onChange={(v) => updateDraft("reps", v)}
                step={1}
                width="w-full md:w-28"
              />
              <NumberCell
                label="Weight"
                value={draft.weight}
                onChange={(v) => updateDraft("weight", v)}
                step={2.5}
                suffix="kg"
                width="w-full md:w-28"
              />
              <NumberCell
                label="RPE"
                value={draft.rpe}
                onChange={(v) => updateDraft("rpe", v)}
                step={0.5}
                min={1}
                max={10}
                width="w-full md:w-24"
              />
            </div>

            <div className="text-xs text-muted">tap a number to edit</div>

            {/* Desktop: inline complete button. Mobile: sticky bar at bottom (rendered below). */}
            <div className="hidden md:block">
              <Button
                variant="primary"
                size="xl"
                onClick={completeSet}
                disabled={submitting}
              >
                <Check size={18} />
                Complete set
                <kbd
                  className="ml-2 text-[10px] px-1.5 py-0.5 rounded"
                  style={{
                    background: "rgba(0,0,0,0.15)",
                    color: "inherit",
                  }}
                >
                  space
                </kbd>
              </Button>
            </div>

            <div className="text-xs text-muted">
              {exercise?.previous_weight ? (
                <>
                  Last time:{" "}
                  <span className="num">
                    {exercise.target_reps} × {exercise.previous_weight}
                  </span>{" "}
                  · target{" "}
                  <span className="num">
                    {exercise.target_reps} × {exercise.target_weight}
                  </span>
                </>
              ) : (
                <>
                  Target:{" "}
                  <span className="num">
                    {exercise?.target_reps} × {exercise?.target_weight}
                  </span>{" "}
                  @ RPE <span className="num">{exercise?.rpe_target || "—"}</span>
                </>
              )}
            </div>
          </>
        )}
      </section>

      {/* Set log */}
      {!isWorkoutDone && (
        <section className="gb-card px-5 py-4">
          <div className="text-xs uppercase tracking-widest text-muted mb-2">
            Set log
          </div>
          <ul className="space-y-1.5">
            {sortedSets.map((s, i) => {
              const isCurrent = i === setIdx;
              const done = !!s.completed_at;
              return (
                <li
                  key={s.id}
                  className="flex items-center gap-3 text-sm"
                  style={{
                    color: done
                      ? "var(--text)"
                      : isCurrent
                      ? "var(--text)"
                      : "var(--text-muted)",
                  }}
                >
                  <span
                    className="inline-flex items-center justify-center rounded-full"
                    style={{
                      width: 18,
                      height: 18,
                      background: done
                        ? "var(--accent)"
                        : isCurrent
                        ? "var(--surface-2)"
                        : "transparent",
                      color: done ? "var(--accent-text)" : "var(--text-muted)",
                      border: done ? "none" : "1px solid var(--border)",
                    }}
                  >
                    {done && <Check size={10} />}
                  </span>
                  <span className="w-16 text-xs">Set {i + 1}</span>
                  {done ? (
                    <span className="num">
                      {s.reps} × {s.weight}{" "}
                      <span className="text-muted">@ RPE {s.rpe}</span>
                    </span>
                  ) : isCurrent ? (
                    <span className="text-xs text-muted italic">current</span>
                  ) : (
                    <span className="text-xs text-muted">—</span>
                  )}
                </li>
              );
            })}
          </ul>
        </section>
      )}

      {/* Rest timer */}
      {!isWorkoutDone && restRemaining > 0 && (
        <section
          className="gb-card px-5 py-3 flex items-center gap-3"
        >
          <div className="text-xs uppercase tracking-widest text-muted w-12">
            Rest
          </div>
          <div className="flex-1">
            <Bar value={restElapsed} max={restTotal} height={6} />
          </div>
          <div className="num text-sm" style={{ minWidth: 60, textAlign: "right" }}>
            {fmtClock(restRemaining)} / {fmtClock(restTotal)}
          </div>
        </section>
      )}

      {/* Up next + escape hatches */}
      {!isWorkoutDone && (
        <section className="flex flex-col md:flex-row md:items-center md:justify-between text-sm gap-2">
          <div className="text-muted">
            {nextExercise ? (
              <>
                <span className="text-xs uppercase tracking-widest mr-2">
                  Up next
                </span>
                <span className="text-fg">{nextExercise.exercise_name}</span>{" "}
                ·{" "}
                <span className="num">
                  {nextExercise.target_reps} × {nextExercise.target_weight}
                </span>
              </>
            ) : (
              <span>Last exercise — go all out</span>
            )}
          </div>
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="sm" onClick={skip}>
              <SkipForward size={14} /> Skip exercise
            </Button>
            <Button variant="ghost" size="sm" onClick={refresh} title="Refresh">
              <RotateCcw size={14} />
            </Button>
          </div>
        </section>
      )}

      {/* Sticky mobile complete-set bar. Sits above the bottom tab nav. */}
      {!isWorkoutDone && (
        <div
          className="md:hidden fixed left-0 right-0 z-30 px-3 pt-2"
          style={{
            bottom: "calc(env(safe-area-inset-bottom, 0px) + 60px)",
            background: "linear-gradient(to top, var(--bg) 60%, transparent)",
            paddingBottom: 8,
          }}
        >
          <button
            onClick={completeSet}
            disabled={submitting}
            className="w-full rounded-lg flex items-center justify-center gap-2 disabled:opacity-50"
            style={{
              background: "var(--accent)",
              color: "var(--accent-text)",
              padding: "16px 20px",
              fontWeight: 500,
              fontSize: "1.05rem",
              boxShadow: "0 6px 16px rgba(0,0,0,0.2)",
            }}
          >
            <Check size={20} />
            Complete set
          </button>
        </div>
      )}
    </div>
  );
};

function useKeyboard(map) {
  useEffect(() => {
    const onKey = (e) => {
      // Don't fire shortcuts while the user is typing in an input
      const tag = e.target?.tagName;
      if (tag === "INPUT" || tag === "TEXTAREA") return;
      const key = e.key === " " ? "Space" : e.key;
      const handler = map[key];
      if (handler) {
        e.preventDefault();
        handler();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(Object.keys(map))]);
}
