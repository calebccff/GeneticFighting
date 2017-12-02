int currentGame = 0;

void keyPressed(){
  if(keyCode == UP){
    currentGame++;
  }else if(keyCode == DOWN){
    currentGame--;
  }
  currentGame = (currentGame<0?GAME_SIZE-1:(currentGame>49?0:currentGame));
}

void keyReleased(){
  if(keyCode == 70){ //'f' key
    showFittest = !showFittest;
  }
}

void mousePressed(){
  frameRate(5);
}
void mouseReleased(){
  frameRate(120);
}
