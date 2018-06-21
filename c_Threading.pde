class GameThread extends Thread { //A custom thread class to easily multithread
  private Thread t;
  private int index;

  GameThread( int name) { //Constructor, has a name for potential future use
    index = name;
  }

  public void run() { //Takes it's own section of the game array
    Game[] toRun = Arrays.copyOfRange(games, THREAD_SECTION_SIZE*index, THREAD_SECTION_SIZE*(index+1));
    for (int i = 0; i < 10; i++) {
      for (Game g : toRun) {
        g.run(); //Runs all the game in this thread
      }
    }
    t = null; //Reset the thread object so the main program knows when to start the thread again
  }

  public void start () {
    if (t == null) {
      t = new Thread (this, str(index));
      t.start ();
    }
  }
}