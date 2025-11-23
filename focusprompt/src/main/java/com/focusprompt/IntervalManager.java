package com.focusprompt;

public class IntervalManager {

    // randomly get a number between configured min and max
    public static int getIntervalSeconds() {
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
}
