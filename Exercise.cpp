#include "Exercise.h"

Exercise::Exercise(const std::vector<Set>& sets, const std::string& exerciseName) : sets(sets), exerciseName(exerciseName) {};

const std::vector<Set>& Exercise::getSets() const { return sets; }
const std::string& Exercise::getExerciseName() const { return exerciseName; }