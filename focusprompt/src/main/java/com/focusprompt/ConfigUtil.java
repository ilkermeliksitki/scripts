package com.focusprompt;

import java.util.Properties;
import java.io.InputStream;

public class ConfigUtil {

    private static Properties props = new Properties();

    static {
        InputStream input = null;
        try {
            input = ConfigUtil.class.getClassLoader().getResourceAsStream("config.properties");
            if (input == null) {
                System.err.println("Sorry, unable to find config.properties");
            }
            props.load(input);
        } catch(Exception e){
            e.printStackTrace();
        } finally {
            if (input != null) {
                try {
                    input.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }


    public static int getIntProperty(String key, int defaultValue) {
        try {
            return Integer.parseInt(props.getProperty(key));
        } catch(Exception e){
            return defaultValue;
        }
    }

    public static boolean getBooleanProperty(String key, boolean defaultValue) {
        try {
            return Boolean.parseBoolean(props.getProperty(key));
        } catch(Exception e){
            return defaultValue;
        }
    }
}
