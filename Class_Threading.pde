class GameThread{
  int subsetFrom, subsetTo;

  GameThread(int f, int t){ //From what index of `games` to what
    subsetFrom = f;
    subsetTo = t;
  }

  void run(){
    for(int i = subsetFrom; i < subsetTo; ++i){
      games[i].run();
    }
  }
}
