/*Current functionality
 - inputs
  + Can I see the enemy?
  + Can I see the enemy's bullet?
  + What's my fov
  + Distance between enemy and me
  + Gaussian noise - encourage random actions.
*/

import java.util.Arrays; //Imports the Arrays class, used to convert array to string to create more readable output

final int GAME_SIZE_MAX = 1000;

int GAME_SIZE = 1; //Initialises constants, these are unchangeable in the program, making use of them allows for more efficient execution
int GAME_TIME = 800; //The time (in frames) between each call of the breed function
float BREED_PERCENT = 0.2; //How many of the top fighters are used to breed

final int NUM_INPUTS = 5; //Constants which define the neural network
final int[] NUM_HIDDEN = {7, 7};
final int NUM_OUTPUTS = 5;
float MUTATION_RATE = 0.2f;
float progressVelocity1 = 0.8;
float progressVelocity2 = 0.3;
final float IMPROVEMENT_THRESHOLD = 0.5;

HashMap fitnessWeights = new HashMap();

boolean showFittest = true; //This defines weather or not to show the fittest game or allow user control
int timeShown = 0; //The number of frames you've been watching one game

int numGens = 0; //Counts the number of generations that have happened since the program started

PGraphics arena; //This allows all the games to be drawn to a seperate canvas, avoids having to do lots of complex maths to display debug info

Fighter[] fighters; //A one dimensional array which stores ALL of the fighters
Game[] games; //A one dimensional array whic stores all the concurrent games

boolean running = false;

void settings(){
  size(round(displayWidth*0.68), displayHeight-48, FX2D);//fullScreen(FX2D); //That cinema experience //Configures the canvas
}

void setup(){ //Called ONCE at the beggining of runtime
  surface.setLocation(displayWidth-round(displayWidth*0.68), 10);
  frameRate(600); //Set the framelimit
  //randomSeed(4); //FOR DEBUGGING

  arena = createGraphics(round(height*0.9), round(height*0.9)); //Make the arena canvas

  imageMode(CENTER); //Define how images and rectangles are drawn to the screen
  rectMode(CENTER);

  //Set font
  PFont mono = createFont("UbuntuMono.ttf", 26); //Initialise the text, monospaced makes text much more readable
  textFont(mono);
  textSize(height*0.02);

  //Init fitness weights
  fitnessWeights.put("HitsTaken", 8.0);
  fitnessWeights.put("ShotsLanded", 9.0);
  fitnessWeights.put("ShotsAvoided", 7.0);
  fitnessWeights.put("ShotsMissed", 4.0);
  fitnessWeights.put("FramesTracked", 8.0);
  fitnessWeights.put("ShotWhileFacing", 10.0);

  makeConfigWindow();
  noLoop();
}

void draw(){ //Caleed 60 (ish) times per second
  background(50); //That space grey
  if(running){
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
  }
  drawStage();

  text("Game  : "+(currentGame+1)+"/"+GAME_SIZE+"\n"+"FPS: "+nf(frameRate, 3, 1)+"\n"+"Gen: "+numGens+" - TS: "+showFittest+" / "+timeShown+"\n"+"MUT: "+nf(MUTATION_RATE, 1, 3), height*0.02, height*0.04);
  if(frameCount%GAME_TIME == 0){
    breed();
  }
  if(showFittest && timeShown > 60){
    float bestFitness = 0;
    for(int i = 0; i < GAME_SIZE; ++i){
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

void breed(){ //This functions breeds a new generation from the current generation
  ArrayList<Fighter> toBreed = new ArrayList<Fighter>();
  for(int i = 0; i < GAME_SIZE*2; i++){
    for(int j = 0; j < fighters[i].piFitness(); ++j){
      toBreed.add(fighters[i]);
    }
  }
  for(int i = 0; i < GAME_SIZE-20; ++i){
    fighters[i*2] = new Fighter(toBreed.get(floor(random(toBreed.size()))), toBreed.get(floor(random(toBreed.size()))), LEFT, i*2);
    fighters[i*2+1] = new Fighter(toBreed.get(floor(random(toBreed.size()))), toBreed.get(floor(random(toBreed.size()))), RIGHT, i*2+1);

    games[i] = new Game(fighters[i*2], fighters[i*2+1]);
  }
  for(int i = 0; i < 50; ++i){
    fighters[i].b = toBreed.get(i).b;
  }
  numGens++;
  MUTATION_RATE *=0.96;
  MUTATION_RATE = constrain(MUTATION_RATE, 0.005, 1);
  progressVelocity1 *= 0.96;
  progressVelocity2 *= 0.96;
  progressVelocity1 = constrain(progressVelocity1, 0.5, 1);
  progressVelocity2 = constrain(progressVelocity2, 0, 0.5);
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
