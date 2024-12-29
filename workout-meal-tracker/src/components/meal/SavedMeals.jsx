// src/components/meal/SavedMeals.jsx
import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import * as api from "../../api";
import { Heart, Calendar, Clock, Star } from "lucide-react";

const CATEGORIES = [
  { label: "All", count: 0 },
  { label: "Favorites", count: 0, icon: Heart },
  { label: "Recurring", count: 0, icon: Calendar },
  { label: "Quick Access", count: 0, icon: Clock },
];

export const SavedMeals = () => {
  const [activeCategory, setActiveCategory] = useState("All");
  const [meals, setMeals] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    const fetchMeals = async () => {
      try {
        setLoading(true);
        let fetchedMeals;

        switch (activeCategory) {
          case "Favorites":
            fetchedMeals = await api.getFavoriteMeals(user.username);
            break;
          case "Quick Access":
            fetchedMeals = await api.getQuickAccessMeals(user.username);
            break;
          case "Recurring":
            fetchedMeals = await api.getRecurringMeals(user.username);
            break;
          default:
            const [favorites, quickAccess, recurring] = await Promise.all([
              api.getFavoriteMeals(user.username),
              api.getQuickAccessMeals(user.username),
              api.getRecurringMeals(user.username),
            ]);
            fetchedMeals = [...favorites, ...quickAccess, ...recurring];
            // Remove duplicates
            fetchedMeals = Array.from(
              new Set(fetchedMeals.map((m) => m.id))
            ).map((id) => fetchedMeals.find((m) => m.id === id));
        }
        setMeals(fetchedMeals);
      } catch (error) {
        console.error("Failed to fetch meals:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchMeals();
  }, [user.username, activeCategory]);

  const handleQuickAdd = async (meal) => {
    try {
      // Create a new meal entry for today using the template
      const today = new Date().toISOString().split("T")[0];
      await api.createMeal(user.username, {
        ...meal,
        date: today,
        time_eaten: new Date().toLocaleTimeString("en-US", {
          hour: "2-digit",
          minute: "2-digit",
        }),
      });
      navigate("/meals");
    } catch (error) {
      console.error("Failed to quick add meal:", error);
    }
  };

  const renderMacros = (meal) => (
    <div className="flex gap-4 text-sm">
      <span>P: {meal.protein}g</span>
      <span>C: {meal.carbs}g</span>
      <span>F: {meal.fat}g</span>
    </div>
  );

  if (loading) {
    return (
      <div className="min-h-screen bg-stone-50 text-stone-800 p-6">
        <div className="animate-pulse">
          <div className="h-10 bg-stone-200 rounded-lg mb-6"></div>
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-40 bg-stone-200 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-stone-50 text-stone-800 p-6">
      {/* Categories */}
      <div className="flex gap-3 overflow-x-auto pb-2 mb-6">
        {CATEGORIES.map((category, index) => {
          const count = meals.filter((meal) =>
            category.label === "All"
              ? true
              : category.label === "Favorites"
              ? meal.is_favorite
              : category.label === "Recurring"
              ? meal.is_recurring
              : category.label === "Quick Access"
              ? meal.is_quick_access
              : false
          ).length;

          return (
            <button
              key={category.label}
              onClick={() => setActiveCategory(category.label)}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg whitespace-nowrap
                transition-colors
                ${
                  activeCategory === category.label
                    ? "bg-stone-800 text-white"
                    : "border border-stone-200 hover:border-stone-300"
                }`}
            >
              {category.icon && <category.icon className="w-4 h-4" />}
              <span className="font-serif">{category.label}</span>
              <span className="text-sm opacity-75">({count})</span>
            </button>
          );
        })}
      </div>

      {/* Saved Meals List */}
      <div className="space-y-4">
        {meals.map((meal, index) => (
          <div
            key={index}
            className="bg-white border border-stone-200 rounded-lg p-4"
          >
            <div className="flex justify-between items-start mb-3">
              <div>
                <h3 className="font-serif text-lg">{meal.name}</h3>
                <div className="flex gap-2 mt-1">
                  {meal.is_favorite && (
                    <span className="text-xs px-2 py-1 bg-red-50 text-red-600 rounded-full">
                      Favorite
                    </span>
                  )}
                  {meal.is_recurring && (
                    <span className="text-xs px-2 py-1 bg-blue-50 text-blue-600 rounded-full">
                      Recurring
                    </span>
                  )}
                  {meal.is_quick_access && (
                    <span className="text-xs px-2 py-1 bg-green-50 text-green-600 rounded-full">
                      Quick Access
                    </span>
                  )}
                </div>
              </div>
              <span className="font-mono bg-stone-100 px-3 py-1 rounded">
                {meal.calories} cal
              </span>
            </div>

            {meal.schedule && (
              <div className="flex items-center gap-2 text-sm text-stone-500 mb-3">
                <Calendar className="w-4 h-4" />
                {meal.schedule}
              </div>
            )}

            {renderMacros(meal)}

            <div className="flex gap-2 mt-3">
              <button
                onClick={() => handleQuickAdd(meal)}
                className="px-3 py-1 text-sm border border-stone-200 rounded-lg
                  hover:bg-stone-50 transition-colors"
              >
                Quick Add
              </button>
              <button
                className="px-3 py-1 text-sm border border-stone-200 rounded-lg
                  hover:bg-stone-50 transition-colors"
              >
                Edit
              </button>
            </div>
          </div>
        ))}

        {meals.length === 0 && (
          <div className="text-center py-12 text-stone-500">
            <div className="mb-4">
              <Star className="w-12 h-12 mx-auto text-stone-300" />
            </div>
            <h3 className="font-serif text-lg mb-2">No saved meals found</h3>
            <p className="text-sm">
              Save your favorite meals for quick access and easy tracking
            </p>
          </div>
        )}
      </div>
    </div>
  );
};
