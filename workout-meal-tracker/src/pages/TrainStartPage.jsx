import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Play, Plus } from "lucide-react";
import { Card, CardHeader, CardBody, Button, Chip } from "../ui";
import * as api from "../api";

export const TrainStartPage = () => {
  const navigate = useNavigate();
  const [active, setActive] = useState(null);
  const [templates, setTemplates] = useState([]);
  const [starting, setStarting] = useState(null);

  useEffect(() => {
    (async () => {
      const [a, t] = await Promise.all([
        api.getActiveWorkout().catch(() => null),
        api.getWorkoutTemplates().catch(() => []),
      ]);
      setActive(a);
      setTemplates(t || []);
    })();
  }, []);

  const start = async (name) => {
    setStarting(name);
    try {
      await api.startWorkout(null, name);
      navigate("/train/active");
    } finally {
      setStarting(null);
    }
  };

  return (
    <div className="space-y-6">
      {active && (
        <Card>
          <CardBody className="flex items-center justify-between">
            <div>
              <div className="text-xs uppercase tracking-widest text-muted">
                In progress
              </div>
              <div className="font-serif-h text-xl mt-0.5">{active.workout_name}</div>
            </div>
            <Button variant="primary" onClick={() => navigate("/train/active")}>
              <Play size={14} /> Resume
            </Button>
          </CardBody>
        </Card>
      )}

      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-xl">Templates</h2>
          <Button onClick={() => navigate("/train/templates/new")}>
            <Plus size={14} /> New template
          </Button>
        </div>

        {templates.length === 0 ? (
          <Card>
            <CardBody>
              <div className="text-sm text-muted">
                No templates yet. Create one to get started.
              </div>
            </CardBody>
          </Card>
        ) : (
          <div className="grid md:grid-cols-2 gap-3">
            {templates.map((t) => (
              <Card key={t.id}>
                <CardHeader title={t.name} />
                <CardBody>
                  <div className="flex flex-wrap gap-1.5">
                    {(t.exercises?.items || []).map((ex, i) => (
                      <Chip key={i} tone="muted">
                        {ex.exercise_name}{" "}
                        <span className="num text-[10px] text-muted">
                          ×{ex.target_sets || 3}
                        </span>
                      </Chip>
                    ))}
                  </div>
                  <div className="mt-4 flex gap-2">
                    <Button
                      variant="primary"
                      size="sm"
                      disabled={starting === t.name || !!active}
                      onClick={() => start(t.name)}
                    >
                      <Play size={12} />
                      {starting === t.name ? "Starting…" : "Start"}
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => navigate(`/train/templates/${encodeURIComponent(t.name)}`)}
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
    </div>
  );
};
