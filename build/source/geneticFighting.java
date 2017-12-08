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
//The Furst

 //Imports the Arrays class, used to convert array to string to create more readable output

final int GAME_SIZE = 500; //Initialises constants, these are unchangeable in the program, making use of them allows for more efficient execution
final float GAME_TIME = 800; //The time (in frames) between each call of the breed function
final float BREED_PERCENT = 0.2f; //How many of the top fighters are used to breed

final int NUM_INPUTS = 5; //Constants which define the neural network
final int NUM_HIDDEN = 5;
final int NUM_OUTPUTS = 5;

boolean showFittest = true; //This defines weather or not to show the fittest game or allow user control

int numGens = 0; //Counts the number of generations that have happened since the program started

PGraphics arena; //This allows all the games to be drawn to a seperate canvas, avoids having to do lots of complex maths to display debug info

Fighter[] fighters = new Fighter[GAME_SIZE*2]; //A one dimensional array which stores ALL of the fighters
Game[] games       = new Game[GAME_SIZE]; //A one dimensional array whic stores all the concurrent games

public void setup(){ //Called ONCE at the beggining of runtime
  //fullScreen(FX2D); //That cinema experience //Configures the canvas
  frameRate(600); //Set the framelimit
  //randomSeed(4); //FOR DEBUGGING

  arena = createGraphics(round(width*0.6f), round(height*0.9f)); //Make the arena canvas

  imageMode(CENTER); //Define how images and rectangles are drawn to the screen
  rectMode(CENTER);

  for(int i = 0; i < GAME_SIZE; i++){ //Initialises all the games
    fighters[i*2] = new Fighter(LEFT); //Use some existing methods to specify what side of the screen each fighter is on
    fighters[i*2+1] = new Fighter(RIGHT);

    games[i] = new Game(fighters[i*2], fighters[i*2+1]); //Creates a new game and passes REFERENCES to two fighters, allows the game AND main program to handle the fighters
  }

  //Set font
  PFont mono = createFont("UbuntuMono.ttf", 26); //Initialise the text, monospaced makes text much more readable
  textFont(mono);
  textSize(height*0.03f);
}

