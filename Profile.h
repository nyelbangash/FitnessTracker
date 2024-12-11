#ifndef PROFILE_H
#define PROFILE_H

#include <string>
#include <stdexcept>
#include "Date.h"
#include "WorkoutLog.h"
#include "MealLog.h"

/**
 * @brief Stores all information about a user including their meal and workout logs.
 * 
 * Includes information on the users age, height, weight, first and last name, when the account was created, their username and password, and their workout and meal log.
 * This class servers as the main entry point for all requests.
 * 
 * This class is comprised of a `MealLog` and a `WorkoutLog`.
 */
class Profile {
public:
    /**
     * @brief Constructs a `Profile` object with an initial age, height, weight, first name, last name, username, and password.
     * 
     * This constructor is primarily used for when creating a new user.
     * 
     * @param age A constant integer of the user's age.
     * @param height A constant double of the user's height in cm's.
     * @param weight A constant double of the user's weight in kg's.
     * @param firstName A constant reference to a string of the user's first name.
     * @param lastName A constant reference to a string of the user's last name.
     * @param username A constant reference to a string of the user's username.
     * @param password A constant reference to a string of the user's password.
     */
    Profile(const int age, const double height, const double weight, 
            const std::string& firstName, const std::string& lastName, 
            const std::string& username, const std::string& password);

    /**
     * @brief Constructs a `Profile` object with an initial age, height, weight, first name, last name, username, password, workout log, and meal log.
     * 
     * This constructor is primarily used for when reconstructing a `Profile` object from JSON.
     * 
     * @param age A constant integer of the user's age.
     * @param height A constant double of the user's height in cm's.
     * @param weight A constant double of the user's weight in kg's.
     * @param firstName A constant reference to a string of the user's first name.
     * @param lastName A constant reference to a string of the user's last name.
     * @param username A constant reference to a string of the user's username.
     * @param password A constant reference to a string of the user's password.
     * @param workoutLog A constant reference to a `WorkoutLog` object of the user's workout log.
     * @param mealLog A constant reference to a `MealLog` object of the user's meal log.
     */
    Profile(const int age, const double height, const double weight,
            const std::string& firstName, const std::string& lastName,
            const Date& dateAccountCreated, const std::string& username,
            const std::string& password, const WorkoutLog& workoutLog,
            const MealLog& mealLog);

    /**
     * @brief Deconstructs the `Profile`
     */
    ~Profile() = default;
    
    /**
     * @breif A getter for the user's age.
     * 
     * @return An integer of the user's age.
     */
    int getAge() const;

    /**
     * @breif A getter for the user's height.
     * 
     * @return A double of the user's height.
     */
    double getHeight() const;

    /**
     * @breif A getter for the user's weight.
     * 
     * @return A double of the user's weight.
     */
    double getWeight() const;

    /**
     * @brief A getter for the user's first name.
     * 
     * @return A constant reference to a string of the user's first name.
     */
    const std::string& getFirstName() const;

    /**
     * @brief A getter for the user's last name.
     * 
     * @return A constant reference to a string of the user's last name.
     */
    const std::string& getLastName() const;

    /**
     * @brief A getter for the user's username.
     * 
     * @return A constant reference to a string of the user's username.
     */
    const std::string& getUsername() const;

    /**
     * @brief A getter for the user's password.
     * 
     * @return A constant reference to a string of the user's password.
     */
    const std::string& getPassword() const;

    /**
     * @brief A getter for the date the user created their account.
     * 
     * @return A constant reference to a `Date` object of the date the user created their account.
     */
    const Date& getDateAccountCreated() const;

    /**
     * @brief Updates the user's date of birth.
     * 
     * @param dateOfBirth A constant reference to a `Date` object of the user's date of birth.
     */
    void updateDateOfBirth(const Date& dateOfBirth);

    /**
     * @brief Updates the user's height.
     * 
     * @param height A double of the user's height in cm's.
     */
    void updateHeight(const double height);

    /**
     * @brief Updates the user's weight.
     * 
     * @param weight A double of the user's weight in kg's.
     */
    void updateWeight(const double weight);

    /**
     * @brief Updates the user's first name.
     * 
     * @param firstName A constant reference of a string of the user's first name.
     */
    void updateFirstName(const std::string& firstName);

    /**
     * @brief Updates the user's last name.
     * 
     * @param lastName A constant reference of a string of the user's last name.
     */
    void updateLastName(const std::string& lastName);

    /**
     * @brief Updates the user's username.
     * 
     * @param username A constant reference of a string of the user's usernmae.
     */
    void updateUsername(const std::string& username);

    /**
     * @brief Updates the user's password.
     * 
     * @param password A constant reference of a string of the user's password.
     */
    void updatePassword(const std::string& password);
    
    /**
     * @brief A getter for the user's workout log.
     * 
     * @return A reference to a `WorkoutLog` object of the user's workout log.
     */
    WorkoutLog& getWorkoutLog();

    /**
     * @brief A getter for the user's meal log.
     * 
     * @return A reference to a `MealLog` object of the user's meal log.
     */
    MealLog& getMealLog();

private:
    void validateProfileData();

    /**
     * @brief The user's height in cm.
     */
    double height;

    /**
     * @brief The user's weight in kg.
     */
    double weight;

    /**
     * @brief The user's first name.
     */
    std::string firstName;

    /**
     * @brief The user's last name.
     */
    std::string lastName;

    /**
     * @brief The date the user created their account.
     */
    Date dateAccountCreated;

    /**
     * @brief The user's date of birth.
     */
    Date dateOfBirth;

    /**
     * @brief The user's username.
     */
    std::string username;

    /**
     * @brief The user's password.
     */
    std::string password;

    /**
     * @brief The user's workout log.
     */
    WorkoutLog workoutLog;

    /**
     * The user's meal log.
     */
    MealLog mealLog;
};

#endif