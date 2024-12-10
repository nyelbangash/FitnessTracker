#ifndef DATE_H
#define DATE_H

#include <ctime>
#include <string>
#include <stdexcept>

class Date {
public:
    Date(const int day, const int month, const int year) {
        if (month < 1 || month > 12)
            throw std::invalid_argument("Month must be between 1 and 12");
        if (day < 1 || day > 31)
            throw std::invalid_argument("Day must be between 1 and 31");
        if (year < 1900)
            throw std::invalid_argument("Year must be 1900 or later");
            
        this->day = day;
        this->month = month;
        this->year = year;
    }
    
    Date() {
        std::time_t now = std::time(nullptr);  
        std::tm* localTime = std::localtime(&now);
        
        day = localTime->tm_mday;
        month = localTime->tm_mon + 1;
        year = localTime->tm_year + 1900;
    }

    int getDay() const { return day; }
    int getMonth() const { return month; }
    int getYear() const { return year; }

    bool operator==(const Date& other) const { return day == other.day && month == other.month && year == other.year; }
private:
    int day;
    int month;
    int year;
};

#endif