public void breed(){ //This functions breeds a new generation from the current generation
  try{
    Arrays.sort(fighters); //Sorts the fighters using the compareTo method
  }catch(IllegalArgumentException e){/*swallow*/}
  Fighter[] toBreed = new Fighter[round(GAME_SIZE*2*BREED_PERCENT)];
  for(int i = 0; i < toBreed.length; i++){
    toBreed[i] = fighters[i];
  }
  for(int i = 0; i < GAME_SIZE; i++){
    fighters[i*2] = new Fighter(toBreed[floor(random(toBreed.length))], toBreed[floor(random(toBreed.length))], LEFT);
    fighters[i*2+1] = new Fighter(toBreed[floor(random(toBreed.length))], toBreed[floor(random(toBreed.length))], RIGHT);

    games[i] = new Game(fighters[i*2], fighters[i*2+1]);
  }
  for(int i = 0; i < toBreed.length; i++){
    fighters[i].b = toBreed[i].b;
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
  // for(Game g : games){
  //   g.display();
  // }
  games[currentGame].display();
  arena.endDraw(); //Stop drawing
  drawStage();

  text("Game  : "+(currentGame+1)+"/"+GAME_SIZE+"\n"+nf(frameRate, 3, 1)+"\n"+numGens, height*0.05f, height*0.05f);
  if(frameCount%GAME_TIME == 0){
    breed();
  }
  if(showFittest){
    float bestFitness = 0;
    for(int i = 0; i < GAME_SIZE; i++){
      float fitness = games[i].localfighters[0].fitness()+games[i].localfighters[1].fitness();
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
      //output[i] = sig(output[i]);
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
          synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX); //At the moment picks new random value, MIGHTFIX
        }else{
          synapse[i] = parent.synapse[i];
        }
      }
    }

    public void propForward(Node[] nodes) { //Propagates forward, takes and array of the previous layer
      value = 0;
      for (int i = 0; i < nodes.length; i++) { //Set my value to be the sum of each previous node * the synaps
        value += nodes[i].value*synapse[i];
      }
      value = sig(value); ///MIGHT NEED TO BE ADJUSTED // Activation function, used to keep the values nice and small.
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

  float netOut[] = new float[NUM_OUTPUTS];
  float[] inputs = new float[NUM_INPUTS]; //Setup the inputs
  float dir = 0, oldDir = 0; //Direction, Processing works in radians so I call a lot of functions to switch cuz, I'm too lazy to learn how they work.
  float fov = 20f; //The Field of View, ie how wide their eyesight is.
  float speed = 0;

  float shotsLanded = 0, hitsTaken = 0, shotsAvoided = 0, distanceTravelled = 0, turnSpeed = 0, framesTracked = 0, shotWhileFacing = 0; //Basic shoddy fitness function implementation, these don't do anything
  float shotsMissed = 0;
  boolean bulletInRange = false;
                                                        //YET
  Fighter(int half){ //Default constructor, need to know which half the screen I'm in
    b = new Brain(NUM_INPUTS, NUM_HIDDEN, NUM_OUTPUTS);  //Creates a crazy random hectic brain
    side(half);
  }

  public void side(int half){
    if(half == LEFT){ //If I'm on the left half
      myfill = color(210, 50, 50); //Let there be RED
      leftEdge = 0; //No offset
      pos = new PVector(random(leftEdge+30, leftEdge+arena.width/2-30), random(30, arena.height-30)); //Set my position
      dir = radians(0);
    }else{
      myfill = color(50, 210, 50); //I'm GREEN and proud
      leftEdge = arena.width/2; //Right side
      pos = new PVector(random(leftEdge+30, leftEdge+arena.width/2-30), random(30, arena.height-30)); //RIGHT SIDE
      dir = 180;
    }
    oldPos = pos;
  }

  Fighter(Brain _b, int half){
    b = _b;
    side(half);
  }

  Fighter(Fighter f1, Fighter f2, int half){ //This means I have parents
    b = new Brain(f1.b, f2.b); //Just pass it on, some more stuff will happen here
    side(half);
  }

  public void run(){ //Lets FIGHT, gotta know where my opponent is!
    //Current input ideas:
    // - Size of FOV (mapped from min: 10 to max: 120 to min: 0, max: 1)
    // - Is player in my FOV (Might make use of analog style values later)
    // - Is the bullet in my FOV ('' '')

    //Is the player in: Get heading between minFOV and player, as well as maxFOV and player, should be > 0 for min, < 0 for max
    //Make a new vector from vel and fov.
    float withinFOV;
    PVector tempVel = vel.copy();
    if(vel.mag() < 2){
      vel = new PVector(10, 0);
      vel.rotate(radians(dir));
    }if(PApplet.parseInt(leftEdge)==0){
      PVector diff = PVector.sub(otherfighter.pos, pos);
      withinFOV = degrees(PVector.angleBetween(vel, diff));
    }else{
      PVector diff = PVector.sub(pos, otherfighter.pos);
      withinFOV = 180-degrees(PVector.angleBetween(vel, diff));
    }

    //float minFOVHeading = degrees(PVector.angleBetween(PVector.fromAngle(radians(degrees(vel.heading())-radians(fov/2))), otherfighter.pos));
    //float maxFOVHeading = degrees(PVector.angleBetween(PVector.fromAngle(radians(degrees(vel.heading())+radians(fov/2))), otherfighter.pos));

    inputs[0] = withinFOV<fov/2?1:0;
    framesTracked += inputs[0];
    framesTracked *= inputs[0];

    //Now the same for the bullets
    if(otherfighter.bullet != null){
      PVector diff = PVector.sub(pos, otherfighter.bullet.bulletPos);
      withinFOV = degrees(PVector.angleBetween(vel, diff));
    }else{
      inputs[1] = 0.0f;
    }

    //And finally, the size of my fov
    inputs[2] = map(fov, 10, 120, 1, 0);
    inputs[3] = map(constrain(fitness(), -150, 150), -150, 150, 0, 1);
    inputs[4] = map(dist(pos.x, pos.y, otherfighter.pos.x, otherfighter.pos.y), 0, dist(0, 0, arena.width, arena.height), 1, 0);
    vel = tempVel.copy();
    //inputs[0] = map(PVector.angleBetween(vel, otherfighter.pos), 0, TWO_PI, 0, 1); //More guesswork, these inputs aren't gonna produce useful results
    //inputs[1] = otherfighter.bullet!=null?(map(PVector.angleBetween(vel, otherfighter.bullet.bulletPos), 0, TWO_PI, 0, 1)):0.5; //Involes bullets, not implemented.
    //float angBetween = degrees(PVector.angleBetween(vel, otherfighter.pos));
    //inputs[0] = (abs(angBetween)<10?1:0);
    //inputs[1] = (otherfighter.bullet!=null?(degrees(abs(otherfighter.bullet.bulletVel.heading())-vel.heading())<30?1:0):0);
    float[] actions = b.propForward(inputs); //Get the output of my BRAIN
    netOut = actions;
    float forward = actions[0]; //Should I move forward?
    float dirVelLeft = actions[1];
    float dirVelRight = actions[2];
    float shoot = actions[3];

    //Update my fov
    fov += map(actions[3], 0, 1, -5, 5);
    fov = constrain(fov, 2, 120);

    speed = forward<0.2f?0:map(forward, 0.2f, 1, 2, 8); //Forward speed
    float dirVel = 0.5f;
    if(dirVelLeft > dirVelRight+0.03f){
      dirVel = dirVelLeft;
    }else if(dirVelRight > dirVelLeft+0.03f){
      dirVel = dirVelRight;
    }

    dirVel = map(dirVel, 0, 1, -10, 10);
    dir += dirVel;
    dir = (dir+360)%360;
    vel = new PVector(speed, 0);
    vel.rotate(radians(dir));
    if(frameCount%10==0){
      oldPos = pos.copy();
    }
    pos.add(vel); //Let's GOOOOO
    if(shoot > 0.3f && bullet == null){ //How hard do you have to pull the trigger (MAKE CONST)
      shoot();
      shotWhileFacing += inputs[0];
    }
    if(bullet != null && bullet.exists){
      bullet.run();
    }
    //Make sure you don't go off the edge.
    pos.x = constrain(pos.x, leftEdge+40, leftEdge+arena.width/2-40);
    pos.y = constrain(pos.y, 0, arena.height);

    shotsLanded = otherfighter.hitsTaken;
    distanceTravelled += map(dist(oldPos.x, oldPos.y, pos.x, pos.y), 0, 1+speed*10, 0, 1)/10;
    distanceTravelled = constrain(distanceTravelled, 0, 100);

    //Increment shotsAvoided
    if(otherfighter.bullet != null){
      if(dist(pos.x, pos.y, otherfighter.bullet.bulletPos.x, otherfighter.bullet.bulletPos.y) < 60 && !bulletInRange){
        shotsAvoided++;
        bulletInRange = true;
      }else if(dist(pos.x, pos.y, otherfighter.bullet.bulletPos.x, otherfighter.bullet.bulletPos.y) > 59){
        bulletInRange = false;
      }
    }

    turnSpeed = abs(oldDir-dir);
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

    //Draw the pointer
    PVector l = vel; //Some funky stuff for drawing a line from a direction
    if(vel.mag() > 1){ //Normalize it, if we're moving
      l.normalize();
      l.mult(10);
    }else{
      l = new PVector(10, 0); //Create a vector using `dir`
      l.rotate(radians(dir));
    }
    arena.line(pos.x, pos.y, pos.x+l.x, pos.y+l.y);
    //Draw the FOV
    for(int i = -1; i <=1; i+=2){
      PVector fovV = vel;
      fovV = new PVector(400, 0);
      fovV.rotate(radians(dir+fov/2*i));
      arena.line(pos.x, pos.y, pos.x+fovV.x, pos.y+fovV.y);
      arena.fill(50, 50, 255);
    }

    if(bullet != null){ //Draw the bullet
      if(!bullet.exists){
        bullet = null;
      }else{
        bullet.drawBullet();
      }
    }
  }

  public float fitness(){ //More baseline stuff to be implemented later, affects how likely I am to breed to the new generation.
    float normalFOV = map(fov, 10, 120, 0, 1);
    return -hitsTaken*2
    +shotsLanded*3
    +shotsAvoided*1
    +distanceTravelled*0.1f
    +turnSpeed*-0.2f
    +shotsMissed*4
    +constrain(framesTracked*map(normalFOV, 0, 1, 2, -0.5f), -50, 50)
    +shotWhileFacing*(1-normalFOV);
  }

  class Bullet{
    PVector bulletPos, bulletVel;
    boolean exists = true;
    Fighter target;

    Bullet(PVector pos, float ang, Fighter f){
      this.bulletPos = pos.copy();
      this.bulletVel = PVector.fromAngle(radians(ang)+radians(random(-fov/2, fov/2)));
      this.bulletVel.mult(6);

      target = f;
    }

    public int run(){
      if(bulletPos.x < 0 || bulletPos.x > arena.width || bulletPos.y < -2 || bulletPos.y > arena.height){
        exists = false;
        shotsMissed += 1;
        return -1;
      }else if(dist(bulletPos.x, bulletPos.y, target.pos.x, target.pos.y) < 18){
        exists = false;
        target.hitsTaken++;
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
    debugText += "ShtMSD: "+f.shotsMissed+"\n";
    debugText += "NetIn : "+Arrays.toString(f.inputs)+"\n";
    debugText += "NetOut: "+Arrays.toString(f.netOut)+"\n";
    debugText += "FOV   : "+f.fov+" : "+(f.fov/2)+"\n";
    debugText += "Dir   : "+f.dir+" : "+(f.leftEdge==0?(degrees(PVector.angleBetween(f.vel, localfighters[1].pos))):(180-degrees(PVector.angleBetween(localfighters[1].vel, localfighters[0].pos))))+"\n";

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
      debuggingInfo += debug(f);
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
  currentGame = (currentGame<0?GAME_SIZE-1:(currentGame>GAME_SIZE-1?0:currentGame));
}

public void keyReleased(){
  if(keyCode == 70){ //'f' key
    showFittest = !showFittest;
  }
}

public void mousePressed(){
  frameRate(10);
}
public void mouseReleased(){
  frameRate(600);
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
