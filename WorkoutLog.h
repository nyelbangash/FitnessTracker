#ifndef WORKOUT_LOG_H
#define WORKOUT_LOG_H

#include "Workout.h"
#include "Log.h"

/**
 * @brief A log for tracking workouts.
 *
 * This class extends the generic `Log` class to manage entries of type `Workout`.
 * It includes functionality to track the total workout time across all logged entries.
 */
class WorkoutLog : public Log<Workout> {
public:
    /**
     * @brief Default constructor for the WorkoutLog class.
     *
     * Initializes an empty workout log with zero total workout time.
     */
    WorkoutLog() = default;

    /**
     * @brief Constructs a WorkoutLog with an initial set of workouts and total workout time.
     *
     * @param workouts A constant reference to a vector of type `Workout` containing workout entries.
     * @param totalWorkoutTime A double of the total time worked out across all workouts in the initial set.
     * 
     * @throws std::invalid_argument if totalWorkoutTime <= 0
     */
    WorkoutLog(const std::vector<Workout>& workouts, double totalWorkoutTime);

    /**
     * @brief A getter for the total workout time logged.
     *
     * @return The total workout time as a double.
     */
    const double getTotalWorkoutTime() const;

    /**
     * @brief Adds a new workout entry to the log.
     *
     * Updates the total workout time accordingly.
     *
     * @param workout A constant reference to a `Workout` object of the workout entry to add to the log.
     */
    void addEntry(const Workout& workout) override;

private:
    /**
     * @brief The total time worked out across all workouts
     */
    double totalWorkoutTime = 0.0;
};

#endif