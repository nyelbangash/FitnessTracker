#include "Set.h"

Set::Set(const int reps, const double weight) : reps(reps), weight(weight) {};
int Set::getReps() const { return reps; }