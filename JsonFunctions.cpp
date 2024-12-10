#include "JsonFunctions.h"

using namespace crow;
using namespace std;

json::wvalue convertDateToJson(const Date& date) {
    json::wvalue dateJson;
    dateJson["day"] = date.getDay();
    dateJson["month"] = date.getMonth();
    dateJson["year"] = date.getYear();
    return dateJson;
}

json::wvalue convertSetToJson(const Set& set) {
    json::wvalue setJson;
    setJson["reps"] = set.getReps();
    setJson["weight"] = set.getWeight();
    return setJson;
}

json::wvalue convertExerciseToJson(const Exercise& exercise) {
    json::wvalue exerciseJson;
    exerciseJson["exerciseName"] = exercise.getExerciseName();
    
    vector<json::wvalue> setsJson;
    for (const Set& set : exercise.getSets())
    {
        setsJson.push_back(convertSetToJson(set));
    }
    exerciseJson["sets"] = move(setsJson);
    return exerciseJson;
}

json::wvalue convertWorkoutToJson(const Workout& workout) {
    json::wvalue workoutJson;
    workoutJson["lengthOfWorkout"] = workout.getLengthOfWorkout();
    workoutJson["dateCreated"] = convertDateToJson(workout.getDateCreated());

    vector<json::wvalue> exercisesJson;
    for (const Exercise& exercise : workout.getExercises())
    {
        exercisesJson.push_back(convertExerciseToJson(exercise));
    }

    workoutJson["exercises"] = move(exercisesJson);
    workoutJson["workoutName"] = workout.getWorkoutName();
    return workoutJson;
}

json::wvalue convertMealToJson(const Meal& meal) {
    json::wvalue mealJson;
    mealJson["mealName"] = meal.getMealName();
    mealJson["calories"] = meal.getCalories();
    mealJson["protein"] = meal.getProtein();
    mealJson["carbs"] = meal.getCarbs();
    mealJson["fat"] = meal.getFat();
    mealJson["ingredients"] = meal.getIngredients();
    mealJson["date"] = convertDateToJson(meal.getDate());
    return mealJson;
}

json::wvalue convertWorkoutLogToJson(const WorkoutLog& workoutLog) 
{
    json::wvalue workoutLogJson;

    vector<json::wvalue> workoutsJson;
    for (const Workout& workout : workoutLog.getLog()) 
    {
        workoutsJson.push_back(convertWorkoutToJson(workout));
    }
    
    workoutLogJson["workouts"] = move(workoutsJson);
    workoutLogJson["totalWorkoutTime"] = workoutLog.getTotalWorkoutTime();
    workoutLogJson["workoutCount"] = workoutLog.getWorkoutCount();
    return workoutLogJson;
}

json::wvalue convertMealLogToJson(const MealLog& mealLog) {
    json::wvalue mealLogJson;
    mealLogJson["totalCalories"] = mealLog.getTotalCalories();
    mealLogJson["totalProtein"] = mealLog.getTotalProtein();
    mealLogJson["totalCarbs"] = mealLog.getTotalCarbs();
    mealLogJson["totalFat"] = mealLog.getTotalFat();
    mealLogJson["mealCount"] = mealLog.getMealCount();

    vector<json::wvalue> mealsJson;
    for (const Meal& meal : mealLog.getLog()) 
    {
        mealsJson.push_back(convertMealToJson(meal));
    }
    
    mealLogJson["meals"] = move(mealsJson);
    return mealLogJson;
}

json::wvalue convertProfileToJsonLimited(Profile& profile) {
    json::wvalue profileJson;
    profileJson["firstName"] = profile.getFirstName();
    profileJson["lastName"] = profile.getLastName();
    profileJson["age"] = profile.getAge();
    profileJson["height"] = profile.getHeight();
    profileJson["weight"] = profile.getWeight();
    profileJson["dateAccountCreated"] = convertDateToJson(profile.getDateAccountCreated());
    profileJson["username"] = profile.getUsername();
    return profileJson;
}

json::wvalue convertProfileToJsonFull(Profile& profile)
{
    json::wvalue profileJson;
    profileJson["firstName"] = profile.getFirstName();
    profileJson["lastName"] = profile.getLastName();
    profileJson["age"] = profile.getAge();
    profileJson["height"] = profile.getHeight();
    profileJson["weight"] = profile.getWeight();
    profileJson["dateAccountCreated"] = convertDateToJson(profile.getDateAccountCreated());
    profileJson["username"] = profile.getUsername();
    profileJson["password"] = profile.getPassword();
    profileJson["workoutLog"] = convertWorkoutLogToJson(profile.getWorkoutLog());
    profileJson["mealLog"] = convertMealLogToJson(profile.getMealLog());
    return profileJson;
}

