// src/components/meal/CustomFoodForm.jsx
import React, { useState } from "react";
import { X } from "lucide-react";

export const CustomFoodForm = ({ onSave, onClose }) => {
  const [foodData, setFoodData] = useState({
    name: "",
    serving: "",
    unit: "g",
    calories: "",
    protein: "",
    carbs: "",
    fat: "",
  });

  const [errors, setErrors] = useState({});

  const validateForm = () => {
    const newErrors = {};
    if (!foodData.name.trim()) newErrors.name = "Name is required";
    if (!foodData.serving) newErrors.serving = "Serving size is required";
    if (!foodData.calories) newErrors.calories = "Calories are required";

    // Validate numbers
    ["calories", "protein", "carbs", "fat"].forEach((field) => {
      if (foodData[field] && isNaN(foodData[field])) {
        newErrors[field] = "Must be a number";
      }
    });

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    onSave({
      ...foodData,
      calories: Number(foodData.calories),
      protein: Number(foodData.protein),
      carbs: Number(foodData.carbs),
      fat: Number(foodData.fat),
    });
  };

  const handleChange = (field, value) => {
    setFoodData((prev) => ({ ...prev, [field]: value }));
    // Clear error when field is edited
    if (errors[field]) {
      setErrors((prev) => ({ ...prev, [field]: undefined }));
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-6">
          <h2 className="font-serif text-xl">Add Custom Food</h2>
          <button
            onClick={onClose}
            className="text-stone-400 hover:text-stone-600 transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Food Name */}
          <div>
            <label className="font-serif text-sm text-stone-500">
              Food Name
            </label>
            <input
              type="text"
              value={foodData.name}
              onChange={(e) => handleChange("name", e.target.value)}
              className={`w-full p-2 mt-1 border rounded-lg font-serif
                ${errors.name ? "border-red-300" : "border-stone-200"}`}
              placeholder="e.g., Homemade Protein Bar"
            />
            {errors.name && (
              <p className="text-sm text-red-500 mt-1">{errors.name}</p>
            )}
          </div>

          {/* Serving Size */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="font-serif text-sm text-stone-500">
                Serving Size
              </label>
              <input
                type="number"
                value={foodData.serving}
                onChange={(e) => handleChange("serving", e.target.value)}
                className={`w-full p-2 mt-1 border rounded-lg font-mono
                  ${errors.serving ? "border-red-300" : "border-stone-200"}`}
                placeholder="100"
              />
              {errors.serving && (
                <p className="text-sm text-red-500 mt-1">{errors.serving}</p>
              )}
            </div>
            <div>
              <label className="font-serif text-sm text-stone-500">Unit</label>
              <select
                value={foodData.unit}
                onChange={(e) => handleChange("unit", e.target.value)}
                className="w-full p-2 mt-1 border border-stone-200 rounded-lg font-serif
                  bg-white"
              >
                <option value="g">grams</option>
                <option value="oz">ounces</option>
                <option value="cup">cup</option>
                <option value="tbsp">tablespoon</option>
                <option value="tsp">teaspoon</option>
              </select>
            </div>
          </div>

          {/* Nutrition Info */}
          <div>
            <label className="font-serif text-sm text-stone-500">
              Calories
            </label>
            <input
              type="number"
              value={foodData.calories}
              onChange={(e) => handleChange("calories", e.target.value)}
              className={`w-full p-2 mt-1 border rounded-lg font-mono
                ${errors.calories ? "border-red-300" : "border-stone-200"}`}
              placeholder="0"
            />
            {errors.calories && (
              <p className="text-sm text-red-500 mt-1">{errors.calories}</p>
            )}
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="font-serif text-sm text-stone-500">
                Protein (g)
              </label>
              <input
                type="number"
                value={foodData.protein}
                onChange={(e) => handleChange("protein", e.target.value)}
                className="w-full p-2 mt-1 border border-stone-200 rounded-lg font-mono"
                placeholder="0"
              />
            </div>
            <div>
              <label className="font-serif text-sm text-stone-500">
                Carbs (g)
              </label>
              <input
                type="number"
                value={foodData.carbs}
                onChange={(e) => handleChange("carbs", e.target.value)}
                className="w-full p-2 mt-1 border border-stone-200 rounded-lg font-mono"
                placeholder="0"
              />
            </div>
            <div>
              <label className="font-serif text-sm text-stone-500">
                Fat (g)
              </label>
              <input
                type="number"
                value={foodData.fat}
                onChange={(e) => handleChange("fat", e.target.value)}
                className="w-full p-2 mt-1 border border-stone-200 rounded-lg font-mono"
                placeholder="0"
              />
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2 border border-stone-200 rounded-lg font-serif
                hover:bg-stone-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 py-2 bg-stone-800 text-white rounded-lg font-serif
                hover:bg-stone-700 transition hover:bg-stone-700 transition-colors 
                disabled:opacity-50 disabled:bg-stone-600"
              disabled={
                !foodData.name || !foodData.serving || !foodData.calories
              }
            >
              Save Food
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
