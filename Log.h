#ifndef LOG_H
#define LOG_H

#include <vector>

/**
 * @brief A generic log class for managing a collection of entries.
 *
 * This class provides an interface for storing and managing log entries of a specified type.
 * It includes methods for accessing and modifying the log, as well as retrieving entry counts.
 *
 * @tparam T The type of the entries in the log.
 */
template <typename T>
class Log {
public:
    /**
     * @brief Default constructor for the Log class.
     *
     * Initializes an empty log.
     */
    Log() = default;

    /**
     * @brief Constructs a Log object with a given set of entries.
     *
     * @param entries A constant reference to a vector containing the initial entries for the log.
     */
    Log(const std::vector<T>& entries);

    /**
     * @brief Retrieves all entries in the log.
     *
     * @return A constant vector containing all entries in the log.
     */
    const std::vector<T> getEntries() const;

    /**
     * @brief Gets the number of entries in the log.
     *
     * @return The total number of entries in the log.
     */
    const int getEntryCount() const;


    /**
     * @brief Adds a new entry to the log.
     *
     * This is a pure virtual function that must be implemented by derived classes.
     *
     * @param entry The entry to add to the log.
     */
    virtual void addEntry(const T& entry) = 0;

protected:
    /**
     * @brief The collection of log entries.
     */
    std::vector<T> entries;
};

#endif