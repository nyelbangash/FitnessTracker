import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Card, CardBody } from "../ui";
import * as api from "../api";

export const MealHistoryPage = () => {
  const navigate = useNavigate();
  const [meals, setMeals] = useState(null);

  useEffect(() => {
    (async () => {
      const m = await api.getMeals().catch(() => []);
      setMeals(m);
    })();
  }, []);

  if (!meals) return <div className="text-muted text-sm">Loading…</div>;

  if (meals.length === 0) {
    return (
      <Card>
        <CardBody>
          <div className="text-sm text-muted">No meals logged yet.</div>
        </CardBody>
      </Card>
    );
  }

  // Group by date
  const byDate = meals.reduce((acc, m) => {
    (acc[m.date] = acc[m.date] || []).push(m);
    return acc;
  }, {});

  const sortedDates = Object.keys(byDate).sort().reverse();

  return (
    <div className="space-y-4">
      {sortedDates.map((d) => {
        const day = byDate[d];
        const sums = day.reduce(
          (acc, m) => ({
            cal: acc.cal + (m.calories || 0),
            p: acc.p + (m.protein || 0),
            c: acc.c + (m.carbs || 0),
            f: acc.f + (m.fat || 0),
          }),
          { cal: 0, p: 0, c: 0, f: 0 }
        );
        return (
          <Card key={d}>
            <CardBody>
              <div className="flex items-baseline justify-between mb-2">
                <div className="font-serif-h text-lg">
                  {new Date(d).toLocaleDateString(undefined, {
                    weekday: "long",
                    month: "short",
                    day: "numeric",
                  })}
                </div>
                <div className="text-xs text-muted num">
                  {sums.cal} cal · {sums.p.toFixed(0)}P · {sums.c.toFixed(0)}C · {sums.f.toFixed(0)}F
                </div>
              </div>
              <ul className="space-y-0.5">
                {day.map((m) => (
                  <li key={m.id}>
                    <button
                      onClick={() =>
                        m.editable !== false &&
                        navigate(`/eat/edit/${m.date}/${encodeURIComponent(m.name)}`)
                      }
                      disabled={m.editable === false}
                      className={`w-full text-sm flex justify-between items-baseline px-2 py-1 -mx-2 rounded transition-colors text-left ${
                        m.editable === false
                          ? "cursor-default"
                          : "hover:bg-surface-2"
                      }`}
                      title={
                        m.editable === false
                          ? "Locked — 24h edit window has passed"
                          : "Click to edit"
                      }
                    >
                      <span>
                        <span className="num text-xs text-muted mr-2">
                          {m.time_eaten || "—"}
                        </span>
                        {m.name}
                      </span>
                      <span className="num text-xs text-muted">
                        {m.calories} cal
                      </span>
                    </button>
                  </li>
                ))}
              </ul>
            </CardBody>
          </Card>
        );
      })}
    </div>
  );
};