json::wvalue convertAllProfilesToJson(vector<Profile*>& allProfiles) 
{
    json::wvalue allProfilesJson;
    vector<json::wvalue> profilesJsonArray;

    for (Profile* profile : allProfiles) 
    {
        profilesJsonArray.push_back(convertProfileToJsonFull(*profile));
    }

    allProfilesJson["profiles"] = move(profilesJsonArray);
    return allProfilesJson;
}

Date convertJsonToDate(const json::rvalue& dateJson)
{
   if (!dateJson.has("day") || !dateJson.has("month") || !dateJson.has("year")) {
        throw invalid_argument("Invalid date JSON format");
    }
    
    try {
        int day = dateJson["day"].i();
        int month = dateJson["month"].i();
        int year = dateJson["year"].i();
        return Date(day, month, year);
    } catch (const exception& e) {
        throw invalid_argument("Invalid date values in JSON");
    }
}

Set convertJsonToSet(const json::rvalue& setJson) {
    if (!setJson.has("reps") || !setJson.has("weight")) {
        throw invalid_argument("Invalid set JSON format");
    }
    
    try {
        int reps = static_cast<int>(setJson["reps"].i());
        double weight = static_cast<double>(setJson["weight"].d());
        return Set(reps, weight);
    } catch (const exception& e) {
        throw invalid_argument("Invalid set values in JSON");
    }
}

Exercise convertJsonToExercise(const json::rvalue& exerciseJson) {
    if (!exerciseJson.has("exerciseName") || !exerciseJson.has("sets")) {
        throw invalid_argument("Invalid exercise JSON format");
    }
    
    try {
        string exerciseName = exerciseJson["exerciseName"].s();
        if (exerciseName.empty()) {
            throw invalid_argument("Exercise name cannot be empty");
        }

        vector<Set> sets;
        for (const auto& setJson : exerciseJson["sets"]) {
            sets.push_back(convertJsonToSet(setJson));
        }
        
        if (sets.empty()) {
            throw invalid_argument("Exercise must have at least one set");
        }

        return Exercise(sets, exerciseName);
    } catch (const invalid_argument& e) {
        throw; 
    } catch (const exception& e) {
        throw invalid_argument("Invalid exercise values in JSON");
    }
}

Workout convertJsonToWorkout(const json::rvalue& workoutJson) {
    if (!workoutJson.has("workoutName") || !workoutJson.has("lengthOfWorkout") || 
        !workoutJson.has("exercises") || !workoutJson.has("dateCreated")) {
        throw invalid_argument("Invalid workout JSON format");
    }
    
    try {
        string workoutName = workoutJson["workoutName"].s();
        if (workoutName.empty()) {
            throw invalid_argument("Workout name cannot be empty");
        }

        double lengthOfWorkout = workoutJson["lengthOfWorkout"].d();
        if (lengthOfWorkout <= 0) {
            throw invalid_argument("Workout length must be positive");
        }

        Date dateCreated = convertJsonToDate(workoutJson["dateCreated"]);

        vector<Exercise> exercises;
        for (const auto& exerciseJson : workoutJson["exercises"]) {
            exercises.push_back(convertJsonToExercise(exerciseJson));
        }
        
        if (exercises.empty()) {
            throw invalid_argument("Workout must have at least one exercise");
        }

        return Workout(exercises, workoutName, lengthOfWorkout, dateCreated);
    } catch (const invalid_argument& e) {
        throw;
    } catch (const exception& e) {
        throw invalid_argument("Invalid workout values in JSON");
    }
}

WorkoutLog convertJsonToWorkoutLog(const json::rvalue& workoutLogJson) {
    if (!workoutLogJson.has("workoutCount") || !workoutLogJson.has("totalWorkoutTime") || 
        !workoutLogJson.has("workouts")) {
        throw invalid_argument("Invalid workout log JSON format");
    }
    
    try {
        int workoutCount = workoutLogJson["workoutCount"].i();
        if (workoutCount < 0) {
            throw invalid_argument("Workout count cannot be negative");
        }

        double totalWorkoutTime = workoutLogJson["totalWorkoutTime"].d();
        if (totalWorkoutTime < 0) {
            throw invalid_argument("Total workout time cannot be negative");
        }

        vector<Workout> workouts;
        for (const auto& workoutJson : workoutLogJson["workouts"]) {
            workouts.push_back(convertJsonToWorkout(workoutJson));
        }

        if (workouts.size() != workoutCount) {
            throw invalid_argument("Workout count does not match number of workouts");
        }

        return WorkoutLog(workouts, workoutCount, totalWorkoutTime);
    } catch (const invalid_argument& e) {
        throw;
    } catch (const exception& e) {
        throw invalid_argument("Invalid workout log values in JSON");
    }
}

