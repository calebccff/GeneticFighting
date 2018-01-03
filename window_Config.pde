import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.util.Hashtable;


ConfigWindow config;

public class ConfigWindow extends JFrame{
	private final int WIDTH = 500;
	private final int HEIGHT = 850;
	private final int GAME_SIZE_SLIDER_TICKS = 5;

  private JButton buttonRun, buttonExit;
  private JSlider sliderGameSize;

	public ConfigWindow(){
		setTitle("Genetic Fighting Config");
		setSize(WIDTH, HEIGHT);
		setVisible(true);
		setDefaultCloseOperation(EXIT_ON_CLOSE);
    Container contentPane = getContentPane();
    contentPane.setLayout(new BoxLayout(this.getContentPane(), BoxLayout.Y_AXIS));
    contentPane.add(Box.createRigidArea(new Dimension(0, 40)));

    JPanel[] panes = new JPanel[4];
    for(int i = 0; i < panes.length; i++){
      panes[i] = new JPanel();
      panes[i].setLayout(new BoxLayout(panes[i], BoxLayout.LINE_AXIS));
    }


    buttonRun = new JButton("Run It!");
    buttonRun.addActionListener(new ButtonHandler(){
      public void actionPerformed(ActionEvent e){
				if(!running){
					fighters = new Fighter[GAME_SIZE*2];
					games = new Game[GAME_SIZE];
					for(int i = 0; i < GAME_SIZE; i++){ //Initialises all the games
				    fighters[i*2] = new Fighter(LEFT, i*2); //Use some existing methods to specify what side of the screen each fighter is on
				    fighters[i*2+1] = new Fighter(RIGHT, i*2+1);

				    games[i] = new Game(fighters[i*2], fighters[i*2+1]); //Creates a new game and passes REFERENCES to two fighters, allows the game AND main program to handle the fighters
				  }
					running = true;
	        loop();
				}
      }
    });

    buttonExit = new JButton("Exit");
    buttonExit.addActionListener(new ButtonHandler(){
      public void actionPerformed(ActionEvent e){
        dispose();
        System.exit(0);
      }
    });
    panes[0].add(buttonRun);
    panes[0].add(Box.createRigidArea(new Dimension(10, 0)));
    panes[0].add(buttonExit);

    sliderGameSize = new JSlider(JSlider.HORIZONTAL, 0, GAME_SIZE_MAX, 200);
    sliderGameSize.setMinorTickSpacing(50);
    sliderGameSize.setMajorTickSpacing(100);
    sliderGameSize.setPaintTicks(true);
    sliderGameSize.setSnapToTicks(true);

    ChangeListener sliderGameSizeListener = new ChangeListener() {
      public void stateChanged(ChangeEvent e) {
				if(!running){
	        int value = sliderGameSize.getValue();
	        GAME_SIZE = value>1?value:2;
				}
      }
    };
    sliderGameSize.addChangeListener(sliderGameSizeListener);

    Hashtable labelTable = new Hashtable();
    labelTable.put(new Integer(0), new JLabel("2"));
		int tickInterval = GAME_SIZE_MAX/GAME_SIZE_SLIDER_TICKS;
    for(int i = 1; i < GAME_SIZE_MAX/tickInterval; i++){
      labelTable.put(i*tickInterval, new JLabel(Integer.toString(i*tickInterval)));
    }
    labelTable.put(GAME_SIZE_MAX, new JLabel("Max"));

    sliderGameSize.setLabelTable(labelTable);
    sliderGameSize.setPaintLabels(true);

    panes[1].add(sliderGameSize);

    for(int i = 0; i < panes.length; i++){
      contentPane.add(panes[i]);
    }
	}

  private class ButtonHandler implements ActionListener{
		public void actionPerformed(ActionEvent e){}
	}

}

void makeConfigWindow(){
	 config = new ConfigWindow();

  config.setVisible(false);
  config.setVisible(true);
}
