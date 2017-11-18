class Fighter{ //The FIGHTER class!
  PVector pos, vel = new PVector(0, 0); //Has a position and velocity
  color myfill; //Some dodgy stuff to make the two fighters different colours
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
      pos = new PVector(arena.width*0.25, arena.height*0.5); //Set my position
    }else{
      myfill = color(50, 210, 50); //I'm GREEN and proud
      leftEdge = arena.width/2; //Right side
      pos = new PVector(arena.width*0.75, arena.height*0.5); //RIGHT SIDE
    }
  }

  Fighter(Fighter f1, Fighter f2){ //This means I have parents
    b = new Brain(f1.b, f2.b); //Just pass it on, some more stuff will happen here
  }

  void run(PVector otherPos){ //Lets FIGHT, gotta know where my opponent is!
    float[] inputs = new float[2]; //Setup the inputs
    inputs[0] = map(degrees(PVector.angleBetween(pos, otherPos)), 0, 360, 0, 1); //More guesswork, these inputs aren't gonna produce useful results
    inputs[1] = 1; //Involes bullets, not implemented.
    debugText += "in : "+Arrays.toString(nfc(inputs))+"\n";
    float[] actions = b.propForward(inputs); //Get the output of my BRAIN
    debugText += "out: "+Arrays.toString(nfc(actions))+"\n";
    float forward = actions[0]; //Should i move forward?
    dir = actions[1];
    float shoot = actions[2];

    float speed = forward<0.5?0:map(forward, 0.5, 1, 2, 8);
    dir = map(dir, 0, 1, -20, 20); //Set my direction
    if(dir < 2 && dir > -2){ //Basically a deadzone, don't want to be always spinning
      dir = 0;
    }
    debugText += "Dir: "+dir+"\n";
    vel = new PVector(1, 0);
    vel.setMag(speed); //Some broken vector stuff
    vel.rotate(radians(dir));
    pos.add(vel); //Let's GOOOOO
    if(shoot > 0.5){ //How hard do you have to pull the trigger (MAKE CONST)
      shoot();
    }

    //Make sure you don't go off the edge.
    if(pos.x > leftEdge+arena.width/2-2 || pos.x < leftEdge+2){
      dir += 180;
    }else if(pos.y < 2 || pos.y > arena.height-2){
      dir += 180;
    }
  }

  void shoot(){
    //make a bullet, set direction (velocity?)
  }

  void display(){ //Draw those curves!
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

  float fitness(){ //More baseline stuff to be implemented later, affects how likely I am to breed to the new generation.
    return shotsLanded*2+shotsAvoided+distanceTravelled;
  }
}
