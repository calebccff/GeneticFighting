int GAME_SIZE = 800; //Initialises constants, these are unchangeable in the program, making use of them allows for more efficient execution
final int GAME_SIZE_MIN = 100;
final int GAME_SIZE_MAX = 10000;

int GAME_TIME = 1800; //The time (in frames) between each call of the breed function
float BREED_PERCENT = 0.2; //How many of the top fighters are used to breed

//Neural net constants
final int NUM_INPUTS = 4; //Constants which define the neural network
final int[] NUM_HIDDEN = {7, 7};
final int NUM_OUTPUTS = 5;
int IMPROVEMENT_THRESHOLD = 5;
float MUTATION_RATE = 0.02f;
float MUTATION_AMT = 0.3;

//Threading data
int THREAD_SECTION_SIZE = 0; //The size of one THREAD_SECTION_SIZE of the games
int THREAD_COUNT = 4;
GameThread[] threads = new GameThread[THREAD_COUNT]; //An array of the threads that run the games

/*
Strings for info boxes and such
*/

final String stringBreedInfo = "Enter the percentage of the population that will be used to breed the next generation";