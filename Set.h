#ifndef SET_H
#define SET_H

#include <stdexcept>

class Set {
public:
    Set(const int reps, const double weight) : reps(reps), weight(weight) {
        if (reps < 0)
            throw std::invalid_argument("Reps must be positive");
        if (weight < 0)
            throw std::invalid_argument("Weight must be positive");
    }
    
    int getReps() const { return reps; }
    double getWeight() const { return weight; }
    
private:
    int reps;
    double weight;
};

#endif