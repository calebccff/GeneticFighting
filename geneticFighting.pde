/* OLD  NOTES
 - Inputs:
  + Enemy to left (lo) or right (hi)
  + Enemy bullet to left (lo) or right (hi)
 - Outputs:
  + Move forward? (confidence affects speed)
  + Turn left (lo) or right (hi) (confidence affects speed)
  + Shoot (confidence affects bullet velocity)
*/

/*Current functionality
 - inputs
  + Can I see the enemy?
  + Can I see the enemy's bullet?
  + What's my fov
  + Distance between enemy and me
  + Gaussian noise - encourage random actions.
*/

import java.util.Arrays; //Imports the Arrays class, used to convert array to string to create more readable output

final int GAME_SIZE = 500; //Initialises constants, these are unchangeable in the program, making use of them allows for more efficient execution
final int GAME_TIME = 800; //The time (in frames) between each call of the breed function
final float BREED_PERCENT = 0.2; //How many of the top fighters are used to breed

final int NUM_INPUTS = 5; //Constants which define the neural network
final int[] NUM_HIDDEN = {7, 7};
final int NUM_OUTPUTS = 5;
float MUTATION_RATE = 0.2f;
final float MUTATION_PERCENT = 0.05f;

boolean showFittest = true; //This defines weather or not to show the fittest game or allow user control
int timeShown = 0; //The number of frames you've been watching one game

int numGens = 0; //Counts the number of generations that have happened since the program started

PGraphics arena; //This allows all the games to be drawn to a seperate canvas, avoids having to do lots of complex maths to display debug info

Fighter[] fighters = new Fighter[GAME_SIZE*2]; //A one dimensional array which stores ALL of the fighters
Game[] games       = new Game[GAME_SIZE]; //A one dimensional array whic stores all the concurrent games

void setup(){ //Called ONCE at the beggining of runtime
  size(1280, 720, FX2D);//fullScreen(FX2D); //That cinema experience //Configures the canvas
  frameRate(600); //Set the framelimit
  //randomSeed(4); //FOR DEBUGGING

  arena = createGraphics(round(width*0.6), round(height*0.9)); //Make the arena canvas

  imageMode(CENTER); //Define how images and rectangles are drawn to the screen
  rectMode(CENTER);

  for(int i = 0; i < GAME_SIZE; i++){ //Initialises all the games
    fighters[i*2] = new Fighter(LEFT, i*2); //Use some existing methods to specify what side of the screen each fighter is on
    fighters[i*2+1] = new Fighter(RIGHT, i*2+1);

    games[i] = new Game(fighters[i*2], fighters[i*2+1]); //Creates a new game and passes REFERENCES to two fighters, allows the game AND main program to handle the fighters
  }

  //Set font
  PFont mono = createFont("UbuntuMono.ttf", 26); //Initialise the text, monospaced makes text much more readable
  textFont(mono);
  textSize(height*0.027);
}

void breed(){ //This functions breeds a new generation from the current generation
  try{
    Arrays.sort(fighters); //Sorts the fighters using the compareTo method
  }catch(IllegalArgumentException e){
    println("Couldn't sort array...\n"+e);
  }
  Fighter[] toBreed = new Fighter[round(GAME_SIZE*2*BREED_PERCENT)];
  for(int i = 0; i < toBreed.length; i++){
    toBreed[i] = fighters[i];
  }
  for(int i = 0; i < GAME_SIZE; i++){
    fighters[i*2] = new Fighter(toBreed[floor(random(toBreed.length))], toBreed[floor(random(toBreed.length))], LEFT, i*2);
    fighters[i*2+1] = new Fighter(toBreed[floor(random(toBreed.length))], toBreed[floor(random(toBreed.length))], RIGHT, i*2+1);

    games[i] = new Game(fighters[i*2], fighters[i*2+1]);
  }
  for(int i = 0; i < toBreed.length; i++){
    if(random(1) < 0.3){
      fighters[i] = new Fighter((fighters[i].leftEdge==0?LEFT:RIGHT), i);
    }
    fighters[i].b = toBreed[i].b;
  }
  numGens++;
  MUTATION_RATE *=0.96;
  MUTATION_RATE = constrain(MUTATION_RATE, 0.005, 1);
}

void draw(){ //Caleed 60 (ish) times per second
  background(50); //That space grey
  for(Game g : games){
    g.run();
  }
  arena.beginDraw(); //Start drawing the ARENA
  renderStage(); //Draw the line, and the fancy curvy edges
  arena.stroke(0); //Black for the line, to show direction
  arena.strokeWeight(2); //THICC lines
  // for(Game g : games){
  //   g.display();
  // }
  games[currentGame].display();
  arena.endDraw(); //Stop drawing
  drawStage();

  text("Game  : "+(currentGame+1)+"/"+GAME_SIZE+"\n"+"FPS: "+nf(frameRate, 3, 1)+"\n"+"Gen: "+numGens+" - TS: "+showFittest+" / "+timeShown+"\n"+"MUT: "+nf(MUTATION_RATE, 1, 3), height*0.02, height*0.04);
  if(frameCount%GAME_TIME == 0){
    breed();
  }
  if(showFittest && timeShown > 60){
    float bestFitness = 0;
    for(int i = 0; i < GAME_SIZE; i++){
      float fitness = games[i].localfighters[0].fitness()+games[i].localfighters[1].fitness();
      if(fitness > bestFitness){
        bestFitness = fitness;
        currentGame = i;
        timeShown = 0;
      }
    }
  }

  timeShown++;
}

void drawStage(){
  image(arena, width*0.7-height*0.05, height*0.5); //Draw the arena to the screen
  strokeWeight(5); //Even thicker lines
  stroke(50);
  noFill();
  rect(width*0.7-height*0.05, height*0.5, arena.width+6, arena.height+6, 20); //Curvey arena
  strokeWeight(2);
}

void renderStage(){ //Draws the arena
  arena.background(200); //WHITE(ISH)
  arena.strokeWeight(4); //THICC lines

  arena.line(arena.width*0.5, 0, arena.width*0.5, arena.height); //Line down the middle
}
