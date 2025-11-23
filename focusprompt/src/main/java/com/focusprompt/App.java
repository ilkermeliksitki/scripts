package com.focusprompt;

import javax.swing.JOptionPane;
import com.formdev.flatlaf.FlatLightLaf;

public class App  {

    // randomly get a number between 1800 and 3600 (30 minutes to 60 minutes)
    protected static int getIntervalSeconds() {
        double random = Math.random();
        int seconds = (int) (1800 + (random * 1800));
        //seconds = 1; // for testing purposes, set to 1 second
        return seconds;
    }

    private static void popUpWarning() {
        JOptionPane.showMessageDialog(
            null,
            "Are you wandering off or doing the actionable task?",
            "Focus Check",
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
