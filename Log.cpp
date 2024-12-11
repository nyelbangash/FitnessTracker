#include "Log.h"


template <typename T>
Log<T>::Log(const std::vector<T>& entriest) : entries(entries) {};

template <typename T>
const std::vector<T> Log<T>::getEntries() const { return entries; }

template <typename T>
const int Log<T>::getEntryCount() const { return entries.size(); }

// explicitly say what types will be used otherwise compiler throws a hissy fit

#include "Meal.h"
#include "Workout.h"
template class Log<Meal>;
template class Log<Workout>;