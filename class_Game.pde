class Game{

  Fighter[] localfighters = new Fighter[2];

  String debuggingInfo = "";

  Game(Fighter f1, Fighter f2){
    localfighters[0] = f1;
    localfighters[1] = f2;
    localfighters[0].otherfighter = f2;
    localfighters[1].otherfighter = f1;
  }

  String debug(Fighter f){
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

  void run(){
    localfighters[0].run();
    localfighters[1].run();
  }

  void display(){
    debuggingInfo = "";
    for(Fighter f : localfighters){
      f.display();
      //debuggingInfo += debug(f);
    }
    text(debuggingInfo, height*0.05, height*0.2);
  }
}
