int currentGame = 0; //Used to switch which game the user is watching

void keyPressed(){ //Is called when the user presses a key
  if(keyCode == UP){ //Constants for up/down arrow key, changes the current game
    currentGame++;
  }else if(keyCode == DOWN){
    currentGame--;
  }
  currentGame = (currentGame<0?GAME_SIZE-1:(currentGame>GAME_SIZE-1?0:currentGame)); //Wrap around, from the end to the beginning
}

void keyReleased(){ //If the user hits the f key, stop auto-switching to the fittest game
  if(keyCode == 70){ //'f' key
    showFittest = !showFittest;
  }
  if(keyCode == ESC){ //Originally overwritten to properly exit the config window in the first GUI
    //config.dispose();
    System.exit(0);
  }
}
