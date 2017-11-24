import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.Arrays; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class geneticFighting extends PApplet {

/* NOTES
 - Inputs:
  + Enemy to left (lo) or right (hi)
  + Enemy bullet to left (lo) or right (hi)
 - Outputs:
  + Move forward? (confidence affects speed)
  + Turn left (lo) or right (hi) (confidence affects speed)
  + Shoot (confidence affects bullet velocity)
*/



final int GAME_SIZE = 50, GAME_TIME = 600;
final float BREED_PERCENT = 0.4f;
boolean showFittest = true;

int numGens = 0;

PGraphics arena; //Makes drawing things easier, so debugging has space.

Fighter[] fighters = new Fighter[GAME_SIZE*2];
Game[] games       = new Game[GAME_SIZE];

public void setup(){ //Called ONCE at the beggining of runtime
  //fullScreen(FX2D); //That cinema experience
  frameRate(300);
  randomSeed(8); //FOR DEBUGGING

  arena = createGraphics(round(width*0.6f), round(height*0.9f)); //Make a square

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
  textSize(height*0.03f);
}

public void breed(){
  Arrays.sort(fighters);
  Fighter[] toBreed = new Fighter[round(GAME_SIZE*2*BREED_PERCENT)];
  for(int i = 0; i < toBreed.length; i++){
    toBreed[i] = fighters[i];
  }
  println(toBreed[0].fitness());
  for(int i = 0; i < GAME_SIZE; i++){
    fighters[i*2] = new Fighter(toBreed[floor(random(toBreed.length))], toBreed[floor(random(toBreed.length))], LEFT);
    fighters[i*2+1] = new Fighter(toBreed[floor(random(toBreed.length))], toBreed[floor(random(toBreed.length))], RIGHT);

    games[i] = new Game(fighters[i*2], fighters[i*2+1]);
  }
  numGens++;
}

public void draw(){ //Caleed 60 (ish) times per second
  background(50); //That space grey
  for(Game g : games){
    g.run();
  }
  arena.beginDraw(); //Start drawing the ARENA
  renderStage(); //Draw the line, and the fancy curvy edges
  arena.stroke(0); //Black for the line, to show direction
  arena.strokeWeight(2); //THICC lines
  for(Game g : games){
    g.display();
  }
  //games[currentGame].display();
  arena.endDraw(); //Stop drawing
  drawStage();

  text("Game  : "+(currentGame+1)+"/"+GAME_SIZE+"\n"+nf(frameRate, 3, 1)+"\n"+numGens, height*0.05f, height*0.05f);
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

public void drawStage(){
  image(arena, width*0.7f-height*0.05f, height*0.5f); //Draw the arena to the screen
  strokeWeight(5); //Even thicker lines
  stroke(50);
  noFill();
  rect(width*0.7f-height*0.05f, height*0.5f, arena.width+6, arena.height+6, 20); //Curvey arena
  strokeWeight(2);
}

public void renderStage(){ //Draws the arena
  arena.background(200); //WHITE(ISH)
  arena.strokeWeight(4); //THICC lines

  arena.line(arena.width*0.5f, 0, arena.width*0.5f, arena.height); //Line down the middle
}
class Brain {

  Node[][] nodes = new Node[3][]; //Staggered 2d array of Node objects that make up the BRAIN

  final float SYNAPSE_MIN = -2f; //Some constants to fine tune the NN, could have a drastic effect on evolution
  final float SYNAPSE_MAX = 2f;
  final float MUTATION_RATE = 0.05f;

  Brain(int lenInput, int lenHidden, int lenOutput) { //Default constructor, specify the lengths of each layer
    nodes[0] = new Node[lenInput]; //Initialises the second dimension of the array
    nodes[1] = new Node[lenHidden];
    nodes[2] = new Node[lenOutput];

    for (int i = 0; i < nodes.length; i++) { //Nested FOR loop, creates each node
      for (int j = 0; j < nodes[i].length; j++) {
        try {
          nodes[i][j] = new Node(nodes[i-1].length); //No. synapses equals the size of the previous layer.
        }
        catch (ArrayIndexOutOfBoundsException e) { //The first layer throws this exception because [0-1] throws a nullPointer.
          nodes[i][j] = new Node(0); //No synapses
        }
      }
    }
  }

  Brain(Brain b1, Brain b2){ //This is used for evolution, basically creates a new BRAIN from two parents.
    nodes[0] = new Node[b1.nodes[0].length]; //Set the size of the staggered array, kinda crusty code MIGHTFIX
    nodes[1] = new Node[b1.nodes[1].length];
    nodes[2] = new Node[b1.nodes[2].length];

    Brain chosen;
    if(random(1)<0.5f){
      chosen = b1;
    }else{
      chosen = b2;
    }

    for(int i = 0; i < nodes.length; i++){ //This is where the evolution comes in, no dominant/recessive genes although that could be added
      for(int j = 0; j < nodes[i].length; j++){
        nodes[i][j] = new Node(chosen.nodes[i][j]); //Picks a random parent and uses their genes.
      }                                                                      //Obviously this isn't great for a NN, MIGHTFIX
    }
  }

  public float[] propForward(float[] inputs) { //Propagates forward, passes inputs through the net and gets an output.
    // Input
    for (int j = 0; j < inputs.length; j++) { //For the first layer, set the values.
      nodes[0][j].value = inputs[j];
    }
    // Hidden/Outer
    for (int i = 1; i < nodes.length; i++) { //Set the next layer
      for (int j = 0; j < nodes[i].length; j++) {
        nodes[i][j].propForward(nodes[i-1]);
      }
    }
    // Get/return the outputs
    float[] output = new float[nodes[nodes.length-1].length]; //Gets the outputs from the last layer
    for (int i = 0; i < output.length; i++) {
      output[i] = nodes[nodes.length-1][i].value;
      output[i] = sig(output[i]);
    }

    return output; //Return them

  }

  public float sig(float x) { //The sigmoid function, look it up.
    return 1/(1+pow((float)Math.E, -x)); //looks like and S shape, Eulers number is AWESOME!
  }

  class Node { //Node class, could use a dictionary or somethin similar but this creates more logical code (and more efficient!)
    // A given node has all the synapses connected to it from the previous layer.
    float synapse[], value = 0;

    Node(int synLen) { //Default constructer, for RANDOM initialisation
      synapse = new float[synLen];
      for (int i = 0; i < synLen; i++) {
        synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX);
      }
    }

    Node(Node parent){ //Takes a random parent Node (see above)
      synapse = new float[parent.synapse.length];
      for(int i = 0; i < synapse.length; i++){ //For each synapse
        if(random(1)<=MUTATION_RATE){ //Small chance of mutation.
          synapse[i] += random(SYNAPSE_MIN/8, SYNAPSE_MAX/8); //At the moment picks new random value, MIGHTFIX
        }
      }
    }

    public void propForward(Node[] nodes) { //Propagates forward, takes and array of the previous layer
      value = 0;
      for (int i = 0; i < nodes.length; i++) { //Set my value to be the sum of each previous node * the synaps
        value += nodes[i].value*synapse[i];
      }
      //value = sig(value); ///MIGHT NEED TO BE ADJUSTED // Activation function, used to keep the values nice and small.
    }

  }
}
class Fighter implements Comparable<Fighter>{ //The FIGHTER class!
  PVector pos, oldPos, vel = new PVector(0, 0); //Has a position and velocity
  int myfill; //Some dodgy stuff to make the two fighters different colours
  int leftEdge; //More dodgy stuff, used to offset each fighter so they don't share the same space.

  Brain b; //Hey they aren't zombies, although they may act like that.
  Bullet bullet;

  Fighter otherfighter;

  float netOut[] = new float[3];
  float[] inputs = new float[2]; //Setup the inputs
  float dir = random(360); //Direction, Processing works in radians so I call a lot of functions to switch cuz, I'm too lazzy to learn how they work.

  int shotsLanded = 0, hitsTaken = 0, shotsAvoided = 0, distanceTravelled = 0; //Basic shoddy fitness function implementation, these don't do anything
                                                                //YET
  Fighter(int half){ //Default constructor, need to know which half the screen I'm in
    b = new Brain(2, 5, 3);  //Creates a crazy random hectic brain
    side(half);
  }

  public void side(int half){
    if(half == LEFT){ //If I'm on the left half
      myfill = color(210, 50, 50); //Let there be RED
      leftEdge = 0; //No offset
      pos = new PVector(random(leftEdge, leftEdge+arena.width/2), random(arena.height)); //Set my position
    }else{
      myfill = color(50, 210, 50); //I'm GREEN and proud
      leftEdge = arena.width/2; //Right side
      pos = new PVector(random(leftEdge, leftEdge+arena.width/2), random(arena.height)); //RIGHT SIDE
    }
    oldPos = pos;
  }

  Fighter(Fighter f1, Fighter f2, int half){ //This means I have parents
    b = new Brain(f1.b, f2.b); //Just pass it on, some more stuff will happen here
    side(half);
  }

  public void run(){ //Lets FIGHT, gotta know where my opponent is!
    inputs[0] = map(PVector.angleBetween(vel, otherfighter.pos), 0, TWO_PI, 0, 1); //More guesswork, these inputs aren't gonna produce useful results
    inputs[1] = otherfighter.bullet!=null?(map(PVector.angleBetween(vel, otherfighter.bullet.bulletPos), 0, TWO_PI, 0, 1)):0.5f; //Involes bullets, not implemented.
    //float angBetween = degrees(PVector.angleBetween(vel, otherfighter.pos));
    //inputs[0] = (abs(angBetween)<10?1:0);
    //inputs[1] = (otherfighter.bullet!=null?(degrees(abs(otherfighter.bullet.bulletVel.heading())-vel.heading())<30?1:0):0);
    float[] actions = b.propForward(inputs); //Get the output of my BRAIN
    netOut = actions;
    float forward = actions[0]; //Should I move forward?
    float dirVel = actions[1];
    float shoot = actions[2];

    float speed = forward<0.2f?0:map(forward, 0.2f, 1, 2, 8);

    dirVel = map(dirVel, 0, 1, -20, 20); //Adjust my direction
    if(dirVel < -3 && dirVel > -2){ //Basically a deadzone, don't want to be always spinning (not that that stops them...)
      dirVel = 0;
    }else{
      dir += dirVel;
    }
    dir = (dir+360)%360;
    vel = new PVector(speed, 0);
    vel.rotate(radians(dir));
    if(frameCount%10==0){
      oldPos = pos.copy();
    }
    pos.add(vel); //Let's GOOOOO
    if(shoot > 0.3f && bullet == null){ //How hard do you have to pull the trigger (MAKE CONST)
      shoot();
    }
    if(bullet != null && bullet.exists){
      bullet.run();
    }

    shotsLanded = otherfighter.hitsTaken;
    distanceTravelled += map(dist(oldPos.x, oldPos.y, pos.x, pos.y), 0, 1+speed*10, 0, 1)/10;
    distanceTravelled = constrain(distanceTravelled, 0, 100);

    //Make sure you don't go off the edge.
    pos.x = constrain(pos.x, leftEdge+40, leftEdge+arena.width/2-40);
    pos.y = constrain(pos.y, 0, arena.height);
  }

  public int compareTo(Fighter other){
    return round(other.fitness()-fitness());
  }

  public void shoot(){
    bullet = new Bullet(pos, dir, otherfighter);
  }

  public void display(){ //Draw those curves!
    arena.fill(myfill); //RAINBOWS

    arena.ellipse(pos.x, pos.y, 20, 20); //CURVY
    PVector l = vel; //Some funky stuff for drawing a line from a direction
    if(vel.mag() > 1){ //Normalize it, if we're moving
      l.normalize();
      l.mult(10);
    }else{
      l = new PVector(10, 0); //Create a vector using `dir`
      l.rotate(radians(dir));
    }
    arena.line(pos.x, pos.y, pos.x+l.x, pos.y+l.y); //Draw the pointer

    if(bullet != null){ //Draw the bullet
      if(!bullet.exists){
        bullet = null;
      }else{
        bullet.drawBullet();
      }
    }
  }

  public float fitness(){ //More baseline stuff to be implemented later, affects how likely I am to breed to the new generation.
    return -hitsTaken+shotsLanded+shotsAvoided+distanceTravelled;
  }

  class Bullet{
    PVector bulletPos, bulletVel;
    boolean exists = true;
    Fighter target;

    Bullet(PVector pos, float ang, Fighter f){
      this.bulletPos = pos.copy();
      this.bulletVel = PVector.fromAngle(radians(ang));
      this.bulletVel.mult(6);

      target = f;
    }

    public int run(){
      if(bulletPos.x < 0 || bulletPos.x > arena.width || bulletPos.y < -2 || bulletPos.y > arena.height){
        exists = false;
        return -1;
      }else if(dist(bulletPos.x, bulletPos.y, target.pos.x, target.pos.y) < 10){
        exists = false;
        target.hitsTaken += 1;
        return -1;
      }
      bulletPos.add(bulletVel);
      return 1;
    }

    public void drawBullet(){
      arena.fill(50, 50, 210);
      arena.ellipse(bulletPos.x, bulletPos.y, 6, 6);
    }
  }
}
class Game{

  Fighter[] localfighters = new Fighter[2];

  String debuggingInfo = "";

  Game(Fighter f1, Fighter f2){
    localfighters[0] = f1;
    localfighters[1] = f2;
    localfighters[0].otherfighter = f2;
    localfighters[1].otherfighter = f1;
  }

  public String debug(Fighter f){
    String debugText = "";
    debugText += "Fighter "+(f.leftEdge==0?"1":"2")+"\n";
    debugText += "Pos   : "+nfs(f.pos.x, 3, 1)+", "+nfs(f.pos.y, 3, 1)+"\n";
    debugText += "Vel   : "+nfs(f.vel.x, 3, 1)+", "+nfs(f.vel.y, 3, 1)+"\n";
    debugText += "Shoot : "+(f.bullet!=null?"O\n":"X\n");
    debugText += "Fit   : "+nfs(f.fitness(), 3, 1)+"\n";
    debugText += "NetIn : "+Arrays.toString(f.inputs)+"\n";
    debugText += "NetOut: "+Arrays.toString(f.netOut)+"\n";

    debugText += "\n";

    return debugText;
  }

  public void run(){
    localfighters[0].run();
    localfighters[1].run();
  }

  public void display(){
    debuggingInfo = "";
    for(Fighter f : localfighters){
      f.display();
      //debuggingInfo += debug(f);
    }
    text(debuggingInfo, height*0.05f, height*0.2f);
  }
}
int currentGame = 0;

public void keyPressed(){
  if(keyCode == UP){
    currentGame++;
  }else if(keyCode == DOWN){
    currentGame--;
  }
  println(keyCode);
  currentGame = (currentGame<0?GAME_SIZE-1:(currentGame>49?0:currentGame));
}

public void keyReleased(){
  if(keyCode == 70){ //'f' key
    showFittest = !showFittest;
  }
  println(showFittest);
}
  public void settings() {  size(1280, 720, FX2D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "geneticFighting" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
