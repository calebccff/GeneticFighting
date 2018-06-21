class Fighter implements Comparable<Fighter>{ //The FIGHTER class!
  int SHOOT_COOLDOWN_LENGTH = 40;
  int FOV_MIN = 3, FOV_MAX = 120;

  PVector pos, oldPos, vel = new PVector(0, 0); //Has a position and velocity
  color myfill; //Some dodgy stuff to make the two fighters different colours
  int leftEdge; //More dodgy stuff, used to offset each fighter so they don't share the same space.
  /*The above variables are used to differentiate the two fighters, by
  giving them different colours and a horizontal offset
  */

  Brain brain; /*Brain object is used to run the neural network for each fighter
             It contains methods such as propForward and getters.
             */
  Bullet bullet;/*The bullet object is used to keep the bullet methods/properties
                  seperate from the Fighter*/

  Fighter otherfighter;/*A reference to the enemy fighter, would like to remove*/

  float netOut[] = new float[NUM_OUTPUTS]; /*The outputs of the neural net, need to be global to the class to dsplay them*/
  float[] inputs = new float[NUM_INPUTS]; /*Setup the inputs (Same as above)
  0 - Can see other fighter?
  1 - Can see other fighter's bullet?
  3 - Distance from me to enemy
  4 - Perlin noise, this is used as a tick, to encourage some random thoughts and stop them getting stuck
  5 - Relative direction of enemy
  6 - Current velocity of enemy (distanceTravelledInLastFrame/1)
  */
  float dir = 0;//, oldDir = 0; //Direction, Processing works in radians so I call a lot of functions to switch cuz, I'm too lazy to learn how they work.
  float fov = 20f; //The Field of View, ie how wide their eyesight is.
  float speed = 0; /*The speed of the Fighter*/
  int shootCooldown = 0; /*Used to only allow a fighter to shoot after a cooldown period*/

  float shotsLanded = 0, hitsTaken = 0, shotsAvoided = 0, framesTracked = 0; //Basic shoddy fitness function implementation
  float shotsMissed = 0, closeHits = 0, shotsFired = 0;
  boolean bulletInRange = false;

  int perlinNoise = 0;

  Fighter(int half, int n){ //Default constructor, need to know which half the screen I'm in
  perlinNoise = n*1000;
    brain = new Brain(NUM_INPUTS, NUM_HIDDEN, NUM_OUTPUTS);  //Creates a crazy random hectic brain
    side(half); /*The side method initialises some globals for the fighter to make sure it's in the right place*/
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

  Fighter(Brain _b, int half, int n){ /*Used to initialise fighters from the previous generation*/
    perlinNoise = n*1000;
    brain = _b;
    side(half);
  }

  Fighter(Fighter f1, int half, int n){ //This means I have parents
    perlinNoise = n*10;
    brain = new Brain(f1.brain); //Just pass it on, some more stuff will happen here (?)
    side(half);
  }

  public int compareTo(Fighter other){/*The comparator compareTo method, for breeding*/
    if(fitness() < other.fitness()){
      return 1;
    }else{
      return -1;
    }
  }

  void run(){ //Runs the NN and manages the fighter
    //Current input ideas:
    // - Size of FOV (mapped from min: 5 to max: 120 to min: 0, max: 1) DONE
    // - Is player in my FOV (Might make use of analog style values later)
    // - Is the enemies bullet in my FOV

    //Is the player in: Get heading between minFOV and player, as well as maxFOV and player, should be > 0 for min, < 0 for max
    //Make a new vector from vel and fov.
    float withinFOV; /*Local temp var to calculate an input*/
    PVector tempVel = vel.copy();
    if(vel.mag() < 1){ //If the fighter is travelling too slowly then use it's direction instead of calculating it from velocity
      vel = new PVector(10, 0);
      vel.rotate(radians(dir)); //Reset velocity using direction
    }
    PVector diff = PVector.sub(pos, otherfighter.pos); //
    withinFOV = (int(leftEdge)==0?0:180)-degrees(PVector.angleBetween(vel, diff));
    diff = null;

    inputs[0] = withinFOV<fov/82?1:0;
    inputs[4] = map(withinFOV, 0, 180, 0, 1);
    framesTracked += inputs[0]*map(fov, FOV_MIN, FOV_MAX, 1, 0);

    //Now the same for the bullets
    try{
        diff = PVector.sub(pos, otherfighter.bullet.bulletPos);
        withinFOV = (int(leftEdge)==0?0:180)-degrees(PVector.angleBetween(vel, diff));
    }catch(NullPointerException e){
      inputs[1] = 0.0;
    }

    inputs[1] = withinFOV<fov/2?1:0;
    inputs[2] = map(dist(pos.x, pos.y, otherfighter.pos.x, otherfighter.pos.y), 0, dist(0, 0, arena.width, arena.height), 1, 0); //Distnce between the two fighters
    try{
    inputs[3] = map(noise((frameCount+perlinNoise)*0.006), 0.15, 0.85, 0, 1);
    }catch(ArithmeticException e){
      e.printStackTrace();
      inputs[3] = random(1);
    }
    vel = tempVel.copy();

    //inputs[4] = map(otherfighter.vel.heading(), 0, TWO_PI, 0, 1); //Allows the fighter to know the direction and speed of the enemy
    inputs[5] = map(otherfighter.vel.mag(), 0, 8, 0, 1); //Enemy's velocity

    float[] actions = brain.propForward(inputs); //Get the output of my BRAIN
    netOut = actions;
    float forward = actions[0]; //Should I move forward?
    float dirVelLeft = actions[1];
    float dirVelRight = actions[2];
    float shoot = actions[3];

    //Update my fov
    fov = map(actions[4], 0, 1, FOV_MIN, FOV_MAX);

    speed = map(forward, 0, 1, 0, 8); //Forward speed
    if(abs(speed) < 2){
      speed = 0;
    }
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

    //Shooting
    if(shoot > 0.5 && shootCooldown == 0 && bullet == null){ //How hard do you have to pull the trigger (MAKE CONST)
      shoot();
    }
    if(bullet != null && !bullet.run()){
      bullet = null;
    }


    //Make sure you don't go off the edge.
    pos.x = constrain(pos.x, leftEdge+40, leftEdge+arena.width/2-40);
    pos.y = constrain(pos.y, 0, arena.height);

    //Increment shotsAvoided
    if(otherfighter.bullet != null){
      float dist = dist(pos.x, pos.y, otherfighter.bullet.bulletPos.x, otherfighter.bullet.bulletPos.y);
      if(dist < arena.width*0.1 && !bulletInRange){
        shotsAvoided++;
        otherfighter.closeHits += map(dist, 0, arena.width*0.1, 1, 0);
        bulletInRange = true;
      }else if(dist > (arena.width*0.1-1)){
        bulletInRange = false;
      }
    }
    //Decrement shooting cooldown.
    shootCooldown--;
    shootCooldown = constrain(shootCooldown, 0, SHOOT_COOLDOWN_LENGTH);
  }

  void shoot(){
    bullet = new Bullet(pos, dir, otherfighter);
    shotsFired += map(fov, FOV_MIN, FOV_MAX, 1, 0);
  }

  void display(){ //Draw those curves!
    arena.fill(myfill); //Set the fill colour to whatever colour this fighter is

    arena.ellipse(pos.x, pos.y, 20, 20); //Draw the fighter

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
      bullet.drawBullet();
    }
  }

  public boolean red(){ //Returns true if this fighter is a red one
    return leftEdge==0;
  }

  float fitness(){ //More baseline stuff to be implemented later, affects how likely I am to breed to the new generation.
    float thisAlgorithmBecomingSkynetCost = 9999999;
    float myFitness =
    +hitsTaken*(float)fitnessWeights.get("HitsTaken")
    +shotsLanded*(float)fitnessWeights.get("ShotsLanded")
    +constrain(shotsAvoided, 0, 50)*(float)fitnessWeights.get("ShotsAvoided")
    +shotsMissed*(float)fitnessWeights.get("ShotsMissed")
    +map(constrain(framesTracked, 0, 150), 0, 150, 0, 4)*(float)fitnessWeights.get("FramesTracked")
    +closeHits*(float)fitnessWeights.get("CloseHits")
    +shotsFired*(float)fitnessWeights.get("ShotsFired");

    return myFitness;
  }
  /*
  Getters and Setters
  */

  Brain getBrain(){
    return this.brain;
  }

  void setBrain(Brain brain){
    this.brain = brain;
  }

  class Bullet{
    PVector bulletPos, bulletVel, distanceTravelled;
    Fighter target;

    Bullet(PVector pos, float ang, Fighter f){
      this.bulletPos = pos.copy();
      this.distanceTravelled = pos.copy();
      this.bulletVel = PVector.fromAngle(radians(ang+random(-fov/2, fov/2)));
      this.bulletVel.mult(15);

      target = f;
    }

    boolean run(){
      if(bulletPos.x < 0 || bulletPos.x > arena.width || bulletPos.y < -2 || bulletPos.y > arena.height){
        shotsMissed += map(fov, FOV_MAX, FOV_MIN, 0.2, 1);
        shootCooldown = SHOOT_COOLDOWN_LENGTH;
        return false;
      }else if(dist(bulletPos.x, bulletPos.y, target.pos.x, target.pos.y) < 18){
        target.hitsTaken++;
        shotsLanded += map(dist(bulletPos.x, bulletPos.y, distanceTravelled.x, distanceTravelled.y), 5, dist(0, 0, arena.width, arena.height), 0, 1);
        shootCooldown = SHOOT_COOLDOWN_LENGTH;
        return false;
      }
      bulletPos.add(bulletVel);
      return true;
    }

    void drawBullet(){
      arena.fill(50, 50, 210);
      arena.ellipse(bulletPos.x, bulletPos.y, 6, 6);
    }
  }
}
