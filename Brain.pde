class Brain {

  Node[][] nodes = new Node[3][]; //Staggered 2d array of Node objects that make up the BRAIN

  final float SYNAPSE_MIN = -2f; //Some constants to fine tune the NN, could have a drastic effect on evolution
  final float SYNAPSE_MAX = 2f;
  final float MUTATION_RATE = 0.05f;

  Brain(int lenInput, int lenHidden, int lenOutput) { //Default constructor, specify the lengths of each layer
    nodes[0] = new Node[lenInput]; //Initialises the second dimension of the array
    nodes[1] = new Node[lenHidden];
    nodes[2] = new Node[lenOutput];

    for (int i = 0; i < nodes.length; i++) { //Nested FOR loop, creates each node
      for (int j = 0; j < nodes[i].length; j++) {
        try {
          nodes[i][j] = new Node(nodes[i-1].length); //No. synapses equals the size of the previous layer.
        }
        catch (ArrayIndexOutOfBoundsException e) { //The first layer throws this exception because [0-1] throws a nullPointer.
          nodes[i][j] = new Node(0); //No synapses
        }
      }
    }
  }

  Brain(Brain b1, Brain b2){ //This is used for evolution, basically creates a new BRAIN from two parents.
    nodes[0] = new Node[b1.nodes[0].length]; //Set the size of the staggered array, kinda crusty code MIGHTFIX
    nodes[1] = new Node[b1.nodes[1].length];
    nodes[2] = new Node[b1.nodes[2].length];

    Brain chosen;
    if(random(1)<0.5){
      chosen = b1;
    }else{
      chosen = b2;
    }

    for(int i = 0; i < nodes.length; i++){ //This is where the evolution comes in, no dominant/recessive genes although that could be added
      for(int j = 0; j < nodes[i].length; j++){
        nodes[i][j] = new Node(chosen.nodes[i][j]); //Picks a random parent and uses their genes.
      }                                                                      //Obviously this isn't great for a NN, MIGHTFIX
    }
  }

  float[] propForward(float[] inputs) { //Propagates forward, passes inputs through the net and gets an output.
    // Input
    for (int j = 0; j < inputs.length; j++) { //For the first layer, set the values.
      nodes[0][j].value = inputs[j];
    }
    // Hidden/Outer
    for (int i = 1; i < nodes.length; i++) { //Set the next layer
      for (int j = 0; j < nodes[i].length; j++) {
        nodes[i][j].propForward(nodes[i-1]);
      }
    }
    // Get/return the outputs
    float[] output = new float[nodes[nodes.length-1].length]; //Gets the outputs from the last layer
    for (int i = 0; i < output.length; i++) {
      output[i] = nodes[nodes.length-1][i].value;
      //output[i] = sig(output[i]);
    }

    return output; //Return them

  }

  float sig(float x) { //The sigmoid function, look it up.
    return 1/(1+pow((float)Math.E, -x)); //looks like and S shape, Eulers number is AWESOME!
  }

  class Node { //Node class, could use a dictionary or somethin similar but this creates more logical code (and more efficient!)
    // A given node has all the synapses connected to it from the previous layer.
    float synapse[], value = 0;

    Node(int synLen) { //Default constructer, for RANDOM initialisation
      synapse = new float[synLen];
      for (int i = 0; i < synLen; i++) {
        synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX);
      }
    }

    Node(Node parent){ //Takes a random parent Node (see above)
      synapse = new float[parent.synapse.length];
      for(int i = 0; i < synapse.length; i++){ //For each synapse
        if(random(1)<=MUTATION_RATE){ //Small chance of mutation.
          synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX); //At the moment picks new random value, MIGHTFIX
        }else{
          synapse[i] = parent.synapse[i];
        }
      }
    }

    void propForward(Node[] nodes) { //Propagates forward, takes and array of the previous layer
      value = 0;
      for (int i = 0; i < nodes.length; i++) { //Set my value to be the sum of each previous node * the synaps
        value += nodes[i].value*synapse[i];
      }
      value = sig(value); ///MIGHT NEED TO BE ADJUSTED // Activation function, used to keep the values nice and small.
    }

  }
}
