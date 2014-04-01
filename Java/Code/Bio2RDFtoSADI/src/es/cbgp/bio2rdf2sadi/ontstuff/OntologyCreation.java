package es.cbgp.bio2rdf2sadi.ontstuff;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileWriter;

import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.AddAxiom;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.OWLClass;
import org.semanticweb.owlapi.model.OWLClassExpression;
import org.semanticweb.owlapi.model.OWLDataFactory;
import org.semanticweb.owlapi.model.OWLDeclarationAxiom;
import org.semanticweb.owlapi.model.OWLEquivalentClassesAxiom;
import org.semanticweb.owlapi.model.OWLObjectProperty;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;

import com.hp.hpl.jena.ontology.OntModel;
import com.hp.hpl.jena.rdf.model.ModelFactory;
import com.hp.hpl.jena.rdf.model.Resource;
import com.hp.hpl.jena.rdf.model.Statement;
import com.hp.hpl.jena.vocabulary.RDFS;

import es.cbgp.bio2rdf2sadi.main.ConfigManager;
import es.cbgp.bio2rdf2sadi.main.Constants;
import es.cbgp.bio2rdf2sadi.main.StaticUtils;
import es.cbgp.bio2rdf2sadi.objects.Endpoint;
import es.cbgp.bio2rdf2sadi.objects.ExtraSPOData;
import es.cbgp.bio2rdf2sadi.objects.SPO;

/**
 * Class to create the ontology, configuration and sparql files.
 * 
 * @author Alejandro Rodríguez González - Centre for Biotechnology and Plant Genomics
 * 
 */
public class OntologyCreation {

	private Endpoint endpoint;
	private OntModel ontModel;
	private OWLOntologyManager manager;
	private OWLOntology ontology;
	private String defaultIRI;
	private String sadiServiceOutputClass;
	private BufferedWriter configFile;

	/**
	 * Constructor receives the endpoint to proces.
	 * 
	 * @param ep
	 *            Endpoint
	 * @throws Exception
	 *             It can throw an exception.
	 */
	public OntologyCreation(Endpoint ep) throws Exception {
		this.defaultIRI = ConfigManager.getConfig(Constants.DEFAULT_IRI_BASE);
		this.sadiServiceOutputClass = ConfigManager
				.getConfig(Constants.SADI_SERVICE_OUTPUT_CLASS);
		this.endpoint = ep;
	}

	/**
	 * Run method extracts all the SPO patterns and create the files.
	 * 
	 * @throws Exception
	 *             It can throw an exception.
	 */
	public void run() throws Exception {
		for (int i = 0; i < this.endpoint.getSPOs().size(); i++) {
			SPO spo = this.endpoint.getSPOs().get(i);
			createOntology(spo);
		}
	}

	/**
	 * This method receives the SPO that is going to be processed.
	 * 
	 * @param spo
	 *            SPO object.
	 * @throws Exception
	 *             It can throw an exception.
	 */
	private void createOntology(SPO spo) throws Exception {
		System.out.println("SPO: " + spo.toString());
		this.ontModel = ModelFactory.createOntologyModel();
		String s, p, o = null;
		/*
		 * First, we try to get resource local name.
		 */
		s = getResourceLocalName(spo.getSubject());
		p = getResourceLocalName(spo.getPredicate());
		o = getResourceLocalName(spo.getObject());
		/*
		 * If we don't have a valid value for s, p or o.. we try to get it's
		 * label.
		 * 
		 * If we are going to use the label, we need the ExtraSPOData object for
		 * these values.
		 */
		ExtraSPOData esd = new ExtraSPOData();
		if (s != null) {
			if (s.equalsIgnoreCase("")) {
				System.out.println("Local name empty (subject): "
						+ spo.getSubject());
				s = getLabelFrom(spo.getSubject());
				if (!StaticUtils.isEmpty(s)) {
					esd.setNewSubject(s);
				} else {
					System.out.println("And.. without label!");
				}
			}
		}
		if (p != null) {
			if (p.equalsIgnoreCase("")) {
				System.out.println("Local name empty (predicate): "
						+ spo.getPredicate());
				p = getLabelFrom(spo.getPredicate());
				if (!StaticUtils.isEmpty(p)) {
					esd.setNewPredicate(p);
				} else {
					System.out.println("And.. without label!");
				}
			}
		}
		if (o != null) {
			if (o.equalsIgnoreCase("")) {
				System.out.println("Local name empty (object): "
						+ spo.getObject());
				o = getLabelFrom(spo.getObject());
				if (!StaticUtils.isEmpty(o)) {
					esd.setNewObject(o);
				} else {
					System.out.println("And.. without label!");
				}
			}
		}
		/*
		 * We create the string to save files subject_predicate_object
		 */
		String saveBasicFile = s + "_" + p + "_" + o;

		/*
		 * We check if already exists this file.
		 */
		boolean alreadyExists = checkSave(saveBasicFile);
		if (!alreadyExists) {
			/*
			 * If not exists..
			 */
			String saveNameOntology = saveBasicFile + ".owl";
			String saveNameSparqlQuery = saveBasicFile + ".sparql";
			String saveNameConfigFile = saveBasicFile + ".cfg";
			this.configFile = new BufferedWriter(new FileWriter("ontologies/"
					+ this.endpoint.getName() + "/" + saveNameConfigFile));
			/*
			 * We create the files.
			 */
			createOntology(saveNameOntology, spo, esd);
			createSPARQLQueryFile(saveNameSparqlQuery, spo);
			saveConfigFile(saveNameConfigFile);
		}
	}

