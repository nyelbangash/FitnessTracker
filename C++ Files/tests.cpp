#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest.h>

#include <string>
#include <vector>
#include <stdexcept>
#include <ctime>

#include "Date.h"
#include "Set.h"
#include "Exercise.h"
#include "Workout.h"
#include "Meal.h"
#include "MealLog.h"
#include "WorkoutLog.h"

TEST_CASE("Testing Date Class") {
    SUBCASE("Valid date construction") {
        Date validDay(6,12,2024);
        CHECK(validDay.getDay() == 6);
        CHECK(validDay.getMonth() == 12);
        CHECK(validDay.getYear() == 2024);
    }

    SUBCASE("Invalid Date Construction") {
        CHECK_THROWS_AS(Date(0,12,2024), std::invalid_argument);
        CHECK_THROWS_AS(Date(7,0,2024), std::invalid_argument);
        CHECK_THROWS_AS(Date(7,12,0), std::invalid_argument);
    }
}
TEST_CASE("Testing Set class") {
    SUBCASE("Valid set construction and getters") {
        Set validSet(5, 135.5);
        CHECK(validSet.getReps() == 5);
        CHECK(validSet.getWeight() == 135.5);
    }

    SUBCASE("Invalid sets throw exceptions") {
        CHECK_THROWS_AS(Set(-1, 135), std::invalid_argument);
        CHECK_THROWS_AS(Set(5, -1), std::invalid_argument);
    }
}

TEST_CASE("Testing Exercise class") {
    std::vector<Set> validSets = {Set(5, 135), Set(5, 155)};
    
    SUBCASE("Valid exercise construction and getters") {
        Exercise exercise(validSets, "Bench Press");
        CHECK(exercise.getExerciseName() == "Bench Press");
        CHECK(exercise.getSets().size() == 2);
    }

    SUBCASE("Invalid exercises throw exceptions") {
        std::vector<Set> emptySets;
        CHECK_THROWS_AS(Exercise(emptySets, "Bench Press"), std::invalid_argument);
        CHECK_THROWS_AS(Exercise(validSets, ""), std::invalid_argument);
    }
}

TEST_CASE("Testing Workout class") {
    std::vector<Set> validSets = {Set(5, 135)};
    std::vector<Exercise> validExercises = {Exercise(validSets, "Bench Press")};
    
    SUBCASE("Valid workout construction and getters") {
        Workout workout(validExercises, "Push Day", 45.0);
        CHECK(workout.getWorkoutName() == "Push Day");
        CHECK(workout.getLengthOfWorkout() == 45.0);
        CHECK(workout.getExercises().size() == 1);
    }

    SUBCASE("Date constructor works correctly") {
        Date specificDate(1, 1, 2024);
        Workout workout(validExercises, "Push Day", 45.0, specificDate);
        CHECK(workout.getDateCreated().getDay() == 1);
        CHECK(workout.getDateCreated().getMonth() == 1);
        CHECK(workout.getDateCreated().getYear() == 2024);
    }

    SUBCASE("Invalid workouts throw exceptions") {
        std::vector<Exercise> emptyExercises;
        CHECK_THROWS_AS(Workout(emptyExercises, "Push Day", 45.0), std::invalid_argument);
        CHECK_THROWS_AS(Workout(validExercises, "", 45.0), std::invalid_argument);
        CHECK_THROWS_AS(Workout(validExercises, "Push Day", 0), std::invalid_argument);
        CHECK_THROWS_AS(Workout(validExercises, "Push Day", -1), std::invalid_argument);
    }
}

TEST_CASE("Testing Meal class") {
    std::vector<std::string> validIngredients = {"chicken", "rice"};
    
    SUBCASE("Valid meal construction and getters") {
        Meal meal("Lunch", 500, 40, 50, 15, validIngredients);
        CHECK(meal.getMealName() == "Lunch");
        CHECK(meal.getCalories() == 500);
        CHECK(meal.getProtein() == 40);
        CHECK(meal.getCarbs() == 50);
        CHECK(meal.getFat() == 15);
        CHECK(meal.getIngredients().size() == 2);
    }

    SUBCASE("Date constructor works correctly") {
        Date specificDate(1, 1, 2024);
        Meal meal("Lunch", 500, 40, 50, 15, validIngredients, specificDate);
        CHECK(meal.getDate().getDay() == 1);
        CHECK(meal.getDate().getMonth() == 1);
        CHECK(meal.getDate().getYear() == 2024);
    }

    SUBCASE("Invalid meals throw exceptions") {
        std::vector<std::string> emptyIngredients;
        CHECK_THROWS_AS(Meal("", 500, 40, 50, 15, validIngredients), std::invalid_argument);
        CHECK_THROWS_AS(Meal("Lunch", -1, 40, 50, 15, validIngredients), std::invalid_argument);
        CHECK_THROWS_AS(Meal("Lunch", 500, -1, 50, 15, validIngredients), std::invalid_argument);
        CHECK_THROWS_AS(Meal("Lunch", 500, 40, -1, 15, validIngredients), std::invalid_argument);
        CHECK_THROWS_AS(Meal("Lunch", 500, 40, 50, -1, validIngredients), std::invalid_argument);
        CHECK_THROWS_AS(Meal("Lunch", 500, 40, 50, 15, emptyIngredients), std::invalid_argument);
    }
}