Meal convertJsonToMeal(const json::rvalue& mealJson) {
    if (!mealJson.has("mealName") || !mealJson.has("calories") || 
        !mealJson.has("protein") || !mealJson.has("carbs") || 
        !mealJson.has("fat") || !mealJson.has("ingredients") ||
        !mealJson.has("date")) {
        throw invalid_argument("Invalid meal JSON format");
    }
    
    try {
        string mealName = mealJson["mealName"].s();
        if (mealName.empty()) {
            throw invalid_argument("Meal name cannot be empty");
        }

        double calories = mealJson["calories"].d();
        double protein = mealJson["protein"].d();
        double carbs = mealJson["carbs"].d();
        double fat = mealJson["fat"].d();

        if (calories < 0 || protein < 0 || carbs < 0 || fat < 0) {
            throw invalid_argument("Nutritional values cannot be negative");
        }

        Date date = convertJsonToDate(mealJson["date"]);

        vector<string> ingredients;
        for (const auto& ingredientJson : mealJson["ingredients"]) {
            string ingredient = ingredientJson.s();
            if (ingredient.empty()) {
                throw invalid_argument("Ingredient cannot be empty");
            }
            ingredients.push_back(ingredient);
        }
        
        if (ingredients.empty()) {
            throw invalid_argument("Meal must have at least one ingredient");
        }

        return Meal(mealName, calories, protein, carbs, fat, ingredients, date);
    } catch (const invalid_argument& e) {
        throw;
    } catch (const exception& e) {
        throw invalid_argument("Invalid meal values in JSON");
    }
}

MealLog convertJsonToMealLog(const json::rvalue& mealLogJson) {
    if (!mealLogJson.has("totalCalories") || !mealLogJson.has("totalProtein") || 
        !mealLogJson.has("totalCarbs") || !mealLogJson.has("totalFat") || 
        !mealLogJson.has("mealCount") || !mealLogJson.has("meals")) {
        throw invalid_argument("Invalid meal log JSON format");
    }
    
    try {
        double totalCalories = mealLogJson["totalCalories"].d();
        double totalProtein = mealLogJson["totalProtein"].d();
        double totalCarbs = mealLogJson["totalCarbs"].d();
        double totalFat = mealLogJson["totalFat"].d();
        int mealCount = mealLogJson["mealCount"].i();

        if (totalCalories < 0 || totalProtein < 0 || totalCarbs < 0 || 
            totalFat < 0 || mealCount < 0) {
            throw invalid_argument("Log totals cannot be negative");
        }

        vector<Meal> meals;
        for (const auto& mealJson : mealLogJson["meals"]) {
            meals.push_back(convertJsonToMeal(mealJson));
        }

        if (meals.size() != mealCount) {
            throw invalid_argument("Meal count does not match number of meals");
        }

        return MealLog(meals, totalCalories, totalProtein, totalCarbs, totalFat, mealCount);
    } catch (const invalid_argument& e) {
        throw;
    } catch (const exception& e) {
        throw invalid_argument("Invalid meal log values in JSON");
    }
}

Profile* convertJsonToProfile(const json::rvalue& profileJson) {
    if (!profileJson.has("firstName") || !profileJson.has("lastName") || 
        !profileJson.has("age") || !profileJson.has("height") || 
        !profileJson.has("weight") || !profileJson.has("dateAccountCreated") || 
        !profileJson.has("username") || !profileJson.has("password") || 
        !profileJson.has("workoutLog") || !profileJson.has("mealLog")) {
        throw invalid_argument("Invalid profile JSON format");
    }
    
    try {
        string firstName = profileJson["firstName"].s();
        string lastName = profileJson["lastName"].s();
        string username = profileJson["username"].s();
        string password = profileJson["password"].s();

        if (firstName.empty() || lastName.empty() || username.empty() || password.empty()) {
            throw invalid_argument("Profile strings cannot be empty");
        }

        int age = profileJson["age"].i();
        double height = profileJson["height"].d();
        double weight = profileJson["weight"].d();

        if (age <= 0 || height <= 0 || weight <= 0) {
            throw invalid_argument("Profile measurements must be positive");
        }

        Date dateAccountCreated = convertJsonToDate(profileJson["dateAccountCreated"]);
        WorkoutLog workoutLog = convertJsonToWorkoutLog(profileJson["workoutLog"]);
        MealLog mealLog = convertJsonToMealLog(profileJson["mealLog"]);

        return new Profile(age, height, weight, firstName, lastName, 
                         dateAccountCreated, username, password, workoutLog, mealLog);
    } catch (const invalid_argument& e) {
        throw;
    } catch (const exception& e) {
        throw invalid_argument("Invalid profile values in JSON");
    }
}