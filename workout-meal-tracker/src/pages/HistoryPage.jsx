import React, { useEffect, useState } from "react";
import { Card, CardBody, Chip } from "../ui";
import * as api from "../api";

const formatDate = (iso) =>
  new Date(iso).toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric",
  });

export const HistoryPage = () => {
  const [history, setHistory] = useState(null);

  useEffect(() => {
    (async () => {
      const h = await api.getWorkoutHistory().catch(() => []);
      setHistory(h);
    })();
  }, []);

  if (!history) return <div className="text-muted text-sm">Loading…</div>;

  if (history.length === 0) {
    return (
      <Card>
        <CardBody>
          <div className="text-sm text-muted">
            No completed workouts yet. Finish a session to see it here.
          </div>
        </CardBody>
      </Card>
    );
  }

  return (
    <div className="space-y-2">
      {history.map((h, i) => (
        <Card key={i}>
          <CardBody className="space-y-3">
            <div className="flex flex-wrap items-start gap-3 md:gap-6">
              <div className="md:w-32 shrink-0">
                <div className="text-xs text-muted">{formatDate(h.date)}</div>
                <div className="font-serif-h text-lg mt-0.5">{h.name}</div>
              </div>
              <div className="flex flex-wrap gap-x-5 gap-y-2 text-sm">
                <div>
                  <div className="text-[10px] uppercase tracking-widest text-muted">
                    Volume
                  </div>
                  <div className="num">
                    {Math.round(h.volume).toLocaleString()} kg
                  </div>
                </div>
                <div>
                  <div className="text-[10px] uppercase tracking-widest text-muted">
                    Duration
                  </div>
                  <div className="num">{Math.round((h.duration || 0) / 60)} min</div>
                </div>
                <div>
                  <div className="text-[10px] uppercase tracking-widest text-muted">
                    Exercises
                  </div>
                  <div className="num">{h.exercises?.length || 0}</div>
                </div>
              </div>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {(h.exercises || []).slice(0, 6).map((ex, j) => (
                <Chip key={j} tone="muted">
                  {ex.name}{" "}
                  <span className="num text-[10px] text-muted ml-0.5">
                    {ex.sets_completed}/{ex.total_sets}
                  </span>
                </Chip>
              ))}
            </div>
          </CardBody>
        </Card>
      ))}
    </div>
  );
};
