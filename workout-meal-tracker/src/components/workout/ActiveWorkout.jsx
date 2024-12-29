import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import * as api from "../../api";

export const ActiveWorkout = () => {
  const [workout, setWorkout] = useState(null);
  const [timer, setTimer] = useState(0);
  const { user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    const fetchWorkout = async () => {
      try {
        const data = await api.getActiveWorkout(user.username);
        setWorkout(data);
        setTimer(Math.floor((Date.now() - new Date(data.start_time)) / 1000));
      } catch (error) {
        console.error("Failed to fetch workout:", error);
      }
    };
    fetchWorkout();
  }, [user.username]);

  useEffect(() => {
    const interval = setInterval(() => {
      setTimer((t) => t + 1);
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
  };

  const handleEndWorkout = async () => {
    try {
      await api.endWorkout(user.username);
      navigate("/workouts");
    } catch (error) {
      console.error("Failed to end workout:", error);
    }
  };

  if (!workout) return <div>Loading...</div>;

  const currentExercise = workout.exercises[workout.current_exercise];

  return (
    <div className="min-h-screen bg-stone-50 text-stone-800 p-6">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="font-serif text-2xl">{workout.workout_name}</h1>
          <p className="font-mono text-sm text-stone-500">
            In Progress - {formatTime(timer)}
          </p>
        </div>
        <button
          onClick={handleEndWorkout}
          className="px-4 py-2 border border-red-200 text-red-600 rounded-lg text-sm"
        >
          End Workout
        </button>
      </div>

      {/* Current Exercise */}
      <div className="bg-white border border-stone-200 rounded-lg p-6 mb-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="font-serif text-xl">
            {currentExercise.exercise_name}
          </h2>
          <span className="font-mono text-sm bg-stone-800 text-white px-3 py-1 rounded">
            Set {workout.current_set + 1}/{currentExercise.sets.length}
          </span>
        </div>
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div>
            <p className="font-serif text-sm text-stone-500">Target</p>
            <p className="font-mono text-2xl">
              {currentExercise.target_weight} lbs ×{" "}
              {currentExercise.target_reps}
            </p>
          </div>
          <div>
            <p className="font-serif text-sm text-stone-500">Rest Timer</p>
            <p className="font-mono text-2xl text-blue-600">
              {workout.rest_timer_end
                ? formatTime(
                    Math.max(
                      0,
                      Math.floor(
                        (new Date(workout.rest_timer_end) - Date.now()) / 1000
                      )
                    )
                  )
                : "--:--"}
            </p>
          </div>
        </div>
        <button
          onClick={() =>
            navigate(`/workout/exercise/${workout.current_exercise}`)
          }
          className="w-full bg-stone-800 text-white font-serif py-3 rounded-lg mb-4"
        >
          Start Set
        </button>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-white border border-stone-200 rounded-lg p-4">
          <p className="font-serif text-sm text-stone-500">Sets Complete</p>
          <p className="font-mono text-xl">
            {workout.completed_sets}/{workout.total_sets}
          </p>
        </div>
        <div className="bg-white border border-stone-200 rounded-lg p-4">
          <p className="font-serif text-sm text-stone-500">Volume</p>
          <p className="font-mono text-xl">
            {workout.total_volume}/{workout.target_volume}
          </p>
        </div>
        <div className="bg-white border border-stone-200 rounded-lg p-4">
          <p className="font-serif text-sm text-stone-500">Avg RPE</p>
          <p className="font-mono text-xl">{workout.average_rpe || "--"}</p>
        </div>
      </div>
    </div>
  );
};
