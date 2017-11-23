int currentGame = 0;

void keyPressed(){
  if(keyCode == UP){
    currentGame++;
  }else if(keyCode == DOWN){
    currentGame--;
  }
  println(keyCode);
  currentGame = (currentGame<0?GAME_SIZE-1:(currentGame>49?0:currentGame));
}
