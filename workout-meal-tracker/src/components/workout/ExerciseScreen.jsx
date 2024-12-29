// src/components/workout/ExerciseScreen.jsx
import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import * as api from "../../api";

export const ExerciseScreen = () => {
  const [workout, setWorkout] = useState(null);
  const [weight, setWeight] = useState("");
  const [reps, setReps] = useState("");
  const [rpe, setRpe] = useState(null);
  const [notes, setNotes] = useState("");
  const [restTimer, setRestTimer] = useState(0);
  const navigate = useNavigate();
  const { user } = useAuth();

  useEffect(() => {
    const fetchWorkout = async () => {
      try {
        const data = await api.getActiveWorkout(user.username);
        setWorkout(data);
        // Initialize weight and reps from target
        const currentExercise = data.exercises[data.current_exercise];
        setWeight(currentExercise.target_weight?.toString() || "");
        setReps(currentExercise.target_reps?.toString() || "");
        setNotes(currentExercise.notes || "");
      } catch (error) {
        console.error("Failed to fetch workout:", error);
      }
    };
    fetchWorkout();
  }, [user.username]);

  useEffect(() => {
    if (!workout?.rest_timer_end) return;

    const interval = setInterval(() => {
      const remaining = Math.max(
        0,
        Math.floor((new Date(workout.rest_timer_end) - Date.now()) / 1000)
      );
      setRestTimer(remaining);
      if (remaining === 0) clearInterval(interval);
    }, 1000);

    return () => clearInterval(interval);
  }, [workout?.rest_timer_end]);

  if (!workout) return <div>Loading...</div>;

  const currentExercise = workout.exercises[workout.current_exercise];
  const previousSet =
    workout.current_set > 0
      ? currentExercise.sets[workout.current_set - 1]
      : null;
  const lastWeekWeight = currentExercise.previous_weight;
  const weightDiff = lastWeekWeight ? Number(weight) - lastWeekWeight : 0;

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
  };

  const handleCompleteSet = async () => {
    if (!weight || !reps || !rpe) {
      alert("Please fill in all fields");
      return;
    }

    try {
      // Save notes if they've changed
      if (notes !== currentExercise.notes) {
        await api.updateWorkoutNotes(user.username, notes);
      }

      await api.completeSet(user.username, {
        weight: Number(weight),
        reps: Number(reps),
        rpe,
      });

      navigate("/workout/active");
    } catch (error) {
      console.error("Failed to complete set:", error);
    }
  };

  return (
    <div className="min-h-screen bg-stone-50 text-stone-800 p-6">
      {/* Top Bar */}
      <div className="flex justify-between items-center mb-8">
        <h1 className="font-serif text-2xl">{currentExercise.exercise_name}</h1>
        <div className="text-right">
          <p className="font-serif text-sm text-stone-500">
            Set {workout.current_set + 1} of {currentExercise.sets.length}
          </p>
          <p className="font-mono text-xl">{formatTime(restTimer)}</p>
        </div>
      </div>

      {/* Current Set Card */}
      <div className="bg-white border border-stone-200 rounded-lg p-6 mb-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="font-serif text-xl">Current Set</h2>
          {restTimer > 0 && (
            <span className="font-mono text-sm text-stone-500">
              {formatTime(restTimer)} Rest
            </span>
          )}
        </div>

        <div className="grid grid-cols-2 gap-4 mb-6">
          <div>
            <p className="font-serif text-sm text-stone-500">Target Weight</p>
            <p className="font-mono text-2xl">
              {currentExercise.target_weight} lbs
            </p>
            {weightDiff !== 0 && (
              <p
                className={`text-xs ${
                  weightDiff > 0 ? "text-emerald-600" : "text-red-600"
                }`}
              >
                {weightDiff > 0 ? "+" : ""}
                {weightDiff} lbs from last week
              </p>
            )}
          </div>
          <div>
            <p className="font-serif text-sm text-stone-500">Target Reps</p>
            <p className="font-mono text-2xl">{currentExercise.target_reps}</p>
            {previousSet && (
              <p className="text-xs text-stone-500">
                Previous: {previousSet.reps} reps @ {previousSet.weight} lbs
              </p>
            )}
          </div>
        </div>
        <div className="border-t border-stone-100 pt-4">
          <p className="font-serif text-sm text-stone-500 mb-2">
            Previous Performance
          </p>
          <div className="flex justify-between text-sm">
            <span>
              Last Week: {lastWeekWeight} lbs ×{" "}
              {currentExercise.previous_reps || "-"}
            </span>
            {currentExercise.personal_record && (
              <span>
                PR: {currentExercise.personal_record.weight} lbs ×{" "}
                {currentExercise.personal_record.reps}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Input Section */}
      <div className="bg-white border border-stone-200 rounded-lg p-6 mb-6">
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div>
            <label className="font-serif text-sm text-stone-500">
              Weight Achieved
            </label>
            <input
              type="number"
              className="w-full font-mono text-2xl bg-stone-50 border border-stone-200 rounded p-2"
              value={weight}
              onChange={(e) => setWeight(e.target.value)}
              placeholder={currentExercise.target_weight?.toString()}
            />
          </div>
          <div>
            <label className="font-serif text-sm text-stone-500">
              Reps Completed
            </label>
            <input
              type="number"
              className="w-full font-mono text-2xl bg-stone-50 border border-stone-200 rounded p-2"
              value={reps}
              onChange={(e) => setReps(e.target.value)}
              placeholder={currentExercise.target_reps?.toString()}
            />
          </div>
        </div>

        <div className="mb-4">
          <label className="font-serif text-sm text-stone-500">
            RPE (Rate of Perceived Exertion)
          </label>
          <div className="flex justify-between mt-2">
            {[6, 7, 8, 9, 10].map((value) => (
              <button
                key={value}
                onClick={() => setRpe(value)}
                className={`w-10 h-10 rounded-full font-mono transition-colors
                  ${
                    rpe === value
                      ? "bg-stone-800 text-white"
                      : "bg-stone-100 hover:bg-stone-200"
                  }`}
              >
                {value}
              </button>
            ))}
          </div>
        </div>

        <button
          onClick={handleCompleteSet}
          className="w-full bg-stone-800 text-white font-serif py-3 rounded hover:bg-stone-700 
            transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          disabled={!weight || !reps || !rpe}
        >
          Complete Set
        </button>
      </div>

      {/* Notes Section */}
      <div className="bg-white border border-stone-200 rounded-lg p-6">
        <h3 className="font-serif text-lg mb-2">Form Notes</h3>
        <textarea
          className="w-full h-24 bg-stone-50 border border-stone-200 rounded p-2 
            font-serif text-sm resize-none"
          placeholder="Add notes about form, feeling, or areas for improvement..."
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
        />
      </div>
    </div>
  );
};
