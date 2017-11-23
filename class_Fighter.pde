class Fighter implements Comparable<Fighter>{ //The FIGHTER class!
  PVector pos, oldPos, vel = new PVector(0, 0); //Has a position and velocity
  color myfill; //Some dodgy stuff to make the two fighters different colours
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

  void side(int half){
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

  void run(){ //Lets FIGHT, gotta know where my opponent is!
    inputs[0] = map(PVector.angleBetween(vel, otherfighter.pos), 0, TWO_PI, 0, 1); //More guesswork, these inputs aren't gonna produce useful results
    inputs[1] = otherfighter.bullet!=null?(map(PVector.angleBetween(vel, otherfighter.bullet.bulletPos), 0, TWO_PI, 0, 1)):0.5; //Involes bullets, not implemented.
    //float angBetween = degrees(PVector.angleBetween(vel, otherfighter.pos));
    //inputs[0] = (abs(angBetween)<10?1:0);
    //inputs[1] = (otherfighter.bullet!=null?(degrees(abs(otherfighter.bullet.bulletVel.heading())-vel.heading())<30?1:0):0);
    float[] actions = b.propForward(inputs); //Get the output of my BRAIN
    netOut = actions;
    float forward = actions[0]; //Should I move forward?
    float dirVel = actions[1];
    float shoot = actions[2];

    float speed = forward<0.2?0:map(forward, 0.2, 1, 2, 8);

    dirVel = map(dirVel, 0, 1, -40, 40); //Adjust my direction
    if(dirVel < 2 && dirVel > -2){ //Basically a deadzone, don't want to be always spinning (not that that stops them...)
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
    if(shoot > 0.3 && bullet == null){ //How hard do you have to pull the trigger (MAKE CONST)
      shoot();
    }
    if(bullet != null && bullet.exists){
      bullet.run();
    }

    shotsLanded = otherfighter.hitsTaken;
    distanceTravelled += map(dist(oldPos.x, oldPos.y, pos.x, pos.y), 0, 1+speed*10, 0, 1);
    distanceTravelled = constrain(distanceTravelled, 0, 100);

    //Make sure you don't go off the edge.
    pos.x = constrain(pos.x, leftEdge+40, leftEdge+arena.width/2-40);
    pos.y = constrain(pos.y, 0, arena.height);
  }

  public int compareTo(Fighter other){
    return round(other.fitness()-fitness());
  }

  void shoot(){
    bullet = new Bullet(pos, dir, otherfighter);
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

    if(bullet != null){ //Draw the bullet
      if(!bullet.exists){
        bullet = null;
      }else{
        bullet.drawBullet();
      }
    }
  }

  float fitness(){ //More baseline stuff to be implemented later, affects how likely I am to breed to the new generation.
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

    int run(){
      if(bulletPos.x < 0 || bulletPos.x > arena.width || bulletPos.y < -2 || bulletPos.y > arena.height){
        exists = false;
        return -1;
      }else if(dist(bulletPos.x, bulletPos.y, target.pos.x, target.pos.y) < 20){
        exists = false;
        target.hitsTaken += 1;
        return -1;
      }
      bulletPos.add(bulletVel);
      return 1;
    }

    void drawBullet(){
      arena.fill(50, 50, 210);
      arena.ellipse(bulletPos.x, bulletPos.y, 10, 10);
    }
  }
}
