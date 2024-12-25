#ifndef REQUEST_FUNCTION_H
#define REQUEST_FUNCTION_H

#include <crow.h>
#include <vector>
#include <string>

#include "JsonFunctions.h"
#include "Profile.h"

/**
 * @brief Finds the index of a profile in a vector of profiles by name.
 * 
 * @param allProfiles A vector of pointers to Profile objects.
 * @param profRequested The name of the profile being searched for.
 * @return The index of the profile in the vector if found, or -1 if not found.
 */
int findProfileIndex(const std::vector<Profile*>& allProfiles, const std::string& profRequested);

/**
 * @brief Authenticates a user based on the parameters of provided request.
 * 
 * @param req The HTTP request.
 * @return A pointer to the authenticated Profile if successful.
 */
Profile* authenticateUser(const crow::request& req);

/**
 * @brief Handles a request to view a user's profile.
 * 
 * Based on the request parameters, either a limited view (excluding meal and workout log) will be returned, or the entire profile will be returned.
 * 
 * @param req The HTTP request containing profile viewing parameters.
 * @return A `crow::response` containing the requested profile's information.
 */
crow::response viewProfile(const crow::request& req);

/**
 * @brief Handles a request to create a new profile.
 * 
 * @param req The HTTP request containing the data for the new profile.
 * @return A `crow::response` indicating the success or failure of the profile creation.
 */
crow::response createProfile(const crow::request& req);

/**
 * @brief Handles a request to update an existing profile.
 * 
 * @param req The HTTP request containing the updated profile data.
 * @return A `crow::response` indicating the success or failure of the update.
 */
crow::response updateProfile(const crow::request& req);

/**
 * @brief Handles a request to view the user's meal log.
 * 
 * @param req The HTTP request.
 * @return A `crow::response` containing the user's meal log.
 */
crow::response viewMealLog(const crow::request& req);

/**
 * @brief Handles a request to add an entry to the user's meal log.
 * 
 * @param req The HTTP request containing the meal data.
 * @return A `crow::response` indicating the success or failure of adding the meal.
 */
crow::response addToMealLog(const crow::request& req);

/**
 * @brief Handles a request to view the user's workout log.
 * 
 * @param req The HTTP request.
 * @return A `crow::response` containing the user's workout log.
 */
crow::response viewWorkoutLog(const crow::request& req);

/**
 * @brief Handles a request to add an entry to the user's workout log.
 * 
 * @param req The HTTP request containing the new workout data.
 * @return A `crow::response` indicating the success or failure of adding the workout.
 */
crow::response addToWorkoutLog(const crow::request& req);

/**
 * @brief Handles a request to view all workouts logged on a specific date.
 * 
 * @param req The HTTP request.
 * @param date A string of the specific date to retrieve workouts for in the format "00-00-0000"
 * @return A `crow::response` containing all workouts logged on the specified date.
 */
crow::response viewWorkoutsOnDate(const crow::request& req, const std::string& date);


/**
 * @brief Handles a request to view all meals logged on a specific date.
 * 
 * @param req The HTTP request.
 * @param date A string of the specific date to retrieve workouts for in the format "00-00-0000"
 * @return A `crow::response` containing all meals logged on the specified date.
 */
crow::response viewMealsOnDate(const crow::request& req, const std::string& date);

#endif