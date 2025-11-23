package com.focusprompt;

import javax.swing.JOptionPane;

public class FocusUI {

    public static boolean popUpWarning() {
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
}
