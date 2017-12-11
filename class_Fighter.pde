class Fighter implements Comparable<Fighter>{ //The FIGHTER class!
  PVector pos, oldPos, vel = new PVector(0, 0); //Has a position and velocity
  color myfill; //Some dodgy stuff to make the two fighters different colours
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

  int myNoise = 0;

  Fighter(int half, int n){ //Default constructor, need to know which half the screen I'm in
  myNoise = n*1000;
    b = new Brain(NUM_INPUTS, NUM_HIDDEN, NUM_OUTPUTS);  //Creates a crazy random hectic brain
    side(half);
  }

  void side(int half){
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
    side(half);
  }

  public int compareTo(Fighter other){
    return round(other.fitness()-fitness());
  }

  void run(){ //Runs the NN and manages the fighter
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
    }if(int(leftEdge)==0){
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
    try{
      if(int(leftEdge)==0){
        PVector diff = PVector.sub(otherfighter.bullet.bulletPos, pos);
        withinFOV = degrees(PVector.angleBetween(vel, diff));
      }else{
        PVector diff = PVector.sub(pos, otherfighter.bullet.bulletPos);
        withinFOV = 180-degrees(PVector.angleBetween(vel, diff));
      }
    }catch(NullPointerException e){
      inputs[1] = 0.0;
    }

    inputs[1] = withinFOV<fov/2?1:0;

    //And finally, the size of my fov
    inputs[2] = map(fov, 10, 120, 1, 0);
    inputs[3] = map(dist(pos.x, pos.y, otherfighter.pos.x, otherfighter.pos.y), 0, dist(0, 0, arena.width, arena.height), 1, 0);
    inputs[4] = map(noise((frameCount+myNoise)*0.006), 0.15, 0.85, 0, 1);
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

    speed = forward<0.2?0:map(forward, 0.2, 1, 0.1, 8); //Forward speed
    float dirVel = 0;
    if(dirVelLeft > dirVelRight+0.03){
      dirVel = -dirVelLeft;
    }else if(dirVelRight > dirVelLeft+0.03){
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
    if(shoot > 0.3 && bullet == null){ //How hard do you have to pull the trigger (MAKE CONST)
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

  void shoot(){
    bullet = new Bullet(pos, dir, otherfighter);
  }

  void display(){ //Draw those curves!
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

  float fitness(){ //More baseline stuff to be implemented later, affects how likely I am to breed to the new generation.
    float normalFOV = map(fov, 5, 120, 0, 1);
    return -hitsTaken*2
    +shotsLanded*8
    +shotsAvoided*2
    +distanceTravelled*1
    -turnSpeed*2
    -shotsMissed*2
    +constrain(framesTracked, -50, 150)
    +shotWhileFacing*20;
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

    int run(){
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

    void drawBullet(){
      arena.fill(50, 50, 210);
      arena.ellipse(bulletPos.x, bulletPos.y, 6, 6);
    }
  }
}
