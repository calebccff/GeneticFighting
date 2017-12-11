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
    debugText += "Shoot : "+(f.bullet!=null?"O\n":"X\n");
    debugText += "Fit   : "+nfs(f.fitness(), 3, 1)+"\n";
    debugText += "Input : \n";
    debugText += "SO  , SOB , FOV , DIST, NOISE\n";
    for(int i = 0; i < f.inputs.length; i++){
      debugText += nf(f.inputs[i], 1, 2)+(i==f.inputs.length-1?"":", ");
    }
    debugText += "\n\n";
    debugText += "Output: \n";
    debugText += "W   , A   , D   , SHO , FOV\n";
    for(int i = 0; i < f.netOut.length; i++){
      debugText += nf(f.netOut[i], 1, 2)+(i==f.netOut.length-1?"":", ");
    }
    debugText += "\n";
    debugText += "FOV   : "+f.fov+"\n";

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
      debuggingInfo += debug(f);
    }
    text(debuggingInfo, height*0.02, height*0.2);
  }
}
