#include <stdexcept>

#include "MealLog.h"

MealLog::MealLog(std::vector<Meal> meals, double totalCalories, double totalProtein, double totalCarbs, double totalFat) 
    :   Log<Meal>(meals),
        totalCalories(totalCalories),
        totalProtein(totalProtein),
        totalCarbs(totalCarbs),
        totalFat(totalFat) 
{
    // meals is allowed to be empty

    if(totalCalories < 0.0)
        throw std::invalid_argument("Total calories cannot be negative.");
    
    if(totalProtein < 0.0)
        throw std::invalid_argument("Total protein cannot be negative.");
    
     if(totalCarbs < 0.0)
        throw std::invalid_argument("Total carbs cannot be negative.");
    
    if(totalFat < 0.0)
        throw std::invalid_argument("Total fat cannot be negative.");
};

double MealLog::getTotalCalories() const { return totalCalories; }
double MealLog::getTotalProtein() const { return totalProtein; }
double MealLog::getTotalCarbs() const { return totalCarbs; }
double MealLog::getTotalFat() const { return totalFat; }

void MealLog::addEntry(const Meal& meal) 
{
    // dont have to check that meal is valid becasue you cant create an invalid meal to begin with
    entries.push_back(meal);
    totalCalories += meal.getCalories();
    totalProtein += meal.getProtein();
    totalCarbs += meal.getCarbs();
    totalFat += meal.getFat();
}