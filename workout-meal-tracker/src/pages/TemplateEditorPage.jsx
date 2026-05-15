import React, { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Plus, Trash2, ArrowLeft } from "lucide-react";
import { Card, CardBody, CardHeader, Button, Input } from "../ui";
import * as api from "../api";

const emptyExercise = () => ({
  exercise_name: "",
  target_reps: 5,
  target_weight: 0,
  target_sets: 3,
  rest_time: 90,
  rpe_target: 8,
});

export const TemplateEditorPage = () => {
  const { templateName } = useParams();
  const navigate = useNavigate();
  const isNew = !templateName;

  const [name, setName] = useState(templateName || "");
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(!isNew);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isNew) {
      setItems([emptyExercise()]);
      return;
    }
    (async () => {
      const ts = await api.getWorkoutTemplates().catch(() => []);
      const t = ts.find((x) => x.name === templateName);
      if (t) {
        setName(t.name);
        setItems(t.exercises?.items || []);
      }
      setLoading(false);
    })();
  }, [templateName, isNew]);

  const save = async () => {
    if (!name.trim()) {
      setError("Name is required");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      if (isNew) {
        await api.createWorkoutTemplate({
          name,
          exercises: { items },
        });
      } else {
        await api.saveWorkoutTemplate(null, templateName, {
          name,
          exercises: { items },
        });
      }
      navigate("/train/templates");
    } catch (e) {
      setError(e?.response?.data?.errors ? "Could not save (see fields)" : "Could not save");
    } finally {
      setSaving(false);
    }
  };

  const update = (i, key, value) => {
    setItems((prev) => {
      const next = [...prev];
      next[i] = { ...next[i], [key]: value };
      return next;
    });
  };

  if (loading) return <div className="text-muted text-sm">Loading…</div>;

  return (
    <div className="max-w-3xl space-y-5">
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate("/train/templates")}
          className="text-muted hover:text-fg"
        >
          <ArrowLeft size={16} />
        </button>
        <h2 className="text-2xl">{isNew ? "New template" : "Edit template"}</h2>
      </div>

      <Card>
        <CardBody>
          <Input
            label="Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Push Day"
          />
        </CardBody>
      </Card>

      <div className="space-y-3">
        {items.map((item, i) => (
          <Card key={i}>
            <CardHeader
              title={`Exercise ${i + 1}`}
              action={
                <button
                  onClick={() =>
                    setItems((prev) => prev.filter((_, j) => j !== i))
                  }
                  className="text-muted hover:text-bad"
                >
                  <Trash2 size={14} />
                </button>
              }
            />
            <CardBody className="space-y-3">
              <Input
                label="Name"
                value={item.exercise_name}
                onChange={(e) => update(i, "exercise_name", e.target.value)}
                placeholder="Bench Press"
              />
              <div className="grid grid-cols-5 gap-3">
                <Input
                  label="Sets"
                  type="number"
                  min="1"
                  value={item.target_sets}
                  onChange={(e) => update(i, "target_sets", parseInt(e.target.value, 10))}
                />
                <Input
                  label="Reps"
                  type="number"
                  min="1"
                  value={item.target_reps}
                  onChange={(e) => update(i, "target_reps", parseInt(e.target.value, 10))}
                />
                <Input
                  label="Weight"
                  type="number"
                  step="2.5"
                  value={item.target_weight}
                  onChange={(e) => update(i, "target_weight", parseFloat(e.target.value))}
                />
                <Input
                  label="Rest (s)"
                  type="number"
                  value={item.rest_time}
                  onChange={(e) => update(i, "rest_time", parseInt(e.target.value, 10))}
                />
                <Input
                  label="RPE"
                  type="number"
                  step="0.5"
                  min="1"
                  max="10"
                  value={item.rpe_target}
                  onChange={(e) => update(i, "rpe_target", parseFloat(e.target.value))}
                />
              </div>
            </CardBody>
          </Card>
        ))}

        <Button
          variant="ghost"
          onClick={() => setItems((prev) => [...prev, emptyExercise()])}
        >
          <Plus size={14} /> Add exercise
        </Button>
      </div>

      {error && <div className="text-sm text-bad">{error}</div>}

      <div className="flex gap-2">
        <Button variant="primary" onClick={save} disabled={saving}>
          {saving ? "Saving…" : "Save template"}
        </Button>
        <Button variant="ghost" onClick={() => navigate("/train/templates")}>
          Cancel
        </Button>
      </div>
    </div>
  );
};
