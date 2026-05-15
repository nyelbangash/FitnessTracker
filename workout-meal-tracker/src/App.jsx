import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider, useAuth } from "./contexts/AuthContext";
import { ThemeProvider } from "./theme/ThemeContext";

import { AppShell } from "./layout/AppShell";

import { LoginPage } from "./pages/LoginPage";
import { SignupPage } from "./pages/SignupPage";

import { TodayPage } from "./pages/TodayPage";

import { TrainPage } from "./pages/TrainPage";
import { TrainStartPage } from "./pages/TrainStartPage";
import { ActiveWorkoutPage } from "./pages/ActiveWorkoutPage";
import { HistoryPage } from "./pages/HistoryPage";
import { TemplatesPage } from "./pages/TemplatesPage";
import { TemplateEditorPage } from "./pages/TemplateEditorPage";

import { EatPage } from "./pages/EatPage";
import { EatTodayPage } from "./pages/EatTodayPage";
import { LogMealPage } from "./pages/LogMealPage";
import { MealHistoryPage } from "./pages/MealHistoryPage";
import { MealFavoritesPage } from "./pages/MealFavoritesPage";

import { ProgressPage } from "./pages/ProgressPage";
import { YouPage } from "./pages/YouPage";

const RequireAuth = ({ children }) => {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  return children;
};

const Redirect = ({ to }) => <Navigate to={to} replace />;

export const App = () => (
  <BrowserRouter>
    <ThemeProvider>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/signup" element={<SignupPage />} />

          <Route
            element={
              <RequireAuth>
                <AppShell />
              </RequireAuth>
            }
          >
            <Route index element={<TodayPage />} />

            <Route path="train" element={<TrainPage />}>
              <Route index element={<TrainStartPage />} />
              <Route path="history" element={<HistoryPage />} />
              <Route path="templates" element={<TemplatesPage />} />
              <Route path="templates/new" element={<TemplateEditorPage />} />
              <Route
                path="templates/:templateName"
                element={<TemplateEditorPage />}
              />
            </Route>
            <Route path="train/active" element={<ActiveWorkoutPage />} />

            <Route path="eat" element={<EatPage />}>
              <Route index element={<EatTodayPage />} />
              <Route path="log" element={<LogMealPage />} />
              <Route path="edit/:date/:name" element={<LogMealPage />} />
              <Route path="history" element={<MealHistoryPage />} />
              <Route path="favorites" element={<MealFavoritesPage />} />
            </Route>

            <Route path="progress" element={<ProgressPage />} />
            <Route path="you" element={<YouPage />} />

            {/* Redirects from legacy URLs */}
            <Route path="workouts/*" element={<Redirect to="/train" />} />
            <Route path="workout/active" element={<Redirect to="/train/active" />} />
            <Route path="meals" element={<Redirect to="/eat" />} />
            <Route path="meals/log" element={<Redirect to="/eat/log" />} />
            <Route path="meals/*" element={<Redirect to="/eat" />} />
            <Route path="nutrition/goals" element={<Redirect to="/you" />} />
            <Route path="profile" element={<Redirect to="/you" />} />
            <Route path="analytics" element={<Redirect to="/progress" />} />
            <Route path="calendar" element={<Redirect to="/progress" />} />
            <Route path="achievements" element={<Redirect to="/progress" />} />
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </ThemeProvider>
  </BrowserRouter>
);
