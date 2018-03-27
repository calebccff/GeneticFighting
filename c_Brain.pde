class Brain {

  private Node[][] nodesVisible = new Node[2][]; //Staggered 2d array of Node objects that make up the BRAIN
  private Node[][] nodesHidden;

  private final float SYNAPSE_MIN = -1f; //Some constants to fine tune the NN, could have a drastic effect on evolution
  private final float SYNAPSE_MAX = 1f;

  Brain(int lenInput, int[] lenHidden, int lenOutput) { //Default constructor, specify the lengths of each layer
    nodesVisible[0] = new Node[lenInput]; //Initialises the second dimension of the array
    nodesVisible[1] = new Node[lenOutput];

    for(int i = 0; i < nodesVisible[0].length; i++){
      nodesVisible[0][i] = new Node(0);
    }

    nodesHidden = new Node[lenHidden.length][];
    for(int i = 0; i < nodesHidden.length; i++){
      nodesHidden[i] = new Node[lenHidden[i]];
    }

    for(int i = 0; i < nodesHidden[0].length; i++){
      nodesHidden[0][i] = new Node(nodesVisible[0].length);
    }

    for(int i = 1; i < lenHidden.length; i++){
      for(int j = 0; j < lenHidden[i]; j++){
        nodesHidden[i][j] = new Node(nodesHidden[i-1].length);
      }
    }

    for (int i = 0; i < nodesVisible[1].length; i++) { //Nested FOR loop, creates each node
      nodesVisible[1][i] = new Node(nodesHidden[nodesHidden.length-1].length);
    }
  }

  Brain(Brain b){ //This is used for evolution, basically creates a new BRAIN from one parent
    nodesVisible[0] = new Node[b.nodesVisible[0].length]; //Set the size of the staggered array, kinda crusty code MIGHTFIX
    nodesVisible[1] = new Node[b.nodesVisible[1].length];
    nodesHidden = new Node[b.nodesHidden.length][];
    for(int i = 0; i < nodesHidden.length; i++){
      nodesHidden[i] = new Node[b.nodesHidden[i].length];
    }

    for(int i = 0; i < nodesVisible.length; i++){ //This is where the evolution comes in, no dominant/recessive genes although that could be added
      for(int j = 0; j < nodesVisible[i].length; j++){
        nodesVisible[i][j] = new Node(b.nodesVisible[i][j]); //Picks a random parent and uses their genes.
      }                                                                      //Obviously this isn't great for a NN, MIGHTFIX
    }
    for(int i = 0; i < nodesHidden.length; i++){ //This is where the evolution comes in, no dominant/recessive genes although that could be added
      for(int j = 0; j < nodesHidden[i].length; j++){
        nodesHidden[i][j] = new Node(b.nodesHidden[i][j]); //Picks a random parent and uses their genes.
      }                                                                      //Obviously this isn't great for a NN, MIGHTFIX
    }
  }

  float[] propForward(float[] inputs) { //Propagates forward, passes inputs through the net and gets an output.
    // Input
    for (int j = 0; j < inputs.length; ++j) { //For the first layer, set the values.
      nodesVisible[0][j].setValue(inputs[j]);
    }
    // Hidden/Outer
    for (int i = 0; i < nodesHidden[0].length; ++i) { //Set the next layer
      nodesHidden[0][i].propForward(nodesVisible[0]);
    }
    for(int j = 1; j < nodesHidden.length; ++j){
      for(int i = 0; i < nodesHidden[j].length; ++i){
        nodesHidden[j][i].propForward(nodesHidden[j-1]);
      }
    }
    for(int i = 0; i < nodesVisible[1].length; ++i){
      nodesVisible[1][i].propForward(nodesHidden[nodesHidden.length-1]);
    }

    // Get/return the outputs
    float[] output = new float[nodesVisible[nodesVisible.length-1].length]; //Gets the outputs from the last layer
    for (int i = 0; i < output.length; ++i) {
      output[i] = nodesVisible[nodesVisible.length-1][i].getValue();
      output[i] = sig(output[i]);
    }

    return output; //Return them

  }

  class Node { //Node class, could use a dictionary or somethin similar but this creates more logical code (and more efficient!)
    // A given node has all the synapses connected to it from the previous layer.
    float synapse[], value = 0;

    Node(int synLen) { //Default constructer, for RANDOM initialisation
      synapse = new float[synLen];
      for (int i = 0; i < synLen; ++i) {
        synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX);
      }
    }

    Node(Node parent){ //Takes a random parent Node (see above)
      synapse = new float[parent.synapse.length];
      for(int i = 0; i < synapse.length; ++i){ //For each synapse
        synapse[i] = parent.getSynapse(i)*random(1-MUTATION_RATE, 1+MUTATION_RATE);
      }
    }

    void propForward(Node[] nodes) { //Propagates forward, takes and array of the previous layer
      value = 0;
      for (int i = 0; i < nodes.length; ++i) { //Set my value to be the sum of each previous node * the synaps
        value += nodes[i].getValue()*synapse[i];
      }
      //value = sig(value); ///MIGHT NEED TO BE ADJUSTED // Activation function, used to keep the values nice and small.
    }

    float getValue(){
      return value;
    }
    void setValue(float val){
      this.value = val;
    }
    float getSynapse(int index){
      return synapse[index];
    }

  }
}
