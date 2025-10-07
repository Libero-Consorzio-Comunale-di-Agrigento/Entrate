package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.afc.jobs.utility.AfcJobUtils
import it.finmatica.tr4.denunce.DenunceService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class VariazioneAutomaticheJob {

	private static Log log = LogFactory.getLog(VariazioneAutomaticheJob)

	AfcElaborazioneService afcElaborazioneService
	DenunceService denunceService

	static triggers = {}

	def group = "VariazioneAutomaticheJob"

	def description = "Variazioni Automatiche"

	def concurrent = false

	def execute(context) {

		log.info 'Inizio job Variazioni Automatiche'

		String utenteBatch = context.mergedJobDataMap.get('codiceUtenteBatch')

		String operazione = context.mergedJobDataMap.get('operazione')
		def parametri = context.mergedJobDataMap.get('parametri')
		parametri.codiceElaborazione = AfcJobUtils.getCodiceElaborazioneFromContext(context)

		log.info "Eseguo '${operazione}'"

		try {
			String message = ""
			def report = [
					retuls : 0,
					message: '',
			]

			switch (operazione) {
				case 'variazioneAutomatiche':
					report = denunceService.variazioneAutomatiche(parametri)
					break
				default:
					throw new Exception("VariazioneAutomaticheJob : Operazione sconosciuta (${operazione})")
			}
			if (report.result == 0) {
				message = "Operazione eseguita : ${report.message}"
			} else {
				message = "Errore durante l'operazione : ${report.message}"
			}

			afcElaborazioneService.addLogPerContext(context, message)
			log.info "${message}"

		} catch (Exception e) {
			afcElaborazioneService.addLogPerContext(context, e.message)
			e.printStackTrace()
			log.info "Errore durante l'operazione : " + e.getMessage()
			throw e
		}
	}
}
