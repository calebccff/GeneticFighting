# GeneticFighting
My computer science A level project - in which a genetic algorithm learns to fight!

### About
This is a project dedicated to utilising a genetcic algorithm in order to train neural networks how to fight each other in a simulation.
I WON'T be adding user vs computer functionality but if you feel like forking it and doing that yourself that would be awesome.

When the program starts you get a java JFrame window which (will) contains lots of configuration options in order to easily customise the simulation.

*For Example:*

You can adjust the number of consecutive games (more is generally better but it will run slower).

You can change the number of hidden layers (and the size) in the NN (could lead to an increase in FPS).

You can change how the fitness function works, to encourage specific attributes such as moving, shooting or slightly more complex things.

You can adjust various constants such as the time allowed for each game, mutation rate, the percentage of fighters to use to breed the next generation, and the min/max values for the synapses.

It will also be possible to adjust how the breed function works, for example is a fighters fitness affected by how it compares to it's parents etc.

### Bugs
As of yet, I have not discovered any game-breaking bugs so to speak, however some functionality may not work as you expect.
For example, on Linux it is possible to set the canvas size to -1 an essentially hide it, this is a very hacky method and I don't know if it works on Windows.
If you find any bugs and want to let me know it would be greatly appreciated.

## Details
I will list my full dissertation with this project when it is complete.
