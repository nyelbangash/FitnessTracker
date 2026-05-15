import axios from "axios";

const API_BASE_URL = process.env.REACT_APP_API_URL || "http://localhost:4000/api";

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem("token");
      localStorage.removeItem("user");
    }
    return Promise.reject(error);
  }
);

// Auth

export const login = async ({ email, password, username }) => {
  // Accept legacy { username } for backwards-compat with the LoginPage,
  // but the backend authenticates by email now.
  const credentials = { email: email ?? username, password };
  const { data } = await api.post("/login", { credentials });
  if (data.token) localStorage.setItem("token", data.token);
  return { token: data.token, profile: data.user };
};

export const logout = async () => {
  try {
    await api.delete("/logout");
  } catch (e) {
    // ignore
  } finally {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
  }
};

export const createProfile = async (profileData) => {
  const payload = {
    user: {
      email: profileData.email ?? profileData.username,
      password: profileData.password,
      first_name: profileData.firstName ?? profileData.first_name ?? "",
      last_name: profileData.lastName ?? profileData.last_name ?? "",
      height_cm: profileData.height ? parseInt(profileData.height, 10) : null,
      weight_kg: profileData.weight ? parseFloat(profileData.weight) : null,
      dob: profileData.dateOfBirth ?? profileData.dob ?? null,
    },
  };
  const { data } = await api.post("/users", payload);
  if (data.token) localStorage.setItem("token", data.token);
  return data;
};

// Username helper kept for backwards-compat; returns whatever's in storage so
// page-level code that displays `user.username` doesn't break.
export const getUsernameFromUser = (user) => {
  if (!user) return null;
  return user.email || user.username || user.user_name || user.name || null;
};

// Workouts

export const getWorkouts = async () => {
  const { data } = await api.get("/workouts");
  return data.workouts;
};

export const addWorkout = async (workoutData) => {
  // Gym Bro doesn't expose a "create-completed-workout" endpoint — workouts
  // are always created via start_workout from a template. This is left in
  // for compatibility but isn't expected to be used by the new flow.
  throw new Error(
    "Direct workout creation is not supported. Start a workout from a template."
  );
};

export const updateWorkout = async () => {
  throw new Error("Workout editing after completion is not supported yet.");
};

export const getActiveWorkout = async () => {
  const { data } = await api.get("/workouts/active");
  return data.workout;
};

export const startWorkout = async (_username, templateName) => {
  const { data } = await api.post("/workouts/active/start", {
    workout_name: templateName,
  });
  return data.workout;
};

export const completeSet = async (_username, setData) => {
  const { data } = await api.post("/workouts/active/set", setData);
  return data.workout;
};

export const updateSetRPE = async (_username, setData) => {
  const { data } = await api.put("/workouts/active/set/rpe", setData);
  return data.workout;
};

export const updateExerciseTargets = async (_username, targetData) => {
  const { data } = await api.put(
    "/workouts/active/exercise/targets",
    targetData
  );
  return data.workout;
};

export const skipExercise = async () => {
  const { data } = await api.post("/workouts/active/skip");
  return data.workout;
};

export const updateRestTimer = async (_username, restTime) => {
  const { data } = await api.put("/workouts/active/rest", {
    rest_time: restTime,
  });
  return data.workout;
};

export const updateWorkoutNotes = async (_username, notes) => {
  const { data } = await api.put("/workouts/active/notes", { notes });
  return data.workout;
};

export const endWorkout = async () => {
  const { data } = await api.post("/workouts/active/end");
  return data.workout;
};

export const getWorkoutHistory = async () => {
  const { data } = await api.get("/workouts/history");
  return data.history;
};

export const getWorkoutSummary = async (_username, workoutName, date) => {
  const { data } = await api.get(
    `/workouts/${encodeURIComponent(workoutName)}/${date}/summary`
  );
  return data.summary;
};

// Workout templates

export const getWorkoutTemplates = async () => {
  const { data } = await api.get("/workouts/templates");
  return data.templates;
};

export const saveWorkoutAsTemplate = async (_username, workoutName) => {
  const { data } = await api.post("/workouts/templates/from-workout", {
    workout_name: workoutName,
  });
  return data.template;
};

export const saveWorkoutTemplate = async (_username, templateName, templateData) => {
  const { data } = await api.put(
    `/workouts/templates/${encodeURIComponent(templateName)}`,
    { template: templateData }
  );
  return data.template;
};

export const createWorkoutTemplate = async (templateData) => {
  const { data } = await api.post("/workouts/templates", {
    template: templateData,
  });
  return data.template;
};

export const deleteWorkoutTemplate = async (_username, templateName) => {
  await api.delete(`/workouts/templates/${encodeURIComponent(templateName)}`);
};

// Meals

export const getMeals = async () => {
  const { data } = await api.get("/meals");
  return data.meals;
};

export const addMeal = async (mealData) => {
  return createMeal(null, mealData);
};

