#include "WorkoutLog.h"

WorkoutLog::WorkoutLog(const std::vector<Workout>& workouts, double totalWorkoutTime) : Log<Workout>(workouts), totalWorkoutTime(totalWorkoutTime) {};

const double WorkoutLog::getTotalWorkoutTime() const { return totalWorkoutTime; }

void WorkoutLog::addEntry(const Workout& workout)
{
    entries.push_back(workout);
    totalWorkoutTime += workout.getLengthOfWorkout();
}