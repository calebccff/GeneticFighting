int GAME_SIZE = 1; //Initialises constants, these are unchangeable in the program, making use of them allows for more efficient execution
final int GAME_SIZE_MIN = 100;
final int GAME_SIZE_MAX = 10000;

int GAME_TIME = 800; //The time (in frames) between each call of the breed function
float BREED_PERCENT = 0.2; //How many of the top fighters are used to breed

final int NUM_INPUTS = 5; //Constants which define the neural network
final int[] NUM_HIDDEN = {7, 7};
final int NUM_OUTPUTS = 5;
int IMPROVEMENT_THRESHOLD = 5;
float MUTATION_RATE = 0.8f;

/*
Strings for info boxes and such
*/

final String stringBreedInfo = "Enter the percentage of the population that will be used to breed the next generation";