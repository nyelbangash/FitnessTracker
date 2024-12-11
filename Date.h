#ifndef DATE_H
#define DATE_H

#include <ctime>
#include <string>
#include <stdexcept>

/**
 * @brief A class to store dates for day, month, and year.
 */
class Date {
public:
    /**
     * @breif Constructs a `Date` object with an initial day, month, and year.
     * 
     * @param day An integer of day.
     * @param month An integer of the month.
     * @param An integer of the year.
     */
    Date(const int day, const int month, const int year);
    
    /**
     * @brief Constructs a `Date` object for the current day.
     */
    Date();

    /**
     * @brief A getter for the day.
     * 
     * @return An integer of the day.
     */
    const int getDay() const;

    /**
     * @brief A getter for the month.
     * 
     * @return An integer of the month.
     */
    const int getMonth() const;

    /**
     * @brief A getter for the year.
     * 
     * @return An integer of the year.
     */
    const int getYear() const;

    /**
     * @brief A double equals comparison operator.
     * 
     * If both `Date` objects have the same day, mont, and year, they are deemed equal.
     * 
     * @return A boolean value of true or false if they are equal or not, respectively.
     */
    const bool operator==(const Date& other) const;

    /**
     * @brief Gets the current year.
     * 
     * Used in constructor for year validity verification.
     * Can be used without creating an instance.
     * 
     * @return A constant integer of the current year.
     */
    static const int getCurrentYear();

private:
    /**
     * @breif The day.
     */
    int day;

    /**
     * @breif The month.
     */
    int month;

    /**
     * @breif The year.
     */
    int year;
};

#endif