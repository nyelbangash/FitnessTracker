// src/components/meal/MealStats.jsx
import React from "react";
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from "recharts";

export const MealStats = ({ dailyStats, weeklyStats, goals }) => {
  // Calculate macro percentages
  const totalCals =
    dailyStats.protein * 4 + dailyStats.carbs * 4 + dailyStats.fat * 9;
  const macroData = [
    { name: "Protein", value: ((dailyStats.protein * 4) / totalCals) * 100 },
    { name: "Carbs", value: ((dailyStats.carbs * 4) / totalCals) * 100 },
    { name: "Fat", value: ((dailyStats.fat * 9) / totalCals) * 100 },
  ];

  const COLORS = ["#BE123C", "#CA8A04", "#15803D"];

  return (
    <div className="bg-white border border-stone-200 rounded-lg p-6">
      <h2 className="font-serif text-xl mb-6">Nutrition Stats</h2>

      <div className="grid grid-cols-2 gap-6">
        {/* Macro Distribution */}
        <div>
          <h3 className="font-serif text-lg mb-4">Macro Distribution</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={macroData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {macroData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index]} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(value) => `${value.toFixed(1)}%`}
                  contentStyle={{
                    backgroundColor: "white",
                    border: "1px solid #e5e7eb",
                    borderRadius: "0.5rem",
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="flex justify-center gap-6 text-sm">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-red-700" />
                <span>Protein</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-amber-700" />
                <span>Carbs</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-green-700" />
                <span>Fat</span>
              </div>
            </div>
          </div>
        </div>

        {/* Weekly Trends */}
        <div>
          <h3 className="font-serif text-lg mb-4">Weekly Trends</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={weeklyStats}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="date"
                  stroke="#78716c"
                  tick={{ fontSize: 12 }}
                />
                <YAxis stroke="#78716c" tick={{ fontSize: 12 }} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "white",
                    border: "1px solid #e5e7eb",
                    borderRadius: "0.5rem",
                  }}
                />
                <Line
                  type="monotone"
                  dataKey="calories"
                  stroke="#292524"
                  strokeWidth={2}
                  dot={{ fill: "#292524" }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Additional Stats */}
      <div className="grid grid-cols-3 gap-4 mt-6">
        <div className="p-4 border border-stone-200 rounded-lg">
          <h4 className="font-serif text-sm text-stone-500 mb-1">
            Average Calories
          </h4>
          <p className="font-mono text-2xl">
            {Math.round(
              weeklyStats.reduce((acc, day) => acc + day.calories, 0) /
                weeklyStats.length
            )}
          </p>
          <p className="text-sm text-stone-500">Past 7 days</p>
        </div>

        <div className="p-4 border border-stone-200 rounded-lg">
          <h4 className="font-serif text-sm text-stone-500 mb-1">
            Goal Progress
          </h4>
          <p className="font-mono text-2xl">
            {Math.round((dailyStats.calories / goals.calories) * 100)}%
          </p>
          <p className="text-sm text-stone-500">of daily goal</p>
        </div>

        <div className="p-4 border border-stone-200 rounded-lg">
          <h4 className="font-serif text-sm text-stone-500 mb-1">
            Protein Ratio
          </h4>
          <p className="font-mono text-2xl">
            {(dailyStats.protein / (dailyStats.weight * 0.8)).toFixed(1)}
          </p>
          <p className="text-sm text-stone-500">g/lb bodyweight</p>
        </div>
      </div>

      {/* Meal Timing */}
      <div className="mt-6">
        <h3 className="font-serif text-lg mb-4">Meal Timing</h3>
        <div className="relative h-12 bg-stone-100 rounded-lg overflow-hidden">
          {dailyStats.meals.map((meal, index) => {
            const timeInMinutes = timeToMinutes(meal.time);
            const position = (timeInMinutes / 1440) * 100;
            const width = (meal.calories / dailyStats.calories) * 100;

            return (
              <div
                key={index}
                className="absolute h-full bg-stone-800"
                style={{
                  left: `${position}%`,
                  width: `${width}%`,
                  opacity: 0.8,
                }}
                title={`${meal.name} - ${meal.calories} cal at ${meal.time}`}
              />
            );
          })}

          {/* Time markers */}
          {[0, 6, 12, 18, 24].map((hour) => (
            <div
              key={hour}
              className="absolute top-0 h-full border-l border-stone-300"
              style={{ left: `${(hour / 24) * 100}%` }}
            >
              <span className="absolute -top-6 left-1 text-xs text-stone-500">
                {hour === 24 ? "24:00" : `${hour}:00`}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const timeToMinutes = (timeStr) => {
  const [hours, minutes] = timeStr.split(":").map(Number);
  return hours * 60 + minutes;
};
