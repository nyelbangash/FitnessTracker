#ifndef MEAL_LOG_H
#define MEAL_LOG_H

#include <stdexcept>
#include "Meal.h"
#include "FitnessLog.h"

class MealLog : public FitnessLog<Meal> {
public:
    MealLog() = default;
    
    MealLog(std::vector<Meal> meals, double totalCalories, double totalProtein, 
            double totalCarbs, double totalFat, int mealCount) 
            : FitnessLog<Meal>(meals, mealCount),
              totalCalories(totalCalories),
              totalProtein(totalProtein),
              totalCarbs(totalCarbs),
              totalFat(totalFat) {
        validateNutritionalValues();
        if (meals.size() != mealCount) {
            throw std::invalid_argument("Meal count does not match size of meals vector");
        }
    }

    //Getters
    double getTotalCalories() const { return totalCalories; }
    double getTotalProtein() const { return totalProtein; }
    double getTotalCarbs() const { return totalCarbs; }
    double getTotalFat() const { return totalFat; }
    int getMealCount() const { return entryCount; }

    //Add Meal
    void addMeal(const Meal& meal) {
        if (meal.getCalories() < 0 || meal.getProtein() < 0 || 
            meal.getCarbs() < 0 || meal.getFat() < 0) {
            throw std::invalid_argument("Meal nutritional values cannot be negative");
        }

        entries.push_back(meal);
        totalCalories += meal.getCalories();
        totalProtein += meal.getProtein();
        totalCarbs += meal.getCarbs();
        totalFat += meal.getFat();
        entryCount += 1;
    }

private:
    //Validate constructor
    void validateNutritionalValues() {
        if (totalCalories < 0)
            throw std::invalid_argument("Total calories cannot be negative");
        if (totalProtein < 0)
            throw std::invalid_argument("Total protein cannot be negative");
        if (totalCarbs < 0)
            throw std::invalid_argument("Total carbs cannot be negative");
        if (totalFat < 0)
            throw std::invalid_argument("Total fat cannot be negative");
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    // std::vector<Meal> meals;
};

#endif