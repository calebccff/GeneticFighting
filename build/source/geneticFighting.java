import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

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

PGraphics arena;

Fighter fighter1, fighter2;

public void setup(){
  

  arena = createGraphics(round(width*0.6f), round(height*0.9f));

  imageMode(CENTER);
  rectMode(CENTER);

  fighter1 = new Fighter(LEFT);
  fighter2 = new Fighter(RIGHT);

  randomSeed(1);
}

public void draw(){
  background(50);
  fighter1.run(fighter2.pos);
  fighter2.run(fighter1.pos);
  arena.beginDraw();
  drawStage();
  fighter1.display();
  fighter2.display();
  arena.endDraw();

}

public void drawStage(){
  arena.background(200);
  arena.strokeWeight(4);

  arena.line(arena.width*0.5f, 0, arena.width*0.5f, arena.height);

  image(arena, width*0.7f-height*0.05f, height*0.5f);
  strokeWeight(5);
  stroke(50);
  noFill();
  rect(width*0.7f-height*0.05f, height*0.5f, arena.width+6, arena.height+6, 20);
  strokeWeight(2);
}
class Brain {

  Node[][] nodes = new Node[3][];

  final float SYNAPSE_MIN = -2f;
  final float SYNAPSE_MAX = 2f;
  final float MUTATION_RATE = 0.02f;

  Brain(int lenInput, int lenHidden, int lenOutput) {
    nodes[0] = new Node[lenInput];
    nodes[1] = new Node[lenHidden];
    nodes[2] = new Node[lenOutput];

    for (int i = 0; i < nodes.length; i++) {
      for (int j = 0; j < nodes[i].length; j++) {
        try {
          nodes[i][j] = new Node(nodes[i-1].length);
        }
        catch (ArrayIndexOutOfBoundsException e) {
          nodes[i][j] = new Node(0);
        }
      }
    }
  }

  Brain(Brain b1, Brain b2){
    nodes[0] = new Node[b1.nodes[0].length];
    nodes[1] = new Node[b1.nodes[1].length];
    nodes[2] = new Node[b1.nodes[2].length];

    for(int i = 0; i < nodes.length; i++){
      for(int j = 0; j < nodes[i].length; j++){
        nodes[i][j] = new Node(random(1)<0.5f?b1.nodes[i][j]:b2.nodes[i][j]);
      }
    }
  }

  public float[] propForward(float[] inputs) {
    // Input
    for (int j = 0; j < inputs.length; j++) {
      nodes[0][j].value = inputs[j];
    }
    // Hidden/Outer
    for (int i = 1; i < nodes.length; i++) {
      for (int j = 0; j < nodes[i].length; j++) {
        nodes[i][j].propForward(nodes[i-1]);
      }
    }
    // Get/return the outputs
    float[] output = new float[nodes[nodes.length-1].length];
    for (int i = 0; i < output.length; i++) {
      output[i] = nodes[nodes.length-1][i].value;
    }

    return output;

  }

  class Node {
    // A given node has all the synapses connected to it from the previous layer.
    float synapse[], value = 0;

    Node(int synLen) {
      synapse = new float[synLen];
      for (int i = 0; i < synLen; i++) {
        synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX);
      }
    }

    Node(Node parent){
      Node t = this;
      t = parent;
      for(int i = 0; i < synapse.length; i++){
        if(random(1)<=MUTATION_RATE){
          synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX);
        }
      }
    }

    public void propForward(Node[] nodes) {
      value = 0;
      for (int i = 0; i < nodes.length; i++) {
        value += nodes[i].value*synapse[i];
      }
      value = sig(value); ///MIGHT NEED TO BE ADJUSTED
    }
    public float sig(float x) {
      return 1/(1+pow((float)Math.E, -x));
    }
  }
}
class Fighter{
  PVector pos, vel = new PVector(0, 0);
  int myfill;
  int leftEdge;

  Brain b;

  float dir = 0;

  int shotsLanded = 0, shotsAvoided = 0, distanceTravelled = 0;

  Fighter(int half){
    b = new Brain(2, 4, 3);

    if(half == LEFT){
      myfill = color(210, 50, 50);
      leftEdge = 0;
      pos = new PVector(arena.width*0.25f, arena.height*0.5f);
    }else{
      myfill = color(50, 210, 50);
      leftEdge = arena.width/2;
      pos = new PVector(arena.width*0.75f, arena.height*0.5f);
    }
  }

  Fighter(Fighter f1, Fighter f2){
    b = new Brain(f1.b, f2.b);
  }

  public void run(PVector otherPos){
    float[] inputs = new float[2];
    inputs[0] = map(degrees(PVector.angleBetween(pos, otherPos)), 0, 360, 0, 1);
    inputs[1] = 1; //Involes bullets, not implemented.
    print("in: ");
    println(inputs);
    float[] actions = b.propForward(inputs);
    print("out: ");
    println(actions);
    float forward = actions[0];
    dir = actions[1];
    float shoot = actions[2];

    float speed = forward<0.3f?0:map(forward, 0.5f, 1, 2, 8);
    dir = map(dir, 0, 1, -20, 20);
    if(dir < 2 && dir > -2){
      dir = 0;
    }
    vel.setMag(speed);
    vel.rotate(radians(dir));
    pos.add(vel);
    if(shoot > 0.5f){
      shoot();
    }
  }

  public void shoot(){
    //make a bullet, set direction (velocity?)
  }

  public void display(){
    arena.fill(myfill);
    arena.stroke(0);
    arena.strokeWeight(2);

    arena.ellipse(pos.x, pos.y, 40, 40);
    PVector l = vel;
    if(vel.mag() > 1){
      l.normalize();
      l.mult(20);
    }else{
      l = new PVector(20, 0);
      l.rotate(radians(dir));
    }
    arena.line(pos.x, pos.y, pos.x+l.x, pos.y+l.y);
  }

  public float fitness(){
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
