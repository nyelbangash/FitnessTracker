import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Card, CardBody, CardHeader } from "../ui";
import * as api from "../api";

export const MealFavoritesPage = () => {
  const navigate = useNavigate();
  const [favorites, setFavorites] = useState(null);
  const [quick, setQuick] = useState([]);

  useEffect(() => {
    (async () => {
      const [f, q] = await Promise.all([
        api.getFavoriteMeals().catch(() => []),
        api.getQuickAccessMeals().catch(() => []),
      ]);
      setFavorites(f);
      setQuick(q);
    })();
  }, []);

  if (!favorites) return <div className="text-muted text-sm">Loading…</div>;

  const Section = ({ title, items }) =>
    items.length === 0 ? null : (
      <Card>
        <CardHeader title={title} subtitle={`${items.length} saved`} />
        <CardBody>
          <div className="grid md:grid-cols-2 gap-2">
            {items.map((m) => (
              <div
                key={m.id}
                className="flex items-baseline justify-between p-2 rounded hover:bg-surface-2 transition-colors cursor-pointer"
                onClick={() => navigate("/eat/log")}
                title="Re-log this meal"
              >
                <div>
                  <div className="text-sm">{m.name}</div>
                  <div className="text-xs text-muted">{m.meal_type}</div>
                </div>
                <div className="text-xs text-muted num">{m.calories} cal</div>
              </div>
            ))}
          </div>
        </CardBody>
      </Card>
    );

  if (favorites.length === 0 && quick.length === 0) {
    return (
      <Card>
        <CardBody>
          <div className="text-sm text-muted">
            No favorites yet. Star a meal on the Today tab to save it here.
          </div>
        </CardBody>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      <Section title="Favorites" items={favorites} />
      <Section title="Quick access" items={quick} />
    </div>
  );
};
