// src/components/meal/MealLogging.jsx
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import * as api from "../../api";
import { Search, Barcode, Plus, Save } from "lucide-react";

const MEAL_TYPES = ["Breakfast", "Lunch", "Dinner", "Snack"];

export const MealLogging = () => {
  const [mealType, setMealType] = useState("Breakfast");
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedFoods, setSelectedFoods] = useState([]);
  const navigate = useNavigate();
  const { user } = useAuth();

  // Mock recent foods - in real app, fetch from API
  const recentFoods = [
    { name: "Chicken Breast", serving: "6 oz", calories: 180 },
    { name: "Brown Rice", serving: "1 cup", calories: 220 },
    { name: "Broccoli", serving: "1 cup", calories: 55 },
    { name: "Olive Oil", serving: "1 tbsp", calories: 120 },
  ];

  const handleAddFood = (food) => {
    setSelectedFoods([...selectedFoods, food]);
  };

  const handleRemoveFood = (index) => {
    setSelectedFoods(selectedFoods.filter((_, i) => i !== index));
  };

  const calculateTotals = () => {
    return selectedFoods.reduce(
      (acc, food) => ({
        calories: acc.calories + food.calories,
        protein: acc.protein + (food.protein || 0),
        carbs: acc.carbs + (food.carbs || 0),
        fat: acc.fat + (food.fat || 0),
      }),
      { calories: 0, protein: 0, carbs: 0, fat: 0 }
    );
  };

  const handleSaveMeal = async () => {
    const currentTime = new Date().toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
    });

    const mealData = {
      name: `${mealType} - ${currentTime}`,
      meal_type: mealType,
      time_eaten: currentTime,
      date: new Date().toISOString().split("T")[0],
      ...calculateTotals(),
      ingredients: selectedFoods.map((food) => ({ name: food.name })),
    };

    try {
      await api.addMeal(mealData);
      navigate("/meals");
    } catch (error) {
      console.error("Failed to save meal:", error);
    }
  };

  return (
    <div className="min-h-screen bg-stone-50 text-stone-800 p-6">
      {/* Header */}
      <div className="flex justify-between items-center mb-8">
        <h1 className="font-serif text-2xl">Log Meal</h1>
        <button
          onClick={() => navigate("/meals")}
          className="text-stone-500 hover:text-stone-700 transition-colors"
        >
          Cancel
        </button>
      </div>

      {/* Meal Type Selection */}
      <div className="bg-white border border-stone-200 rounded-lg p-6 mb-6">
        <div className="grid grid-cols-4 gap-3">
          {MEAL_TYPES.map((type) => (
            <button
              key={type}
              onClick={() => setMealType(type)}
              className={`p-3 rounded-lg text-center font-serif transition-colors
                ${
                  mealType === type
                    ? "bg-stone-800 text-white"
                    : "border border-stone-200 hover:border-stone-300"
                }`}
            >
              {type}
            </button>
          ))}
        </div>
      </div>

      {/* Food Search & Recent */}
      <div className="bg-white border border-stone-200 rounded-lg p-6 mb-6">
        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-stone-400" />
          <input
            type="text"
            placeholder="Search foods..."
            className="w-full p-3 pl-10 bg-stone-50 border border-stone-200 rounded-lg 
              font-serif placeholder-stone-400 focus:outline-none focus:border-stone-300"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <h3 className="font-serif text-sm text-stone-500 mb-3">Recent Foods</h3>
        <div className="space-y-3">
          {recentFoods.map((food, index) => (
            <div
              key={index}
              className="flex justify-between items-center p-3 border border-stone-100 
                  rounded-lg hover:border-stone-200 transition-colors"
            >
              <div>
                <h4 className="font-serif">{food.name}</h4>
                <p className="text-sm text-stone-500">{food.serving}</p>
              </div>
              <div className="text-right">
                <p className="font-mono">{food.calories} cal</p>
                <button
                  onClick={() => handleAddFood(food)}
                  className="text-sm text-blue-600 hover:text-blue-700 transition-colors"
                >
                  Add
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Current Meal */}
      <div className="bg-white border border-stone-200 rounded-lg p-6 mb-6">
        <h2 className="font-serif text-lg mb-4">Current Meal</h2>
        <div className="space-y-4 mb-6">
          {selectedFoods.map((food, index) => (
            <div
              key={index}
              className="flex justify-between items-start p-3 border border-stone-100 rounded-lg"
            >
              <div>
                <div className="flex items-center gap-2">
                  <h4 className="font-serif">{food.name}</h4>
                  <span className="text-sm text-stone-500">{food.serving}</span>
                </div>
                <div className="flex gap-3 mt-1 text-sm text-stone-500">
                  <span>P: {food.protein || 0}g</span>
                  <span>C: {food.carbs || 0}g</span>
                  <span>F: {food.fat || 0}g</span>
                </div>
              </div>
              <div className="text-right">
                <p className="font-mono">{food.calories} cal</p>
                <button
                  onClick={() => handleRemoveFood(index)}
                  className="text-sm text-red-600 hover:text-red-700 transition-colors"
                >
                  Remove
                </button>
              </div>
            </div>
          ))}

          {selectedFoods.length === 0 && (
            <div className="text-center py-8 text-stone-400">
              No foods added yet
            </div>
          )}
        </div>

        {/* Meal Totals */}
        {selectedFoods.length > 0 && (
          <div className="border-t border-stone-100 pt-4">
            <div className="grid grid-cols-4 gap-4 mb-6">
              <div>
                <p className="font-serif text-sm text-stone-500">
                  Total Calories
                </p>
                <p className="font-mono text-xl">
                  {calculateTotals().calories}
                </p>
              </div>
              <div>
                <p className="font-serif text-sm text-stone-500">Protein</p>
                <p className="font-mono text-xl">
                  {calculateTotals().protein}g
                </p>
              </div>
              <div>
                <p className="font-serif text-sm text-stone-500">Carbs</p>
                <p className="font-mono text-xl">{calculateTotals().carbs}g</p>
              </div>
              <div>
                <p className="font-serif text-sm text-stone-500">Fat</p>
                <p className="font-mono text-xl">{calculateTotals().fat}g</p>
              </div>
            </div>

            <button
              onClick={handleSaveMeal}
              className="w-full bg-stone-800 text-white font-serif py-3 rounded-lg
                  hover:bg-stone-700 transition-colors flex items-center justify-center gap-2"
            >
              <Save size={20} />
              Save Meal
            </button>
          </div>
        )}
      </div>

      {/* Quick Tools */}
      <div className="grid grid-cols-3 gap-4">
        <button
          className="bg-white border border-stone-200 rounded-lg p-4 text-center
              hover:border-stone-300 transition-colors group"
        >
          <div className="flex flex-col items-center gap-2">
            <div className="p-2 bg-stone-100 rounded-lg group-hover:bg-stone-200 transition-colors">
              <Barcode className="w-5 h-5" />
            </div>
            <p className="font-serif">Scan Barcode</p>
          </div>
        </button>
        <button
          className="bg-white border border-stone-200 rounded-lg p-4 text-center
              hover:border-stone-300 transition-colors group"
        >
          <div className="flex flex-col items-center gap-2">
            <div className="p-2 bg-stone-100 rounded-lg group-hover:bg-stone-200 transition-colors">
              <Plus className="w-5 h-5" />
            </div>
            <p className="font-serif">Custom Food</p>
          </div>
        </button>
        <button
          className="bg-white border border-stone-200 rounded-lg p-4 text-center
              hover:border-stone-300 transition-colors group"
        >
          <div className="flex flex-col items-center gap-2">
            <div className="p-2 bg-stone-100 rounded-lg group-hover:bg-stone-200 transition-colors">
              <Save className="w-5 h-5" />
            </div>
            <p className="font-serif">Save as Meal</p>
          </div>
        </button>
      </div>
    </div>
  );
};
