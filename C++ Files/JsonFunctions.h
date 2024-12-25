#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <crow.h>
#include <string>
#include <vector>

#include "Set.h"
#include "Exercise.h"
#include "Workout.h"
#include "WorkoutLog.h"
#include "Meal.h"
#include "MealLog.h"
#include "Date.h"
#include "Profile.h"

/**
 * @brief Converts a `Date` object into JSON.
 * 
 * @param date A `Date` object of the date to be converted to JSON
 * @return A `crow::json::wvalue` representing the JSON equivalent of the date.
 */
crow::json::wvalue convertDateToJson(const Date& date);

/**
 * @brief Converts a `Set` object into JSON.
 * 
 * @param set A `Set` object of the date to be converted to JSON
 * @return A `crow::json::wvalue` representing the JSON equivalent of the set.
 */
crow::json::wvalue convertSetToJson(const Set& set);

/**
 * @brief Converts an `Exercise` object into JSON.
 * 
 * @param exercise An `Exercise` object of the date to be converted to JSON
 * @return A `crow::json::wvalue` representing the JSON equivalent of the exercise.
 */
crow::json::wvalue convertExerciseToJson(const Exercise& exercise);

/**
 * @brief Converts a `Workout` object into JSON.
 * 
 * @param workout A `Workout` object of the date to be converted to JSON
 * @return A `crow::json::wvalue` representing the JSON equivalent of the workout.
 */
crow::json::wvalue convertWorkoutToJson(const Workout& workout);

/**
 * @brief Converts a limited view of a `Profile` object into JSON.
 * 
 * Will not show the user's workout log or meal log
 * 
 * @param profile A `Profile` object of the date to be converted to JSON
 * @return A `crow::json::wvalue` representing the JSON equivalent of the profile.
 */
crow::json::wvalue convertProfileToJsonLimited(Profile& profile);

/**
 * @brief Converts an entire `Profile` object into JSON.
 * 
 * @param profile A `Profile` object of the date to be converted to JSON
 * @return A `crow::json::wvalue` representing the JSON equivalent of the profile.
 */
crow::json::wvalue convertProfileToJsonFull(Profile& profile);

/**
 * @brief Converts a vector of `Profile` pointers to a JSON representation.
 * 
 * @param allProfiles The vector of `Profile` pointers to convert.
 * @return A `crow::json::wvalue` representing the JSON equivalent of all profiles.
 */
crow::json::wvalue convertAllProfilesToJson(std::vector<Profile*>& allProfiles);

/**
 * @brief Converts a `Meal` object to a JSON representation.
 * 
 * @param meal The `Meal` object to convert.
 * @return A `crow::json::wvalue` representing the JSON equivalent of the meal.
 */
crow::json::wvalue convertMealToJson(const Meal& meal);

/**
 * @brief Converts a `MealLog` object to a JSON representation.
 * 
 * @param mealLog The `MealLog` object to convert.
 * @return A `crow::json::wvalue` representing the JSON equivalent of the meal log.
 */
crow::json::wvalue convertMealLogToJson(const MealLog& mealLog);

/**
 * @brief Converts a `WorkoutLog` object to a JSON representation.
 * 
 * @param workoutLog The `WorkoutLog` object to convert.
 * @return A `crow::json::wvalue` representing the JSON equivalent of the workout log.
 */
crow::json::wvalue convertWorkoutLogToJson(const WorkoutLog& workoutLog);

/**
 * @brief Converts a JSON representation into a `Date` object.
 * 
 * @param dateJson The JSON representation of the `Date` object.
 * @return A `Date` object reconstructed from the JSON data.
 */
Date convertJsonToDate(const crow::json::rvalue& dateJson);

/**
 * @brief Converts a JSON representation into a `Set` object.
 * 
 * @param setJson The JSON representation of the `Set` object.
 * @return A `Set` object reconstructed from the JSON data.
 */
Set convertJsonToSet(const crow::json::rvalue& setJson);

/**
 * @brief Converts a JSON representation into a `Exercise` object.
 * 
 * @param exerciseJson The JSON representation of the `Exercise` object.
 * @return A `Exercise` object reconstructed from the JSON data.
 */
Exercise convertJsonToExercise(const crow::json::rvalue& exerciseJson);

/**
 * @brief Converts a JSON representation into a `Workout` object.
 * 
 * @param workoutJson The JSON representation of the `Workout` object.
 * @return A `Workout` object reconstructed from the JSON data.
 */
Workout convertJsonToWorkout(const crow::json::rvalue& workoutJson);

/**
 * @brief Converts a JSON representation into a `WorkoutLog` object.
 * 
 * @param workoutLogJson The JSON representation of the `WorkoutLog` object.
 * @return A `WorkoutLog` object reconstructed from the JSON data.
 */
WorkoutLog convertJsonToWorkoutLog(const crow::json::rvalue& workoutLogJson);

/**
 * @brief Converts a JSON representation into a `Meal` object.
 * 
 * @param mealJson The JSON representation of the `Meal` object.
 * @return A `Meal` object reconstructed from the JSON data.
 */
Meal convertJsonToMeal(const crow::json::rvalue& mealJson);

/**
 * @brief Converts a JSON representation into a `MealLog` object.
 * 
 * @param mealLogJson The JSON representation of the `MealLog` object.
 * @return A `MealLog` object reconstructed from the JSON data.
 */
MealLog convertJsonToMealLog(const crow::json::rvalue& mealLogJson);

/**
 * @brief Converts a JSON representation into a `Profile` object pointer.
 * 
 * @param profileJson The JSON representation of the `Profile` object.
 * @return A `Profile` object pointer reconstructed from the JSON data.
 */
Profile* convertJsonToProfile(const crow::json::rvalue& profileJson);

#endif