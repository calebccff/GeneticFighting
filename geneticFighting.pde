import g4p_controls.*;

/*TODO
 - Find a good library for doing JFrames and fix that junk
 - Make a good UI
 - Clean up the really dodgy stuff
 - Have red/green be seperate populations that don't interbreed (much?)
 - Customise fitness for each population. Different species have different goals.
 - Option to remove barrier
 - Track fighter fitness over time, record fitnesses at the end of each generation as a CSV
 - Adjust inputs... Should they know the relative direction of the other fighter/bullet? (0.5:straight on, 0.0:left edge, 1.0:right edge), descrete vs continuous
 - FOV Fixes: Make speed proportional to FOV, so move faster when bigger
 */
/*REPORT stuff
 Testing:
 Bad breed function
 Two seperate populations
 Glitch with swing inserting comma to inbox box
 Adjusted breeding, added mutation amount. Only some synapses become mutated, rather than every synapse being mutated. Mutation is a modifacation to the synapse not a replacement
 
 */
import java.util.Arrays; //Imports the Arrays class, used to convert array to string to create more readable output

HashMap fitnessWeights = new HashMap();

boolean showFittest = true; //This defines weather or not to show the fittest game or allow user control
int timeShown = 0; //The number of frames you've been watching one game

int numGens = 0; //Counts the number of generations that have happened since the program started

PGraphics arena; //This allows all the games to be drawn to a seperate canvas, avoids having to do lots of complex maths to display debug info

Fighter[] fighters; //A one dimensional array which stores ALL of the fighters
Game[] games; /*A one dimensional array which stores all the games
 This is used so that the program can easily become multithreaded as wrapping up
 all of the interactions that occur between two fighters in one class makes it
 easy to run independantly of the main thread.
 */
int state = 0; /*Program state..
 0 - Main menu
 1 - Running simulation
 */

void settings() {
  fullScreen(); //Makes the window invisible, untested on other platforms
}

void setup() { //Called ONCE at the beggining of runtime
  frameRate(60); //Set the framelimit
  //randomSeed(4); //FOR DEBUGGING

  arena = createGraphics(850, 850); //Make the arena canvas
  noSmooth();

  imageMode(CENTER); //Define how images and rectangles are drawn to the screen
  rectMode(CENTER);  //This means their x/y coords refer to the center of the object

  //Set font
  PFont mono = createFont("UbuntuMono.ttf", 26); //Initialise the text, monospaced makes text much more readable
  textFont(mono);
  textSize(height*0.018); //This might need tweaking

  //Init fitness weights
  fitnessWeights.put("HitsTaken", -1.5);
  fitnessWeights.put("ShotsLanded", 1.5);
  fitnessWeights.put("ShotsAvoided", 1.1);
  fitnessWeights.put("ShotsMissed", -0.8);
  fitnessWeights.put("FramesTracked", 0.8);
  fitnessWeights.put("ShotWhileFacing", 0.6);

  //surface.setSize(-1, -1); //Some glitchy stuff to "hide" the main window until you hit run
  //makeConfigWindow(); //Sets up the config window
  //noLoop(); //This still calls draw for one frame, which means all of the debug text gets written to the screen
  surface.setLocation(10, 10);
  surface.setSize(int(displayWidth*0.45), int(displayHeight-50));
  createGUI();
}

void threadInit() { //Configure the variabls for multithreading
  THREAD_SECTION_SIZE = GAME_SIZE/THREAD_COUNT;
  for (int i = 0; i < THREAD_COUNT; i++) {
    threads[i] = new GameThread(i);
  }
}

void draw() { //Called 60 (ish) times per second
  switch (state) {
  case 0:
    background(230);
    break;
  case 1:
    background(50); //That space grey
    for (int i = 0; i < THREAD_COUNT; i++) {
      //println("Starting thread"+i);
      threads[i].start();
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
    games[currentGame].display(); //Draw the currently displayed game to the PGraphic
    arena.endDraw(); //Stop drawing

    drawStage(); //Draw the arena to the canvas

    text("Game  : "+(currentGame+1)+"/"+GAME_SIZE+"\n"+"FPS: "+nf(frameRate, 3, 1) //Some debugging text
      +"\nGEN   : "+numGens
      +"\nMTR   : "+nf(MUTATION_RATE, 1, 3), height*0.02, height*0.04);
    if (frameCount%GAME_TIME == 0) { //Calls breed every <GAME_TIME> frames
      breed();
    }
    if (showFittest && timeShown > 300) { //Every 300 frames update the game to be shown
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
    break;
  }
}

void breed() { //This functions breeds a new generation from the current generation
  ArrayList<Fighter> toBreedRED = new ArrayList<Fighter>();
  ArrayList<Fighter> toBreedGRE = new ArrayList<Fighter>();
  for (int i = 0; i < GAME_SIZE*2; i++) {
    for (int j = 0; j < ceil(fighters[i].fitness())&&fighters[i].red(); ++j) {
      toBreedRED.add(fighters[i]);
    }
    for (int j = 0; j < ceil(fighters[i].fitness())&&!fighters[i].red(); ++j) {
      toBreedGRE.add(fighters[i]);
    }
  }
  for (int i = 0; i < GAME_SIZE; ++i) {
    fighters[i*2] = new Fighter(toBreedRED.get(floor(random(toBreedRED.size()))), LEFT, round(i*2+random(10000)));
    fighters[i*2+1] = new Fighter(toBreedGRE.get(floor(random(toBreedGRE.size()))), RIGHT, round(i*2+random(10000)));

    games[i] = new Game(fighters[i*2], fighters[i*2+1]);
  }
  numGens++;
  MUTATION_RATE *=0.98;
  MUTATION_RATE = constrain(MUTATION_RATE, 0.003, 0.1);
}

void drawStage() {
  image(arena, height*1, height*0.5); //Draw the arena to the screen
  strokeWeight(2);
}

void renderStage() { //Draws the arena
  arena.background(250); //WHITE(ISH)
  arena.strokeWeight(4); //THICC lines

  arena.line(arena.width*0.5, 0, arena.width*0.5, arena.height); //Line down the middle
}