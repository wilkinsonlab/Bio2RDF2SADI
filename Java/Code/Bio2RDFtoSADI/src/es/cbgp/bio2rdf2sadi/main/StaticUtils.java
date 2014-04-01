package es.cbgp.bio2rdf2sadi.main;


/**
 * Static Utils
 * 
 * @author Alejandro Rodríguez González - Centre for Biotechnology and Plant Genomics
 * 
 */
public class StaticUtils {


	/**
	 * Method to check if the string is empty ("" or null)
	 * 
	 * @param str
	 *            Receives the string.
	 * @return Returns a boolean.
	 */
	public static boolean isEmpty(String str) {
		return ((str == null) || (str.trim().equals("")));
	}


}