import React, { useState } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
  useNavigate,
} from "react-router-dom";
import { ThemeProvider, createTheme } from "@mui/material";
import LoginPage from "./components/LoginPage";
import {
  Dumbbell,
  Utensils,
  BarChart,
  User,
  ArrowLeft,
  Plus,
  Calendar,
} from "lucide-react";
import ProfilePage from "./components/ProfilePage";
import AddWorkout from "./components/AddWorkout";
import AddMeal from "./components/AddMeal";
import WorkoutLog from "./components/WorkoutLog";
import MealLog from "./components/MealLog";

const theme = createTheme();

// Navigation Component (Move this to a separate file later)
const Navigation = ({ handleLogout }) => {
  const [activeModule, setActiveModule] = useState("home");
  const navigate = useNavigate();
  const userName = localStorage.getItem("username");

  const handleWorkoutClick = () => {
    navigate("/add-workout");
  };

  const handleMealClick = () => {
    navigate("/add-meal");
  };

  const renderContent = () => {
    switch (activeModule) {
      case "workouts":
        return (
          <div className="p-4 space-y-4">
            <button
              onClick={handleWorkoutClick}
              className="w-full p-8 bg-blue-50 rounded-lg flex items-center gap-4 hover:bg-blue-100"
            >
              <Plus size={32} />
              <div>
                <h3 className="text-xl font-medium">Start Workout</h3>
                <p className="text-gray-600">Begin your training session</p>
              </div>
            </button>

            <button
              onClick={() => navigate("/workout-log")}
              className="w-full p-8 bg-gray-50 rounded-lg flex items-center gap-4 hover:bg-gray-100"
            >
              <Calendar size={32} />
              <div>
                <h3 className="text-xl">Workout History</h3>
                <p className="text-gray-600">View past workouts</p>
              </div>
            </button>
          </div>
        );

      case "meals":
        return (
          <div className="p-4 space-y-4">
            <button
              onClick={handleMealClick}
              className="w-full p-8 bg-blue-50 rounded-lg flex items-center gap-4 hover:bg-blue-100"
            >
              <Plus size={32} />
              <div>
                <h3 className="text-xl font-medium">Log Meal</h3>
                <p className="text-gray-600">Track your nutrition</p>
              </div>
            </button>

            <button
              onClick={() => navigate("/meal-log")}
              className="w-full p-8 bg-gray-50 rounded-lg flex items-center gap-4 hover:bg-gray-100"
            >
              <Calendar size={32} />
              <div>
                <h3 className="text-xl">Meal History</h3>
                <p className="text-gray-600">View meal log</p>
              </div>
            </button>
          </div>
        );

      default:
        return (
          <div className="p-4 space-y-4">
            <h2 className="text-2xl mb-6">Hi, {userName}</h2>

            <button
              onClick={() => setActiveModule("workouts")}
              className="w-full p-8 bg-gray-50 rounded-lg flex items-center gap-4 hover:bg-gray-100"
            >
              <Dumbbell size={32} />
              <div>
                <span className="text-xl">Workouts</span>
                <p className="text-gray-600 text-sm">Start training</p>
              </div>
            </button>

            <button
              onClick={() => setActiveModule("meals")}
              className="w-full p-8 bg-gray-50 rounded-lg flex items-center gap-4 hover:bg-gray-100"
            >
              <Utensils size={32} />
              <div>
                <span className="text-xl">Meals</span>
                <p className="text-gray-600 text-sm">Track nutrition</p>
              </div>
            </button>

            <button className="w-full p-8 bg-gray-50 rounded-lg flex items-center gap-4 hover:bg-gray-100">
              <BarChart size={32} />
              <div>
                <span className="text-xl">Progress</span>
                <p className="text-gray-600 text-sm">Check your stats</p>
              </div>
            </button>
          </div>
        );
    }
  };

  return (
    <div className="h-screen bg-white">
      <div className="flex justify-between items-center p-4 border-b">
        {activeModule !== "home" ? (
          <button
            onClick={() => setActiveModule("home")}
            className="flex items-center gap-2 text-blue-500"
          >
            <ArrowLeft size={20} />
            Back
          </button>
        ) : (
          <div></div>
        )}
        <h2 className="text-lg font-medium">
          {activeModule === "home"
            ? "Home"
            : activeModule.charAt(0).toUpperCase() + activeModule.slice(1)}
        </h2>
        <button
          onClick={() => navigate("/profile")}
          className="p-2 rounded-full hover:bg-gray-100"
        >
          <User size={24} />
        </button>
      </div>

      <div className="h-[calc(100vh-64px)] overflow-auto">
        {renderContent()}
      </div>
    </div>
  );
};

const App = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(
    !!localStorage.getItem("username")
  );

  const handleLogout = () => {
    localStorage.removeItem("username");
    setIsAuthenticated(false);
  };

  return (
    <ThemeProvider theme={theme}>
      <Router>
        <Routes>
          <Route
            path="/"
            element={
              isAuthenticated ? (
                <Navigation handleLogout={handleLogout} />
              ) : (
                <LoginPage setIsAuthenticated={setIsAuthenticated} />
              )
            }
          />
          <Route
            path="/profile"
            element={
              isAuthenticated ? (
                <ProfilePage handleLogout={handleLogout} />
              ) : (
                <Navigate to="/" />
              )
            }
          />
          <Route
            path="/add-workout"
            element={isAuthenticated ? <AddWorkout /> : <Navigate to="/" />}
          />
          <Route
            path="/add-meal"
            element={isAuthenticated ? <AddMeal /> : <Navigate to="/" />}
          />
          <Route
            path="/workout-log"
            element={isAuthenticated ? <WorkoutLog /> : <Navigate to="/" />}
          />
          <Route
            path="/meal-log"
            element={isAuthenticated ? <MealLog /> : <Navigate to="/" />}
          />
        </Routes>
      </Router>
    </ThemeProvider>
  );
};

export default App;
