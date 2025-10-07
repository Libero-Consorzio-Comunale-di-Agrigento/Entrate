package it.finmatica.tr4.jobs

import it.finmatica.tr4.datiesterni.anagrafetributaria.AllineamentoAnagrafeTributariaService
import it.finmatica.tr4.elaborazioni.*
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class AnagrafeTributariaOutputJob {

    private static Log log = LogFactory.getLog(AnagrafeTributariaOutputJob)

    ElaborazioniService elaborazioniService
    AllineamentoAnagrafeTributariaService allineamentoAnagrafeTributariaService

    static triggers = {}

    def group = "ElaborazioniMassiveGroup"

    def description = "Genera file output anagrafe tributaria"

    def concurrent = false

    def execute(context) {
        def nowElaborazione = System.currentTimeMillis()

        AttivitaElaborazione attivita = AttivitaElaborazione.get(context.mergedJobDataMap.get('attivita'))
        ElaborazioneMassiva elaborazione = attivita.elaborazione
        List<DettaglioElaborazione> dettagli = context.mergedJobDataMap.get('dettaglio') ?: elaborazioniService.listaDettagliDaElaborare(
                elaborazione,
                elaborazioniService.dettagliOrderBy
        )

        try {

            def cliente = context.mergedJobDataMap.get('cliente')

            def fileName = "${attivita.elaborazione.nomeElaborazione.replace("/", "-").replace("\\", "-")}_${attivita.id}.txt".replace(" ", "_").toUpperCase()
            def outputFolder = "${elaborazioniService.getDocFolder()}${File.separator}${attivita.id}${File.separator}"
            new File(outputFolder).mkdir()

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_IN_CORSO))

            log.info "Avvio job per attvita' ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti."

            new File("${outputFolder}${File.separator}${fileName}").text = allineamentoAnagrafeTributariaService.generateOutput(dettagli, attivita).text

            def attDoc = AttivitaElaborazioneDocumento.get(attivita.id)
            attDoc.documento = "URL:${outputFolder}${File.separator}${fileName}".getBytes("UTF-8")
            attDoc.save(failOnError: true, flush: true)

            log.info "Job per attvita' ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti conclusa."

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_COMPLETATA))

            def tempoElaborazione = ((System.currentTimeMillis() - nowElaborazione) as BigDecimal) / 1000
            log.info "Attivita' [${attivita.elaborazione.nomeElaborazione} - ${attivita.id}] eseguita in ${tempoElaborazione}s."
        } catch (Exception e) {
            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_ERRORE), e.message)
            e.printStackTrace()
        }

    }
}
