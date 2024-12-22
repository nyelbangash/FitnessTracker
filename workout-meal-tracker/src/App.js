import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import {
  Container,
  AppBar,
  Toolbar,
  Button,
  Box,
  ThemeProvider,
  createTheme,
} from "@mui/material";
import LoginPage from "./LoginPage";
import AddWorkout from "./AddWorkout";
import AddMeal from "./AddMeal";
import WorkoutLog from "./WorkoutLog";
import MealLog from "./MealLog";

// Create a theme instance
const theme = createTheme();

const App = () => {
  return (
    <ThemeProvider theme={theme}>
      <Router>
        <Box
          sx={{ display: "flex", flexDirection: "column", minHeight: "100vh" }}
        >
          <AppBar position="static">
            <Toolbar>
              <Box sx={{ flexGrow: 1, display: "flex", gap: 2 }}>
                <Button color="inherit" href="/">
                  Login
                </Button>
                <Button color="inherit" href="/add-workout">
                  Add Workout
                </Button>
                <Button color="inherit" href="/add-meal">
                  Add Meal
                </Button>
                <Button color="inherit" href="/workout-log">
                  Workout Log
                </Button>
                <Button color="inherit" href="/meal-log">
                  Meal Log
                </Button>
              </Box>
            </Toolbar>
          </AppBar>

          <Container component="main" maxWidth="md" sx={{ mt: 4, mb: 4 }}>
            <Routes>
              <Route path="/" element={<LoginPage />} />
              <Route path="/add-workout" element={<AddWorkout />} />
              <Route path="/add-meal" element={<AddMeal />} />
              <Route path="/workout-log" element={<WorkoutLog />} />
              <Route path="/meal-log" element={<MealLog />} />
            </Routes>
          </Container>
        </Box>
      </Router>
    </ThemeProvider>
  );
};

export default App;
