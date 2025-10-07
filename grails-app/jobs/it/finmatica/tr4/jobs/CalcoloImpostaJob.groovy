package it.finmatica.tr4.jobs

import it.finmatica.afc.jobs.AfcElaborazioneService
import it.finmatica.afc.jobs.utility.AfcJobUtils
import it.finmatica.tr4.imposte.ImposteService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class CalcoloImpostaJob {

    private static Log log = LogFactory.getLog(CalcoloImpostaJob)

    def grailsApplication
    ImposteService imposteService
    AfcElaborazioneService afcElaborazioneService

    static triggers = {}

    def group = "CalcoloImpostaGroup"

    def description = "Procedura di calcolo imposta"

    def concurrent = false

    def execute(context) {
        log.info 'Inizio job'
        log.info "Eseguo " + context.mergedJobDataMap.get('customDescrizioneJob')

        def anno = context.mergedJobDataMap.get('anno')
        String codFiscale = context.mergedJobDataMap.get('codiceFiscale')
        String tipoTributo = context.mergedJobDataMap.get('tipoTributo')
        String pFlagNormalizzato = context.mergedJobDataMap.get('pFlagNormalizzato')
        Integer pChkRate = context.mergedJobDataMap.get('pChkRate')
        Double pLimite = context.mergedJobDataMap.get('pLimite')
		Map paramAggiuntivi = context.mergedJobDataMap.get('pParametriAgg')

        String codiceElaborazione = AfcJobUtils.getCodiceElaborazioneFromContext(context)

        String messaggio = ""
        try {
            messaggio = imposteService.proceduraCalcolaImposta(anno, codFiscale, null, tipoTributo, pFlagNormalizzato, pChkRate, pLimite, null, codiceElaborazione, paramAggiuntivi)
            afcElaborazioneService.addLogPerContext(context, "Calcolo eseguito con successo")
        } catch (Exception e) {
            afcElaborazioneService.addLogPerContext(context, e.message)
            e.printStackTrace()
            log.info "Errore in calcolo imposta ${anno} " + e.getMessage()
            throw e
        }

    }

}
