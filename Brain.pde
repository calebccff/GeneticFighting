class Brain {

  Node[][] nodes = new Node[3][];

  final float SYNAPSE_MIN = -2f;
  final float SYNAPSE_MAX = 2f;
  final float MUTATION_RATE = 0.02f;

  Brain(int lenInput, int lenHidden, int lenOutput) {
    nodes[0] = new Node[lenInput];
    nodes[1] = new Node[lenHidden];
    nodes[2] = new Node[lenOutput];

    for (int i = 0; i < nodes.length; i++) {
      for (int j = 0; j < nodes[i].length; j++) {
        try {
          nodes[i][j] = new Node(nodes[i-1].length);
        }
        catch (ArrayIndexOutOfBoundsException e) {
          nodes[i][j] = new Node(0);
        }
      }
    }
  }

  Brain(Brain b1, Brain b2){
    nodes[0] = new Node[b1.nodes[0].length];
    nodes[1] = new Node[b1.nodes[1].length];
    nodes[2] = new Node[b1.nodes[2].length];

    for(int i = 0; i < nodes.length; i++){
      for(int j = 0; j < nodes[i].length; j++){
        nodes[i][j] = new Node(random(1)<0.5?b1.nodes[i][j]:b2.nodes[i][j]);
      }
    }
  }

  float[] propForward(float[] inputs) {
    // Input
    for (int j = 0; j < inputs.length; j++) {
      nodes[0][j].value = inputs[j];
    }
    // Hidden/Outer
    for (int i = 1; i < nodes.length; i++) {
      for (int j = 0; j < nodes[i].length; j++) {
        nodes[i][j].propForward(nodes[i-1]);
      }
    }
    // Get/return the outputs
    float[] output = new float[nodes[nodes.length-1].length];
    for (int i = 0; i < output.length; i++) {
      output[i] = nodes[nodes.length-1][i].value;
    }

    return output;

  }

  class Node {
    // A given node has all the synapses connected to it from the previous layer.
    float synapse[], value = 0;

    Node(int synLen) {
      synapse = new float[synLen];
      for (int i = 0; i < synLen; i++) {
        synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX);
      }
    }

    Node(Node parent){
      Node t = this;
      t = parent;
      for(int i = 0; i < synapse.length; i++){
        if(random(1)<=MUTATION_RATE){
          synapse[i] = random(SYNAPSE_MIN, SYNAPSE_MAX);
        }
      }
    }

    void propForward(Node[] nodes) {
      value = 0;
      for (int i = 0; i < nodes.length; i++) {
        value += nodes[i].value*synapse[i];
      }
      value = sig(value); ///MIGHT NEED TO BE ADJUSTED
    }
    float sig(float x) {
      return 1/(1+pow((float)Math.E, -x));
    }
  }
}
