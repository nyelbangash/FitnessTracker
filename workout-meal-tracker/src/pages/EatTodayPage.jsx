import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, Star, Zap, Trash2, Pencil } from "lucide-react";
import { Card, CardHeader, CardBody, Button, Ring } from "../ui";
import * as api from "../api";

const todayISO = () => new Date().toISOString().slice(0, 10);

export const EatTodayPage = () => {
  const navigate = useNavigate();
  const [report, setReport] = useState(null);
  const [meals, setMeals] = useState([]);

  const load = async () => {
    const [r, m] = await Promise.all([
      api.getDailyNutrition(null, todayISO()).catch(() => null),
      api.getMeals().catch(() => []),
    ]);
    setReport(r);
    const today = todayISO();
    setMeals((m || []).filter((meal) => meal.date === today));
  };

  useEffect(() => {
    load();
  }, []);

  if (!report) return <div className="text-muted text-sm">Loading…</div>;

  const totals = report.totals || {};
  const goals = report.goals || {};

  const toggleFav = async (m) => {
    await api.toggleMealFavorite(null, m.name, m.date);
    load();
  };

  const toggleQuick = async (m) => {
    await api.toggleMealQuickAccess(null, m.name, m.date);
    load();
  };

  const remove = async (m) => {
    if (!window.confirm(`Delete "${m.name}"?`)) return;
    await api.deleteMeal(null, m.name, m.date);
    load();
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader title="Today's macros" action={<Button onClick={() => navigate("/eat/log")}><Plus size={14}/> Log meal</Button>} />
        <CardBody>
          <div className="grid grid-cols-4 gap-4">
            <Ring
              size={88}
              stroke={8}
              value={totals.calories || 0}
              max={goals.calories || 2000}
              label="cal"
              number={Math.round(totals.calories || 0)}
            />
            <Ring
              size={88}
              stroke={8}
              value={totals.protein || 0}
              max={goals.protein || 150}
              label="protein"
              number={Math.round(totals.protein || 0)}
              color="var(--good)"
            />
            <Ring
              size={88}
              stroke={8}
              value={totals.carbs || 0}
              max={goals.carbs || 200}
              label="carbs"
              number={Math.round(totals.carbs || 0)}
              color="var(--warn)"
            />
            <Ring
              size={88}
              stroke={8}
              value={totals.fat || 0}
              max={goals.fat || 65}
              label="fat"
              number={Math.round(totals.fat || 0)}
              color="var(--bad)"
            />
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardHeader title="Meals" subtitle={`${meals.length} logged today`} />
        <CardBody>
          {meals.length === 0 ? (
            <div className="text-sm text-muted">
              No meals yet. Press <kbd className="px-1 mx-0.5 rounded text-[10px]" style={{background: "var(--surface-2)", border: "1px solid var(--border)"}}>+ Log meal</kbd> to start.
            </div>
          ) : (
            <ul className="space-y-2">
              {meals.map((m) => (
                <li
                  key={m.id}
                  className="flex flex-wrap items-center gap-x-3 gap-y-1 py-2 border-b last:border-0"
                  style={{ borderColor: "var(--border)" }}
                >
                  <div className="num text-xs text-muted w-12">{m.time_eaten || "—"}</div>
                  <div className="flex-1 min-w-0">
                    <div className="text-sm truncate">{m.name}</div>
                    <div className="text-xs text-muted">
                      <span className="num">{m.calories}</span> cal ·{" "}
                      <span className="num">{m.protein}</span>P ·{" "}
                      <span className="num">{m.carbs}</span>C ·{" "}
                      <span className="num">{m.fat}</span>F
                    </div>
                  </div>
                  <button
                    title="Edit"
                    onClick={() =>
                      navigate(`/eat/edit/${m.date}/${encodeURIComponent(m.name)}`)
                    }
                    className="text-muted hover:text-fg p-2"
                  >
                    <Pencil size={16} />
                  </button>
                  <button
                    title={m.is_favorite ? "Unfavorite" : "Favorite"}
                    onClick={() => toggleFav(m)}
                    className="text-muted hover:text-fg p-2"
                  >
                    <Star
                      size={16}
                      fill={m.is_favorite ? "var(--accent)" : "none"}
                      stroke={m.is_favorite ? "var(--accent)" : "currentColor"}
                    />
                  </button>
                  <button
                    title="Quick-access"
                    onClick={() => toggleQuick(m)}
                    className="text-muted hover:text-fg p-2"
                  >
                    <Zap
                      size={16}
                      fill={m.is_quick_access ? "var(--accent)" : "none"}
                      stroke={m.is_quick_access ? "var(--accent)" : "currentColor"}
                    />
                  </button>
                  <button
                    title="Delete"
                    onClick={() => remove(m)}
                    className="text-muted hover:text-bad p-2"
                  >
                    <Trash2 size={14} />
                  </button>
                </li>
              ))}
            </ul>
          )}
        </CardBody>
      </Card>
    </div>
  );
};
