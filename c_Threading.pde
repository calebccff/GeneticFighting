class GameThread extends Thread {
  private Thread t;
  private int index;

  GameThread( int name) {
    index = name;
  }

  public void run() {
    //Do the code here
    for (int i = 0; i < 100; i++) {
      Game[] toRun = Arrays.copyOfRange(games, quarter*index, quarter*(index+1));
      for (Game g : toRun) {
        g.run();
      }
    }
  threadState[index] = 1;
  t = null;
}

public void start () {
  if (t == null) {
    t = new Thread (this, str(index));
    t.start ();
  }
}
}