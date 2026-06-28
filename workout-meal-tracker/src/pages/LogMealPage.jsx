import React, { useEffect, useRef, useState } from "react";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import { Plus, Trash2, ArrowLeft, Camera, AlertTriangle, Sparkles, Lock } from "lucide-react";
import { Card, CardBody, CardHeader, Button, Input, Textarea, Chip } from "../ui";
import { RefineChat } from "../ui/RefineChat";
import * as api from "../api";

const todayISO = () => new Date().toISOString().slice(0, 10);

export const LogMealPage = () => {
  const navigate = useNavigate();
  const { name: editName, date: editDate } = useParams();
  const [searchParams] = useSearchParams();
  const isEdit = Boolean(editName && editDate);
  const autoOpenCamera = searchParams.get("camera") === "1";

  const [quickList, setQuickList] = useState([]);
  const [loading, setLoading] = useState(isEdit);

  const [form, setForm] = useState({
    name: "",
    date: todayISO(),
    time_eaten: new Date().toTimeString().slice(0, 5),
    meal_type: "breakfast",
    calories: "",
    protein: "",
    carbs: "",
    fat: "",
    ingredients: [],
  });

  const [error, setError] = useState(null);
  const [saving, setSaving] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  const [analyzingText, setAnalyzingText] = useState(false);
  const [analysis, setAnalysis] = useState(null);
  const [description, setDescription] = useState("");
  const [locked, setLocked] = useState(false);
  const [editableUntil, setEditableUntil] = useState(null);
  const fileInputRef = useRef(null);

  // Load the existing meal when in edit mode.
  useEffect(() => {
    if (!isEdit) return;
    (async () => {
      try {
        // The backend index returns all meals; find the one matching name+date.
        const meals = await api.getMeals();
        const meal = (meals || []).find(
          (m) => m.name === decodeURIComponent(editName) && m.date === editDate
        );
        if (meal) {
          setForm({
            name: meal.name,
            date: meal.date,
            time_eaten: meal.time_eaten || "",
            meal_type: meal.meal_type || "lunch",
            calories: String(meal.calories ?? ""),
            protein: String(meal.protein ?? ""),
            carbs: String(meal.carbs ?? ""),
            fat: String(meal.fat ?? ""),
            ingredients: (meal.ingredients || []).map((i) => ({
              name: i.name || "",
              amount: i.amount ?? "",
              unit: i.unit || "g",
            })),
          });
          if (meal.editable === false) setLocked(true);
          if (meal.editable_until) setEditableUntil(meal.editable_until);
        } else {
          setError("Meal not found");
        }
      } catch (_) {
        setError("Could not load meal");
      } finally {
        setLoading(false);
      }
    })();
  }, [isEdit, editName, editDate]);

  useEffect(() => {
    if (isEdit) return; // Quick-add only applies to new meals.
    (async () => {
      const [qa, favs] = await Promise.all([
        api.getQuickAccessMeals().catch(() => []),
        api.getFavoriteMeals().catch(() => []),
      ]);
      // Dedup by name, prefer quick-access
      const map = new Map();
      [...qa, ...favs].forEach((m) => map.set(m.name, m));
      setQuickList(Array.from(map.values()).slice(0, 12));
    })();
  }, [isEdit]);

  const update = (key, value) => setForm((f) => ({ ...f, [key]: value }));

  const updateIngredient = (i, key, value) => {
    setForm((f) => {
      const next = [...f.ingredients];
      next[i] = { ...next[i], [key]: value };
      return { ...f, ingredients: next };
    });
  };

  const onPickPhoto = () => fileInputRef.current?.click();

  // Auto-open camera when arriving via the home-screen camera shortcut.
  useEffect(() => {
    if (autoOpenCamera && !isEdit) {
      // Tiny delay so the file input is mounted before we click it.
      const t = setTimeout(() => fileInputRef.current?.click(), 150);
      return () => clearTimeout(t);
    }
  }, [autoOpenCamera, isEdit]);

  // Apply an analysis result (initial or refined) to the form fields.
  const applyAnalysisToForm = (result) => {
    setAnalysis(result);
    setForm((f) => ({
      ...f,
      name: result.meal_name || f.name,
      meal_type: result.meal_type || f.meal_type,
      calories: String(result.calories ?? ""),
      protein: String(result.protein ?? ""),
      carbs: String(result.carbs ?? ""),
      fat: String(result.fat ?? ""),
      ingredients: (result.ingredients || []).map((ing) => ({
        name: ing.name || "",
        amount: ing.amount ?? "",
        unit: ing.unit || "g",
      })),
    }));
  };

  const onPhotoSelected = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = ""; // allow re-uploading the same file
    if (!file) return;
    setError(null);
    setAnalyzing(true);
    try {
      const result = await api.analyzeMealPhoto(file);
      applyAnalysisToForm(result);
    } catch (err) {
      const detail =
        err?.response?.data?.detail || err?.message || "Could not analyze photo";
      setError(`Analysis failed: ${detail}`);
    } finally {
      setAnalyzing(false);
    }
  };

  const onAnalyzeDescription = async () => {
    const text = description.trim();
    if (!text || analyzingText) return;
    setError(null);
    setAnalyzingText(true);
    try {
      const result = await api.analyzeMealText(text);
      applyAnalysisToForm(result);
    } catch (err) {
      const detail =
        err?.response?.data?.error ||
        err?.response?.data?.detail ||
        err?.message ||
        "Could not analyze description";
      setError(`Analysis failed: ${detail}`);
    } finally {
      setAnalyzingText(false);
    }
  };

  const populateFromMeal = (m) => {
    setForm((f) => ({
      ...f,
      name: m.name,
      meal_type: m.meal_type || f.meal_type,
      calories: String(m.calories ?? ""),
      protein: String(m.protein ?? ""),
      carbs: String(m.carbs ?? ""),
      fat: String(m.fat ?? ""),
      ingredients: (m.ingredients || []).map((i) => ({
        name: i.name,
        amount: i.amount || "",
        unit: i.unit || "",
      })),
    }));
  };

  const save = async () => {
    setError(null);
    setSaving(true);
    const payload = {
      ...form,
      calories: parseInt(form.calories, 10) || 0,
      protein: parseFloat(form.protein) || 0,
      carbs: parseFloat(form.carbs) || 0,
      fat: parseFloat(form.fat) || 0,
    };
    try {
      if (isEdit) {
        await api.updateMeal(
          decodeURIComponent(editName),
          editDate,
          payload
        );
      } else {
        await api.createMeal(null, payload);
      }
      navigate("/eat");
    } catch (e) {
      const errors = e?.response?.data?.errors;
      setError(
        errors
          ? Object.entries(errors)[0].join(": ")
          : isEdit
          ? "Could not save changes"
          : "Could not log meal"
      );
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="max-w-3xl space-y-5">
      <div className="flex items-center gap-3">
        <button onClick={() => navigate("/eat")} className="text-muted hover:text-fg">
          <ArrowLeft size={16} />
        </button>
        <h2 className="text-2xl">{isEdit ? (locked ? "Meal (locked)" : "Edit meal") : "Log a meal"}</h2>
      </div>

      {locked && (
        <Card>
          <CardBody className="flex items-start gap-3">
            <Lock size={16} className="mt-0.5 shrink-0" style={{ color: "var(--text-muted)" }} />
            <div className="text-sm">
              <div>This meal is locked — the 24-hour edit window has passed.</div>
              {editableUntil && (
                <div className="text-xs text-muted mt-0.5">
                  Was editable until{" "}
                  {new Date(editableUntil).toLocaleString(undefined, {
                    month: "short",
                    day: "numeric",
                    hour: "numeric",
                    minute: "2-digit",
                  })}
                  .
                </div>
              )}
            </div>
          </CardBody>
        </Card>
      )}

      {!isEdit && (
      <Card>
        <CardHeader
          title="From a photo"
          subtitle="snap a meal, get a draft you can edit"
        />
        <CardBody>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            capture="environment"
            className="hidden"
            onChange={onPhotoSelected}
          />
          <div className="flex items-center gap-3">
            <Button
              variant="primary"
              onClick={onPickPhoto}
              disabled={analyzing}
            >
              <Camera size={14} />
              {analyzing ? "Analyzing…" : analysis ? "Try another photo" : "Upload photo"}
            </Button>
            {analysis && (
              <Chip tone={
                analysis.overall_confidence === "high"
                  ? "accent"
                  : analysis.overall_confidence === "low"
                  ? "muted"
                  : "default"
              }>
                {analysis.overall_confidence} confidence
              </Chip>
            )}
          </div>

          {analysis && (analysis.warnings || []).length > 0 && (
            <ul className="mt-3 space-y-1">
              {analysis.warnings.map((w, i) => (
                <li
                  key={i}
                  className="text-xs flex items-start gap-1.5"
                  style={{ color: "var(--warn)" }}
                >
                  <AlertTriangle size={12} className="mt-0.5 shrink-0" />
                  {w}
                </li>
              ))}
            </ul>
          )}

          {analysis && (analysis.ingredients || []).length > 0 && (
            <div className="mt-4 flex flex-wrap gap-1.5">
              {analysis.ingredients.map((ing, i) => (
                <Chip
                  key={i}
                  tone={
                    ing.confidence === "high"
                      ? "default"
                      : ing.confidence === "low"
                      ? "muted"
                      : "default"
                  }
                  title={`${ing.confidence} confidence${ing.source === "unmatched" ? " · no USDA match" : ""}`}
                >
                  {ing.name}{" "}
                  <span className="num text-[10px] text-muted">
                    {ing.amount}{ing.unit}
                  </span>
                  {ing.source === "unmatched" && (
                    <span className="text-bad ml-1">·?</span>
                  )}
                </Chip>
              ))}
            </div>
          )}

          {analysis && (
            <div className="text-xs text-muted mt-3">
              Numbers below were estimated. Review portions before logging.
            </div>
          )}
        </CardBody>
      </Card>
      )}

      {!isEdit && (
      <Card>
        <CardHeader
          title="From a description"
          subtitle="just type what you ate"
        />
        <CardBody>
          <Textarea
            rows={3}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="e.g. 4 eggs with olive oil, glass of OJ, pound of chicken breast, half a cup of instant rice, 6 toll house mini cookies"
          />
          <div className="flex items-center gap-3 mt-3">
            <Button
              variant="primary"
              onClick={onAnalyzeDescription}
              disabled={analyzingText || !description.trim()}
            >
              <Sparkles size={14} />
              {analyzingText ? "Analyzing…" : "Analyze"}
            </Button>
            <span className="text-xs text-muted">
              Estimates portions, looks up macros from USDA.
            </span>
          </div>
        </CardBody>
      </Card>
      )}

      {!isEdit && quickList.length > 0 && (
        <Card>
          <CardHeader title="Quick start" subtitle="from favorites and quick-access" />
          <CardBody>
            <div className="flex flex-wrap gap-1.5">
              {quickList.map((m) => (
                <Chip key={m.id} onClick={() => populateFromMeal(m)}>
                  {m.name}
                </Chip>
              ))}
            </div>
          </CardBody>
        </Card>
      )}

      <Card>
        <CardBody className="space-y-3">
          <Input
            label="Name"
            value={form.name}
            onChange={(e) => update("name", e.target.value)}
            placeholder="Greek yogurt with berries"
          />
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <Input
              label="Date"
              type="date"
              value={form.date}
              onChange={(e) => update("date", e.target.value)}
            />
            <Input
              label="Time"
              type="time"
              value={form.time_eaten}
              onChange={(e) => update("time_eaten", e.target.value)}
            />
            <label className="block col-span-2 md:col-span-1">
              <span className="block text-xs uppercase tracking-wide text-muted mb-1">
                Meal type
              </span>
              <select
                value={form.meal_type}
                onChange={(e) => update("meal_type", e.target.value)}
                className="w-full rounded px-3 py-2"
                style={{
                  background: "var(--surface)",
                  color: "var(--text)",
                  border: "1px solid var(--border)",
                }}
              >
                {["breakfast", "lunch", "dinner", "snack"].map((t) => (
                  <option key={t}>{t}</option>
                ))}
              </select>
            </label>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <Input
              label="Calories"
              type="number"
              value={form.calories}
              onChange={(e) => update("calories", e.target.value)}
            />
            <Input
              label="Protein"
              type="number"
              step="0.1"
              value={form.protein}
              onChange={(e) => update("protein", e.target.value)}
            />
            <Input
              label="Carbs"
              type="number"
              step="0.1"
              value={form.carbs}
              onChange={(e) => update("carbs", e.target.value)}
            />
            <Input
              label="Fat"
              type="number"
              step="0.1"
              value={form.fat}
              onChange={(e) => update("fat", e.target.value)}
            />
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardHeader title="Ingredients" subtitle="optional" />
        <CardBody>
          {form.ingredients.length === 0 && (
            <div className="text-sm text-muted mb-2">
              Add ingredients to track your food library.
            </div>
          )}
          <div className="space-y-2">
            {form.ingredients.map((ing, i) => (
              <div
                key={i}
                className="flex flex-col md:flex-row md:items-end gap-2 pb-2 md:pb-0 border-b md:border-0"
                style={{ borderColor: "var(--border)" }}
              >
                <div className="md:flex-1">
                  <Input
                    value={ing.name}
                    placeholder="rolled oats"
                    onChange={(e) => updateIngredient(i, "name", e.target.value)}
                  />
                </div>
                <div className="flex gap-2 items-end">
                  <Input
                    className="w-24 md:w-28"
                    value={ing.amount}
                    placeholder="60"
                    type="number"
                    onChange={(e) => updateIngredient(i, "amount", e.target.value)}
                  />
                  <Input
                    className="w-20"
                    value={ing.unit}
                    placeholder="g"
                    onChange={(e) => updateIngredient(i, "unit", e.target.value)}
                  />
                  <button
                    onClick={() =>
                      setForm((f) => ({
                        ...f,
                        ingredients: f.ingredients.filter((_, j) => j !== i),
                      }))
                    }
                    className="text-muted hover:text-bad p-2.5 ml-auto"
                    aria-label="Remove ingredient"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
          <Button
            variant="ghost"
            size="sm"
            className="mt-3"
            onClick={() =>
              setForm((f) => ({
                ...f,
                ingredients: [...f.ingredients, { name: "", amount: "", unit: "" }],
              }))
            }
          >
            <Plus size={12} /> Add ingredient
          </Button>
        </CardBody>
      </Card>

      {error && <div className="text-sm text-bad">{error}</div>}

      <div className="flex gap-2">
        <Button
          variant="primary"
          onClick={save}
          disabled={saving || loading || locked}
        >
          {saving ? "Saving…" : isEdit ? "Save changes" : "Log meal"}
        </Button>
        <Button variant="ghost" onClick={() => navigate("/eat")}>
          {locked ? "Back" : "Cancel"}
        </Button>
      </div>

      {analysis?.analysis_id && (
        <RefineChat
          analysisId={analysis.analysis_id}
          onUpdate={applyAnalysisToForm}
          onDismiss={() => setAnalysis((a) => (a ? { ...a, analysis_id: null } : a))}
        />
      )}
    </div>
  );
};
