#include <stdexcept>

#include "Meal.h"

Meal::Meal(const std::string& mealName, double calories, double protein, double carbs, double fat, const std::vector<std::string>& ingredients)
        :   mealName(mealName),
            calories(calories),
            protein(protein),
            carbs(carbs),
            fat(fat),
            ingredients(ingredients),
            dateMealEaten(Date()) 
{ verifyValidData(); };

Meal::Meal(const std::string& mealName, double calories, double protein, double carbs, double fat, const std::vector<std::string>& ingredients, const Date& dateMealEaten)
        : mealName(mealName),
          calories(calories),
          protein(protein),
          carbs(carbs),
          fat(fat),
          ingredients(ingredients),
          dateMealEaten(dateMealEaten) 
{
        verifyValidData();
        // dont have to check to make sure dateMealEaten is valid because you cant create an invalid meal to begin with
};

const std::string& Meal::getMealName() const { return mealName; }
double Meal::getCalories() const { return calories; }
double Meal::getProtein() const { return protein; }
double Meal::getCarbs() const { return carbs; }
double Meal::getFat() const { return fat; }
const std::vector<std::string>& Meal::getIngredients() const { return ingredients; }
const Date& Meal::getDate() const { return dateMealEaten; }

void Meal::verifyValidData() const
{
        if(mealName.empty())
        throw std::invalid_argument("Must provide a name for the meal");

        if(calories < 0.0)
                throw std::invalid_argument("Calories cannot be negative");

        if(protein < 0.0)
                throw std::invalid_argument("Protein cannot be negative");

        if(carbs < 0.0)
                throw std::invalid_argument("Carbs cannot be negative");

        if(fat < 0.0)
                throw std::invalid_argument("Fat cannot be negative");

        if(ingredients.empty())
                throw std::invalid_argument("Cannot provide an empty set of ingredients.");
}