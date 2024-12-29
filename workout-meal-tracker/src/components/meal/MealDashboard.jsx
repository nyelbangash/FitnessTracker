// src/components/meal/MealDashboard.jsx
import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import * as api from "../../api";
import { Plus, Barcode } from "lucide-react";

const ProgressBar = ({ label, current, max, color = "bg-stone-800" }) => {
  const percentage = Math.min(Math.round((current / max) * 100), 100);

  return (
    <div>
      <div className="flex justify-between text-sm mb-1">
        <span className="font-serif">{label}</span>
        <span className="font-mono">{percentage}%</span>
      </div>
      <div className="h-2 bg-stone-100 rounded-full">
        <div
          className={`h-full rounded-full ${color}`}
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  );
};

export const MealDashboard = () => {
  const [dailyStats, setDailyStats] = useState(null);
  const [goals, setGoals] = useState(null);
  const navigate = useNavigate();
  const { user } = useAuth();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const today = new Date().toISOString().split("T")[0];
        const [dailyData, goalsData] = await Promise.all([
          api.getDailyNutrition(user.username, today),
          api.getNutritionGoals(user.username),
        ]);
        setDailyStats(dailyData);
        setGoals(goalsData);
      } catch (error) {
        console.error("Failed to fetch nutrition data:", error);
      }
    };
    fetchData();
  }, [user.username]);

  if (!dailyStats || !goals) return <div>Loading...</div>;

  return (
    <div className="min-h-screen bg-stone-50 text-stone-800 p-6">
      {/* Header */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-4">
          <h1 className="font-serif text-3xl">Today's Nutrition</h1>
          <span className="font-mono text-sm text-stone-500">
            {new Date().toLocaleDateString("en-US", {
              month: "long",
              day: "numeric",
              year: "numeric",
            })}
          </span>
        </div>

        {/* Daily Progress */}
        <div className="bg-white border border-stone-200 rounded-lg p-6 mb-6">
          <div className="grid grid-cols-4 gap-6 mb-6">
            <div>
              <p className="font-serif text-sm text-stone-500">Calories</p>
              <p className="font-mono text-2xl">{dailyStats.calories}</p>
              <p className="text-sm text-stone-500">of {goals.calories}</p>
            </div>
            <div>
              <p className="font-serif text-sm text-stone-500">Protein</p>
              <p className="font-mono text-2xl">{dailyStats.protein}g</p>
              <p className="text-sm text-stone-500">of {goals.protein}g</p>
            </div>
            <div>
              <p className="font-serif text-sm text-stone-500">Carbs</p>
              <p className="font-mono text-2xl">{dailyStats.carbs}g</p>
              <p className="text-sm text-stone-500">of {goals.carbs}g</p>
            </div>
            <div>
              <p className="font-serif text-sm text-stone-500">Fat</p>
              <p className="font-mono text-2xl">{dailyStats.fat}g</p>
              <p className="text-sm text-stone-500">of {goals.fat}g</p>
            </div>
          </div>

          {/* Progress Bars */}
          <div className="space-y-4">
            <ProgressBar
              label="Daily Calories"
              current={dailyStats.calories}
              max={goals.calories}
            />
            <ProgressBar
              label="Protein Goal"
              current={dailyStats.protein}
              max={goals.protein}
              color="bg-red-700"
            />
            <ProgressBar
              label="Carbs Goal"
              current={dailyStats.carbs}
              max={goals.carbs}
              color="bg-amber-700"
            />
            <ProgressBar
              label="Fat Goal"
              current={dailyStats.fat}
              max={goals.fat}
              color="bg-green-700"
            />
          </div>
        </div>
      </div>

      {/* Meal Log */}
      <div className="bg-white border border-stone-200 rounded-lg p-6 mb-6">
        <div className="flex justify-between items-center mb-6">
          <h2 className="font-serif text-xl">Today's Meals</h2>
          <button
            onClick={() => navigate("/meals/log")}
            className="px-4 py-2 bg-stone-800 text-white rounded-lg text-sm 
              hover:bg-stone-700 transition-colors"
          >
            Log Meal
          </button>
        </div>

        {/* Meal Entries */}
        <div className="space-y-6">
          {dailyStats.meals.map((meal, index) => (
            <div
              key={index}
              className="border-b border-stone-100 last:border-0 pb-4"
            >
              <div className="flex justify-between items-start mb-3">
                <div>
                  <h3 className="font-serif text-lg">{meal.name}</h3>
                  <p className="font-mono text-sm text-stone-500">
                    {meal.time}
                  </p>
                </div>
                <span className="font-mono bg-stone-100 px-3 py-1 rounded">
                  {meal.calories} cal
                </span>
              </div>

              <div className="grid grid-cols-3 gap-4 mb-3">
                <div className="text-sm">
                  <span className="text-stone-500">Protein:</span>
                  <span className="font-mono ml-2">{meal.macros.protein}g</span>
                </div>
                <div className="text-sm">
                  <span className="text-stone-500">Carbs:</span>
                  <span className="font-mono ml-2">{meal.macros.carbs}g</span>
                </div>
                <div className="text-sm">
                  <span className="text-stone-500">Fat:</span>
                  <span className="font-mono ml-2">{meal.macros.fat}g</span>
                </div>
              </div>

              <div className="flex flex-wrap gap-2">
                {meal.ingredients.map((item, i) => (
                  <span
                    key={i}
                    className="text-xs bg-stone-100 px-2 py-1 rounded"
                  >
                    {item}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Quick Add Section */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <button
          onClick={() => navigate("/meals/quick-add")}
          className="bg-white border border-stone-200 rounded-lg p-4 text-left 
            hover:border-stone-300 transition-colors group"
        >
          <div className="flex items-center gap-2">
            <div className="p-2 bg-stone-100 rounded-lg group-hover:bg-stone-200 transition-colors">
              <Plus className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-serif text-lg mb-1">Quick Add Meal</h3>
              <p className="text-sm text-stone-500">
                Use a previous meal template
              </p>
            </div>
          </div>
        </button>
        <button
          onClick={() => navigate("/meals/scan")}
          className="bg-white border border-stone-200 rounded-lg p-4 text-left 
            hover:border-stone-300 transition-colors group"
        >
          <div className="flex items-center gap-2">
            <div className="p-2 bg-stone-100 rounded-lg group-hover:bg-stone-200 transition-colors">
              <Barcode className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-serif text-lg mb-1">Scan Barcode</h3>
              <p className="text-sm text-stone-500">
                Quickly add packaged foods
              </p>
            </div>
          </div>
        </button>
      </div>

      {/* Recent Favorites */}
      <div className="bg-white border border-stone-200 rounded-lg p-6">
        <h2 className="font-serif text-lg mb-4">Recent Favorites</h2>
        <div className="grid grid-cols-2 gap-4">
          {[
            "Protein Smoothie (350 cal)",
            "Chicken & Rice (450 cal)",
            "Post-Workout Shake (220 cal)",
            "Greek Salad (380 cal)",
          ].map((item, index) => (
            <button
              key={index}
              className="p-3 border border-stone-100 rounded text-left
                hover:border-stone-300 transition-colors"
            >
              <span className="font-serif">{item}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};
