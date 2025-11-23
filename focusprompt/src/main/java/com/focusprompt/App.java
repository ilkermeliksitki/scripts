package com.focusprompt;

import com.formdev.flatlaf.FlatLightLaf;

public class App  {

    public static void main(String[] args) {
        // set a modern look with FlatLaf
        FlatLightLaf.setup();

        System.out.println("Focus Prompt is running. Press Ctrl+C to stop.");

        // initial wait
        int interval = IntervalManager.getIntervalSeconds();

        while (true) {
            try {
                Thread.sleep(interval * 1000L); // from milliseconds to seconds with *1000
                boolean snoozed = FocusUI.popUpWarning();
                
                if (snoozed) {
                    interval = ConfigUtil.getIntProperty("snooze.duration", 300);
                    if (ConfigUtil.getBooleanProperty("verbose", false)) {
                        System.out.println("Snoozed for " + interval + " seconds.");
                    }
                } else {
                    interval = IntervalManager.getIntervalSeconds();
                }

            } catch(Exception e){
                e.printStackTrace();
            }
        }
    }
}
