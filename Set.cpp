#include <stdexcept>

#include "Set.h"

Set::Set(const int reps, const double weight) : reps(reps), weight(weight) 
{
    if(reps <= 0)
        throw std::invalid_argument("Reps must be at least 1");

    if(weight < 0.0)
        throw std::invalid_argument("Weight must be positive");
};
int Set::getReps() const { return reps; }