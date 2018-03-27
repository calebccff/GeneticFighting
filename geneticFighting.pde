/*TODO
 - Find a good library for doing JFrames and fix that junk
 - Make a good UI
 - Clean up the really dodgy stuff
 - Have red/green be seperate populations that don't interbreed
*/
import java.util.Arrays; //Imports the Arrays class, used to convert array to string to create more readable output

HashMap fitnessWeights = new HashMap();

boolean showFittest = true; //This defines weather or not to show the fittest game or allow user control
int timeShown = 0; //The number of frames you've been watching one game

int numGens = 0; //Counts the number of generations that have happened since the program started

PGraphics arena; //This allows all the games to be drawn to a seperate canvas, avoids having to do lots of complex maths to display debug info

Fighter[] fighters; //A one dimensional array which stores ALL of the fighters
Game[] games; //A one dimensional array whic stores all the concurrent games

boolean running = false;

//Threading data
int THREAD_SECTION_SIZE = 0; //The size of one THREAD_SECTION_SIZE of the games
int THREAD_COUNT = 4;
int[] threadState = new int[THREAD_COUNT];
GameThread[] threads = new GameThread[THREAD_COUNT];

void settings() {
  size(round(displayWidth*0.68), displayHeight-48); //Makes the window invisible, untested on other platforms
}

void setup() { //Called ONCE at the beggining of runtime
  frameRate(60); //Set the framelimit, hehe
  //randomSeed(4); //FOR DEBUGGING

  arena = createGraphics(round(height*0.8), round(height*0.8)); //Make the arena canvas

  imageMode(CENTER); //Define how images and rectangles are drawn to the screen
  rectMode(CENTER);  //This means their x/y coords refer to the center of the object

  //Set font
  PFont mono = createFont("UbuntuMono.ttf", 26); //Initialise the text, monospaced makes text much more readable
  textFont(mono);
  textSize(height*0.02); //This might need tweaking

  //Init fitness weights
  fitnessWeights.put("HitsTaken", -0.8);
  fitnessWeights.put("ShotsLanded", 1.5);
  fitnessWeights.put("ShotsAvoided", 1.1);
  fitnessWeights.put("ShotsMissed", -0.8);
  fitnessWeights.put("FramesTracked", 0.8);
  fitnessWeights.put("ShotWhileFacing", 0.6);

  surface.setSize(-1, -1);
  makeConfigWindow();
  noLoop();
}

void threadInit() {
  THREAD_SECTION_SIZE = GAME_SIZE/THREAD_COUNT;
  for(int i = 0; i < THREAD_COUNT; i++){
    threads[i] = new GameThread(i);
    threadState[i] = 0;
  }
}

void draw() { //Called 60 (ish) times per second
  background(50); //That space grey
  if (running) {
    for (int i = 0; i < THREAD_COUNT; i++) {
      //println("Starting thread"+i);
      threads[i].start();
      threadState[i] = 0;
    }
    //for(Game g : games){
    //  g.run();
    //}
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
  if (frameCount%GAME_TIME == 0) {
    breed();
  }
  if (showFittest && timeShown > 60) {
    float bestFitness = 0;
    for (int i = 0; i < GAME_SIZE*2; ++i) {
      float fitness = fighters[i].fitness();
      if (fitness > bestFitness) {
        bestFitness = fitness;
        currentGame = floor(i/2);
        timeShown = 0;
      }
    }
  }

  timeShown++;
}

void breed() { //This functions breeds a new generation from the current generation
  ArrayList<Fighter> toBreed = new ArrayList<Fighter>();
  for (int i = 0; i < GAME_SIZE*2; i++) {
    for (int j = 0; j < ceil(fighters[i].fitness()); ++j) {
      toBreed.add(fighters[i]);
    }
  }
  for (int i = 0; i < GAME_SIZE; ++i) {
    fighters[i*2] = new Fighter(toBreed.get(floor(random(toBreed.size()))), LEFT, round(i*2+random(10000)));
    fighters[i*2+1] = new Fighter(toBreed.get(floor(random(toBreed.size()))), RIGHT, round(i*2+random(10000)));

    games[i] = new Game(fighters[i*2], fighters[i*2+1]);
  }
  numGens++;
  MUTATION_RATE *=0.95;
  MUTATION_RATE = constrain(MUTATION_RATE, 0.003, 1);
}

void drawStage() {
  image(arena, width*0.7-height*0.05, height*0.5); //Draw the arena to the screen
  strokeWeight(5); //Even thicker lines
  stroke(50);
  noFill();
  rect(width*0.7-height*0.05, height*0.5, arena.width+6, arena.height+6, 20); //Curvey arena
  strokeWeight(2);
}

void renderStage() { //Draws the arena
  arena.background(200); //WHITE(ISH)
  arena.strokeWeight(4); //THICC lines

  arena.line(arena.width*0.5, 0, arena.width*0.5, arena.height); //Line down the middle
}
