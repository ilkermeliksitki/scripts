package com.focusprompt;

import junit.framework.TestCase;

public class AppTest extends TestCase
{
    public void testMinIntervalPositive() {
        int min = ConfigUtil.getIntProperty("interval.min", 1800);
        assertTrue("Minimum interval should be positive", min > 0);
    }

    public void testMaxIntervalGreaterThanMin() {
        int min = ConfigUtil.getIntProperty("interval.min", 1800);
        int max = ConfigUtil.getIntProperty("interval.max", 3600);
        assertTrue("Maximum interval should be greater than minimum interval", max > min);
    }

    public void testVerboseProperty() {
        boolean verbose = ConfigUtil.getBooleanProperty("verbose", false);
        // just check that the property can be retrieved without error
        assertNotNull("Verbose property should not be null", verbose);
    }

    public void testIntervalSecondsInRange() {
        int min = ConfigUtil.getIntProperty("interval.min", 1800);
        int max = ConfigUtil.getIntProperty("interval.max", 3600);
        // repeat multiple times to catch any random failures
        for (int i = 0; i < 100; i++) {
            int seconds = IntervalManager.getIntervalSeconds();

            // default range is 1800 to 3600 seconds
            assertTrue("Interval should be >= " + min + " seconds", seconds >= min);
            assertTrue("Interval should be <= " + max + " seconds", seconds <= max);
        }
    }
}
