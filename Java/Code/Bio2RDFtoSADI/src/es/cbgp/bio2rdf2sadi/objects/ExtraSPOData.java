package es.cbgp.bio2rdf2sadi.objects;

/**
 * Extra SPO Data.
 * @author Alejandro Rodríguez González - Centre for Biotechnology and Plant Genomics
 *
 */
public class ExtraSPOData {

	private boolean newSubject;
	private boolean newPredicate;
	private boolean newObject;

	private SPO spo;

	public ExtraSPOData() {
		this.newObject = false;
		this.newPredicate = false;
		this.newSubject = false;
		this.spo = new SPO(null, null, null);
	}

	public void setNewSubject(String s) {
		this.newSubject = true;
		this.spo.setSubject(s);
	}

	public void setNewPredicate(String p) {
		this.newPredicate = true;
		this.spo.setPredicate(p);
	}

	public void setNewObject(String o) {
		this.newObject = true;
		this.spo.setObject(o);
	}

	public boolean haveNewSubject() {
		return this.newSubject;
	}

	public boolean haveNewObject() {
		return this.newObject;
	}

	public boolean haveNewPredicate() {
		return this.newPredicate;
	}
	
	public String getNewSubject() {
		return this.spo.getSubject();
	}
	
	public String getNewPredicate() {
		return this.spo.getPredicate();
	}
	
	public String getNewObject() {
		return this.spo.getObject();
	}
}
