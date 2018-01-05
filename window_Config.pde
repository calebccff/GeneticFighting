import javax.swing.*; //Lots
import java.awt.*; //And lots
import java.awt.event.*; //Of imports
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.util.Hashtable;


ConfigWindow config;

public class ConfigWindow extends JFrame{
	private final int WIDTH = 500; //Set window size, will become dependant on screen size at some point
	private final int HEIGHT = 850;
	private final int GAME_SIZE_SLIDER_TICKS = 5; //Number of ticks between each number in the game size slider

  private JButton buttonRun, buttonExit; //Init all the button and stuff
  private JSlider sliderGameSize;

	public ConfigWindow(){ //The constructer, initialises the window
		setTitle("Genetic Fighting Config"); //Set the title
		setSize(WIDTH, HEIGHT); //Set the size
		setVisible(true); //Make it visible?
		setDefaultCloseOperation(EXIT_ON_CLOSE); //Causes the program to exit when this window is closed
    Container contentPane = getContentPane(); //Get the window content pane to init the layout and stuff
    contentPane.setLayout(new BoxLayout(this.getContentPane(), BoxLayout.Y_AXIS)); //Set it to a box layout for boxy stuff
    contentPane.add(Box.createRigidArea(new Dimension(0, 25))); //Creates some blank space at the top so the buttons aren't too high up

    JPanel[] panes = new JPanel[4]; //Creates 4 horizontal panels
    for(int i = 0; i < panes.length; ++i){ //Init each panel
      panes[i] = new JPanel();
      panes[i].setLayout(new BoxLayout(panes[i], BoxLayout.LINE_AXIS));
    }


    buttonRun = new JButton("Run It!"); //The run button
    buttonRun.addActionListener(new ButtonHandler(){ //Add an event listener to call a function when an action is performed
      public void actionPerformed(ActionEvent e){
				if(!running){ //You can only click run when it's not running
					fighters = new Fighter[GAME_SIZE*2]; //Create all the fighters
					games = new Game[GAME_SIZE];
					for(int i = 0; i < GAME_SIZE; ++i){ //Initialises all the games
				    fighters[i*2] = new Fighter(LEFT, i*2); //Use some existing methods to specify what side of the screen each fighter is on
				    fighters[i*2+1] = new Fighter(RIGHT, i*2+1);

				    games[i] = new Game(fighters[i*2], fighters[i*2+1]); //Creates a new game and passes REFERENCES to two fighters, allows the game AND main program to handle the fighters
				  }
					running = true;
	        loop();
				}
      }
    });

    buttonExit = new JButton("Exit"); //Create the exit button
    buttonExit.addActionListener(new ButtonHandler(){ //Setup the event listener
      public void actionPerformed(ActionEvent e){
        dispose();
        System.exit(0);
      }
    });
    panes[0].add(buttonRun); //Add the buttons to the horizontal pane
    panes[0].add(Box.createRigidArea(new Dimension(10, 0)));
    panes[0].add(buttonExit);

    sliderGameSize = new JSlider(JSlider.HORIZONTAL, 0, GAME_SIZE_MAX, 200); //Create a slider for the game size
    sliderGameSize.setMinorTickSpacing(50); //Setup how the slider works
    sliderGameSize.setMajorTickSpacing(100);
    sliderGameSize.setPaintTicks(true);
    sliderGameSize.setSnapToTicks(true);

    ChangeListener sliderGameSizeListener = new ChangeListener() { //Creates a listener to detect when the slider is changed
      public void stateChanged(ChangeEvent e) {
				if(!running){
	        int value = sliderGameSize.getValue(); //Temporary variable, for readability
	        GAME_SIZE = value>1?value:2; //Can't have less than 2 games
				}
      }
    };
    sliderGameSize.addChangeListener(sliderGameSizeListener); //Add the listener to the slider

    Hashtable labelTable = new Hashtable(); //Hashtable to store the labels for the slider.
    labelTable.put(new Integer(0), new JLabel("2")); //The minimum
		int tickInterval = GAME_SIZE_MAX/GAME_SIZE_SLIDER_TICKS; //Number of ticks
    for(int i = 1; i < GAME_SIZE_MAX/tickInterval; i++){ //Add the numbers
      labelTable.put(i*tickInterval, new JLabel(Integer.toString(i*tickInterval)));
    }
    labelTable.put(GAME_SIZE_MAX, new JLabel("Max")); //Add the Max label

    sliderGameSize.setLabelTable(labelTable); //Make slider use the labels
    sliderGameSize.setPaintLabels(true); //Display the labels

    panes[1].add(sliderGameSize); //Add the slider to the first pane

    for(int i = 0; i < panes.length; i++){ //Add all the horizontal panes to the vertical pane
      contentPane.add(panes[i]);
    }
	}

  private class ButtonHandler implements ActionListener{ //To be overwritten
		public void actionPerformed(ActionEvent e){}
	}

}

void makeConfigWindow(){ //Function called in setup to create the config window
	 config = new ConfigWindow();

  config.setVisible(false); //Force the window to refresh, fixes a glitch
  config.setVisible(true);
}
