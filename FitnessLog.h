#ifndef FITNESS_LOG_H
#define FITNESS_LOG_H

#include <stdexcept>

template <typename T>
class FitnessLog {
public:
    FitnessLog() = default;
    FitnessLog(const std::vector<T>& entries, int entryCount) : entries(entries), entryCount(entryCount) {
        validateEntryCount();
    }

    std::vector<T> getEntries() { return entries; }
    int getEntryCount() const { return entryCount; }


    // Template method for getting the log
    const std::vector<T>& getLog() const {
        return entries;
    }

protected:
    void validateEntryCount() {
        if (entryCount < 0) {
            throw std::invalid_argument("Entry count cannot be negative");
        }
    }

    int entryCount = 0;
    std::vector<T> entries;
};

#endif