TEST_CASE("Testing MealLog class") {
    std::vector<std::string> validIngredients = {"chicken", "rice"};
    Meal validMeal("Lunch", 500, 40, 50, 15, validIngredients);
    std::vector<Meal> validMeals = {validMeal};
    
    SUBCASE("Default constructor") {
        MealLog emptyLog;
        CHECK(emptyLog.getMealCount() == 0);
        CHECK(emptyLog.getTotalCalories() == 0);
        CHECK(emptyLog.getTotalProtein() == 0);
        CHECK(emptyLog.getTotalCarbs() == 0);
        CHECK(emptyLog.getTotalFat() == 0);
    }

    SUBCASE("Parameterized constructor and getters") {
        MealLog log(validMeals, 500, 40, 50, 15, 1);
        CHECK(log.getMealCount() == 1);
        CHECK(log.getTotalCalories() == 500);
        CHECK(log.getTotalProtein() == 40);
        CHECK(log.getTotalCarbs() == 50);
        CHECK(log.getTotalFat() == 15);
    }

    SUBCASE("Adding meals updates totals") {
        MealLog log;
        log.addMeal(validMeal);
        CHECK(log.getMealCount() == 1);
        CHECK(log.getTotalCalories() == 500);
        CHECK(log.getTotalProtein() == 40);
        CHECK(log.getTotalCarbs() == 50);
        CHECK(log.getTotalFat() == 15);
    }

    SUBCASE("Invalid meal logs throw exceptions") {
        std::vector<Meal> meals;
        CHECK_THROWS_AS(MealLog(meals, -1, 0, 0, 0, 0), std::invalid_argument);
        CHECK_THROWS_AS(MealLog(meals, 0, -1, 0, 0, 0), std::invalid_argument);
        CHECK_THROWS_AS(MealLog(meals, 0, 0, -1, 0, 0), std::invalid_argument);
        CHECK_THROWS_AS(MealLog(meals, 0, 0, 0, -1, 0), std::invalid_argument);
        CHECK_THROWS_AS(MealLog(meals, 0, 0, 0, 0, -1), std::invalid_argument);
        CHECK_THROWS_AS(MealLog(meals, 0, 0, 0, 0, 1), std::invalid_argument);
    }
}

TEST_CASE("Testing WorkoutLog class") {
    std::vector<Set> validSets = {Set(5, 135)};
    std::vector<Exercise> validExercises = {Exercise(validSets, "Bench Press")};
    Workout validWorkout(validExercises, "Push Day", 45.0);
    std::vector<Workout> validWorkouts = {validWorkout};
    
    SUBCASE("Default constructor") {
        WorkoutLog emptyLog;
        CHECK(emptyLog.getWorkoutCount() == 0);
        CHECK(emptyLog.getTotalWorkoutTime() == 0);
    }

    SUBCASE("Parameterized constructor and getters") {
        WorkoutLog log(validWorkouts, 1, 45.0);
        CHECK(log.getWorkoutCount() == 1);
        CHECK(log.getTotalWorkoutTime() == 45.0);
    }

    SUBCASE("Adding workouts updates totals") {
        WorkoutLog log;
        log.addWorkout(validWorkout);
        CHECK(log.getWorkoutCount() == 1);
        CHECK(log.getTotalWorkoutTime() == 45.0);
    }

    SUBCASE("Invalid workout logs throw exceptions") {
        std::vector<Workout> workouts;
        CHECK_THROWS_AS(WorkoutLog(workouts, -1, 0), std::invalid_argument);
        CHECK_THROWS_AS(WorkoutLog(workouts, 0, -1), std::invalid_argument);
        CHECK_THROWS_AS(WorkoutLog(workouts, 1, 0), std::invalid_argument);
    }
}