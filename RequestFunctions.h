#ifndef REQUEST_FUNCTION_H
#define REQUEST_FUNCTION_H

#include <crow.h>
#include "JsonFunctions.h"
#include "Profile.h"
#include <vector>
#include <string>

// Helper functions
int findProfileIndex(const std::vector<Profile*>& allProfiles, const std::string& profRequested);
Profile* authenticateUser(const crow::request& req);

// Profile endpoints
crow::response viewProfile(const crow::request& req);
crow::response createProfile(const crow::request& req);
crow::response updateProfile(const crow::request& req);

// Meal log endpoints
crow::response viewMealLog(const crow::request& req);
crow::response addToMealLog(const crow::request& req);

// Workout log endpoints  
crow::response viewWorkoutLog(const crow::request& req);
crow::response addToWorkoutLog(const crow::request& req);

crow::response viewWorkoutsOnDate(const crow::request& req, const std::string& date);
crow::response viewMealsOnDate(const crow::request& req, const std::string& date);

#endif