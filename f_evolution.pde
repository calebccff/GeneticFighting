float sig(float x) { //The sigmoid function, look it up.
  return 1/(1+exp(-x)); //looks like and S shape, Eulers number is AWESOME!
}

float pi(float D, float p1, float p2){
  float imp1 = D-p1;
  float imp2 = D-p2;
  int choice = 0;
  if(imp1 > IMPROVEMENT_THRESHOLD){
    choice += 70;
  } else if (imp1 < -IMPROVEMENT_THRESHOLD){
    choice += 30;
  } else {
    choice += 50;
  }
  if(imp2 > IMPROVEMENT_THRESHOLD){
    choice += 7;
  } else if (imp2 < -IMPROVEMENT_THRESHOLD){
    choice += 3;
  } else {
    choice += 5;
  }
  switch (choice){
    case 77:
    // better than both
    return 5; //<
    case 75:
    case 57:
    // better than one
    return 4; //<
    case 55:
    // equal to both
    return 3; //<
    case 73:
    case 53:
    case 35:
    case 37:
    // worse than one
    return 2; //<
    case 33:
    // worse than both
    default:
    //error
    return 1; //<
  }
}
