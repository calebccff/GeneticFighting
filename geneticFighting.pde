/* NOTES
 - Inputs:
  + Enemy to left (lo) or right (hi)
  + Enemy bullet to left (lo) or right (hi)
 - Outputs:
  + Move forward? (confidence affects speed)
  + Turn left (lo) or right (hi) (confidence affects speed)
  + Shoot (confidence affects bullet velocity)
*/

PGraphics arena;

Fighter fighter1, fighter2;

void setup(){
  fullScreen(FX2D);

  arena = createGraphics(round(width*0.6), round(height*0.9));

  imageMode(CENTER);
  rectMode(CENTER);

  fighter1 = new Fighter(LEFT);
  fighter2 = new Fighter(RIGHT);

  randomSeed(1);
}

void draw(){
  background(50);
  fighter1.run(fighter2.pos);
  fighter2.run(fighter1.pos);
  arena.beginDraw();
  drawStage();
  fighter1.display();
  fighter2.display();
  arena.endDraw();

}

void drawStage(){
  arena.background(200);
  arena.strokeWeight(4);

  arena.line(arena.width*0.5, 0, arena.width*0.5, arena.height);

  image(arena, width*0.7-height*0.05, height*0.5);
  strokeWeight(5);
  stroke(50);
  noFill();
  rect(width*0.7-height*0.05, height*0.5, arena.width+6, arena.height+6, 20);
  strokeWeight(2);
}
