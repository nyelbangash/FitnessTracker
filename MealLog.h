#ifndef MEAL_LOG_H
#define MEAL_LOG_H

#include "Meal.h"
#include "FitnessLog.h"

/**
 * @brief A log for tracking meals.
 *
 * This class extends the generic `Log` class to manage entries of type `Meal`.
 * It includes functionality to track total calories, protein, carbs, fat across all logged entries along with the meals themselves.
 */
class MealLog : public FitnessLog<Meal> {
public:
    /**
     * @brief Default constructor.
     *
     * Initializes an empty MealLog.
     */
    MealLog() = default;
    
    /**
     * @brief Constructs a MealLog with initial set of meals and total calories, protein, carbs, fat
     * 
     * @param meals A vector of type Meal containing meal entries.
     * @param totalCalories A double of the total calories accross all meals.
     * @param totalProtein A double of the total protein accross all meals.
     * @param totalCarbs A double of the total carbs accross all meals.
     * @param totalFat A double of the total calories accross all meals.
     */
    MealLog(std::vector<Meal> meals, double totalCalories, double totalProtein, double totalCarbs, double totalFat);

    /**
     * @brief Getter for the total calories across all meals.
     * 
     * @return A double of the total calories across all meals.
     */
    double getTotalCalories() const;

    /**
     * @brief Getter for the total protein across all meals.
     * 
     * @return A double of the total protein across all meals.
     */
    double getTotalProtein() const;

    /**
     * @brief Getter for the total carbs across all meals.
     * 
     * @return A double of the total carbs across all meals.
     */
    double getTotalCarbs() const;

    /**
     * @brief Getter for the total fat across all meals.
     * 
     * @return A double of the total fat across all meals.
     */
    double getTotalFat() const;

    /**
     * @brief Adds a new meal entry to the log.
     *
     * Updates the total calories, protein, carbs, fat acoordingly.
     *
     * @param meal The meal entry to add to the log.
     */
    void addEntry(const Meal& meal);

private:
    /**
     * @brief The total calories accumulated across all meals
     */
    double totalCalories = 0;

    /**
     * @brief The total protein accumulated across all meals
     */
    double totalProtein = 0;

    /**
     * @brief The total carbs accumulated across all meals
     */
    double totalCarbs = 0;

    /**
     * @brief The total fat accumulated across all meals
     */
    double totalFat = 0;
};

#endif