package es.cbgp.bio2rdf2sadi.main;

import java.io.File;
import java.io.FileInputStream;
import java.util.LinkedList;
import java.util.Properties;

import es.cbgp.bio2rdf2sadi.objects.Endpoint;
import es.cbgp.bio2rdf2sadi.ontstuff.OntologyCreation;
import es.cbgp.bio2rdf2sadi.ontstuff.SPARQLQueryEngine;

/**
 * Logic class. Execute the processes.
 * @author Alejandro Rodríguez González - Centre for Biotechnology and Plant Genomics
 *
 */
public class Logic {

	private LinkedList<Endpoint> endpoints;

	public void execute() throws Exception {
		/*
		 * Load available endpoints.
		 */
		loadEndpoints();
		for (int i = 0; i < endpoints.size(); i++) {
			/*
			 * For each endpoint, we query it's sparql endpoint and get the SPO patterns.
			 */
			SPARQLQueryEngine sqe = new SPARQLQueryEngine();
			System.out.println("Endpoint: " + endpoints.get(i).getName());
			sqe.executeQuery(endpoints.get(i));
			System.out.println("---------");
		}
		/*
		 * We delete previous existing files.
		 */
		deletePreviousOntologies();
		/*
		 * For each SPO endpoint we create the SPO patterns as files.
		 */
		for (int i = 0; i < endpoints.size(); i++) {
			System.out.println("Creating data for endpoint: " + endpoints.get(i).getName());
			OntologyCreation oc = new OntologyCreation(this.endpoints.get(i));
			oc.run();
		}
	}

	private void deletePreviousOntologies() throws Exception {
		boolean del = Boolean.parseBoolean(ConfigManager
				.getConfig(Constants.DELETE_ONTOLOGIES_ALREADY_CREATED));
		if (del) {
			File dirs[] = new File("ontologies").listFiles();
			for (int i = 0; i < dirs.length; i++) {
				File files[] = new File(dirs[i].toString()).listFiles();
				for (int j = 0; j < files.length; j++) {
					files[j].delete();
				}
				dirs[i].delete();
			}
		}

	}

	private void loadEndpoints() throws Exception {
		this.endpoints = new LinkedList<Endpoint>();
		File folder = new File("endpoints");
		File[] files = folder.listFiles();
		for (int i = 0; i < files.length; i++) {
			loadEndpoint(files[i]);
		}
	}

	private void loadEndpoint(File f) throws Exception {
		Properties prop = new Properties();
		prop.load(new FileInputStream(f));
		String name = prop.getProperty("NAME");
		String ep = prop.getProperty("ENDPOINT");
		String dataset = "http://bio2rdf.org/bio2rdf-" + name + "-statistics";
		this.endpoints.add(new Endpoint(ep, name, dataset));
	}

}
