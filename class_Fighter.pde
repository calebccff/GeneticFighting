class Fighter{
  PVector pos, vel = new PVector(0, 0);
  color myfill;
  int leftEdge;

  Brain b;

  float dir = 0;

  int shotsLanded = 0, shotsAvoided = 0, distanceTravelled = 0;

  Fighter(int half){
    b = new Brain(2, 4, 3);

    if(half == LEFT){
      myfill = color(210, 50, 50);
      leftEdge = 0;
      pos = new PVector(arena.width*0.25, arena.height*0.5);
    }else{
      myfill = color(50, 210, 50);
      leftEdge = arena.width/2;
      pos = new PVector(arena.width*0.75, arena.height*0.5);
    }
  }

  Fighter(Fighter f1, Fighter f2){
    b = new Brain(f1.b, f2.b);
  }

  void run(PVector otherPos){
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

    float speed = forward<0.3?0:map(forward, 0.5, 1, 2, 8);
    dir = map(dir, 0, 1, -20, 20);
    if(dir < 2 && dir > -2){
      dir = 0;
    }
    vel.setMag(speed);
    vel.rotate(radians(dir));
    pos.add(vel);
    if(shoot > 0.5){
      shoot();
    }
  }

  void shoot(){
    //make a bullet, set direction (velocity?)
  }

  void display(){
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

  float fitness(){
    return shotsLanded*2+shotsAvoided+distanceTravelled;
  }
}
