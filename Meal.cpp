#include "Meal.h"

Meal::Meal(const std::string& mealName, double calories, double protein, double carbs, double fat, const std::vector<std::string>& ingredients)
        :   mealName(mealName),
            calories(calories),
            protein(protein),
            carbs(carbs),
            fat(fat),
            ingredients(ingredients),
            dateMealEaten(Date()) {};

Meal::Meal(const std::string& mealName, double calories, double protein, double carbs, double fat, const std::vector<std::string>& ingredients, const Date& dateMealEaten)
        : mealName(mealName),
          calories(calories),
          protein(protein),
          carbs(carbs),
          fat(fat),
          ingredients(ingredients),
          dateMealEaten(dateMealEaten) {};

const std::string& Meal::getMealName() const { return mealName; }
double Meal::getCalories() const { return calories; }
double Meal::getProtein() const { return protein; }
double Meal::getCarbs() const { return carbs; }
double Meal::getFat() const { return fat; }
const std::vector<std::string>& Meal::getIngredients() const { return ingredients; }
const Date& Meal::getDate() const { return dateMealEaten; }