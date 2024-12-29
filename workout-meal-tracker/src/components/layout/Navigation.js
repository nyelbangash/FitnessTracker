import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { Dumbbell, Apple, User } from "lucide-react";

export const Navigation = () => {
  const { logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <nav className="bg-stone-800 text-white py-4">
      <div className="container mx-auto px-4 flex items-center justify-between">
        <Link to="/" className="font-serif text-xl">
          FitnessTracker
        </Link>

        <div className="flex items-center space-x-6">
          <Link
            to="/workouts"
            className="flex items-center gap-2 hover:text-stone-300"
          >
            <Dumbbell size={20} />
            <span>Workouts</span>
          </Link>

          <Link
            to="/meals"
            className="flex items-center gap-2 hover:text-stone-300"
          >
            <Apple size={20} />
            <span>Nutrition</span>
          </Link>

          <div className="flex items-center gap-4">
            <Link to="/profile" className="hover:text-stone-300">
              <User size={20} />
            </Link>
            <button
              onClick={handleLogout}
              className="px-4 py-2 bg-stone-700 rounded hover:bg-stone-600"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
};
