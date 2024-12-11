#include "MealLog.h"

MealLog::MealLog(std::vector<Meal> meals, double totalCalories, double totalProtein, double totalCarbs, double totalFat) 
    :   FitnessLog<Meal>(meals, mealCount),
        totalCalories(totalCalories),
        totalProtein(totalProtein),
        totalCarbs(totalCarbs),
        totalFat(totalFat) {};

double MealLog::getTotalCalories() const { return totalCalories; }
double MealLog::getTotalProtein() const { return totalProtein; }
double MealLog::getTotalCarbs() const { return totalCarbs; }
double MealLog::getTotalFat() const { return totalFat; }
int MealLog::getMealCount() const { return entryCount; }

void MealLog::addEntry(const Meal& meal) 
{
    entries.push_back(meal);
    totalCalories += meal.getCalories();
    totalProtein += meal.getProtein();
    totalCarbs += meal.getCarbs();
    totalFat += meal.getFat();
}