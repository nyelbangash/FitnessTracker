import React, { useEffect, useState } from "react";
import { Card, CardBody, CardHeader, Stat, Chip } from "../ui";
import * as api from "../api";

export const ProgressPage = () => {
  const [history, setHistory] = useState(null);

  useEffect(() => {
    (async () => {
      const h = await api.getWorkoutHistory().catch(() => []);
      setHistory(h);
    })();
  }, []);

  if (!history) return <div className="text-muted text-sm">Loading…</div>;

  // Compute PRs by exercise: max weight observed across all completed sessions.
  // Backend already exposes "best_set" per exercise per workout in history.
  const prByExercise = {};
  history.forEach((w) => {
    (w.exercises || []).forEach((ex) => {
      if (!ex.best_set) return;
      const prev = prByExercise[ex.name];
      if (
        !prev ||
        (ex.best_set.weight || 0) > (prev.weight || 0) ||
        ((ex.best_set.weight || 0) === (prev.weight || 0) &&
          (ex.best_set.reps || 0) > (prev.reps || 0))
      ) {
        prByExercise[ex.name] = {
          weight: ex.best_set.weight,
          reps: ex.best_set.reps,
          rpe: ex.best_set.rpe,
          date: w.date,
        };
      }
    });
  });
  const prs = Object.entries(prByExercise).sort((a, b) =>
    a[0].localeCompare(b[0])
  );

  // Aggregates
  const totalVolume = history.reduce((acc, w) => acc + (w.volume || 0), 0);
  const totalTime = history.reduce((acc, w) => acc + (w.duration || 0), 0);

  // Weekly volume bars (last 8 weeks)
  const weeks = lastNWeeks(8);
  const weekData = weeks.map((wk) => {
    const inside = history.filter((h) => h.date >= wk.start && h.date <= wk.end);
    const vol = inside.reduce((a, h) => a + (h.volume || 0), 0);
    return { ...wk, vol, sessions: inside.length };
  });
  const maxWeekVol = Math.max(1, ...weekData.map((w) => w.vol));

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      <header>
        <h1 className="text-3xl">Progress</h1>
        <p className="text-muted text-sm mt-1">PRs, trends, and totals.</p>
      </header>

      <div className="grid md:grid-cols-3 gap-4">
        <Card>
          <CardBody>
            <Stat
              label="Total sessions"
              value={history.length}
              hint="completed workouts"
            />
          </CardBody>
        </Card>
        <Card>
          <CardBody>
            <Stat
              label="Total volume"
              value={Math.round(totalVolume).toLocaleString()}
              unit="kg"
            />
          </CardBody>
        </Card>
        <Card>
          <CardBody>
            <Stat
              label="Time in gym"
              value={Math.round(totalTime / 3600)}
              unit="hr"
              hint={`${Math.round(totalTime / 60)} minutes`}
            />
          </CardBody>
        </Card>
      </div>

      <Card>
        <CardHeader
          title="Weekly volume"
          subtitle="last 8 weeks · total weight moved"
        />
        <CardBody>
          <div className="flex items-end gap-3 h-32">
            {weekData.map((wk, i) => (
              <div key={i} className="flex-1 flex flex-col items-center justify-end gap-1">
                <div className="text-[10px] text-muted num">
                  {wk.vol ? Math.round(wk.vol / 1000) + "k" : ""}
                </div>
                <div
                  className="w-full rounded-t transition-all"
                  style={{
                    height: `${(wk.vol / maxWeekVol) * 90}%`,
                    minHeight: wk.vol > 0 ? 4 : 1,
                    background:
                      wk.vol > 0 ? "var(--accent)" : "var(--surface-2)",
                  }}
                />
                <div className="text-[10px] text-muted">{wk.label}</div>
              </div>
            ))}
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardHeader title="Personal records" subtitle={`${prs.length} exercise${prs.length === 1 ? "" : "s"}`} />
        <CardBody>
          {prs.length === 0 ? (
            <div className="text-sm text-muted">
              No PRs yet. Complete a workout to log your first.
            </div>
          ) : (
            <ul className="space-y-2">
              {prs.map(([name, pr]) => (
                <li
                  key={name}
                  className="flex items-baseline justify-between py-2 border-b last:border-0"
                  style={{ borderColor: "var(--border)" }}
                >
                  <div>
                    <div className="text-sm">{name}</div>
                    <div className="text-xs text-muted">
                      {new Date(pr.date).toLocaleDateString(undefined, {
                        month: "short",
                        day: "numeric",
                        year: "numeric",
                      })}
                    </div>
                  </div>
                  <div className="num">
                    <span className="text-xl">{pr.weight}</span>
                    <span className="text-sm text-muted ml-1">kg ×</span>{" "}
                    <span className="text-xl">{pr.reps}</span>{" "}
                    {pr.rpe != null && (
                      <Chip tone="muted" className="ml-2">
                        RPE {pr.rpe}
                      </Chip>
                    )}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </CardBody>
      </Card>
    </div>
  );
};

function lastNWeeks(n) {
  const out = [];
  const today = new Date();
  const monday = new Date(today);
  const dow = (monday.getDay() + 6) % 7;
  monday.setDate(monday.getDate() - dow);
  for (let i = n - 1; i >= 0; i--) {
    const start = new Date(monday);
    start.setDate(monday.getDate() - i * 7);
    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    out.push({
      start: start.toISOString().slice(0, 10),
      end: end.toISOString().slice(0, 10),
      label:
        i === 0
          ? "now"
          : start.toLocaleDateString(undefined, { month: "short", day: "numeric" }),
    });
  }
  return out;
}