	/**
	 * Method to get the local name of a resource.
	 * 
	 * @param uri
	 *            Receives the resource URI.
	 * @return Return the local name.
	 */
	private String getResourceLocalName(String uri) {
		this.ontModel = ModelFactory.createOntologyModel();
		try {
			this.ontModel.read(uri);
			Resource r = this.ontModel.getResource(uri);
			if (r != null) {
				return r.getLocalName();
			} else {
				return null;
			}
		} catch (Exception e) {
			System.err.println("Error loading resource (" + uri + "): "
					+ e.getMessage());
			return null;
		}
	}

	/**
	 * Method to get the label from a resource.
	 * @param r Receives the resource.
	 * @return Returns the label (removing attached information between brackets "name [cod]". Just "name").
	 */
	private String getLabelFrom(String r) {
		this.ontModel = ModelFactory.createOntologyModel();
		this.ontModel.read(r);
		Statement st = ontModel.getResource(r).getProperty(RDFS.label);
		if (st != null) {
			String lb = st.getObject().toString();
			String parts[] = lb.split(" ");
			String label = "";
			for (int i = 0; i < parts.length; i++) {
				if (parts[i].charAt(0) != '[') {
					label += parts[i] + " ";
				}
			}
			label = label.trim();
			label = label.replace(' ', '_');
			return label;
		}
		return "";
	}

	/**
	 * Method to save the configuration file.
	 * @param sncfg Receives the file.
	 * @throws Exception It can throws an exception.
	 */
	private void saveConfigFile(String sncfg) throws Exception {
		configFile.write(Constants.ORIGINAL_ENDPOINT + Constants.EQUALS
				+ this.endpoint.getEndpointURL());
		configFile.newLine();
		configFile.write(Constants.GENERIC_ENDPOINT + Constants.EQUALS
				+ Constants.HTTP + this.endpoint.getName()
				+ ConfigManager.getConfig(Constants.BIO2RDF_DEFAULT_EP));
		configFile.newLine();
		configFile.close();
	}

	/**
	 * Method to create the SPARQL query file.
	 * @param snsq Receives the file.
	 * @param spo Receives the SPO.
	 * @throws Exception It can throws an exception.
	 */
	private void createSPARQLQueryFile(String snsq, SPO spo) throws Exception {
		String query = "";
		Resource r = this.ontModel.getResource(spo.getPredicate());
		query += "PREFIX pre: <" + r.getNameSpace() + ">\n";
		query += "SELECT *\n";
		query += "WHERE {\n";
		query += "\t%VAR pre:" + r.getLocalName() + " ?obj.\n";
		query += "}\n";
		BufferedWriter bW = new BufferedWriter(new FileWriter("ontologies/"
				+ this.endpoint.getName() + "/" + snsq));
		bW.write(query);
		bW.close();
	}

