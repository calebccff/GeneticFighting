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



PGraphics arena; //Makes drawing things easier, so debugging has space.

Fighter fighter1, fighter2; //The two fighters, not very modular but ah well, don't worry it'll become an array at some points

String debugText = "";

public void setup(){ //Called ONCE at the beggining of runtime
   //That cinema experience

  arena = createGraphics(round(width*0.6f), round(height*0.9f)); //Make a square

  imageMode(CENTER); //Changing some settings
  rectMode(CENTER);

  fighter1 = new Fighter(LEFT); //Make the fighters, yes I used built in constants for the arrow keys
  fighter2 = new Fighter(RIGHT);

  randomSeed(1); //FOR DEBUGGING

  //Set font
  PFont mono = createFont("UbuntuMono.ttf", 26);
  textFont(mono);
}

public void draw(){ //Caleed 60 (ish) times per second
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
  text(debugText, height*0.05f, height*0.05f);
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
  final float MUTATION_RATE = 0.02f;

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

    for(int i = 0; i < nodes.length; i++){ //This is where the evolution comes in, no dominant/recessive genes although that could be added
      for(int j = 0; j < nodes[i].length; j++){
        nodes[i][j] = new Node(random(1)<0.5f?b1.nodes[i][j]:b2.nodes[i][j]); //Picks a random parent and uses their genes.
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
      Node t = this;
      t = parent;
      for(int i = 0; i < synapse.length; i++){ //For each synapse
        if(random(1)<=MUTATION_RATE){ //Small chance of mutation.
          synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX); //At the moment picks new random value, MIGHTFIX
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
    public float sig(float x) { //The sigmoid function, look it up.
      return 1/(1+pow((float)Math.E, -x)); //looks like and S shape, Eulers number is AWESOME!
    }
  }
}
class Fighter{ //The FIGHTER class!
  PVector pos, vel = new PVector(0, 0); //Has a position and velocity
  int myfill; //Some dodgy stuff to make the two fighters different colours
  int leftEdge; //More dodgy stuff, used to offset each fighter so they don't share the same space.

  Brain b; //Hey they aren't zombies, although they may act like that.

  float dir = 0; //Direction, Processing works in radians so I call a lot of functions to switch cuz, I'm too lazzy to learn how they work.

  int shotsLanded = 0, shotsAvoided = 0, distanceTravelled = 0; //Basic shoddy fitness function implementation, these don't do anything
                                                                //YET
  Fighter(int half){ //Default constructor, need to know which half the screen I'm in
    b = new Brain(2, 4, 3);  //Creates a crazy random hectic brain

    if(half == LEFT){ //If I'm on the left half
      myfill = color(210, 50, 50); //Let there be RED
      leftEdge = 0; //No offset
      pos = new PVector(arena.width*0.25f, arena.height*0.5f); //Set my position
    }else{
      myfill = color(50, 210, 50); //I'm GREEN and proud
      leftEdge = arena.width/2; //Right side
      pos = new PVector(arena.width*0.75f, arena.height*0.5f); //RIGHT SIDE
    }
  }

  Fighter(Fighter f1, Fighter f2){ //This means I have parents
    b = new Brain(f1.b, f2.b); //Just pass it on, some more stuff will happen here
  }

  public void run(PVector otherPos){ //Lets FIGHT, gotta know where my opponent is!
    float[] inputs = new float[2]; //Setup the inputs
    inputs[0] = map(degrees(PVector.angleBetween(pos, otherPos)), 0, 360, 0, 1); //More guesswork, these inputs aren't gonna produce useful results
    inputs[1] = 1; //Involes bullets, not implemented.
    debugText += "in : "+Arrays.toString(nfc(inputs))+"\n";
    float[] actions = b.propForward(inputs); //Get the output of my BRAIN
    debugText += "out: "+Arrays.toString(nfc(actions))+"\n";
    float forward = actions[0]; //Should i move forward?
    dir = actions[1];
    float shoot = actions[2];

    float speed = forward<0.5f?0:map(forward, 0.5f, 1, 2, 8);
    dir = map(dir, 0, 1, -20, 20); //Set my direction
    if(dir < 2 && dir > -2){ //Basically a deadzone, don't want to be always spinning
      dir = 0;
    }
    debugText += "Dir: "+dir+"\n";
    vel = new PVector(1, 0);
    vel.setMag(speed); //Some broken vector stuff
    vel.rotate(radians(dir));
    pos.add(vel); //Let's GOOOOO
    if(shoot > 0.5f){ //How hard do you have to pull the trigger (MAKE CONST)
      shoot();
    }

    //Make sure you don't go off the edge.
    if(pos.x > leftEdge+arena.width/2-2 || pos.x < leftEdge+2){
      dir += 180;
    }else if(pos.y < 2 || pos.y > arena.height-2){
      dir += 180;
    }
  }

  public void shoot(){
    //make a bullet, set direction (velocity?)
  }

  public void display(){ //Draw those curves!
    arena.fill(myfill); //RAINBOWS
    arena.stroke(0); //Black for the line, to show direction
    arena.strokeWeight(2); //THICC lines

    arena.ellipse(pos.x, pos.y, 40, 40); //CURVY
    PVector l = vel; //Some funky stuff for drawing a line from a direction
    if(vel.mag() > 1){ //Normalize it, if we're moving
      l.normalize();
      l.mult(20);
    }else{
      l = new PVector(20, 0); //Create a vector using `dir`
      l.rotate(radians(dir));
    }
    arena.line(pos.x, pos.y, pos.x+l.x, pos.y+l.y); //Draw the pointer
  }

  public float fitness(){ //More baseline stuff to be implemented later, affects how likely I am to breed to the new generation.
    return shotsLanded*2+shotsAvoided+distanceTravelled;
  }
}
  public void settings() {  fullScreen(FX2D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "geneticFighting" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
