#ifndef WORKOUT_H
#define WORKOUT_H

#include <vector>
#include "Exercise.h"
#include "Date.h"

class Workout {
public:
    /**
     * @brief Constructs a Workout object with an intital set of exercises, a workout name, and the length of the workout.
     * 
     * dateWorkedOut will be automatically initialized durring construction.
     * 
     * @param exercises A reference to a vector of type exercises.
     * @param workoutName A string of the workout name.
     * @param lengthOfWorkout A double of the length of the workout.
     */
    Workout(const std::vector<Exercise>& exercises, const std::string& workoutName, double lengthOfWorkout);

    /**
     * @brief Constructs a Workout object with an intital set of exercises, a workout name, the length of the workout, and the date worked out.
     * 
     * @param exercises A constant reference to a vector of type exercises.
     * @param workoutName A constant string of the workout name.
     * @param lengthOfWorkout A double of the length of the workout.
     * @param dateWorkedOut A constant reference to a Date object of the date worked out.
     */
    Workout(const std::vector<Exercise>& exercises, const std::string& workoutName, double lengthOfWorkout, const Date& dateWorkedOut);
    
    /**
     * @brief A getter for the exercises that comprise the workout.
     * 
     * @return A vector of type Exercise for the exercises that comprise the workout.
     */
    const std::vector<Exercise>& getExercises() const;

    /**
     * @brief A getter for the workout name.
     * 
     * @return A string of the workout name.
     */
    const std::string& getWorkoutName() const;

    /**
     * @brief A getter for the lenght of the workout.
     * 
     * @return A double of the length of the workout.
     */
    double getLengthOfWorkout() const;
    

    /**
     * @brief A getter for the date workoed out.
     * 
     * @return A date object of the date worked out.
     */
    const Date& getDateCreated() const;
    
private:

    /**
     * @brief The exercises that comprise the workout.
     */
    std::vector<Exercise> exercises;

    /**
     * @brief The name of the workout.
     */
    std::string workoutName;

    /**
     * The lenght of the workout.
     */
    double lengthOfWorkout;

    /**
     * The date the user worked out.
     */
    Date dateWorkedOut;
};

#endif