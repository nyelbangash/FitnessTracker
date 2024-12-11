#include <crow.h>
#include <vector>
#include <fstream>
#include "Profile.h"
#include "JsonFunctions.h"
#include "RequestFunctions.h"

using namespace std;
using namespace crow;


vector<Profile*> allProfiles = {};


int main() 
{
    // load in every user's profile
    ifstream inFile("JsonTestFiles/allProfilesArchive.json");
    string jsonString((istreambuf_iterator<char>(inFile)), istreambuf_iterator<char>());
    auto rootJson = json::load(jsonString);
    for (auto profileJson : rootJson["profiles"]) {
        allProfiles.push_back(convertJsonToProfile(profileJson));
    }

    

    // Setup the simple web service.
    SimpleApp app;

    CROW_ROUTE(app, "/workout-api/profile").methods(HTTPMethod::GET)(viewProfile);
    CROW_ROUTE(app, "/workout-api/profile").methods(HTTPMethod::PUT)(updateProfile);
    CROW_ROUTE(app, "/workout-api/profile").methods(HTTPMethod::POST)(createProfile);

    CROW_ROUTE(app, "/workout-api/workout/<string>").methods(HTTPMethod::GET)(viewWorkoutsOnDate);

    CROW_ROUTE(app, "/workout-api/workoutlog").methods(HTTPMethod::GET)(viewWorkoutLog);
    CROW_ROUTE(app, "/workout-api/workoutlog").methods(HTTPMethod::PUT)(addToWorkoutLog);

    CROW_ROUTE(app, "/workout-api/meal/<string>").methods(HTTPMethod::GET)(viewMealsOnDate);

    CROW_ROUTE(app, "/workout-api/meallog").methods(HTTPMethod::GET)(viewMealLog);
    CROW_ROUTE(app, "/workout-api/meallog").methods(HTTPMethod::PUT)(addToMealLog);


    // Run the web service app. 
    app.port(15963).run();

    // save the profiles to json file
    ofstream outFile("allProfiles.json");
    outFile << convertAllProfilesToJson(allProfiles).dump();
    outFile.close();

    // Clean up the profiles
    for (Profile* profile : allProfiles) {
        delete profile;
    }
    allProfiles.clear();
    
    return 0;
}

    /* SETTING UP A TEST USER 
    // push day
    Set benchSet1{4, 225};
    Set benchSet2{4, 215};
    Set benchSet3{3, 205};
    vector<Set> benchSets = {benchSet1, benchSet2, benchSet3};
    Exercise bench{benchSets, "Bench press"};

    Set pdSet1{12, 90};
    Set pdSet2{12, 90};
    Set pdSet3{12, 90};
    Set pdSet4{11, 90};
    vector<Set> pushdownSets = {pdSet1, pdSet2, pdSet3, pdSet4};
    Exercise pushdowns{pushdownSets, "Pushdowns"};

    vector<Exercise> pushDayExercises = {bench, pushdowns};

    Workout pushDay{pushDayExercises, "Push Day 1", 134.55};


    // leg day
    Set squatSet1{5, 305};
    Set squatSet2{5, 305};
    Set squatSet3{4, 305};
    Set squatSet4{5, 225};
    vector<Set> squatSets = {squatSet1, squatSet2, squatSet3, squatSet4};
    Exercise squat{squatSets, "Squat"};

    Set legExtensionSet1{6, 200};
    Set legExtensionSet2{5, 200};
    Set legExtensionSet3{4, 200};
    vector<Set> legExtensionSets = {legExtensionSet1, legExtensionSet2, legExtensionSet3};
    Exercise legExtensions{legExtensionSets, "Leg extensions"};

    vector<Exercise> legDayExercises = {squat, legExtensions};

    Workout legDay{legDayExercises, "Leg Day 1", 156.45};

    // breakfast
    vector<string> breakfastIngredients = {"eggs", "bacon", "toast", "coffee"};
    Meal breakfast{"Breakfast", 652.3, 48.7, 57, 25, breakfastIngredients};

    // lunch
    vector<string> lunchIngredients = {"rice", "chicken", "broccili"};
    Meal lunch{"Lunch", 1045.3, 67.3, 107, 39, lunchIngredients};

    // user profile
    Profile* janeDoe = new Profile(23, 63, 105.6, "Jane", "Doe", "janedoe", "janedoe1234");

    // add to global list of users
    allProfiles.push_back(janeDoe);

    // add workouts
    janeDoe->getWorkoutLog().addEntry(pushDay);
    janeDoe->getWorkoutLog().addEntry(legDay);

    // add meal
    janeDoe->getMealLog().addEntry(breakfast);
    janeDoe->getMealLog().addEntry(lunch);

    cout << "\n\n" << convertProfileToJsonFull(*janeDoe).dump() << "\n\n" << endl;
    */

   /*
       // SETTING UP A TEST USER 
    // push day
    Set curlsSets1{12, 35};
    Set curlsSets2{10, 35};
    Set curlsSets3{8, 35};
    Set curlsSets4{12, 20};
    vector<Set> curlsSets = {curlsSets1, curlsSets2, curlsSets3, curlsSets4};
    Exercise dbcurls{curlsSets, "Dumbell Curls"};

    Set triExtSet1{15, 100};
    Set triExtSet2{15, 100};
    Set triExtSet3{14, 100};
    Set triExtSet4{12, 100};
    Set triExtSet5{15, 80};
    vector<Set> triExtSets = {triExtSet1, triExtSet2, triExtSet3, triExtSet4, triExtSet5};
    Exercise triExts{triExtSets, "Tricep extensions"};

    Set triKickSet1{8, 20};
    Set triKickSet2{8, 20};
    Set triKickSet3{8, 20};
    vector<Set> triKickSets = {triKickSet1, triKickSet2, triKickSet3};
    Exercise triKicks{triKickSets, "Tricep Kickbacks"};

    vector<Exercise> armsDayExercises = {dbcurls, triExts, triKicks};

    Workout armsDay{armsDayExercises, "Arms Day 1", 70};

    // breakfast
    vector<string> breakfastIngredients = {"eggs", "steak", "avacado", "celcius"};
    Meal breakfast{"Meal 1", 656.3, 54.4, 43.2, 34, breakfastIngredients};

    // lunch
    vector<string> lunchIngredients = {"pasta", "beef", "squash"};
    Meal lunch{"Meal 2", 932, 62.1, 100, 29, lunchIngredients};

    // snack
    vector<string> snackIngredients = {"yogurt", "fruit", "granola", "honey"};
    Meal snack{"Snack", 403.2, 40.2, 30.4, 50.1, snackIngredients};

    // dinner
    vector<string> dinnerIngredients = {"chicken", "rice", "vegetables"};
    Meal dinner{"Meal 3", 732, 60, 70, 30, lunchIngredients};

    // user profile
    Profile* johnDoe = new Profile(34, 78, 220, "John", "Doe", "jdoe", "jdoe112");

    // add to global list of users
    allProfiles.push_back(johnDoe);

    // add workouts
    johnDoe->getWorkoutLog().addWorkout(armsDay);

    // add meal
    johnDoe->getMealLog().addMeal(breakfast);
    johnDoe->getMealLog().addMeal(lunch);
    johnDoe->getMealLog().addMeal(snack);
    johnDoe->getMealLog().addMeal(dinner);

    cout << "\n\n" << convertProfileToJsonFull(*johnDoe).dump() << "\n\n" << endl;
   */