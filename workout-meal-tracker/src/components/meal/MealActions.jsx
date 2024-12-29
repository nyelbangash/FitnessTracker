// src/components/meal/MealActions.jsx
import React, { useState } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { api } from "../../api";
import { Heart, Calendar, Clock, Copy, X } from "lucide-react";

export const MealActions = ({ meal, onUpdate }) => {
  const [showSaveModal, setShowSaveModal] = useState(false);
  const [customName, setCustomName] = useState("");
  const { user } = useAuth();

  const handleSaveAsFavorite = async () => {
    try {
      await api.toggleFavoriteMeal(user.username, meal.name, meal.date);
      setShowSaveModal(false);
      if (onUpdate) onUpdate();
    } catch (error) {
      console.error("Failed to save as favorite:", error);
    }
  };

  const handleSetRecurring = async () => {
    try {
      await api.setRecurringMeal(user.username, meal.name, meal.date, {
        schedule: "Weekdays", // This could be made configurable
      });
      setShowSaveModal(false);
      if (onUpdate) onUpdate();
    } catch (error) {
      console.error("Failed to set recurring:", error);
    }
  };

  const handleQuickAccess = async () => {
    try {
      await api.toggleQuickAccessMeal(user.username, meal.name, meal.date);
      setShowSaveModal(false);
      if (onUpdate) onUpdate();
    } catch (error) {
      console.error("Failed to toggle quick access:", error);
    }
  };

  const handleSaveAsTemplate = async () => {
    if (!customName.trim()) return;

    try {
      await api.createMealTemplate(user.username, {
        ...meal,
        template_name: customName,
      });
      setShowSaveModal(false);
      setCustomName("");
      if (onUpdate) onUpdate();
    } catch (error) {
      console.error("Failed to save template:", error);
    }
  };

  return (
    <div className="bg-white border border-stone-200 rounded-lg p-6">
      {/* Save Options Modal */}
      {showSaveModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md relative">
            <button
              onClick={() => setShowSaveModal(false)}
              className="absolute top-4 right-4 text-stone-400 hover:text-stone-600"
            >
              <X size={20} />
            </button>

            <h3 className="font-serif text-xl mb-4">Save Meal</h3>

            <div className="space-y-4">
              {/* Favorite Option */}
              <button
                onClick={handleSaveAsFavorite}
                className="w-full flex items-center justify-between p-4 border border-stone-200 
                  rounded-lg hover:bg-stone-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <Heart className="w-5 h-5 text-red-500" />
                  <div className="text-left">
                    <p className="font-serif">Save as Favorite</p>
                    <p className="text-sm text-stone-500">
                      Quick access to meals you love
                    </p>
                  </div>
                </div>
              </button>

              {/* Recurring Option */}
              <button
                onClick={handleSetRecurring}
                className="w-full flex items-center justify-between p-4 border border-stone-200 
                  rounded-lg hover:bg-stone-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <Calendar className="w-5 h-5 text-blue-500" />
                  <div className="text-left">
                    <p className="font-serif">Set as Recurring</p>
                    <p className="text-sm text-stone-500">
                      Automatically add on specific days
                    </p>
                  </div>
                </div>
              </button>

              {/* Quick Add Option */}
              <button
                onClick={handleQuickAccess}
                className="w-full flex items-center justify-between p-4 border border-stone-200 
                  rounded-lg hover:bg-stone-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <Clock className="w-5 h-5 text-green-500" />
                  <div className="text-left">
                    <p className="font-serif">Add to Quick Access</p>
                    <p className="text-sm text-stone-500">
                      Show in quick add menu
                    </p>
                  </div>
                </div>
              </button>

              {/* Template Option */}
              <button
                onClick={handleSaveAsTemplate}
                className="w-full flex items-center justify-between p-4 border border-stone-200 
                  rounded-lg hover:bg-stone-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <Copy className="w-5 h-5 text-purple-500" />
                  <div className="text-left">
                    <p className="font-serif">Save as Template</p>
                    <p className="text-sm text-stone-500">
                      Create a reusable meal template
                    </p>
                  </div>
                </div>
              </button>
            </div>

            {/* Custom Name Input */}
            <div className="mt-4">
              <label className="font-serif text-sm text-stone-500">
                Custom Name (Optional)
              </label>
              <input
                type="text"
                placeholder="e.g., Pre-workout Breakfast"
                className="w-full mt-1 p-2 border border-stone-200 rounded-lg font-serif
                  focus:outline-none focus:border-stone-300"
                value={customName}
                onChange={(e) => setCustomName(e.target.value)}
              />
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setShowSaveModal(false)}
                className="flex-1 py-2 border border-stone-200 rounded-lg font-serif
                  hover:bg-stone-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveAsTemplate}
                className="flex-1 py-2 bg-stone-800 text-white rounded-lg font-serif
                  hover:bg-stone-700 transition-colors"
                disabled={!customName.trim()}
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Trigger Button */}
      <div className="flex justify-between items-center">
        <div>
          <h3 className="font-serif text-lg">This Meal</h3>
          <p className="text-sm text-stone-500">Save for future use</p>
        </div>
        <button
          onClick={() => setShowSaveModal(true)}
          className="p-2 hover:bg-stone-100 rounded-lg transition-colors"
        >
          <Heart className="w-6 h-6" />
        </button>
      </div>
    </div>
  );
};
