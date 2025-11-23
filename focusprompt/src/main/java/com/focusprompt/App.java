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

    private static boolean popUpWarning() {
        String message = ConfigUtil.getStringProperty("prompt.message", "Are you wandering off or doing the actionable task?");
        String header = ConfigUtil.getStringProperty("prompt.header", "Focus Check");

        Object[] options = {"I'm Focused", "Snooze"};
        int n = JOptionPane.showOptionDialog(
            null,
            message,
            header,
            JOptionPane.YES_NO_OPTION,
            JOptionPane.WARNING_MESSAGE,
            null,
            options,
            options[0]
        );

        return n == 1; // 1 is the index of "Snooze"
    }

    public static void main(String[] args) {
        // set a modern look with FlatLaf
        FlatLightLaf.setup();

        System.out.println("Focus Prompt is running. Press Ctrl+C to stop.");

        // initial wait
        int interval = getIntervalSeconds();

        while (true) {
            try {
                Thread.sleep(interval * 1000L); // from milliseconds to seconds with *1000
                boolean snoozed = popUpWarning();
                
                if (snoozed) {
                    interval = ConfigUtil.getIntProperty("snooze.duration", 300);
                    if (ConfigUtil.getBooleanProperty("verbose", false)) {
                        System.out.println("Snoozed for " + interval + " seconds.");
                    }
                } else {
                    interval = getIntervalSeconds();
                }

            } catch(Exception e){
                e.printStackTrace();
            }
        }
    }
}
