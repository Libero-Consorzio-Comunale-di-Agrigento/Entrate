package it.finmatica.tr4.jobs

import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.elaborazioni.AttivitaElaborazione
import it.finmatica.tr4.elaborazioni.ElaborazioneMassiva
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.elaborazioni.StatoAttivita
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class ElaborazioneAvvisiAgidJob {

    private static Log log = LogFactory.getLog(ElaborazioneAvvisiAgidJob)

    ElaborazioniService elaborazioniService
    IntegrazioneDePagService integrazioneDePagService

    static triggers = {}

    def group = "ElaborazioniMassiveGroup"

    def description = "Avvisi AGID"

    def concurrent = false

    def execute(context) {

        def nowElaborazione = System.currentTimeMillis()

        AttivitaElaborazione attivita = AttivitaElaborazione.get(context.mergedJobDataMap.get('attivita'))
        ElaborazioneMassiva elaborazione = attivita.elaborazione

        def dettagli = elaborazioniService.listaDettagliDaElaborare(
                elaborazione,
                elaborazioniService.dettagliOrderBy
        )

        String tipoTributo = elaborazione.tipoTributo.tipoTributo
		String gruppoTributo = elaborazione.gruppoTributo
        Long praticaId = 0
        Short anno = elaborazione.anno

        try {

            def ruolo = (elaborazione.ruolo > 0) ? Ruolo.get(elaborazione.ruolo) : null

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_IN_CORSO))

            log.info "Avvio job per attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti."

            log.info "Generazione e concatenamento Avviso Agid..."

            dettagli.each {

                String codFiscale = it.contribuente.codFiscale

                // Si devono generare gli avvisi per il numero di rate
                if (ruolo != null) {
                    elaborazioniService.allegaAvvisoAgidRuolo(it, attivita.id, ruolo.id, codFiscale)
                } else if (it.pratica?.id) {
                    elaborazioniService.allegaAvvisoAgidPratica(it, attivita.id, it.pratica?.id)
                } else {
                    elaborazioniService.allegaAvvisoAgidImposta(it, attivita.id, codFiscale, anno, tipoTributo, gruppoTributo)
                }
            }
            log.info "Generazione e concatenamento Avviso Agid conclusa."

            log.info "Job per attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti conclusa."

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_COMPLETATA))

            def tempoElaborazione = ((System.currentTimeMillis() - nowElaborazione) as BigDecimal) / 1000

            log.info "Attività [${attivita.elaborazione.nomeElaborazione} - ${attivita.id}] eseguita in ${tempoElaborazione}s."
        } catch (Exception e) {
            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_ERRORE),
                    e.message ?: e.cause?.message)
            e.printStackTrace()
        }
    }
}
