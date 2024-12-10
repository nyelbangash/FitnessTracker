#ifndef MEAL_H
#define MEAL_H

#include <string>
#include <vector>
#include <stdexcept>
#include "Date.h"

class Meal {
public:
    Meal(const std::string& mealName, double calories, double protein, double carbs, 
         double fat, const std::vector<std::string>& ingredients)
        : mealName(mealName),
          calories(calories),
          protein(protein),
          carbs(carbs),
          fat(fat),
          ingredients(ingredients),
          date(Date()) {  // Initialize with current date
        validateMealData();
    }
    
    Meal(const std::string& mealName, double calories, double protein, double carbs,
         double fat, const std::vector<std::string>& ingredients, const Date& date)
        : mealName(mealName),
          calories(calories),
          protein(protein),
          carbs(carbs),
          fat(fat),
          ingredients(ingredients),
          date(date) {
        validateMealData();
    }

    const std::string& getMealName() const { return mealName; }
    double getCalories() const { return calories; }
    double getProtein() const { return protein; }
    double getCarbs() const { return carbs; }
    double getFat() const { return fat; }
    const std::vector<std::string>& getIngredients() const { return ingredients; }
    const Date& getDate() const { return date; }
    
private:
    void validateMealData() {
        if (mealName.empty()) {
            throw std::invalid_argument("Meal name cannot be empty");
        }
        if (calories < 0) {
            throw std::invalid_argument("Calories cannot be negative");
        }
        if (protein < 0) {
            throw std::invalid_argument("Protein cannot be negative");
        }
        if (carbs < 0) {
            throw std::invalid_argument("Carbs cannot be negative");
        }
        if (fat < 0) {
            throw std::invalid_argument("Fat cannot be negative");
        }
        if (ingredients.empty()) {
            throw std::invalid_argument("Ingredients list cannot be empty");
        }
    }

    std::string mealName;
    double calories = 0.0;
    double protein = 0.0;
    double carbs = 0.0;
    double fat = 0.0;
    std::vector<std::string> ingredients;
    Date date;
};

#endif