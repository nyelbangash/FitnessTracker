#ifndef MEAL_H
#define MEAL_H

#include <string>
#include <vector>
#include "Date.h"

class Meal {
public:
    /**
     * @brief Constructs a Meal object with an initial meal name, amount of calories, protein, carbs, fat, and a set of ingredients.
     * 
     * dateMealEaten will be automatically initialized durring construction.
     * 
     * @param mealName A constant reference to a string of the name of the meal.
     * @param calories A double of the number of calories in the meal.
     * @param protein A double of the number of grams of protein in the meal.
     * @param carbs A double of the number of grams of carbs in the meal.
     * @param fat A double of the number of grams of fat in the meal.
     * @param ingredients A constant reference to a vector of strings of the ingredients that comprise the meal.
     */
    Meal(const std::string& mealName, double calories, double protein, double carbs, double fat, const std::vector<std::string>& ingredients);
    
    /**
     * @brief Constructs a Meal object with an initial meal name, amount of calories, protein, carbs, fat, and a set of ingredients.
     * 
     * @param mealName A constant reference to a string of the name of the meal.
     * @param calories A double of the number of calories in the meal.
     * @param protein A double of the number of grams of protein in the meal.
     * @param carbs A double of the number of grams of carbs in the meal.
     * @param fat A double of the number of grams of fat in the meal.
     * @param ingredients A constant reference to a vector of strings of the ingredients that comprise the meal.
     * @param date A constant reference to a `Date` object of the date the meal was eaten.
     */
    Meal(const std::string& mealName, double calories, double protein, double carbs, double fat, const std::vector<std::string>& ingredients, const Date& date);

    /**
     * @brief A getter for the name of the meal.
     * 
     * @return A constant reference to a string of the name of the meal.
     */
    const std::string& getMealName() const;

    /**
     * @brief A getter for the number of calories in the meal.
     * 
     * @return A double of the number of calories in the meal.
     */
    double getCalories() const;

    /**
     * @breif A getter for the number of grams of protein in the meal.
     * 
     * @return A double of the number of grams of protein in the meal.
     */
    double getProtein() const;

    /**
     * @breif A getter for the number of grams of carbs in the meal.
     * 
     * @return A double of the number of grams of carbs in the meal.
     */
    double getCarbs() const;

    /**
     * @breif A getter for the number of grams of fat in the meal.
     * 
     * @return A double of the number of grams of fat in the meal.
     */
    double getFat() const;

    /**
     * @brief A getter for the ingredients that comprise the meal.
     * 
     * @return A constant reference to a vector of strings of the ingredients that comprise the meal.
     */
    const std::vector<std::string>& getIngredients() const;

    /**
     * @brief A getter for the date the meal was eaten.
     * 
     * @return A constant reference to a `Date` object of the date the meal was eaten.
     */
    const Date& getDate() const;
    
private:
    /**
     * @brief The name of the meal
     */
    std::string mealName;

    /**
     * @brief The amount of calories in the meal
     */
    double calories = 0.0;

    /**
     * @brief The amount of grams of protein in the meal.
     */
    double protein = 0.0;

    /**
     * @brief The amount of grams of carbs in the meal.
     */
    double carbs = 0.0;

    /**
     * @brief The amount of grams of fat in the meal.
     */
    double fat = 0.0;

    /**
     * @brief The ingredients that comprise the meal.
     */
    std::vector<std::string> ingredients;

    /**
     * The date the meal was eaten.
     */
    Date dateMealEaten;
};

#endif