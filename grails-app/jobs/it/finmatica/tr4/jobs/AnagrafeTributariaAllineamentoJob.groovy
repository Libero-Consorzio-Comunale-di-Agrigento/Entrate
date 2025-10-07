package it.finmatica.tr4.jobs

import it.finmatica.tr4.datiesterni.anagrafetributaria.AllineamentoAnagrafeTributariaService
import it.finmatica.tr4.elaborazioni.*
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class AnagrafeTributariaAllineamentoJob {

	private static Log log = LogFactory.getLog(AnagrafeTributariaAllineamentoJob)

	ElaborazioniService elaborazioniService
	AllineamentoAnagrafeTributariaService allineamentoAnagrafeTributariaService

	static triggers = {}

	def group = "ElaborazioniMassiveGroup"

	def description = "Allineamento anagrafe tributaria"

	def concurrent = false

	def execute(context) {
		def nowElaborazione = System.currentTimeMillis()

		AttivitaElaborazione attivita = AttivitaElaborazione.get(context.mergedJobDataMap.get('attivita'))
		ElaborazioneMassiva elaborazione = attivita.elaborazione

		try {

			def cliente = context.mergedJobDataMap.get('cliente')

			elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_IN_CORSO))

			log.info "Avvio job per attvita' ${attivita.id} - ${attivita.tipoAttivita.descrizione}."

			allineamentoAnagrafeTributariaService.allineamentoAT(null, attivita)

			log.info "Job per attvita' ${attivita.id} - ${attivita.tipoAttivita.descrizione} conclusa."

			elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_COMPLETATA))

			def tempoElaborazione = ((System.currentTimeMillis() - nowElaborazione) as BigDecimal) / 1000
			log.info "Attivita' [${attivita.elaborazione.nomeElaborazione} - ${attivita.id}] eseguita in ${tempoElaborazione}s."
		}
		catch (Exception e) {
			elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_ERRORE), e.message)
			e.printStackTrace()
		}
	}
}
