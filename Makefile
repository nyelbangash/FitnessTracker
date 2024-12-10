all: app

app: JsonFunctions.o RequestFunctions.o app.o
	g++ JsonFunctions.o RequestFunctions.o app.o -o app

app.o: app.cpp Profile.h JsonFunctions.h RequestFunctions.h Date.h Set.h Exercise.h Workout.h WorkoutLog.h Meal.h MealLog.h FitnessLog.h
	g++ -c app.cpp

tests.o: tests.cpp Date.h Set.h Exercise.h Workout.h WorkoutLog.h Meal.h MealLog.h FitnessLog.h
	g++ -c tests.cpp

tests: tests.o
	g++ tests.o -o tests

JsonFunctions.o: JsonFunctions.cpp JsonFunctions.h Date.h Set.h Exercise.h Workout.h WorkoutLog.h Profile.h Meal.h MealLog.h FitnessLog.h
	g++ -c JsonFunctions.cpp

RequestFunctions.o: RequestFunctions.cpp RequestFunctions.h JsonFunctions.h Date.h Set.h Exercise.h Workout.h WorkoutLog.h Profile.h Meal.h MealLog.h FitnessLog.h
	g++ -c RequestFunctions.cpp

clean:
	rm -f *.o app tests