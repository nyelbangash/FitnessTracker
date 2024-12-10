#ifndef WORKOUT_LOG_H
#define WORKOUT_LOG_H

#include <vector>
#include <stdexcept>
#include "Workout.h"
#include "FitnessLog.h"

class WorkoutLog : public FitnessLog<Workout> {
public:
    WorkoutLog() = default;
    
    WorkoutLog(const std::vector<Workout>& workouts, int workoutCount, double totalWorkoutTime)
        : FitnessLog<Workout>(workouts, workoutCount),
          totalWorkoutTime(totalWorkoutTime) {
        validateWorkoutLogData();
        if (workouts.size() != workoutCount) {
            throw std::invalid_argument("Workout count does not match size of workouts vector");
        }
    }

    double getTotalWorkoutTime() const { return totalWorkoutTime; }
    int getWorkoutCount() const { return entryCount; }
    
    void addWorkout(const Workout& workout) {
        if (workout.getLengthOfWorkout() <= 0) {
            throw std::invalid_argument("Workout length must be positive");
        }
        entries.push_back(workout);
        totalWorkoutTime += workout.getLengthOfWorkout();
        entryCount += 1;
    }

private:
    void validateWorkoutLogData() {
        if (totalWorkoutTime < 0) {
            throw std::invalid_argument("Total workout time cannot be negative");
        }
    }

    double totalWorkoutTime = 0.0;
};

#endif