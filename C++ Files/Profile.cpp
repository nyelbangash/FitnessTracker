#include "Profile.h"

Profile::Profile(const Date& dateOfBirth, const double height, const double weight, const std::string& firstName, const std::string& lastName, const std::string& username, const std::string& password)
        : dateOfBirth(dateOfBirth), 
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

Profile::Profile(const Date& dateOfBirth, const double height, const double weight, const std::string& firstName, const std::string& lastName, const Date& dateAccountCreated, const std::string& username, const std::string& password, const WorkoutLog& workoutLog, const MealLog& mealLog)
        : dateOfBirth(dateOfBirth), 
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
    // dont have to check validity of date because you cant create an invalid date to begin with
    // dont have to check validity of mealLog because you cant create an invalid mealLog to begin with
    // dont have to check validity of workoutLog because you cant create an invalid workoutLog to begin with
    validateProfileData();
}

int Profile::getAge() const 
{
    // Get today's date
    Date today = Date();


    int age = today.getYear() - dateOfBirth.getYear();

    // Check if the birthday hasn't occurred yet this year
    if ((today.getMonth() < dateOfBirth.getMonth()) || (today.getMonth() == dateOfBirth.getMonth()) && today.getDay() < dateOfBirth.getDay()) 
    {
        age--; // Subtract one year
    }

    return age;
}

int Profile::getAge(const Date& dateOfBirth)
{
    // dont have to check validity of date because you cant create an invalid date to begin with

    // Get today's date
    Date today = Date();


    int age = today.getYear() - dateOfBirth.getYear();

    // Check if the birthday hasn't occurred yet this year
    if ((today.getMonth() < dateOfBirth.getMonth()) || (today.getMonth() == dateOfBirth.getMonth()) && today.getDay() < dateOfBirth.getDay()) 
    {
        age--; // Subtract one year
    }

    return age;
}

const Date& Profile::getDateOfBirth() const { return dateOfBirth; }
double Profile::getHeight() const { return height; }
double Profile::getWeight() const { return weight; }
const std::string& Profile::getFirstName() const { return firstName; }
const std::string& Profile::getLastName() const { return lastName; }
const std::string& Profile::getUsername() const { return username; }
const std::string& Profile::getPassword() const { return password; }
const Date& Profile::getDateAccountCreated() const { return dateAccountCreated; }
WorkoutLog& Profile::getWorkoutLog() { return workoutLog; }
MealLog& Profile::getMealLog() { return mealLog; }

// dont have to check validity of date because you cant create an invalid date to begin with
void Profile::updateDateOfBirth(const Date& dateOfBirth) { this->dateOfBirth = dateOfBirth; }


void Profile::updateHeight(const double height) 
{ 
    if(height <= 0.0)
        throw std::invalid_argument("Height must be positive and non zero");
    
    this->height = height; 
}

void Profile::updateWeight(const double weight) 
{ 
    if(weight <= 0.0)
        throw std::invalid_argument("Weight must be positive and non zero");
    
    this->weight = weight; 
}

void Profile::updateFirstName(const std::string& firstName) 
{ 
    if(firstName.empty()) 
        throw std::invalid_argument("First name cannot be empty");
    
    this->firstName = firstName; 
}

void Profile::updateLastName(const std::string& lastName) 
{ 
    if (lastName.empty())
        throw std::invalid_argument("Last name cannot be empty");
    
    this->lastName = lastName; 
}

void Profile::updateUsername(const std::string& username) 
{ 
    if (username.empty())
        throw std::invalid_argument("Username cannot be empty");
    
    this->username = username; 
}


void Profile::updatePassword(const std::string& password) 
{ 
    if (password.empty())
        throw std::invalid_argument("Password cannot be empty"); 
    
    this->password = password; 
}

void Profile::validateProfileData() 
{
    if (getAge() <= 0)
        throw std::invalid_argument("Age must be positive and non zero");
    if (height <= 0)
        throw std::invalid_argument("Height must be positive and non zero");
    if (weight <= 0)
        throw std::invalid_argument("Weight must be positive and non zero");
    if (firstName.empty())
        throw std::invalid_argument("First name cannot be empty");
    if (lastName.empty())
        throw std::invalid_argument("Last name cannot be empty");
    if (username.empty())
        throw std::invalid_argument("Username cannot be empty");
    if (password.empty())
        throw std::invalid_argument("Password cannot be empty");
}