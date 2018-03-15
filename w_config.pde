import javax.swing.*; //Lots
import java.awt.*; //And lots
import java.awt.event.*; //Of imports
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.util.Hashtable;
import java.text.NumberFormat;
import javax.swing.text.NumberFormatter;


ConfigWindow config;

public class ConfigWindow extends JFrame {
  private final int WIDTH = 500; //Set window size, will become dependant on screen size at some point
  private final int HEIGHT = 850;

  private JButton buttonRun, buttonExit; //Init all the button and stuff //PANE 0

  private JFormattedTextField textGameSize;                              //PANE 1
  private NumberFormat format = NumberFormat.getInstance();
  private NumberFormatter formatter = new NumberFormatter(format);
  private JLabel labelGameSize;
  
  private JLabel labelBreedInfo;

  public ConfigWindow() { //The constructer, initialises the window
    setTitle("Genetic Fighting Config"); //Set the title
    setSize(WIDTH, HEIGHT); //Set the size
    setVisible(true); //Make it visible?
    setDefaultCloseOperation(EXIT_ON_CLOSE); //Causes the program to exit when this window is closed
    Container contentPane = getContentPane(); //Get the window content pane to init the layout and stuff
    contentPane.setLayout(new BoxLayout(this.getContentPane(), BoxLayout.Y_AXIS)); //Set it to a box layout for boxy stuff
    contentPane.add(Box.createRigidArea(new Dimension(0, 25))); //Creates some blank space at the top so the buttons aren't too high up

    JPanel[] panes = new JPanel[4]; //Creates 4 horizontal panels
    for (int i = 0; i < panes.length; ++i) { //Init each panel
      panes[i] = new JPanel();
      panes[i].setLayout(new BoxLayout(panes[i], BoxLayout.LINE_AXIS));
    }

    //PANE 0
    buttonRun = new JButton("Run It!"); //The run button
    buttonRun.addActionListener(new ButtonHandler() { //Add an event listener to call a function when an action is performed
      public void actionPerformed(ActionEvent e) {
        try {
          GAME_SIZE = Integer.parseInt(textGameSize.getText().replaceAll(",", ""));
        }
        catch(NumberFormatException exc) {
          exc.printStackTrace();
          GAME_SIZE = GAME_SIZE_MIN;
        }
        if (GAME_SIZE < GAME_SIZE_MIN) GAME_SIZE = GAME_SIZE_MIN;
        fighters = new Fighter[GAME_SIZE*2]; //Create all the fighters
        games = new Game[GAME_SIZE];
        for (int i = 0; i < GAME_SIZE; ++i) { //Initialises all the games
          fighters[i*2] = new Fighter(LEFT, i*2); //Use some existing methods to specify what side of the screen each fighter is on
          fighters[i*2+1] = new Fighter(RIGHT, i*2+1);

          games[i] = new Game(fighters[i*2], fighters[i*2+1]); //Creates a new game and passes REFERENCES to two fighters, allows the game AND main program to handle the fighters
        }
        running = true; //legacy
        setVisible(false);
        surface.setLocation(displayWidth-round(displayWidth*0.68), 10); //Reset some properties, unhide the sketch
        surface.setSize(round(displayWidth*0.68), displayHeight-48);
        loop(); //Start the animation thread
      }
    }
    );

    buttonExit = new JButton("Exit"); //Create the exit button
    buttonExit.addActionListener(new ButtonHandler() { //Setup the event listener
      public void actionPerformed(ActionEvent e) {
        dispose();
        System.exit(0);
      }
    }
    );
    panes[0].add(buttonRun); //Add the buttons to the horizontal pane
    panes[0].add(Box.createRigidArea(new Dimension(10, 0)));
    panes[0].add(buttonExit);

    //PANE 1

    labelGameSize = new JLabel("Number of games ("+String.valueOf(GAME_SIZE_MIN)+"-"+String.valueOf(GAME_SIZE_MAX)+")");

    formatter.setValueClass(Integer.class);
    formatter.setMinimum(1);
    formatter.setMaximum(10000);
    formatter.setAllowsInvalid(false);

    textGameSize = new JFormattedTextField(formatter);
    textGameSize.setColumns(5);

    panes[1].add(labelGameSize);
    textGameSize.setAlignmentX(Component.CENTER_ALIGNMENT);
    panes[1].add(textGameSize); //Add the slider to the first pane
    panes[1].add(Box.createRigidArea(new Dimension(200, 0)));
  
  
    //PANE 2
    labelBreedInfo = new JLabel();
    labelBreedInfo.setText(stringBreedInfo);
    
    
    panes[2].add(labelBreedInfo);
  
    for (int i = 0; i < panes.length; i++) { //Add all the horizontal panes to the vertical pane
      contentPane.add(panes[i]);
    }
    contentPane.add(Box.createRigidArea(new Dimension(0, 20000)));
  }
  
  

  private class ButtonHandler implements ActionListener { //To be overwritten
    public void actionPerformed(ActionEvent e) {
    }
  }
}

void makeConfigWindow() { //Function called by setup to create the config window
  config = new ConfigWindow();
  config.setResizable(false);

  config.setVisible(false); //Force the window to refresh, fixes a glitch
  config.setVisible(true);
}