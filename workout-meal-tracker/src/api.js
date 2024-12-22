import axios from "axios";

const API_BASE_URL = "http://localhost:15963/workout-api";

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
});

export const login = async (username, password) => {
  try {
    const response = await api.post("/profile", {
      // Changed from /login to /profile
      username,
      password,
    });
    return response.data;
  } catch (error) {
    console.error("Login error:", error);
    throw new Error("Login failed");
  }
};

export const getWorkouts = async () => {
  try {
    const response = await api.get("/workoutlog"); // Changed from /workouts to /workoutlog
    return response.data;
  } catch (error) {
    console.error("Fetch workouts error:", error);
    throw new Error("Failed to fetch workouts");
  }
};

export const addWorkout = async (workoutData) => {
  try {
    const response = await api.put("/workoutlog", workoutData); // Changed from POST to PUT
    return response.data;
  } catch (error) {
    console.error("Add workout error:", error);
    throw new Error("Failed to add workout");
  }
};

export const getMeals = async () => {
  try {
    const response = await api.get("/meallog"); // Changed from /meals to /meallog
    return response.data;
  } catch (error) {
    console.error("Fetch meals error:", error);
    throw new Error("Failed to fetch meals");
  }
};

export const addMeal = async (mealData) => {
  try {
    const response = await api.put("/meallog", mealData); // Changed from POST to PUT
    return response.data;
  } catch (error) {
    console.error("Add meal error:", error);
    throw new Error("Failed to add meal");
  }
};
