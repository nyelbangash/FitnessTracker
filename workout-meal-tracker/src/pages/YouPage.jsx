import React, { useEffect, useState } from "react";
import { Card, CardBody, CardHeader, Button, Input } from "../ui";
import { useTheme } from "../theme/ThemeContext";
import { themes, themeGroups } from "../theme/themes";
import { useAuth } from "../contexts/AuthContext";
import * as api from "../api";

export const YouPage = () => {
  const { user, logout } = useAuth();
  const { themeId, setThemeId } = useTheme();

  const [profile, setProfile] = useState({
    first_name: user?.first_name || "",
    last_name: user?.last_name || "",
    height_cm: user?.height_cm ?? "",
    weight_kg: user?.weight_kg ?? "",
    dob: user?.dob || "",
  });
  const [goals, setGoals] = useState(user?.nutrition_goals || {});
  const [savingProfile, setSavingProfile] = useState(false);
  const [savingGoals, setSavingGoals] = useState(false);
  const [filter, setFilter] = useState("");

  useEffect(() => {
    (async () => {
      const u = await api.getMe().catch(() => null);
      if (u) {
        setProfile({
          first_name: u.first_name || "",
          last_name: u.last_name || "",
          height_cm: u.height_cm ?? "",
          weight_kg: u.weight_kg ?? "",
          dob: u.dob || "",
        });
        setGoals(u.nutrition_goals || {});
      }
    })();
  }, []);

  const saveProfile = async () => {
    setSavingProfile(true);
    try {
      await api.updateProfile(null, {
        ...profile,
        height_cm: profile.height_cm ? parseInt(profile.height_cm, 10) : null,
        weight_kg: profile.weight_kg ? parseFloat(profile.weight_kg) : null,
      });
    } finally {
      setSavingProfile(false);
    }
  };

  const saveGoals = async () => {
    setSavingGoals(true);
    try {
      await api.updateNutritionGoals(null, {
        calories: parseInt(goals.calories, 10) || 0,
        protein: parseFloat(goals.protein) || 0,
        carbs: parseFloat(goals.carbs) || 0,
        fat: parseFloat(goals.fat) || 0,
      });
    } finally {
      setSavingGoals(false);
    }
  };

  const visibleGroups = Object.entries(themeGroups).map(([group, ids]) => [
    group,
    ids.filter((id) =>
      themes[id].name.toLowerCase().includes(filter.toLowerCase())
    ),
  ]);

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <header>
        <h1 className="text-3xl">You</h1>
        <p className="text-muted text-sm mt-1">Profile, goals, theme, account.</p>
      </header>

      <Card id="theme">
        <CardHeader
          title="Theme"
          subtitle={`${Object.keys(themes).length} themes · live preview on hover`}
          action={
            <input
              placeholder="search…"
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
              className="text-sm px-2 py-1 rounded"
              style={{
                background: "var(--surface-2)",
                color: "var(--text)",
                border: "1px solid var(--border)",
              }}
            />
          }
        />
        <CardBody className="space-y-4">
          {visibleGroups.map(
            ([group, ids]) =>
              ids.length > 0 && (
                <div key={group}>
                  <div className="text-xs uppercase tracking-widest text-muted mb-2">
                    {group}
                  </div>
                  <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-2">
                    {ids.map((id) => (
                      <ThemeSwatch
                        key={id}
                        id={id}
                        active={id === themeId}
                        onPick={() => setThemeId(id)}
                      />
                    ))}
                  </div>
                </div>
              )
          )}
        </CardBody>
      </Card>

      <Card id="goals">
        <CardHeader
          title="Nutrition goals"
          subtitle="daily targets"
          action={
            <Button size="sm" onClick={saveGoals} disabled={savingGoals}>
              {savingGoals ? "Saving…" : "Save"}
            </Button>
          }
        />
        <CardBody>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <Input
              label="Calories"
              type="number"
              value={goals.calories || ""}
              onChange={(e) => setGoals({ ...goals, calories: e.target.value })}
            />
            <Input
              label="Protein"
              type="number"
              value={goals.protein || ""}
              onChange={(e) => setGoals({ ...goals, protein: e.target.value })}
            />
            <Input
              label="Carbs"
              type="number"
              value={goals.carbs || ""}
              onChange={(e) => setGoals({ ...goals, carbs: e.target.value })}
            />
            <Input
              label="Fat"
              type="number"
              value={goals.fat || ""}
              onChange={(e) => setGoals({ ...goals, fat: e.target.value })}
            />
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardHeader
          title="Profile"
          action={
            <Button size="sm" onClick={saveProfile} disabled={savingProfile}>
              {savingProfile ? "Saving…" : "Save"}
            </Button>
          }
        />
        <CardBody>
          <div className="grid grid-cols-2 gap-3">
            <Input
              label="First name"
              value={profile.first_name}
              onChange={(e) =>
                setProfile({ ...profile, first_name: e.target.value })
              }
            />
            <Input
              label="Last name"
              value={profile.last_name}
              onChange={(e) =>
                setProfile({ ...profile, last_name: e.target.value })
              }
            />
            <Input
              label="Height (cm)"
              type="number"
              value={profile.height_cm}
              onChange={(e) =>
                setProfile({ ...profile, height_cm: e.target.value })
              }
            />
            <Input
              label="Weight (kg)"
              type="number"
              step="0.1"
              value={profile.weight_kg}
              onChange={(e) =>
                setProfile({ ...profile, weight_kg: e.target.value })
              }
            />
            <Input
              label="Date of birth"
              type="date"
              value={profile.dob || ""}
              onChange={(e) => setProfile({ ...profile, dob: e.target.value })}
            />
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardHeader title="Account" subtitle={user?.email} />
        <CardBody>
          <Button variant="ghost" onClick={logout}>
            Sign out
          </Button>
        </CardBody>
      </Card>
    </div>
  );
};

const ThemeSwatch = ({ id, active, onPick }) => {
  const t = themes[id];
  return (
    <button
      onClick={onPick}
      className="text-left rounded transition-colors p-2"
      style={{
        background: t.surface,
        color: t.text,
        border: `1px solid ${active ? t.accent : t.border}`,
        boxShadow: active ? `inset 0 0 0 1px ${t.accent}` : "none",
      }}
    >
      <div className="flex items-center justify-between mb-2">
        <div className="text-sm" style={{ color: t.text, fontWeight: active ? 500 : 400 }}>
          {t.name}
        </div>
        {active && (
          <span
            className="text-[9px] px-1 py-0.5 rounded"
            style={{ background: t.accent, color: t.accentText }}
          >
            active
          </span>
        )}
      </div>
      <div className="flex gap-1">
        {[t.bg, t.surface2, t.accent, t.good, t.warn, t.bad].map((c, i) => (
          <div
            key={i}
            className="flex-1 h-3 rounded"
            style={{ background: c, border: `1px solid ${t.border}` }}
          />
        ))}
      </div>
    </button>
  );
};
