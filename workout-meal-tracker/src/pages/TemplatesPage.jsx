import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, Trash2 } from "lucide-react";
import { Card, CardBody, CardHeader, Button } from "../ui";
import * as api from "../api";

export const TemplatesPage = () => {
  const navigate = useNavigate();
  const [templates, setTemplates] = useState(null);

  const load = async () => {
    const t = await api.getWorkoutTemplates().catch(() => []);
    setTemplates(t);
  };

  useEffect(() => {
    load();
  }, []);

  const del = async (name) => {
    if (!window.confirm(`Delete template "${name}"?`)) return;
    await api.deleteWorkoutTemplate(null, name);
    load();
  };

  if (!templates) return <div className="text-muted text-sm">Loading…</div>;

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Button onClick={() => navigate("/train/templates/new")}>
          <Plus size={14} /> New template
        </Button>
      </div>
      {templates.length === 0 ? (
        <Card>
          <CardBody>
            <div className="text-sm text-muted">
              No templates yet. Create one to start tracking workouts.
            </div>
          </CardBody>
        </Card>
      ) : (
        <div className="grid md:grid-cols-2 gap-3">
          {templates.map((t) => (
            <Card key={t.id}>
              <CardHeader
                title={t.name}
                action={
                  <button
                    onClick={() => del(t.name)}
                    className="text-muted hover:text-bad"
                    title="Delete"
                  >
                    <Trash2 size={14} />
                  </button>
                }
              />
              <CardBody>
                <div className="space-y-1.5">
                  {(t.exercises?.items || []).map((ex, i) => (
                    <div key={i} className="text-sm flex items-baseline gap-2">
                      <span>{ex.exercise_name}</span>
                      <span className="text-muted num text-xs">
                        {ex.target_sets || 3} × {ex.target_reps} @{" "}
                        {ex.target_weight}
                      </span>
                    </div>
                  ))}
                </div>
                <div className="mt-3">
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() =>
                      navigate(`/train/templates/${encodeURIComponent(t.name)}`)
                    }
                  >
                    Edit
                  </Button>
                </div>
              </CardBody>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
};
