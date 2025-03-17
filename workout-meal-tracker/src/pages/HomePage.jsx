// src/pages/HomePage.jsx
import React from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { LogOut } from "lucide-react";

export const HomePage = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate("/login");
  };

  return (
    <div className="min-h-screen bg-stone-50 p-6 relative">
      {/* Logout Button */}
      <button
        onClick={handleLogout}
        className="absolute top-6 right-6 flex items-center gap-2 px-4 py-2 text-stone-600 hover:text-stone-800"
      >
        <LogOut size={20} />
        <span className="font-serif">Log out</span>
      </button>

      {/* Main Content */}
      <div className="flex flex-col items-center justify-center min-h-screen -mt-16">
        {/* Greeting */}
        <h1 className="font-serif text-4xl text-stone-800 mb-12">
          Hello, Nyel
        </h1>

        {/* Navigation Buttons */}
        <div className="space-y-4 w-full max-w-md">
          <button
            onClick={() => navigate("/workouts")}
            className="w-full bg-stone-800 text-white font-serif py-6 rounded-lg text-xl hover:bg-stone-700 transition-colors"
          >
            Workouts
          </button>

          <button
            onClick={() => navigate("/meals")}
            className="w-full bg-stone-800 text-white font-serif py-6 rounded-lg text-xl hover:bg-stone-700 transition-colors"
          >
            Meals
          </button>

          <button
            onClick={() => navigate("/progress")}
            className="w-full bg-stone-800 text-white font-serif py-6 rounded-lg text-xl hover:bg-stone-700 transition-colors"
          >
            Daily Progress
          </button>
        </div>
      </div>
    </div>
  );
};