export const createMeal = async (_username, mealData) => {
  const payload = {
    meal: {
      name: mealData.name,
      date: mealData.date,
      time_eaten: mealData.time_eaten ?? mealData.timeEaten ?? null,
      meal_type: mealData.meal_type ?? mealData.mealType,
      calories: mealData.calories != null ? parseInt(mealData.calories, 10) : 0,
      protein: mealData.protein != null ? parseFloat(mealData.protein) : 0,
      carbs: mealData.carbs != null ? parseFloat(mealData.carbs) : 0,
      fat: mealData.fat != null ? parseFloat(mealData.fat) : 0,
      ingredients: (mealData.ingredients ?? []).map((ing) =>
        typeof ing === "string" ? { name: ing } : ing
      ),
      notes: mealData.notes ?? null,
    },
  };
  const { data } = await api.post("/meals", payload);
  return data.meal;
};

export const updateMeal = async (mealName, date, mealData) => {
  const payload = {
    meal: {
      ...mealData,
      calories: mealData.calories != null ? parseInt(mealData.calories, 10) : undefined,
      protein: mealData.protein != null ? parseFloat(mealData.protein) : undefined,
      carbs: mealData.carbs != null ? parseFloat(mealData.carbs) : undefined,
      fat: mealData.fat != null ? parseFloat(mealData.fat) : undefined,
      ingredients: (mealData.ingredients ?? []).map((ing) =>
        typeof ing === "string" ? { name: ing } : ing
      ),
    },
  };
  const { data } = await api.put(
    `/meals/${encodeURIComponent(mealName)}/${date}`,
    payload
  );
  return data.meal;
};

export const deleteMeal = async (_username, mealName, date) => {
  await api.delete(`/meals/${encodeURIComponent(mealName)}/${date}`);
};

export const getFavoriteMeals = async () => {
  const { data } = await api.get("/meals/favorites");
  return data.meals;
};

export const toggleMealFavorite = async (_username, mealName, date) => {
  const { data } = await api.post(
    `/meals/${encodeURIComponent(mealName)}/${date}/favorite`
  );
  return data.meal;
};

export const getQuickAccessMeals = async () => {
  const { data } = await api.get("/meals/quick-access");
  return data.meals;
};

export const toggleMealQuickAccess = async (_username, mealName, date) => {
  const { data } = await api.post(
    `/meals/${encodeURIComponent(mealName)}/${date}/quick-access`
  );
  return data.meal;
};

export const getRecurringMeals = async () => {
  const { data } = await api.get("/meals/recurring");
  return data.meals;
};

export const setMealRecurring = async (_username, mealName, date, schedule) => {
  const { data } = await api.post(
    `/meals/${encodeURIComponent(mealName)}/${date}/recurring`,
    { schedule }
  );
  return data.meal;
};

export const getMealTemplates = async () => {
  const { data } = await api.get("/meals/templates");
  return data.templates;
};

export const analyzeMealPhoto = async (file) => {
  const form = new FormData();
  form.append("image", file);
  const { data } = await api.post("/meals/analyze", form, {
    headers: { "Content-Type": "multipart/form-data" },
    timeout: 45000,
  });
  return data.analysis;
};

export const refineMealAnalysis = async (analysisId, message, history) => {
  const { data } = await api.post("/meals/analyze/refine", {
    analysis_id: analysisId,
    message,
    history,
  }, { timeout: 45000 });
  return data.analysis;
};

export const createMealTemplate = async (_username, mealData) => {
  const { data } = await api.post("/meals/templates", { template: mealData });
  return data.template;
};

// Profile + nutrition

export const updateProfile = async (_username, profileData) => {
  const payload = {
    user: {
      first_name: profileData.first_name ?? profileData.firstName,
      last_name: profileData.last_name ?? profileData.lastName,
      height_cm:
        profileData.height_cm ??
        (profileData.height ? parseInt(profileData.height, 10) : undefined),
      weight_kg:
        profileData.weight_kg ??
        (profileData.weight ? parseFloat(profileData.weight) : undefined),
      dob: profileData.dob ?? profileData.dateOfBirth,
      theme: profileData.theme,
    },
  };
  // Strip undefined keys so we don't accidentally clear server values.
  Object.keys(payload.user).forEach(
    (k) => payload.user[k] === undefined && delete payload.user[k]
  );
  const { data } = await api.put("/me", payload);
  return data.user;
};

export const getMe = async () => {
  const { data } = await api.get("/me");
  return data.user;
};

export const getNutritionGoals = async () => {
  const { data } = await api.get("/nutrition/goals");
  return data.goals;
};

export const updateNutritionGoals = async (_username, goalsData) => {
  const { data } = await api.put("/nutrition/goals", { goals: goalsData });
  return data.goals;
};

export const getDailyNutrition = async (_username, date) => {
  const { data } = await api.get(`/nutrition/daily/${date}`);
  return data;
};
