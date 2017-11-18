/* NOTES
 - Inputs:
  + Enemy to left (lo) or right (hi)
  + Enemy bullet to left (lo) or right (hi)
 - Outputs:
  + Move forward? (confidence affects speed)
  + Turn left (lo) or right (hi) (confidence affects speed)
  + Shoot (confidence affects bullet velocity)
*/

import java.util.Arrays;

PGraphics arena; //Makes drawing things easier, so debugging has space.

Fighter fighter1, fighter2; //The two fighters, not very modular but ah well, don't worry it'll become an array at some points

String debugText = "";

void setup(){ //Called ONCE at the beggining of runtime
  fullScreen(FX2D); //That cinema experience

  arena = createGraphics(round(width*0.6), round(height*0.9)); //Make a square

  imageMode(CENTER); //Changing some settings
  rectMode(CENTER);

  fighter1 = new Fighter(LEFT); //Make the fighters, yes I used built in constants for the arrow keys
  fighter2 = new Fighter(RIGHT);

  randomSeed(1); //FOR DEBUGGING

  //Set font
  PFont mono = createFont("UbuntuMono.ttf", 26);
  textFont(mono);
}

void draw(){ //Caleed 60 (ish) times per second
  background(50); //That space grey
  debugText =  "Fighter 1:\n";
  fighter1.run(fighter2.pos); //Make the fighters run
  debugText += "\nFighter 2:\n";
  fighter2.run(fighter1.pos);
  arena.beginDraw(); //Start drawing the ARENA
  renderStage(); //Draw the line, and the fancy curvy edges
  fighter1.display(); //Draw the fighters
  fighter2.display();
  arena.endDraw(); //Stop drawing
  drawStage();

  //Debug text
  text(debugText, height*0.05, height*0.05);
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
