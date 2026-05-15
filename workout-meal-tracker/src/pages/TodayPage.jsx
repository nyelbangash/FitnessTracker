import React, { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Play, Plus, ArrowRight, Flame, Camera } from "lucide-react";
import { Card, CardHeader, CardBody, CardFooter, Button, Chip, Stat, Ring } from "../ui";
import { useAuth } from "../contexts/AuthContext";
import * as api from "../api";

const todayISO = () => new Date().toISOString().slice(0, 10);

const dayShort = (iso) => {
  const d = new Date(iso);
  return d.toLocaleDateString(undefined, { weekday: "short" });
};

const formatGreeting = (user, planned) => {
  const hour = new Date().getHours();
  const part = hour < 5 ? "Late night" : hour < 12 ? "Morning" : hour < 18 ? "Afternoon" : "Evening";
  const name = user?.first_name || "";
  const tail = planned
    ? `${planned} on deck.`
    : "Plan a workout, log a meal, or just read.";
  return `${part}${name ? `, ${name}` : ""}. ${tail}`;
};

export const TodayPage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [active, setActive] = useState(null);
  const [templates, setTemplates] = useState([]);
  const [report, setReport] = useState(null);
  const [history, setHistory] = useState([]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const [activeWorkout, tmpls, dailyReport, hist] = await Promise.all([
        api.getActiveWorkout().catch(() => null),
        api.getWorkoutTemplates().catch(() => []),
        api.getDailyNutrition(null, todayISO()).catch(() => null),
        api.getWorkoutHistory().catch(() => []),
      ]);
      if (cancelled) return;
      setActive(activeWorkout);
      setTemplates(tmpls || []);
      setReport(dailyReport);
      setHistory(hist || []);
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const lastWorkout = history?.[0];
  const plannedLabel = active
    ? `${active.workout_name} in progress`
    : lastWorkout
    ? `Last: ${lastWorkout.name}`
    : null;

  // Streak: longest consecutive trailing days with a completed workout.
  const streak = computeStreak(history);

  // Week strip: last 7 days
  const weekDays = lastNDays(7);
  const trainedDates = new Set((history || []).map((h) => h.date));

  const totals = report?.totals ?? { calories: 0, protein: 0, carbs: 0, fat: 0 };
  const goals = report?.goals ?? user?.nutrition_goals ?? {};
  const meals = report?.meals ?? [];

  return (
    <div className="max-w-5xl mx-auto space-y-4 md:space-y-6">
      <header>
        <h1 className="text-2xl md:text-3xl tracking-tight leading-tight">
          {formatGreeting(user, plannedLabel)}
        </h1>
      </header>

      {/* Quick actions — mobile-prominent, hidden on desktop where the
          sidebar + status pill cover the same job. */}
      <div className="md:hidden grid grid-cols-2 gap-3">
        <button
          onClick={() => navigate("/eat/log?camera=1")}
          className="rounded-lg p-4 flex flex-col items-center justify-center gap-1"
          style={{
            background: "var(--accent)",
            color: "var(--accent-text)",
            minHeight: 96,
          }}
        >
          <Camera size={28} />
          <span className="text-sm font-medium">Snap a meal</span>
        </button>
        <button
          onClick={() => navigate(active ? "/train/active" : "/train")}
          className="rounded-lg p-4 flex flex-col items-center justify-center gap-1 border"
          style={{
            background: "var(--surface)",
            borderColor: "var(--border)",
            color: "var(--text)",
            minHeight: 96,
          }}
        >
          <Play size={28} />
          <span className="text-sm font-medium">
            {active ? "Resume workout" : "Start workout"}
          </span>
        </button>
      </div>

      <div className="grid md:grid-cols-2 gap-3 md:gap-4">
        {/* Training card */}
        <Card>
          <CardHeader
            title="Training"
            subtitle={
              active
                ? "You have an active session"
                : lastWorkout
                ? `Last session ${dayShort(lastWorkout.date)}`
                : "No recent sessions"
            }
          />
          <CardBody>
            {active ? (
              <div className="space-y-4">
                <div className="flex items-end gap-6">
                  <Stat
                    label="Volume"
                    value={Math.round(active.total_volume || 0).toLocaleString()}
                    unit="kg"
                  />
                  <Stat
                    label="Avg RPE"
                    value={(active.average_rpe ?? 0).toFixed(1)}
                  />
                  <Stat
                    label="Exercise"
                    value={`${(active.current_exercise ?? 0) + 1}/${
                      active.exercises?.length ?? 0
                    }`}
                  />
                </div>
                <Button
                  variant="primary"
                  size="lg"
                  full
                  onClick={() => navigate("/train/active")}
                >
                  <Play size={16} />
                  Resume workout
                </Button>
              </div>
            ) : templates.length > 0 ? (
              <div className="space-y-3">
                <div className="text-sm text-muted">Pick a template to start:</div>
                <div className="flex flex-wrap gap-2">
                  {templates.slice(0, 6).map((t) => (
                    <Chip
                      key={t.id}
                      onClick={async () => {
                        await api.startWorkout(null, t.name);
                        navigate("/train/active");
                      }}
                      tone="accent"
                    >
                      <Play size={11} /> {t.name}
                    </Chip>
                  ))}
                </div>
                <Link
                  to="/train/templates"
                  className="text-xs text-muted hover:text-fg inline-flex items-center gap-1"
                >
                  Manage templates <ArrowRight size={11} />
                </Link>
              </div>
            ) : (
              <div className="space-y-3">
                <div className="text-sm text-muted">
                  No templates yet. Create one to start tracking.
                </div>
                <Button onClick={() => navigate("/train/templates/new")}>
                  <Plus size={14} /> New template
                </Button>
              </div>
            )}
          </CardBody>
          {lastWorkout && (
            <CardFooter>
              <span className="num">{Math.round(lastWorkout.volume).toLocaleString()} kg</span>
              <span className="mx-2">·</span>
              <span className="num">
                {Math.round((lastWorkout.duration || 0) / 60)} min
              </span>
              <span className="mx-2">·</span>
              <span>{lastWorkout.exercises?.length ?? 0} exercises</span>
            </CardFooter>
          )}
        </Card>

        {/* Nutrition card */}
        <Card>
          <CardHeader
            title="Nutrition"
            subtitle={`${meals.length} meal${meals.length === 1 ? "" : "s"} logged`}
            action={
              <Button size="sm" variant="ghost" onClick={() => navigate("/eat/log")}>
                <Plus size={14} /> Log meal
              </Button>
            }
          />
          <CardBody>
            <div className="grid grid-cols-4 gap-4">
              <Ring
                size={56}
                value={totals.calories}
                max={goals.calories || 2000}
                label="cal"
                number={Math.round(totals.calories)}
              />
              <Ring
                size={56}
                value={totals.protein}
                max={goals.protein || 150}
                label="protein"
                number={Math.round(totals.protein)}
                color="var(--good)"
              />
              <Ring
                size={56}
                value={totals.carbs}
                max={goals.carbs || 200}
                label="carbs"
                number={Math.round(totals.carbs)}
                color="var(--warn)"
              />
              <Ring
                size={56}
                value={totals.fat}
                max={goals.fat || 65}
                label="fat"
                number={Math.round(totals.fat)}
                color="var(--bad)"
              />
            </div>

            {meals.length > 0 && (
              <div className="mt-4 flex flex-wrap gap-1.5">
                {meals.map((m, i) => (
                  <Chip key={i} tone="muted">
                    <span className="num text-[10px]">{m.time || "—"}</span>
                    {m.name}
                  </Chip>
                ))}
              </div>
            )}
          </CardBody>
        </Card>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-3 md:gap-4">
        {/* Streak */}
        <Card>
          <CardBody className="flex items-center gap-4">
            <Flame
              size={28}
              style={{ color: streak > 0 ? "var(--accent)" : "var(--text-muted)" }}
            />
            <div>
              <div className="num text-3xl leading-none">{streak}</div>
              <div className="text-xs text-muted mt-0.5">
                day workout streak
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Week */}
        <Card>
          <CardBody>
            <div className="text-xs uppercase tracking-widest text-muted mb-2">
              This week
            </div>
            <div className="flex gap-1.5">
              {weekDays.map((iso) => (
                <div
                  key={iso}
                  className="flex-1 flex flex-col items-center gap-1"
                >
                  <div className="text-[10px] text-muted">
                    {dayShort(iso).slice(0, 1)}
                  </div>
                  <div
                    className="w-full h-6 rounded"
                    style={{
                      background: trainedDates.has(iso)
                        ? "var(--accent)"
                        : "var(--surface-2)",
                    }}
                  />
                </div>
              ))}
            </div>
          </CardBody>
        </Card>

        {/* Latest note / PR */}
        <Card>
          <CardBody>
            <div className="text-xs uppercase tracking-widest text-muted mb-2">
              Last session
            </div>
            {lastWorkout ? (
              <>
                <div className="font-serif-h text-lg">{lastWorkout.name}</div>
                <div className="text-xs text-muted mt-1">
                  {new Date(lastWorkout.date).toLocaleDateString(undefined, {
                    month: "short",
                    day: "numeric",
                  })}{" "}
                  ·{" "}
                  <span className="num">
                    {Math.round(lastWorkout.volume).toLocaleString()}
                  </span>{" "}
                  kg
                </div>
              </>
            ) : (
              <div className="text-sm text-muted">No history yet.</div>
            )}
          </CardBody>
        </Card>
      </div>
    </div>
  );
};

function lastNDays(n) {
  const out = [];
  const today = new Date();
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    out.push(d.toISOString().slice(0, 10));
  }
  return out;
}

function computeStreak(history) {
  if (!history?.length) return 0;
  const trainedSet = new Set(history.map((h) => h.date));
  let streak = 0;
  const today = new Date();
  // Walk back day-by-day; if today not trained, allow yesterday to start the
  // streak so a missed morning doesn't visually punish you.
  for (let i = 0; i < 365; i++) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    const iso = d.toISOString().slice(0, 10);
    if (trainedSet.has(iso)) {
      streak += 1;
    } else if (i === 0) {
      // skip today
    } else {
      break;
    }
  }
  return streak;
}
