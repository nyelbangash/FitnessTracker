#include "Profile.h"

Profile::Profile(const int age, const double height, const double weight, const std::string& firstName, const std::string& lastName, const std::string& username, const std::string& password)
        : age(age), 
          height(height), 
          weight(weight), 
          firstName(firstName), 
          lastName(lastName),
          username(username), 
          password(password),
          dateAccountCreated(Date()) 
{
    validateProfileData();
}

Profile::Profile(const int age, const double height, const double weight, const std::string& firstName, const std::string& lastName, const Date& dateAccountCreated, const std::string& username, const std::string& password, const WorkoutLog& workoutLog, const MealLog& mealLog)
        : age(age), 
          height(height), 
          weight(weight),
          firstName(firstName), 
          lastName(lastName),
          dateAccountCreated(dateAccountCreated), 
          username(username),
          password(password), 
          workoutLog(workoutLog), 
          mealLog(mealLog) 
{
    validateProfileData();
}

int Profile::getAge() const { return age; }
double Profile::getHeight() const { return height; }
double Profile::getWeight() const { return weight; }
const std::string& Profile::getFirstName() const { return firstName; }
const std::string& Profile::getLastName() const { return lastName; }
const std::string& Profile::getUsername() const { return username; }
const std::string& Profile::getPassword() const { return password; }
const Date& Profile::getDateAccountCreated() const { return dateAccountCreated; }
WorkoutLog& Profile::getWorkoutLog() { return workoutLog; }
MealLog& Profile::getMealLog() { return mealLog; }

void Profile::updateDateOfBirth(const Date& dateOfBirth) { this->dateOfBirth = dateOfBirth; }
void Profile::updateHeight(const double height) { if(height > 0.0) this->height = height; }
void Profile::updateWeight(const double weight) { if(weight > 0.0) this->weight = weight; }
void Profile::updateFirstName(const std::string& firstName) { if(firstName != "") this->firstName = firstName; }
void Profile::updateLastName(const std::string& lastName) { if(lastName != "") this->lastName = lastName; }
void Profile::updateUsername(const std::string& username) { if(username != "") this->username = username; }
void Profile::updatePassword(const std::string& password) { if(password != "") this->password = password; }

void Profile::validateProfileData() 
{
    if (age <= 0)
        throw std::invalid_argument("Age must be positive");
    if (height <= 0)
        throw std::invalid_argument("Height must be positive");
    if (weight <= 0)
        throw std::invalid_argument("Weight must be positive");
    if (firstName.empty())
        throw std::invalid_argument("First name cannot be empty");
    if (lastName.empty())
        throw std::invalid_argument("Last name cannot be empty");
    if (username.empty())
        throw std::invalid_argument("Username cannot be empty");
    if (password.empty())
        throw std::invalid_argument("Password cannot be empty");
}