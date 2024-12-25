#include <stdexcept>

#include "Workout.h"

Workout::Workout(const std::vector<Exercise>& exercises, const std::string& workoutName, double lengthOfWorkout) 
        :   exercises(exercises),
            workoutName(workoutName),
            lengthOfWorkout(lengthOfWorkout),
            dateWorkedOut(Date()) 
{
    if(exercises.empty())
        throw std::invalid_argument("Cannot provide an empty exercises list.");

    if(workoutName.empty())
        throw std::invalid_argument("Must provide a name for the workout.");

    if(lengthOfWorkout < 0.0)
        throw std::invalid_argument("Length of workout cannot be negative.");
};

Workout::Workout(const std::vector<Exercise>& exercises, const std::string& workoutName, double lengthOfWorkout, const Date& dateWorkedOut)
        :   exercises(exercises),
            workoutName(workoutName),
            lengthOfWorkout(lengthOfWorkout),
            dateWorkedOut(dateWorkedOut) 
{
    if(exercises.empty())
        throw std::invalid_argument("Cannot provide an empty exercises list.");

    if(workoutName.empty())
        throw std::invalid_argument("Must provide a name for the workout.");

    if(lengthOfWorkout < 0.0)
        throw std::invalid_argument("Length of workout cannot be negative.");
    
    // dont need to check that dateWorkedOut is a valid Date object because you cant create an invalid Date object to begin with
};

const std::vector<Exercise>& Workout::getExercises() const { return exercises; }
const std::string& Workout::getWorkoutName() const { return workoutName; }
double Workout::getLengthOfWorkout() const { return lengthOfWorkout; }
const Date& Workout::getDateCreated() const { return dateWorkedOut; }