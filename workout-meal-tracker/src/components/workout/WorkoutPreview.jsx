import React from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { api } from "../../api";

export const WorkoutPreview = () => {
  const navigate = useNavigate();
  useAuth();

  const handleStartWorkout = async () => {
    try {
      navigate("/workout/active");
    } catch (error) {
      console.error("Failed to start workout:", error);
    }
  };

  return (
    <div className="min-h-screen bg-stone-50 text-stone-800 p-6">
      {/* Header */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-4">
          <h1 className="font-serif text-3xl">Upper Body</h1>
          <span className="font-mono text-sm text-stone-500">
            December 28, 2024
          </span>
        </div>
        <p className="font-serif text-stone-500">
          Estimated Duration: 65 minutes
        </p>
      </div>

      {/* Exercise List */}
      <div className="mb-8 bg-white border border-stone-200 rounded-lg p-6">
        <h2 className="font-serif text-xl mb-6">Workout Overview</h2>

        <div className="space-y-6">
          {[
            { name: "DB Incline", sets: "2 × 4-8", note: "Last: 65 lbs × 8" },
            { name: "Chest Press", sets: "1 × 4-8", note: "Last: 185 lbs × 6" },
            {
              name: "Tricep Rope Unilateral",
              sets: "2 × 4-8",
              note: "Last: 45 lbs × 8",
            },
            {
              name: "Lateral Raise Unilateral",
              sets: "2 × 4-8",
              note: "Last: 20 lbs × 8",
            },
            {
              name: "Tricep EZ Bar Pushdown",
              sets: "1 × 4-8",
              note: "Last: 75 lbs × 7",
            },
            {
              name: "Alternate T-bar Row",
              sets: "2 × 4-8",
              note: "Last: 90 lbs × 8",
            },
            {
              name: "Tricep Dip Machine",
              sets: "1 × 4-8",
              note: "Last: 160 lbs × 6",
            },
            {
              name: "Bicep Curl Machine",
              sets: "1 × 4-8",
              note: "Last: 95 lbs × 8",
            },
          ].map((exercise, index) => (
            <div
              key={index}
              className="border-b border-stone-100 last:border-0 pb-4 last:pb-0"
            >
              <div className="flex justify-between items-start mb-1">
                <h3 className="font-serif text-lg">{exercise.name}</h3>
                <span className="font-mono text-sm bg-stone-100 px-3 py-1 rounded">
                  {exercise.sets}
                </span>
              </div>
              <p className="text-sm text-stone-500 font-mono">
                {exercise.note}
              </p>
            </div>
          ))}
        </div>
      </div>

      {/* Stats Summary */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        <div className="bg-white border border-stone-200 rounded-lg p-4">
          <p className="font-serif text-sm text-stone-500">Total Sets</p>
          <p className="font-mono text-2xl">12</p>
        </div>
        <div className="bg-white border border-stone-200 rounded-lg p-4">
          <p className="font-serif text-sm text-stone-500">Volume Goal</p>
          <p className="font-mono text-2xl">15,750 lbs</p>
        </div>
        <div className="bg-white border border-stone-200 rounded-lg p-4">
          <p className="font-serif text-sm text-stone-500">Target RPE</p>
          <p className="font-mono text-2xl">7-8</p>
        </div>
      </div>

      {/* Start Button */}
      <button
        onClick={handleStartWorkout}
        className="w-full bg-stone-800 text-white font-serif py-4 rounded-lg text-lg"
      >
        Begin Workout
      </button>

      {/* Notes */}
      <div className="mt-6 bg-white border border-stone-200 rounded-lg p-4">
        <p className="font-serif text-sm text-stone-500">Last Workout Notes</p>
        <p className="font-serif text-sm mt-2">
          Focus on controlled negatives for tricep exercises. Increase DB
          Incline weight if RPE below 7.
        </p>
      </div>
    </div>
  );
};
