/* NOTES
 - Inputs:
  + Enemy to left (lo) or right (hi)
  + Enemy bullet to left (lo) or right (hi)
 - Outputs:
  + Move forward? (confidence affects speed)
  + Turn left (lo) or right (hi) (confidence affects speed)
  + Shoot (confidence affects bullet velocity)
*/
//The Furst

import java.util.Arrays;

final int GAME_SIZE = 50;
final float GAME_TIME = 600;
final float BREED_PERCENT = 0.4;

final int NUM_INPUTS = 3;
final int NUM_HIDDEN = 5;
final int NUM_OUTPUTS = 4;

boolean showFittest = true;

int numGens = 0;

PGraphics arena; //Makes drawing things easier, so debugging has space.

Fighter[] fighters = new Fighter[GAME_SIZE*2];
Game[] games       = new Game[GAME_SIZE];

void setup(){ //Called ONCE at the beggining of runtime
  size(1280, 720, FX2D);//fullScreen(FX2D); //That cinema experience
  frameRate(300);
  randomSeed(8); //FOR DEBUGGING

  arena = createGraphics(round(width*0.6), round(height*0.9)); //Make a square

  imageMode(CENTER); //Changing some settings
  rectMode(CENTER);

  for(int i = 0; i < GAME_SIZE; i++){
    fighters[i*2] = new Fighter(LEFT);
    fighters[i*2+1] = new Fighter(RIGHT);

    games[i] = new Game(fighters[i*2], fighters[i*2+1]);
  }

  //Set font
  PFont mono = createFont("UbuntuMono.ttf", 26);
  textFont(mono);
  textSize(height*0.03);
}

void breed(){
  Arrays.sort(fighters);
  Fighter[] toBreed = new Fighter[round(GAME_SIZE*2*BREED_PERCENT)];
  for(int i = 0; i < toBreed.length; i++){
    toBreed[i] = fighters[i];
  }
  for(int i = 0; i < GAME_SIZE; i++){
    fighters[i*2] = new Fighter(toBreed[floor(random(toBreed.length))], toBreed[floor(random(toBreed.length))], LEFT);
    fighters[i*2+1] = new Fighter(toBreed[floor(random(toBreed.length))], toBreed[floor(random(toBreed.length))], RIGHT);

    games[i] = new Game(fighters[i*2], fighters[i*2+1]);
  }
  numGens++;
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

  text("Game  : "+(currentGame+1)+"/"+GAME_SIZE+"\n"+nf(frameRate, 3, 1)+"\n"+numGens, height*0.05, height*0.05);
  if(frameCount%GAME_TIME == 0){
    breed();
  }
  if(showFittest){
    float bestFitness = 0;
    for(int i = 0; i < GAME_SIZE; i++){
      float fitness = abs(games[i].localfighters[0].fitness())+abs(games[i].localfighters[1].fitness());
      if(fitness > bestFitness){
        bestFitness = fitness;
        currentGame = i;
      }
    }
  }
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
