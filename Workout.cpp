#include "Workout.h"

Workout::Workout(const std::vector<Exercise>& exercises, const std::string& workoutName, double lengthOfWorkout) 
        :   exercises(exercises),
            workoutName(workoutName),
            lengthOfWorkout(lengthOfWorkout),
            dateWorkedOut(Date()) {};

Workout::Workout(const std::vector<Exercise>& exercises, const std::string& workoutName, double lengthOfWorkout, const Date& dateWorkedOut)
        :   exercises(exercises),
            workoutName(workoutName),
            lengthOfWorkout(lengthOfWorkout),
            dateWorkedOut(dateWorkedOut) {};

const std::vector<Exercise>& Workout::getExercises() const { return exercises; }
const std::string& Workout::getWorkoutName() const { return workoutName; }
double Workout::getLengthOfWorkout() const { return lengthOfWorkout; }
const Date& Workout::getDateCreated() const { return dateWorkedOut; }