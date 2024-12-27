import axios from "axios";

const API_BASE_URL = "http://localhost:4001/ft";

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
});

// Helper to get current username from localStorage
const getUsername = () => localStorage.getItem("username");

export const login = async (username, password) => {
  try {
    const response = await api.post("/login", {
      credentials: {
        username,
        password,
      },
    });

    if (response.data.success) {
      localStorage.setItem("username", username);
      return { success: true };
    }
    throw new Error("Invalid credentials");
  } catch (error) {
    console.error("Login error:", error);
    throw new Error(error.response?.data?.message || "Login failed");
  }
};

export const getWorkouts = async () => {
  try {
    const username = getUsername();
    const response = await api.get(`/profile/${username}/workout`);
    return response.data.workouts;
  } catch (error) {
    console.error("Fetch workouts error:", error);
    throw new Error("Failed to fetch workouts");
  }
};

export const addWorkout = async (workoutData) => {
  try {
    const username = getUsername();
    const response = await api.post(`/profile/${username}/workout`, {
      workout: {
        workout_name: workoutData.workoutName,
        exercises: workoutData.exercises.map((ex) => ({
          exercise_name: ex.name,
          sets: [
            {
              reps: parseInt(ex.reps),
              weight: parseFloat(ex.weight),
            },
          ],
        })),
        length_of_workout: parseInt(workoutData.duration),
        date_worked_out: workoutData.date,
      },
    });
    return response.data;
  } catch (error) {
    console.error("Add workout error:", error);
    throw new Error("Failed to add workout");
  }
};

export const getMeals = async () => {
  try {
    const username = getUsername();
    const response = await api.get(`/profile/${username}/meal`);
    return response.data.meals;
  } catch (error) {
    console.error("Fetch meals error:", error);
    throw new Error("Failed to fetch meals");
  }
};

export const addMeal = async (mealData) => {
  try {
    const username = getUsername();
    const response = await api.post(`/profile/${username}/meal`, {
      meal: {
        meal_name: mealData.mealName,
        calories: parseInt(mealData.calories),
        protein: parseFloat(mealData.protein),
        carbs: parseFloat(mealData.carbs),
        fat: parseFloat(mealData.fat),
        ingredients: mealData.ingredients.map((ing) => ({
          name: ing.name,
        })),
        date_eaten: mealData.date,
      },
    });
    return response.data;
  } catch (error) {
    console.error("Add meal error:", error);
    throw new Error("Failed to add meal");
  }
};

// Additional useful functions

export const createProfile = async (profileData) => {
  try {
    const response = await api.post("/profile", {
      firstName: profileData.firstName,
      lastName: profileData.lastName,
      username: profileData.username,
      password: profileData.password,
      dateOfBirth: profileData.dateOfBirth,
      height: parseFloat(profileData.height),
      weight: parseFloat(profileData.weight),
    });
    return response.data;
  } catch (error) {
    console.error("Create profile error:", error);
    throw new Error("Failed to create profile");
  }
};

export const updateMeal = async (mealName, date, mealData) => {
  try {
    const username = getUsername();
    const response = await api.put(
      `/profile/${username}/meal/${mealName}/${date}`,
      {
        meal: {
          meal_name: mealData.mealName,
          calories: parseInt(mealData.calories),
          protein: parseFloat(mealData.protein),
          carbs: parseFloat(mealData.carbs),
          fat: parseFloat(mealData.fat),
          ingredients: mealData.ingredients.map((ing) => ({
            name: ing.name,
          })),
          date_eaten: mealData.date,
        },
      }
    );
    return response.data;
  } catch (error) {
    console.error("Update meal error:", error);
    throw new Error("Failed to update meal");
  }
};

export const updateWorkout = async (workoutName, date, workoutData) => {
  try {
    const username = getUsername();
    const response = await api.put(
      `/profile/${username}/workout/${workoutName}/${date}`,
      {
        workout: {
          workout_name: workoutData.workoutName,
          exercises: workoutData.exercises.map((ex) => ({
            exercise_name: ex.name,
            sets: [
              {
                reps: parseInt(ex.reps),
                weight: parseFloat(ex.weight),
              },
            ],
          })),
          length_of_workout: parseInt(workoutData.duration),
          date_worked_out: workoutData.date,
        },
      }
    );
    return response.data;
  } catch (error) {
    console.error("Update workout error:", error);
    throw new Error("Failed to update workout");
  }
};
