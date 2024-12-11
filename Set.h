#ifndef SET_H
#define SET_H

/**
 * @brief This class represents a single set in an exercise.
 *
 * This class is used in composition of the `Exercise` class.
 */
class Set {
public:
    /**
     * @brief Constructs a Set object with an initial number of reps and weight
     * 
     * @param reps An integer of the number of reps completed in the set
     * @param weight A double of the amount of weight used in the set
     * 
     * @throws std::invalid_argument if reps <= 0 or weight < 0
     */
    Set(const int reps, const double weight);

    /**
     * @brief A getter for the number of reps completed in the set
     * 
     * @return An integer of the number of reps completed in the set
     */
    int getReps() const;

    /**
     * @brief A getter for the amount of weight used in the set
     * 
     * @return A double of the amount of weight used in the set
     */
    double getWeight() const { return weight; }
    
private:
    /**
     * @brief The amount of reps completed in the set
     */
    int reps;

    /**
     * @brief The amount of weight used in the set
     */
    double weight;
};

#endif