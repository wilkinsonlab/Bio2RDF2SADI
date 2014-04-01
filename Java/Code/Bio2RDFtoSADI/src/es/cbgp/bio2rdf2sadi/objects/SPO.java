package es.cbgp.bio2rdf2sadi.objects;

/**
 * SPO
 * @author Alejandro Rodríguez González - Centre for Biotechnology and Plant Genomics
 *
 */
public class SPO {

	private String subject;
	private String predicate;
	private String object;

	public SPO(String s, String p, String o) {
		this.subject = s;
		this.predicate = p;
		this.object = o;
	}
	
	public String getSubject() {
		return subject;
	}

	
	public void setSubject(String subject) {
		this.subject = subject;
	}

	public String getPredicate() {
		return predicate;
	}

	public void setPredicate(String predicate) {
		this.predicate = predicate;
	}

	public String getObject() {
		return object;
	}

	public void setObject(String object) {
		this.object = object;
	}

	public String toString() {
		return "[ " + this.subject + ", " + this.predicate + ", " + this.object + " ]";
	}

}
