package es.cbgp.bio2rdf2sadi.objects;

import java.util.LinkedList;

/**
 * Endpoint class
 * @author Alejandro Rodríguez González - Centre for Biotechnology and Plant Genomics
 *
 */
public class Endpoint {

	private String epURL;
	private String name;
	private String dataset;
	private LinkedList<SPO> spos;

	public Endpoint(String u, String n, String d) {
		this.epURL = u;
		this.name = n;
		this.dataset = d;
	}

	public LinkedList<SPO> getSPOs() {
		return this.spos;
	}

	public void setEndpointURL(String u) {
		this.epURL = u;
	}

	public String getEndpointURL() {
		return this.epURL;
	}

	public String getName() {
		return this.name;
	}

	public void setName(String n) {
		this.name = n;
	}

	public String getDataset() {
		return this.dataset;
	}

	public void setDataset(String d) {
		this.dataset = d;
	}

	public void addSPOs(LinkedList<SPO> s) {
		this.spos = s;

	}
}
