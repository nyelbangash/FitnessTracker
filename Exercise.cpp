#include <stdexcept>

#include "Exercise.h"

Exercise::Exercise(const std::vector<Set>& sets, const std::string& exerciseName) : sets(sets), exerciseName(exerciseName) 
{
    if(sets.empty())
        throw std::invalid_argument("Cannot provide an empty set list");

    if(exerciseName.empty())
        throw std::invalid_argument("Must provide a name for the exercise");
};

const std::vector<Set>& Exercise::getSets() const { return sets; }
const std::string& Exercise::getExerciseName() const { return exerciseName; }