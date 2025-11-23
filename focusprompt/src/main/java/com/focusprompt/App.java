package com.focusprompt;

import javax.swing.JOptionPane;
import com.formdev.flatlaf.FlatLightLaf;

public class App  {

    // randomly get a number between 1800 and 3600 (30 minutes to 60 minutes)
    protected static int getIntervalSeconds() {
        int min = ConfigUtil.getIntProperty("interval.min", 1800);
        int max = ConfigUtil.getIntProperty("interval.max", 3600);

        if (ConfigUtil.getBooleanProperty("verbose", false)) {
            System.out.println("Interval range: " + min + " to " + max + " seconds.");
        }

        int seconds = min + (int)(Math.random() * ((max - min) + 1));
        if (ConfigUtil.getBooleanProperty("verbose", false)) {
            System.out.println("Next prompt in " + seconds + " seconds.");
        }
        return seconds;
    }

    private static void popUpWarning() {
        String message = ConfigUtil.getStringProperty("prompt.message", "Are you wandering off or doing the actionable task?");
        String header = ConfigUtil.getStringProperty("prompt.header", "Focus Check");

        JOptionPane.showMessageDialog(
            null,
            message,
            header,
            JOptionPane.WARNING_MESSAGE
        );
    }

    public static void main(String[] args) {
        // set a modern look with FlatLaf
        FlatLightLaf.setup();

        System.out.println("Focus Prompt is running. Press Ctrl+C to stop.");

        while (true) {
            try {
                int interval = getIntervalSeconds();
                Thread.sleep(interval * 1000); // from milliseconds to seconds with *1000
                popUpWarning();
            } catch(Exception e){
                e.printStackTrace();
            }
        }
    }
}
