#ifndef WORKOUT_H
#define WORKOUT_H

#include <vector>
#include <stdexcept>
#include "Exercise.h"
#include "Date.h"

class Workout {
public:
    Workout(const std::vector<Exercise>& exercises, const std::string& workoutName, 
            double lengthOfWorkout) 
            : exercises(exercises),
              workoutName(workoutName),
              lengthOfWorkout(lengthOfWorkout),
              dateCreated(Date()) {  // Initialize with current date
        validateWorkoutData();
    }
    
    Workout(const std::vector<Exercise>& exercises, const std::string& workoutName, 
            double lengthOfWorkout, const Date& dateCreated) 
            : exercises(exercises),
              workoutName(workoutName),
              lengthOfWorkout(lengthOfWorkout),
              dateCreated(dateCreated) {
        validateWorkoutData();
    }
    
    const std::vector<Exercise>& getExercises() const { return exercises; }
    const std::string& getWorkoutName() const { return workoutName; }
    double getLengthOfWorkout() const { return lengthOfWorkout; }
    const Date& getDateCreated() const { return dateCreated; }
    
private:
    void validateWorkoutData() {
        if (exercises.empty())
            throw std::invalid_argument("Exercises vector cannot be empty");
        if (workoutName.empty())
            throw std::invalid_argument("Workout name cannot be empty");
        if (lengthOfWorkout <= 0)
            throw std::invalid_argument("Workout length must be positive");
    }

    std::vector<Exercise> exercises;
    std::string workoutName;
    double lengthOfWorkout;
    Date dateCreated;
};

#endif