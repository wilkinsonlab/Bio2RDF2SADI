package es.cbgp.bio2rdf2sadi.main;

/**
 * Main class.
 * @author Alejandro Rodríguez González - Centre for Biotechnology and Plant Genomics
 *
 */
public class Main {

	public Main() throws Exception {
		Logic lo = new Logic();
		lo.execute();
	}

	public static void main(String[] args) {
		try {
			new Main();
		} catch (Exception e) {
			System.err.println("Error: " + e.getMessage());
		}
	}

}
