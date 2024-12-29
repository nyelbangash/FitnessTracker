import axios from "axios";

const API_BASE_URL = "http://localhost:4001/ft";

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
});

const getUsername = () => localStorage.getItem("username");

export const login = async ({ username, password }) => {
  try {
    const response = await api.post("/login", {
      credentials: { username, password },
    });

    console.log("Login response data:", response.data); // Log the response data

    if (response.data.success) {
      return { profile: response.data.profile }; // Adjust if needed to match the response format
    } else {
      throw new Error("Login failed");
    }
  } catch (error) {
    console.error("Error during login:", error);
    throw error; // Rethrow to be caught by the AuthContext login function
  }
};

export const createProfile = async (profileData) => {
  try {
    const response = await api.post("/profile", {
      first_name: profileData.firstName,
      last_name: profileData.lastName,
      username: profileData.username,
      password: profileData.password,
      date_of_birth: profileData.dateOfBirth,
      height: parseFloat(profileData.height),
      weight: parseFloat(profileData.weight),
    });
    return response.data;
  } catch (error) {
    console.error("Create profile error:", error);
    throw new Error("Failed to create profile");
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
    validateWorkoutData(workoutData);

    const formattedExercises = formatExercises(workoutData.exercises);

    const response = await api.post(`/profile/${username}/workout`, {
      workout: {
        workout_name: workoutData.workoutName,
        exercises: formattedExercises,
        length_of_workout: parseInt(workoutData.duration) || 0,
        date_worked_out: workoutData.date,
      },
    });
    return response.data;
  } catch (error) {
    console.error("Add workout error:", error);
    throw new Error(error.message || "Failed to add workout");
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
          exercises: formatExercises(workoutData.exercises),
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

export const getActiveWorkout = async (username) => {
  try {
    const response = await api.get(`/profile/${username}/workout/active`);
    return response.data;
  } catch (error) {
    console.error("Fetch active workout error:", error);
    throw new Error("Failed to fetch active workout");
  }
};

export const completeSet = async (username, setData) => {
  try {
    const response = await api.post(
      `/profile/${username}/workout/active/set`,
      setData
    );
    return response.data;
  } catch (error) {
    console.error("Complete set error:", error);
    throw new Error("Failed to complete set");
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
        ...mealData,
        calories: parseInt(mealData.calories),
        protein: parseFloat(mealData.protein),
        carbs: parseFloat(mealData.carbs),
        fat: parseFloat(mealData.fat),
        ingredients: mealData.ingredients.map((ing) => ({ name: ing.name })),
      },
    });
    return response.data;
  } catch (error) {
    console.error("Add meal error:", error);
    throw new Error("Failed to add meal");
  }
};

export const updateMeal = async (mealName, date, mealData) => {
  try {
    const username = getUsername();
    const response = await api.put(
      `/profile/${username}/meal/${mealName}/${date}`,
      {
        meal: {
          ...mealData,
          calories: parseInt(mealData.calories),
          protein: parseFloat(mealData.protein),
          carbs: parseFloat(mealData.carbs),
          fat: parseFloat(mealData.fat),
          ingredients: mealData.ingredients.map((ing) => ({ name: ing.name })),
        },
      }
    );
    return response.data;
  } catch (error) {
    console.error("Update meal error:", error);
    throw new Error("Failed to update meal");
  }
};

export const getDailyNutrition = async (username, date) => {
  try {
    const response = await api.get(
      `/profile/${username}/nutrition/daily/${date}`
    );
    return response.data;
  } catch (error) {
    console.error("Fetch daily nutrition error:", error);
    throw new Error("Failed to fetch daily nutrition");
  }
};

export const getNutritionGoals = async (username) => {
  try {
    const response = await api.get(`/profile/${username}/nutrition/goals`);
    return response.data;
  } catch (error) {
    console.error("Fetch nutrition goals error:", error);
    throw new Error("Failed to fetch nutrition goals");
  }
};

// Helper functions

const validateWorkoutData = (workoutData) => {
  if (
    !workoutData ||
    !workoutData.exercises ||
    !Array.isArray(workoutData.exercises)
  ) {
    throw new Error("Invalid workout data structure");
  }
};

const formatExercises = (exercises) => {
  return exercises.map((ex) => {
    if (!ex || !ex.name || !Array.isArray(ex.sets)) {
      throw new Error("Invalid exercise data");
    }

    ex.sets.forEach((set, index) => {
      if (!set.reps || !set.weight) {
        throw new Error(`Invalid data for set ${index + 1}`);
      }
    });

    return {
      exercise_name: ex.name,
      sets: ex.sets.map((set) => ({
        reps: parseInt(set.reps) || 0,
        weight: parseFloat(set.weight) || 0,
      })),
    };
  });
};
// Get favorite meals
export const getFavoriteMeals = async (username) => {
  try {
    const response = await api.get(`/profile/${username}/meal/favorites`);
    return response.data.meals;
  } catch (error) {
    console.error("Fetch favorite meals error:", error);
    throw new Error("Failed to fetch favorite meals");
  }
};

// Get quick access meals
export const getQuickAccessMeals = async (username) => {
  try {
    const response = await api.get(`/profile/${username}/meal/quick-access`);
    return response.data.meals;
  } catch (error) {
    console.error("Fetch quick access meals error:", error);
    throw new Error("Failed to fetch quick access meals");
  }
};

// Get recurring meals
export const getRecurringMeals = async (username) => {
  try {
    const response = await api.get(`/profile/${username}/meal/recurring`);
    return response.data.meals;
  } catch (error) {
    console.error("Fetch recurring meals error:", error);
    throw new Error("Failed to fetch recurring meals");
  }
};

// Create a new meal entry
export const createMeal = async (username, mealData) => {
  try {
    const response = await api.post(`/profile/${username}/meal`, mealData);
    return response.data;
  } catch (error) {
    console.error("Create meal error:", error);
    throw new Error("Failed to create meal");
  }
};

// End the active workout
export const endWorkout = async (username) => {
  try {
    const response = await api.post(`/profile/${username}/workout/end`);
    return response.data;
  } catch (error) {
    console.error("End workout error:", error);
    throw new Error("Failed to end workout");
  }
};

// Update workout notes
export const updateWorkoutNotes = async (username, notes) => {
  try {
    const response = await api.put(
      `/profile/${username}/workout/active/notes`,
      { notes }
    );
    return response.data;
  } catch (error) {
    console.error("Update workout notes error:", error);
    throw new Error("Failed to update workout notes");
  }
};
