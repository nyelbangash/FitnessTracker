// App.jsx
import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./contexts/AuthContext";
import { NutritionProvider } from "./contexts/NutritionContext";
import { ProtectedRoute } from "./components/auth/ProtectedRoute";
import { AppLayout } from "./components/layout/AppLayout";

// Auth Pages
import { LoginPage } from "./pages/LoginPage";
import { SignupPage } from "./pages/SignupPage";
import { ProfilePage } from "./pages/ProfilePage";

// Workout Pages
import { WorkoutPreview } from "./components/workout/WorkoutPreview";
import { ActiveWorkout } from "./components/workout/ActiveWorkout";
import { ExerciseScreen } from "./components/workout/ExerciseScreen";

// Meal Pages
import { MealDashboard } from "./components/meal/MealDashboard";
import { MealLogging } from "./components/meal/MealLogging";
import { SavedMeals } from "./components/meal/SavedMeals";
import { MealStats } from "./components/meal/MealStats.jsx";

export const App = () => {
  return (
    <BrowserRouter>
      <AuthProvider>
        <NutritionProvider>
          <Routes>
            {/* Public Routes */}
            <Route path="/login" element={<LoginPage />} />
            <Route path="/signup" element={<SignupPage />} />

            {/* Protected Routes */}
            <Route
              element={
                <ProtectedRoute>
                  <AppLayout />
                </ProtectedRoute>
              }
            >
              {/* Workout Routes */}
              <Route path="/workouts" element={<WorkoutPreview />} />
              <Route path="/workout/active" element={<ActiveWorkout />} />
              <Route
                path="/workout/exercise/:exerciseIndex"
                element={<ExerciseScreen />}
              />

              {/* Meal Routes */}
              <Route path="/meals" element={<MealDashboard />} />
              <Route path="/meals/log" element={<MealLogging />} />
              <Route path="/meals/saved" element={<SavedMeals />} />
              <Route path="/meals/stats" element={<MealStats />} />

              {/* Profile Route */}
              <Route path="/profile" element={<ProfilePage />} />

              {/* Redirect root to workouts */}
              <Route path="/" element={<Navigate to="/workouts" replace />} />
            </Route>
          </Routes>
        </NutritionProvider>
      </AuthProvider>
    </BrowserRouter>
  );
};
