#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <crow.h>
#include <string>
#include <vector>
#include "Date.h"
#include "Set.h"
#include "Exercise.h"
#include "Workout.h"
#include "WorkoutLog.h"
#include "Profile.h"
#include "Meal.h"
#include "MealLog.h"

// Convert to JSON functions
crow::json::wvalue convertDateToJson(const Date& date);
crow::json::wvalue convertSetToJson(const Set& set);
crow::json::wvalue convertExerciseToJson(const Exercise& exercise);
crow::json::wvalue convertWorkoutToJson(const Workout& workout);
crow::json::wvalue convertProfileToJsonLimited(Profile& profile);
crow::json::wvalue convertProfileToJsonFull(Profile& profile);
crow::json::wvalue convertAllProfilesToJson(std::vector<Profile*>& allProfiles);
crow::json::wvalue convertMealToJson(const Meal& meal);
crow::json::wvalue convertMealLogToJson(const MealLog& mealLog);
crow::json::wvalue convertWorkoutLogToJson(const WorkoutLog& workoutLog);

// Convert from JSON functions
Date convertJsonToDate(const crow::json::rvalue& dateJson);
Set convertJsonToSet(const crow::json::rvalue& setJson);
Exercise convertJsonToExercise(const crow::json::rvalue& exerciseJson);
Workout convertJsonToWorkout(const crow::json::rvalue& workoutJson);
WorkoutLog convertJsonToWorkoutLog(const crow::json::rvalue& workoutLogJson);
Meal convertJsonToMeal(const crow::json::rvalue& mealJson);
MealLog convertJsonToMealLog(const crow::json::rvalue& mealLogJson);
Profile* convertJsonToProfile(const crow::json::rvalue& profileJson);

#endif