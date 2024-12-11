#include <stdexcept>

#include "WorkoutLog.h"

WorkoutLog::WorkoutLog(const std::vector<Workout>& workouts, double totalWorkoutTime) : Log<Workout>(workouts), totalWorkoutTime(totalWorkoutTime) 
{
    // workouts is allowed to be empty

    if(totalWorkoutTime < 0.0)
        throw std::invalid_argument("Total workout time cannot be negative.");
};

const double WorkoutLog::getTotalWorkoutTime() const { return totalWorkoutTime; }

// dont need to check that the Workout object is valid because you cannot create an invalid workout to begin with
void WorkoutLog::addEntry(const Workout& workout)
{
    entries.push_back(workout);
    totalWorkoutTime += workout.getLengthOfWorkout();
}