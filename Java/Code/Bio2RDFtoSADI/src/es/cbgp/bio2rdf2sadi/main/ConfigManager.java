package es.cbgp.bio2rdf2sadi.main;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Properties;

/**
 * Configuration Manager.
 * @author Alejandro Rodríguez González - Centre for Biotechnology and Plant Genomics
 *
 */
public class ConfigManager {

	private static Properties config;
	private final static String CFG_FILE = "config/config.cfg";

	/**
	 * Method to create the instance.
	 * 
	 * @throws Exception
	 *             It can throw an exception.
	 */
	private static void createInstace() throws Exception {
		config = new Properties();
		config.load(new FileInputStream(CFG_FILE));
	}

	/**
	 * Method to obtain a configuration value.
	 * 
	 * @param key
	 *            Receives the key.
	 * @return Returns the value.
	 * @throws Exception
	 *             It can throw an exception.
	 */
	public static String getConfig(String key) throws Exception {
		if (config == null) {
			createInstace();
		}
		String ret = config.getProperty(key);
		if (ret == null) {
			ret = "";
		}
		return ret;
	}

	/**
	 * Method to obtain configuration from a file.
	 * 
	 * @param key
	 *            Receives the key.
	 * @param file
	 *            Receives the file.
	 * @return Return the result.
	 * @throws Exception
	 *             It can throw an exception.
	 */
	public static String getConfig(String key, File file) throws Exception {
		Properties tmpProp = new Properties();
		tmpProp.load(new FileInputStream(file));
		String ret = tmpProp.getProperty(key);
		if (ret == null) {
			ret = "";
		}
		return ret;
	}

	/**
	 * Method to set a configuration value.
	 * 
	 * @param key
	 *            Receives the key.
	 * @param value
	 *            Receives the value.
	 * @throws Exception
	 *             It can throw an exception.
	 */
	public static void setConfig(String key, String value) throws Exception {
		if (config == null) {
			createInstace();
		}
		config.setProperty(key, value);
		config.store(new FileOutputStream(CFG_FILE), "");
	}

	/**
	 * Method to establish a configuration on other file.
	 * 
	 * @param key
	 *            Receives the key.
	 * @param value
	 *            Receives the value.
	 * @param file
	 *            Receives the file.
	 * @throws Exception
	 *             It can throw an exception.
	 */
	public static void setConfig(String key, String value, File file)
			throws Exception {
		Properties tmpProp = new Properties();
		tmpProp.load(new FileInputStream(file));
		tmpProp.setProperty(key, value);
		tmpProp.store(new FileOutputStream(file), "");
	}
}
