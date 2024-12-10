#ifndef EXERCISE_H
#define EXERCISE_H

#include <vector>
#include <string>
#include <stdexcept>
#include "Set.h"

class Exercise {
public:
    Exercise(const std::vector<Set>& sets, const std::string& exerciseName) 
        : sets(sets), exerciseName(exerciseName) {
        if (sets.empty())
            throw std::invalid_argument("Sets vector cannot be empty");
        if (exerciseName.empty())
            throw std::invalid_argument("Exercise name cannot be empty");
    }
    
    const std::vector<Set>& getSets() const { return sets; }
    const std::string& getExerciseName() const { return exerciseName; }

private:
    std::vector<Set> sets;
    std::string exerciseName;
};

#endif