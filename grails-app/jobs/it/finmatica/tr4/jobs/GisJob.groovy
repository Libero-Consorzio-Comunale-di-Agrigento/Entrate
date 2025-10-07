package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.tr4.webgis.IntegrazioneWEBGISService

import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class GisJob {

	private static Log log = LogFactory.getLog(GisJob)

	IntegrazioneWEBGISService integrazioneWEBGISService
	
	AfcElaborazioneService afcElaborazioneService

	static triggers = {
	}

	def group = "GisSyncronizeGroup"

	def description = "Sincronizzazione WebGIS"

	def concurrent = false

	def execute(context) {
		
		Map parametri = [:]

		log.info "******************************"
		log.info "Eseguo \'${description}\'";
///		log.info parametri								// Al momento non ci sono parametri
		log.info "******************************"
		
		String messaggio = ""
		try {
			messaggio = integrazioneWEBGISService.sincronizzaWebGIS()
		} 
		catch (Exception e) {
			e.printStackTrace()
			log.info "Errore in \'${description}\' : " + e.getMessage()
			throw e
		}
		finally {
			log.info "Completato Job \'${description}\' !"; 
		}
		afcElaborazioneService.addLogPerContext(context, messaggio)
	}
}
