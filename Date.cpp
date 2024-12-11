#include "Date.h"

Date::Date() 
{
    std::time_t now = std::time(nullptr);  
    std::tm* localTime = std::localtime(&now);
    
    day = localTime->tm_mday;
    month = localTime->tm_mon + 1;
    year = localTime->tm_year + 1900;
}

Date::Date(const int month, const int day, const int year) 
    : day(day), month(month), year(year)
{
    if (month < 1 || month > 12)
        throw std::invalid_argument("Month must be between 1 and 12");
    if (day < 1 || day > 31)
        throw std::invalid_argument("Day must be between 1 and 31");
    if (year < 1900 || year > getCurrentYear())
        throw std::invalid_argument("Year must be later than 1900 up until the present year");
}

const int Date::getCurrentYear()
{
    // Get the current time as a time_t object
    std::time_t now = std::time(nullptr);

    // Convert the time_t object to a tm struct for local time
    std::tm* localTime = std::localtime(&now);

    // Access the year (tm_year is the number of years since 1900)
    int currentYear = 1900 + localTime->tm_year;

    return currentYear;
}

const int Date::getDay() const { return day; }
const int Date::getMonth() const { return month; }
const int Date::getYear() const { return year; }

const bool Date::operator==(const Date& other) const { return day == other.day && month == other.month && year == other.year; }