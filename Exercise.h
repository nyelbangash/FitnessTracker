#ifndef EXERCISE_H
#define EXERCISE_H

#include <vector>
#include <string>
#include "Set.h"

/**
 * @brief This class represents one exercise in a workout, comprised of sets.
 * 
 * This class is comprised of several `Set` objects.
 * This class is used in composition of the `Workout` class. 
 */
class Exercise {
public:
    /**
     * @brief Constructs an `Exercise` object, with an initial set of sets and an exercise name.
     * 
     * @param sets A constant reference to a vector of type `Set`containing the sets that comprise the exercise.
     * @param exerciseName A constant reference to a string of the name of the exercise.
     * 
     * @throws std::invalid_argument if sets or exerciseName is empty 
     */
    Exercise(const std::vector<Set>& sets, const std::string& exerciseName);

    /**
     * @breif A getter for the sets that comprise the exercise.
     * 
     * @return A constant reference to a vector of type `Set` for the sets that comprise the exercise.
     */
    const std::vector<Set>& getSets() const;

    /**
     * @brief A getter for the exercise name
     * 
     * @return A constant reference to a string of the exercise name.
     */
    const std::string& getExerciseName() const;

private:
    /**
     * @brief The sets that comprise the exercise
     */
    std::vector<Set> sets;

    /**
     * @brief The name of the exercise.
     */
    std::string exerciseName;
};

#endif