	/**
	 * Method to create the ontology.
	 * @param sno Receives the file.
	 * @param spo Receives the SPO.
	 * @param esd Receives Extra SPO data (if necessary).
	 * @throws Exception It can throw an exception.
	 */
	private void createOntology(String sno, SPO spo, ExtraSPOData esd)
			throws Exception {
		this.manager = OWLManager.createOWLOntologyManager();
		this.ontology = manager.createOntology();
		OWLDataFactory factory = manager.getOWLDataFactory();
		IRI subjectClass = IRI.create(spo.getSubject());
		configFile.write(Constants.INPUTCLASS_URI + Constants.EQUALS
				+ subjectClass.toURI().toString());
		configFile.newLine();
		/*
		 * By default, the inputclassname is the fragment of subject class
		 * However, if in the creation of the ontology we found that the subject
		 * was empty in the getLocalName retrieved by Jena we got the label
		 * removing the part between brackets and this is the part that we are
		 * going to use here
		 */
		String inputClassName = subjectClass.getFragment();
		if (esd.haveNewSubject()) {
			inputClassName = esd.getNewSubject();
		}

		inputClassName = processToRemoveColonAndPrefix(inputClassName);
		configFile.write(Constants.INPUTCLASS_NAME + Constants.EQUALS
				+ inputClassName);
		configFile.newLine();
		IRI objectClass = IRI.create(spo.getObject());
		IRI sadiOutputClass = IRI.create(defaultIRI + this.endpoint.getName()
				+ "/" + sno + "#" + this.sadiServiceOutputClass);
		configFile.write(Constants.OUTPUTCLASS_NAME + Constants.EQUALS
				+ this.sadiServiceOutputClass);
		configFile.newLine();
		configFile.write(Constants.OUTPUTCLASS_URI + Constants.EQUALS
				+ sadiOutputClass.toURI().toString());
		configFile.newLine();
		IRI ontologyIRI = IRI.create(defaultIRI + sno);
		OWLClass subjectOWLClass = factory.getOWLClass(subjectClass);
		OWLClass objectOWLClass = factory.getOWLClass(objectClass);
		OWLClass sadiOutputOWLClass = factory.getOWLClass(sadiOutputClass);
		ontology = manager.createOntology(ontologyIRI);
		OWLDeclarationAxiom declarationAxiomSC = factory
				.getOWLDeclarationAxiom(subjectOWLClass);
		manager.addAxiom(ontology, declarationAxiomSC);
		OWLDeclarationAxiom declarationAxiomOC = factory
				.getOWLDeclarationAxiom(objectOWLClass);
		manager.addAxiom(ontology, declarationAxiomOC);
		OWLDeclarationAxiom declarationAxiomSOC = factory
				.getOWLDeclarationAxiom(sadiOutputOWLClass);
		manager.addAxiom(ontology, declarationAxiomSOC);
		IRI predicateIRI = IRI.create(spo.getPredicate());
		OWLObjectProperty predicate = factory
				.getOWLObjectProperty(predicateIRI);
		configFile.write(Constants.PREDICATE_NAME + Constants.EQUALS
				+ processToRemoveColonAndPrefix(predicateIRI.getFragment()));
		configFile.newLine();
		configFile.write(Constants.PREDICATE_URI + Constants.EQUALS
				+ predicateIRI.toURI().toString());
		configFile.newLine();
		OWLDeclarationAxiom declarationAxiomPred = factory
				.getOWLDeclarationAxiom(predicate);
		manager.addAxiom(ontology, declarationAxiomPred);

		OWLClassExpression predicateSomeObject = factory
				.getOWLObjectSomeValuesFrom(predicate, objectOWLClass);
		OWLClassExpression subjectAndPredicateSomeObject = factory
				.getOWLObjectIntersectionOf(subjectOWLClass,
						predicateSomeObject);

		OWLEquivalentClassesAxiom ax = factory.getOWLEquivalentClassesAxiom(
				subjectAndPredicateSomeObject, sadiOutputOWLClass);
		AddAxiom addAx = new AddAxiom(ontology, ax);
		manager.applyChange(addAx);

		manager.saveOntology(ontology, new FileOutputStream("ontologies/"
				+ this.endpoint.getName() + "/" + sno));
	}

	/**
	 * Method to remove colon and prefix from an URI.
	 * @param fragment Receives the URI.
	 * @return Returns the value.
	 */
	private String processToRemoveColonAndPrefix(String fragment) {
		if (fragment.contains(":")) {
			String parts[] = fragment.split(":");
			if (parts.length == 2) {
				return parts[1];
			}
		}
		return fragment;
	}

	/**
	 * Method to check if a file exists.
	 * @param s Receives the file.
	 * @return Returns a boolean.
	 */
	private boolean checkSave(String s) {
		File f = new File("ontologies/" + this.endpoint.getName() + "/");
		if (!f.exists()) {
			f.mkdir();
		}
		f = new File("ontologies/" + this.endpoint.getName() + "/" + s + ".owl");
		return f.exists();
	}
}
