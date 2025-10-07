package it.finmatica.datiesterni.beans

import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;

import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.datiesterni.ImportaService

class ImportCatastoCensuario {
	
	private static final Logger log = Logger.getLogger(ImportCatastoCensuario.class)
	
	ImportaService importaService
	
	def sessionFactory
	def propertyInstanceMap = org.codehaus.groovy.grails.plugins.DomainClassGrailsPlugin.PROPERTY_INSTANCE_MAP
	
	def cleanUpGorm() {
		def session = sessionFactory.currentSession
		session.flush()
		session.clear()
		propertyInstanceMap.get().clear()
	}
	
	String importaFabbricati(def parametri) {
		long idDocumento = parametri.idDocumento
		DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)
		try {
			int i = 0
			InputStream filefab = new ByteArrayInputStream(doc.contenuto)
			filefab.eachLine { line ->
				int fieldCount = StringUtils.countMatches(line, "|")+1
				def tokens = line.split('\\|')
				tokens += ['']*(fieldCount-tokens.size())
				importaService.importaFabbricato(tokens, parametri)
				if (++i % 100 == 0) cleanUpGorm()
			}

			doc.stato = 2
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)
			return "file " + doc.nomeDocumento + " importato con successo"
		} catch (Throwable e) {
			log.error("Errore in importazione fabbricati catasto " + e.getMessage())
			doc.stato = 4
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)
			throw e;
		}
	}

	String importaSoggetti(def parametri) {
		long idDocumento = parametri.idDocumento
		DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)
		try {
			InputStream filesog = new ByteArrayInputStream(doc.contenuto)
			
			filesog.eachLine { line ->
				int fieldCount = StringUtils.countMatches(line, "|")
				def tokens = line.split('\\|')
				tokens += ['']*(fieldCount-tokens.size())
				importaService.importaSoggetto(tokens, parametri)
			}

			doc.stato = 2
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)
			return "file " + doc.nomeDocumento + " importato con successo"
		} catch (Throwable e) {
			log.error("Errore in importazione soggetti catasto " + e.getMessage())
			doc.stato = 4
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)
			throw e;
		}
	}

	String importaTerreni(def parametri) {
		long idDocumento = parametri.idDocumento
		DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)

		try {
			InputStream fileter = new ByteArrayInputStream(doc.contenuto)

			fileter.eachLine { line ->
				int fieldCount = StringUtils.countMatches(line, "|")
				def tokens = line.split('\\|')
				tokens += ['']*(fieldCount-tokens.size())
				importaService.importaTerreno(tokens, parametri)
			}
			doc.stato = 2
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)

			return "file " + doc.nomeDocumento + " importato con successo"
		} catch (Throwable e) {
			log.error("Errore in importazione terreni catasto " + e.getMessage())
			doc.stato = 4
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)
			throw e;
		}
	}

	String importaTitolarita(def parametri) {
		long idDocumento = parametri.idDocumento
		DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)

		try {
			InputStream filetit = new ByteArrayInputStream(doc.contenuto)

			filetit.eachLine { line ->
				int fieldCount = StringUtils.countMatches(line, "|")
				def tokens = line.split('\\|')
				tokens += ['']*(fieldCount-tokens.size())
				importaService.importaTitolarita(tokens, parametri)
			}
			doc.stato = 2
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)

			return "file " + doc.nomeDocumento + " importato con successo"
		} catch (Throwable e) {
			log.error("Errore in importazione titolarità catasto " + e.getMessage())
			doc.stato = 4
			doc.utente = parametri.utente.getDomainObject()
			doc.save(flush: true, failOnError: true)
			throw e
		}
	}
}
