package es.cbgp.bio2rdf2sadi.ontstuff;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.LinkedList;

import com.hp.hpl.jena.query.*;
import com.hp.hpl.jena.rdf.model.Resource;

import es.cbgp.bio2rdf2sadi.objects.Endpoint;
import es.cbgp.bio2rdf2sadi.objects.SPO;

/**
 * Class to perform the SPARQL query.
 * @author Alejandro Rodríguez González - Centre for Biotechnology and Plant Genomics
 *
 */
public class SPARQLQueryEngine {

	private String sparqlFile = "sparql/query.sparql";

	/**
	 * Method to execute the query.
	 * @param ep Receives the endpoint.
	 * @throws Exception It can throw an exception.
	 */
	public void executeQuery(Endpoint ep) throws Exception {
		LinkedList<SPO> spos = new LinkedList<SPO>();
		String finalQuery = loadQueryFromFile(ep);
		String serviceEndpoint = ep.getEndpointURL();
		//System.out.println(finalQuery);
		Query query = null;
		QueryExecution qexec = null;
		try {
			query = QueryFactory.create(finalQuery);
			qexec = QueryExecutionFactory.sparqlService(serviceEndpoint, query);
			ResultSet results = qexec.execSelect();
			while (results.hasNext()) {
				QuerySolution qs = results.next();
				Resource sub = qs.getResource("?subjectType");
				Resource pred = qs.getResource("?aPred");
				Resource objc = qs.getResource("?objType");
				//System.out.println(sub.toString() + "," + pred.toString() + "," + objc.toString());
				spos.add(new SPO(sub.toString(), pred.toString(), objc
						.toString()));
			}
		} catch (Exception e) {
			System.err.println("[ERROR] Error querying endpoint '" + ep.getName() + "': " + e.getMessage());
		} finally {
			if (qexec != null) {
				qexec.close();
			}
		}
		System.out.println(spos.size() + " (s,p,o) patterns extracted.");
		ep.addSPOs(spos);
	}

	/**
	 * Method to load query from a file given an endpoint.
	 * @param ep Receives the endpoint.
	 * @return Returns the String with the final query.
	 * @throws Exception It can throw an exception.
	 */
	private String loadQueryFromFile(Endpoint ep) throws Exception {
		String query = "";
		BufferedReader bL = new BufferedReader(new FileReader(this.sparqlFile));
		while (bL.ready()) {
			String read = bL.readLine() + "\n";
			if (read.contains("FROM <@DATASET>")) {
				read = "FROM <" + ep.getDataset() + ">\n";
			}
			query += read;
		}
		bL.close();
		return query;
	}

	/**
	 * Method to set the query file.
	 * @param sparqlFile Receives the file.
	 */
	public void setQueryFile(String sparqlFile) {
		this.sparqlFile = sparqlFile;
	}
}
