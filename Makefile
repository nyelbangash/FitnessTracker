CXX = g++
CXXFLAGS = -std=c++17 -Wall -I/opt/homebrew/include
default: app

all: app tests

Set.o: Set.cpp Set.h
	$(CXX) $(CXXFLAGS) -c Set.cpp

Exercise.o: Exercise.cpp Exercise.h Set.h
	$(CXX) $(CXXFLAGS) -c Exercise.cpp

Workout.o: Workout.cpp Workout.h Date.h Exercise.h Set.h
	$(CXX) $(CXXFLAGS) -c Workout.cpp

WorkoutLog.o: WorkoutLog.cpp WorkoutLog.h Log.h Workout.h Date.h Exercise.h Set.h
	$(CXX) $(CXXFLAGS) -c WorkoutLog.cpp

Meal.o: Meal.cpp Meal.h Date.h
	$(CXX) $(CXXFLAGS) -c Meal.cpp

MealLog.o: MealLog.cpp MealLog.h Meal.h Date.h Log.h
	$(CXX) $(CXXFLAGS) -c MealLog.cpp

Log.o: Log.cpp Log.h
	$(CXX) $(CXXFLAGS) -c Log.cpp

Date.o: Date.cpp Date.h
	$(CXX) $(CXXFLAGS) -c Date.cpp

Profile.o: Profile.cpp Profile.h Date.h MealLog.h Meal.h Log.h WorkoutLog.h Workout.h Exercise.h Set.h
	$(CXX) $(CXXFLAGS) -c Profile.cpp

JsonFunctions.o: JsonFunctions.cpp JsonFunctions.h Profile.h Date.h MealLog.h Meal.h Log.h WorkoutLog.h Workout.h Exercise.h Set.h RequestFunctions.h
	$(CXX) $(CXXFLAGS) -c JsonFunctions.cpp

RequestFunctions.o: RequestFunctions.cpp RequestFunctions.h JsonFunctions.h Profile.h Date.h MealLog.h Meal.h Log.h WorkoutLog.h Workout.h Exercise.h Set.h
	$(CXX) $(CXXFLAGS) -c RequestFunctions.cpp

app.o: app.cpp Profile.h Date.h MealLog.h Meal.h Log.h WorkoutLog.h Workout.h Exercise.h Set.h JsonFunctions.h RequestFunctions.h
	$(CXX) $(CXXFLAGS) -c app.cpp

app: app.o Profile.o Log.o MealLog.o Meal.o WorkoutLog.o Workout.o Exercise.o Set.o JsonFunctions.o RequestFunctions.o Date.o
	$(CXX) $(CXXFLAGS) $^ -o $@

# tests.o: tests.cpp Date.h Set.h Exercise.h Workout.h WorkoutLog.h Meal.h MealLog.h FitnessLog.h
# 	$(CXX) $(CXXFLAGS) -c tests.cpp

# tests: tests.o
# 	$(CXX) $(CXXFLAGS) $^ -o $@

clean:
	rm -f *.o app tests