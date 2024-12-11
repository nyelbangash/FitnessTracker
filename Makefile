default: app

all: app tests

Set.o: Set.cpp Set.h
	g++ -c Set.cpp

Exercise.o: Exercise.cpp Exercise.h Set.h
	g++ -c Exercise.cpp

Workout.o: Workout.cpp Workout.h Date.h Exercise.h Set.h
	g++ -c Workout.cpp

WorkoutLog.o: WorkoutLog.cpp WorkoutLog.h Log.h Workout.h Date.h Exercise.h Set.h
	g++ -c WorkoutLog.cpp

Meal.o: Meal.cpp Meal.h Date.h
	g++ -c Meal.cpp

MealLog.o: MealLog.cpp MealLog.h Meal.h Date.h Log.h
	g++ -c MealLog.cpp

Log.o: Log.cpp Log.h
	g++ -c Log.cpp

Profile.o: Profile.cpp Profile.h Date.h MealLog.h Meal.h Log.h WorkoutLog.h Workout.h Exercise.h Set.h
	g++ -c Profile.cpp

JsonFunctions.o: JsonFunctions.cpp JsonFunctions.h Profile.h Date.h MealLog.h Meal.h Log.h WorkoutLog.h Workout.h Exercise.h Set.h RequestFunctions.h
	g++ -c JsonFunctions.cpp

RequestFunctions.o: RequestFunctions.cpp RequestFunctions.h JsonFunctions.h Profile.h Date.h MealLog.h Meal.h Log.h WorkoutLog.h Workout.h Exercise.h Set.h
	g++ -c RequestFunctions.cpp

app.o: app.cpp Profile.h Date.h MealLog.h Meal.h Log.h WorkoutLog.h Workout.h Exercise.h Set.h JsonFunctions.h RequestFunctions.h
	g++ -c app.cpp

app: app.o Profile.o Log.o MealLog.o Meal.o WorkoutLog.o Workout.o Exercise.o Set.o JsonFunctions.o RequestFunctions.o
	g++ Profile.o Log.o MealLog.o Meal.o WorkoutLog.o Workout.o Exercise.o Set.o JsonFunctions.o RequestFunctions.o -o app

# tests.o: tests.cpp Date.h Set.h Exercise.h Workout.h WorkoutLog.h Meal.h MealLog.h FitnessLog.h
# 	g++ -c tests.cpp

# tests: tests.o
# 	g++ tests.o -o tests

clean:
	rm -f *.o app tests