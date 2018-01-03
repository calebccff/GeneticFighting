import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.Arrays; 
import javax.swing.*; 
import java.awt.*; 
import java.awt.event.*; 
import javax.swing.event.ChangeEvent; 
import javax.swing.event.ChangeListener; 
import java.awt.event.KeyEvent; 
import java.awt.event.KeyListener; 
import java.util.Hashtable; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class geneticFighting extends PApplet {

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

 //Imports the Arrays class, used to convert array to string to create more readable output

final int GAME_SIZE_MAX = 1000;

int GAME_SIZE = 1; //Initialises constants, these are unchangeable in the program, making use of them allows for more efficient execution
int GAME_TIME = 800; //The time (in frames) between each call of the breed function
float BREED_PERCENT = 0.2f; //How many of the top fighters are used to breed

final int NUM_INPUTS = 5; //Constants which define the neural network
final int[] NUM_HIDDEN = {7, 7};
final int NUM_OUTPUTS = 5;
float MUTATION_RATE = 0.2f;
float progressVelocity1 = 0.8f;
float progressVelocity2 = 0.3f;
final float IMPROVEMENT_THRESHOLD = 0.5f;

HashMap fitnessWeights = new HashMap();

boolean showFittest = true; //This defines weather or not to show the fittest game or allow user control
int timeShown = 0; //The number of frames you've been watching one game

int numGens = 0; //Counts the number of generations that have happened since the program started

PGraphics arena; //This allows all the games to be drawn to a seperate canvas, avoids having to do lots of complex maths to display debug info

Fighter[] fighters; //A one dimensional array which stores ALL of the fighters
Game[] games; //A one dimensional array whic stores all the concurrent games

boolean running = false;

public void settings(){
  size(round(displayWidth*0.68f), displayHeight-48, FX2D);//fullScreen(FX2D); //That cinema experience //Configures the canvas
}

public void setup(){ //Called ONCE at the beggining of runtime
  surface.setLocation(displayWidth-round(displayWidth*0.68f), 10);
  frameRate(600); //Set the framelimit
  //randomSeed(4); //FOR DEBUGGING

  arena = createGraphics(round(height*0.9f), round(height*0.9f)); //Make the arena canvas

  imageMode(CENTER); //Define how images and rectangles are drawn to the screen
  rectMode(CENTER);

  //Set font
  PFont mono = createFont("UbuntuMono.ttf", 26); //Initialise the text, monospaced makes text much more readable
  textFont(mono);
  textSize(height*0.02f);

  //Init fitness weights
  fitnessWeights.put("HitsTaken", 8.0f);
  fitnessWeights.put("ShotsLanded", 9.0f);
  fitnessWeights.put("ShotsAvoided", 7.0f);
  fitnessWeights.put("ShotsMissed", 4.0f);
  fitnessWeights.put("FramesTracked", 8.0f);
  fitnessWeights.put("ShotWhileFacing", 10.0f);

  makeConfigWindow();
  noLoop();
}

public void draw(){ //Caleed 60 (ish) times per second
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

  text("Game  : "+(currentGame+1)+"/"+GAME_SIZE+"\n"+"FPS: "+nf(frameRate, 3, 1)+"\n"+"Gen: "+numGens+" - TS: "+showFittest+" / "+timeShown+"\n"+"MUT: "+nf(MUTATION_RATE, 1, 3), height*0.02f, height*0.04f);
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

public void breed(){ //This functions breeds a new generation from the current generation
  ArrayList<Fighter> toBreed = new ArrayList<Fighter>();
  for(int i = 0; i < GAME_SIZE*2; i++){
    for(int j = 0; j < fighters[i].piFitness(); j++){
      toBreed.add(fighters[i]);
    }
  }
  for(int i = 0; i < GAME_SIZE-20; i++){
    fighters[i*2] = new Fighter(toBreed.get(floor(random(toBreed.size()))), toBreed.get(floor(random(toBreed.size()))), LEFT, i*2);
    fighters[i*2+1] = new Fighter(toBreed.get(floor(random(toBreed.size()))), toBreed.get(floor(random(toBreed.size()))), RIGHT, i*2+1);

    games[i] = new Game(fighters[i*2], fighters[i*2+1]);
  }
  for(int i = 0; i < 50; i++){
    fighters[i].b = toBreed.get(i).b;
  }
  numGens++;
  MUTATION_RATE *=0.96f;
  MUTATION_RATE = constrain(MUTATION_RATE, 0.005f, 1);
  progressVelocity1 *= 0.96f;
  progressVelocity2 *= 0.96f;
  progressVelocity1 = constrain(progressVelocity1, 0.5f, 1);
  progressVelocity2 = constrain(progressVelocity2, 0, 0.5f);
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

  Node[][] nodesVisible = new Node[2][]; //Staggered 2d array of Node objects that make up the BRAIN
  Node[][] nodesHidden;

  final float SYNAPSE_MIN = -2f; //Some constants to fine tune the NN, could have a drastic effect on evolution
  final float SYNAPSE_MAX = 2f;

  Brain(int lenInput, int[] lenHidden, int lenOutput) { //Default constructor, specify the lengths of each layer
    nodesVisible[0] = new Node[lenInput]; //Initialises the second dimension of the array
    nodesVisible[1] = new Node[lenOutput];

    for(int i = 0; i < nodesVisible[0].length; i++){
      nodesVisible[0][i] = new Node(0);
    }

    nodesHidden = new Node[lenHidden.length][];
    for(int i = 0; i < nodesHidden.length; i++){
      nodesHidden[i] = new Node[lenHidden[i]];
    }

    for(int i = 0; i < nodesHidden[0].length; i++){
      nodesHidden[0][i] = new Node(nodesVisible[0].length);
    }

    for(int i = 1; i < lenHidden.length; i++){
      for(int j = 0; j < lenHidden[i]; j++){
        nodesHidden[i][j] = new Node(nodesHidden[i-1].length);
      }
    }

    for (int i = 0; i < nodesVisible[1].length; i++) { //Nested FOR loop, creates each node
      nodesVisible[1][i] = new Node(nodesHidden[nodesHidden.length-1].length);
    }
  }

  Brain(Brain b1, Brain b2){ //This is used for evolution, basically creates a new BRAIN from two parents.
    nodesVisible[0] = new Node[b1.nodesVisible[0].length]; //Set the size of the staggered array, kinda crusty code MIGHTFIX
    nodesVisible[1] = new Node[b1.nodesVisible[1].length];
    nodesHidden = new Node[b1.nodesHidden.length][];
    for(int i = 0; i < nodesHidden.length; i++){
      nodesHidden[i] = new Node[b1.nodesHidden[i].length];
    }

    Brain chosen;
    if(random(1)<0.5f){
      chosen = b1;
    }else{
      chosen = b2;
    }

    for(int i = 0; i < nodesVisible.length; i++){ //This is where the evolution comes in, no dominant/recessive genes although that could be added
      for(int j = 0; j < nodesVisible[i].length; j++){
        nodesVisible[i][j] = new Node(chosen.nodesVisible[i][j]); //Picks a random parent and uses their genes.
      }                                                                      //Obviously this isn't great for a NN, MIGHTFIX
    }
    for(int i = 0; i < nodesHidden.length; i++){ //This is where the evolution comes in, no dominant/recessive genes although that could be added
      for(int j = 0; j < nodesHidden[i].length; j++){
        nodesHidden[i][j] = new Node(chosen.nodesHidden[i][j]); //Picks a random parent and uses their genes.
      }                                                                      //Obviously this isn't great for a NN, MIGHTFIX
    }
  }

  public float[] propForward(float[] inputs) { //Propagates forward, passes inputs through the net and gets an output.
    // Input
    for (int j = 0; j < inputs.length; j++) { //For the first layer, set the values.
      nodesVisible[0][j].value =
      inputs[j];
    }
    // Hidden/Outer
    for (int i = 0; i < nodesHidden[0].length; i++) { //Set the next layer
      nodesHidden[0][i].propForward(nodesVisible[0]);
    }
    for(int j = 1; j < nodesHidden.length; j++){
      for(int i = 0; i < nodesHidden[j].length; i++){
        nodesHidden[j][i].propForward(nodesHidden[j-1]);
      }
    }
    for(int i = 0; i < nodesVisible[1].length; i++){
      nodesVisible[1][i].propForward(nodesHidden[nodesHidden.length-1]);
    }

    // Get/return the outputs
    float[] output = new float[nodesVisible[nodesVisible.length-1].length]; //Gets the outputs from the last layer
    for (int i = 0; i < output.length; i++) {
      output[i] = nodesVisible[nodesVisible.length-1][i].value;
      //output[i] = sig(output[i]);
    }

    return output; //Return them

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
        // if(random(1)<=MUTATION_RATE){ //Small chance of mutation.
        //   synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX); //At the moment picks new random value, MIGHTFIX
        // }else{
          synapse[i] = parent.synapse[i]*random(1-MUTATION_RATE, 1+MUTATION_RATE);
        //}
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
  final int SHOOT_COOLDOWN_LENGTH = 40;

  PVector pos, oldPos, vel = new PVector(0, 0); //Has a position and velocity
  int myfill; //Some dodgy stuff to make the two fighters different colours
  int leftEdge; //More dodgy stuff, used to offset each fighter so they don't share the same space.

  Brain b; //Hey they aren't zombies, although they may act like that.
  Bullet bullet;

  Fighter otherfighter;
  float parent1Fit = 0;
  float parent2Fit = 0;

  float netOut[] = new float[NUM_OUTPUTS];
  float[] inputs = new float[NUM_INPUTS]; //Setup the inputs
  float dir = 0;//, oldDir = 0; //Direction, Processing works in radians so I call a lot of functions to switch cuz, I'm too lazy to learn how they work.
  float fov = 20f; //The Field of View, ie how wide their eyesight is.
  float speed = 0;
  int shootCooldown = 0;

  float shotsLanded = 0, hitsTaken = 0, shotsAvoided = 0, distanceTravelled = 0, framesTracked = 0, shotWhileFacing = 0; //Basic shoddy fitness function implementation, these don't do anything
  float shotsMissed = 0;
  boolean bulletInRange = false;

  int myNoise = 0;

  Fighter(int half, int n){ //Default constructor, need to know which half the screen I'm in
  myNoise = n*1000;
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

  Fighter(Brain _b, int half, int n){
    myNoise = n*1000;
    b = _b;
    side(half);
  }

  Fighter(Fighter f1, Fighter f2, int half, int n){ //This means I have parents
    myNoise = n*1000;
    b = new Brain(f1.b, f2.b); //Just pass it on, some more stuff will happen here
    parent1Fit = f1.fitness();
    parent2Fit = f2.fitness();
    side(half);
  }

  public int compareTo(Fighter other){
    if(fitness() < other.fitness()){
      return 1;
    }else{
      return -1;
    }
  }

  public void run(){ //Runs the NN and manages the fighter
    //Current input ideas:
    // - Size of FOV (mapped from min: 5 to max: 120 to min: 0, max: 1)
    // - Is player in my FOV (Might make use of analog style values later)
    // - Is the enemies bullet in my FOV

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
    framesTracked *= map(fov, 5, 120, 1, 0);

    //Now the same for the bullets
    try{
      if(PApplet.parseInt(leftEdge)==0){
        PVector diff = PVector.sub(otherfighter.bullet.bulletPos, pos);
        withinFOV = degrees(PVector.angleBetween(vel, diff));
      }else{
        PVector diff = PVector.sub(pos, otherfighter.bullet.bulletPos);
        withinFOV = 180-degrees(PVector.angleBetween(vel, diff));
      }
    }catch(NullPointerException e){
      inputs[1] = 0.0f;
    }

    inputs[1] = withinFOV<fov/2?1:0;

    //And finally, the size of my fov
    inputs[2] = map(fov, 10, 120, 1, 0);
    inputs[3] = map(dist(pos.x, pos.y, otherfighter.pos.x, otherfighter.pos.y), 0, dist(0, 0, arena.width, arena.height), 1, 0);
    inputs[4] = map(noise((frameCount+myNoise)*0.006f), 0.15f, 0.85f, 0, 1);
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
    fov += map(actions[4], 0, 1, -5, 5);
    fov = constrain(fov, 5, 120);

    speed = map(forward, 0, 1, 0, 8); //Forward speed
    if(abs(speed) < 2){
      speed = 0;
    }
    float dirVel = 0;
    if(dirVelLeft > dirVelRight+0.03f){
      dirVel = -dirVelLeft;
    }else if(dirVelRight > dirVelLeft+0.03f){
      dirVel = dirVelRight;
    }

    dirVel = map(dirVel, -1, 1, -10, 10);
    dir += dirVel;
    dir = (dir+360)%360;
    vel = new PVector(speed, 0);
    vel.rotate(radians(dir));
    if(frameCount%10==0){
      oldPos = pos.copy();
    }
    pos.add(vel); //Let's GOOOOO

    //Shooting
    if(shoot > 0.5f && shootCooldown == 0 && bullet == null){ //How hard do you have to pull the trigger (MAKE CONST)
      shoot();
      shotWhileFacing += inputs[0]*map(fov, 5, 120, 1, 0);
    }
    if(bullet != null && bullet.exists){
      bullet.run();
    }


    //Make sure you don't go off the edge.
    pos.x = constrain(pos.x, leftEdge+40, leftEdge+arena.width/2-40);
    pos.y = constrain(pos.y, 0, arena.height);

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
    //Decrement shooting cooldown.
    shootCooldown--;
    shootCooldown = constrain(shootCooldown, 0, SHOOT_COOLDOWN_LENGTH);
  }

  public void shoot(){
    bullet = new Bullet(pos, dir, otherfighter);
  }

  public void display(){ //Draw those curves!
    arena.fill(myfill); //RAINBOWS

    arena.ellipse(pos.x, pos.y, 20, 20); //CURVY

    //Draw the pointer
    PVector l = vel; //Some funky stuff for drawing a line from a direction
    // if(vel.mag() > 1){ //Normalize it, if we're moving
    //   l.normalize();
    //   l.mult(10);
    // }else{
      l = new PVector(10, 0); //Create a vector using `dir`
      l.rotate(radians(dir));
    //}
    arena.line(pos.x, pos.y, pos.x+l.x, pos.y+l.y);
    //Draw the FOV
    for(int i = -1; i <=1; i+=2){
      PVector fovV = vel;
      fovV = new PVector(250, 0);
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

  public float piFitness(){
    return pi(fitness(), parent1Fit, parent2Fit);
  }

  public float fitness(){ //More baseline stuff to be implemented later, affects how likely I am to breed to the new generation.
    float normalFOV = map(fov, 5, 120, 0, 1); //Make this adjust the reward for EACH shot
    float myFitness =
    -hitsTaken*(float)fitnessWeights.get("HitsTaken")
    +shotsLanded*(float)fitnessWeights.get("ShotsLanded")
    +constrain(shotsAvoided, 0, 50)*(float)fitnessWeights.get("ShotsAvoided")
    -shotsMissed*(float)fitnessWeights.get("ShotsMissed")
    +map(constrain(framesTracked, 0, 150), 0, 150, 0, 4)*(float)fitnessWeights.get("FramesTracked")
    +shotWhileFacing*(float)fitnessWeights.get("ShotWhileFacing");

    return myFitness;
  }

  class Bullet{
    PVector bulletPos, bulletVel;
    boolean exists = true;
    Fighter target;

    Bullet(PVector pos, float ang, Fighter f){
      this.bulletPos = pos.copy();
      this.bulletVel = PVector.fromAngle(radians(ang+random(-fov/2, fov/2)));
      this.bulletVel.mult(10);

      target = f;
    }

    public int run(){
      if(bulletPos.x < 0 || bulletPos.x > arena.width || bulletPos.y < -2 || bulletPos.y > arena.height){
        exists = false;
        shotsMissed += map(fov, 5, 120, 0.2f, 1);
        shootCooldown = SHOOT_COOLDOWN_LENGTH;
        return -1;
      }else if(dist(bulletPos.x, bulletPos.y, target.pos.x, target.pos.y) < 18){
        exists = false;
        target.hitsTaken++;
        shotsLanded += map(fov, 5, 120, 1, 0);
        shootCooldown = SHOOT_COOLDOWN_LENGTH;
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
    debugText += "Shoot : "+(f.bullet!=null?"O":"X")+" : "+f.shootCooldown+"\n";
    debugText += "Fit   : "+nfs(f.fitness(), 3, 1)+" : "+f.parent1Fit+" : "+f.parent2Fit+"\n";
    debugText += "Hits taken : "+f.hitsTaken+"\n";
    debugText += "Shots land : "+f.shotsLanded+"\n";
    debugText += "Shots avoid: "+f.shotsAvoided+"\n";
    debugText += "Dist Trave : "+f.distanceTravelled+"\n";
    debugText += "Shots Miss : "+f.shotsMissed+"\n";
    debugText += "Frames Trac: "+f.framesTracked+"\n";
    debugText += "Shots Face : "+f.shotWhileFacing+"\n";
    debugText += "FOV   : "+f.fov+"\n";
    // debugText += "Input : \n";
    // debugText += "SO  , SOB , FOV , DIST, NOISE\n";
    // for(int i = 0; i < f.inputs.length; i++){
    //   debugText += nf(f.inputs[i], 1, 2)+(i==f.inputs.length-1?"":", ");
    // }
    // debugText += "\n\n";
    // debugText += "Output: \n";
    // debugText += "W   , A   , D   , SHO , FOV\n";
    // for(int i = 0; i < f.netOut.length; i++){
    //   debugText += nf(f.netOut[i], 1, 2)+(i==f.netOut.length-1?"":", ");
    // }
    debugText += "\n";

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
    text(debuggingInfo, height*0.02f, height*0.2f);
  }
}
public float sig(float x) { //The sigmoid function, look it up.
  return 1/(1+exp(-x)); //looks like and S shape, Eulers number is AWESOME!
}

public float pi(float D, float p1, float p2){
  float imp1 = D-p1;
  float imp2 = D-p2;
  int choice = 0;
  if(imp1 > IMPROVEMENT_THRESHOLD){
    choice += 70;
  } else if (imp1 < -IMPROVEMENT_THRESHOLD){
    choice += 30;
  } else {
    choice += 50;
  }
  if(imp2 > IMPROVEMENT_THRESHOLD){
    choice += 7;
  } else if (imp2 < -IMPROVEMENT_THRESHOLD){
    choice += 3;
  } else {
    choice += 5;
  }
  switch (choice){
    case 77:
    // better than both
    return 5;
    case 75:
    case 57:
    // better than one
    return 4;
    case 55:
    // equal to both
    return 3;
    case 73:
    case 53:
    case 35:
    case 37:
    // worse than one
    return 2;
    case 33:
    // worse than both
    default:
    //error
    return 1;
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
  if(keyCode == ESC){
    config.dispose();
    System.exit(0);
  }
}

public void mousePressed(){
  frameRate(10);
}
public void mouseReleased(){
  frameRate(600);
}










ConfigWindow config;

public class ConfigWindow extends JFrame{
	private final int WIDTH = 500;
	private final int HEIGHT = 850;
	private final int GAME_SIZE_SLIDER_TICKS = 5;

  private JButton buttonRun, buttonExit;
  private JSlider sliderGameSize;

	public ConfigWindow(){
		setTitle("Genetic Fighting Config");
		setSize(WIDTH, HEIGHT);
		setVisible(true);
		setDefaultCloseOperation(EXIT_ON_CLOSE);
    Container contentPane = getContentPane();
    contentPane.setLayout(new BoxLayout(this.getContentPane(), BoxLayout.Y_AXIS));
    contentPane.add(Box.createRigidArea(new Dimension(0, 40)));

    JPanel[] panes = new JPanel[4];
    for(int i = 0; i < panes.length; i++){
      panes[i] = new JPanel();
      panes[i].setLayout(new BoxLayout(panes[i], BoxLayout.LINE_AXIS));
    }


    buttonRun = new JButton("Run It!");
    buttonRun.addActionListener(new ButtonHandler(){
      public void actionPerformed(ActionEvent e){
				if(!running){
					fighters = new Fighter[GAME_SIZE*2];
					games = new Game[GAME_SIZE];
					for(int i = 0; i < GAME_SIZE; i++){ //Initialises all the games
				    fighters[i*2] = new Fighter(LEFT, i*2); //Use some existing methods to specify what side of the screen each fighter is on
				    fighters[i*2+1] = new Fighter(RIGHT, i*2+1);

				    games[i] = new Game(fighters[i*2], fighters[i*2+1]); //Creates a new game and passes REFERENCES to two fighters, allows the game AND main program to handle the fighters
				  }
					running = true;
	        loop();
				}
      }
    });

    buttonExit = new JButton("Exit");
    buttonExit.addActionListener(new ButtonHandler(){
      public void actionPerformed(ActionEvent e){
        dispose();
        System.exit(0);
      }
    });
    panes[0].add(buttonRun);
    panes[0].add(Box.createRigidArea(new Dimension(10, 0)));
    panes[0].add(buttonExit);

    sliderGameSize = new JSlider(JSlider.HORIZONTAL, 0, GAME_SIZE_MAX, 200);
    sliderGameSize.setMinorTickSpacing(50);
    sliderGameSize.setMajorTickSpacing(100);
    sliderGameSize.setPaintTicks(true);
    sliderGameSize.setSnapToTicks(true);

    ChangeListener sliderGameSizeListener = new ChangeListener() {
      public void stateChanged(ChangeEvent e) {
				if(!running){
	        int value = sliderGameSize.getValue();
	        GAME_SIZE = value>1?value:2;
				}
      }
    };
    sliderGameSize.addChangeListener(sliderGameSizeListener);

    Hashtable labelTable = new Hashtable();
    labelTable.put(new Integer(0), new JLabel("2"));
		int tickInterval = GAME_SIZE_MAX/GAME_SIZE_SLIDER_TICKS;
    for(int i = 1; i < GAME_SIZE_MAX/tickInterval; i++){
      labelTable.put(i*tickInterval, new JLabel(Integer.toString(i*tickInterval)));
    }
    labelTable.put(GAME_SIZE_MAX, new JLabel("Max"));

    sliderGameSize.setLabelTable(labelTable);
    sliderGameSize.setPaintLabels(true);

    panes[1].add(sliderGameSize);

    for(int i = 0; i < panes.length; i++){
      contentPane.add(panes[i]);
    }
	}

  private class ButtonHandler implements ActionListener{
		public void actionPerformed(ActionEvent e){}
	}

}

public void makeConfigWindow(){
	 config = new ConfigWindow();

  config.setVisible(false);
  config.setVisible(true);
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "geneticFighting" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
