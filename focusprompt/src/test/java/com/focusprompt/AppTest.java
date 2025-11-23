package com.focusprompt;

import junit.framework.TestCase;

public class AppTest extends TestCase
{
    public void testIntervalSecondsInRange() {
        // repeat multiple times to catch any random failures
        for (int i = 0; i < 100; i++) {
            int seconds = App.getIntervalSeconds();

            // default range is 1800 to 3600 seconds
            assertTrue("Interval should be >= 1800 seconds", seconds >= 1800);
            assertTrue("Interval should be <= 3600 seconds", seconds <= 3600);
        }
    }
}
