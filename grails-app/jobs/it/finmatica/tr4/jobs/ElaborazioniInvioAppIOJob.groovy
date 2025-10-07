package it.finmatica.tr4.jobs

import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.DocumentoContribuente
import it.finmatica.tr4.comunicazioni.ComunicazioniService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.elaborazioni.AttivitaElaborazione
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.elaborazioni.StatoAttivita
import it.finmatica.tr4.email.MessaggisticaService
import messaggistica.Messaggio
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class ElaborazioniInvioAppIOJob {

    private static Log log = LogFactory.getLog(ElaborazioniInvioAppIOJob)

    ElaborazioniService elaborazioniService
    MessaggisticaService messaggisticaService
    ContribuentiService contribuentiService
    ComunicazioniService comunicazioniService

    static triggers = {}

    def group = "ElaborazioniMassiveGroup"

    def description = "Invio AppIO"

    def concurrent = false


    def execute(context) {

        def nowElaborazione = System.currentTimeMillis()

        AttivitaElaborazione attivita = AttivitaElaborazione.get(context.mergedJobDataMap.get('attivita'))
        def dettagli = elaborazioniService.listaDettagliDaElaborare(
                attivita.elaborazione,
                elaborazioniService.dettagliOrderBy
        )

        try {

            def msg =
                    [tipo                   : "AIO",
                     mittente               : null,
                     destinatario           : null,
                     copiaConoscenza        : null,
                     copiaConoscenzaNascosta: null,
                     oggetto                : null,
                     testo                  : null,
                     allegati               : []]

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_IN_CORSO))

            log.info "Avvio job per attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti."

            def jsonSlurper = new JsonSlurper()
            def invioAppIo = jsonSlurper.parseText(attivita.testoAppio)
            def messaggioTemplate = invioAppIo.messaggio
            def comunicazioneTesto = invioAppIo.comunicazioneTesto
            def tipoTributoComunicazione = invioAppIo.tipoTributo
            def tipoComunicazione = invioAppIo.tipoComunicazione
            def tag = invioAppIo.tag
            def tipoComunicazionePnd = invioAppIo.tipoComunicazionePnd

            def msgId = null

            dettagli.each {
                try {
                    def msgAppIO = messaggisticaService.generaMessaggio(
                            Messaggio.TIPO.APP_IO,
                            comunicazioneTesto,
                            it.contribuente.codFiscale,
                            it.elaborazione.anno,
                            it.pratica?.id,
                            it.elaborazione.ruolo
                    )

                    msg.oggetto = messaggioTemplate?.oggetto?.trim() ?: msgAppIO.oggetto
                    msg.testo = msgAppIO.testo

                    def tipologia = ''
                    if ( it.elaborazione.ruolo) {
                      tipologia = 'S'
                    } else if (it.pratica?.id) {
                        tipologia = it.pratica?.tipoPratica == 'S' ? 'T' : 'P'
                    }

                    msgId = messaggisticaService.inviaAppIO(
                            it.contribuente.codFiscale,
                            msg.oggetto,
                            msg.testo,
                            tag,
                            tipoComunicazionePnd,
                            comunicazioniService.generaParametriSmartPND(it.contribuente.codFiscale,
                                    it.elaborazione.anno,
                                    it.pratica?.id ?: it.elaborazione.ruolo,
                                    invioAppIo.tipoTributo,
                                    tipologia)
                    )


                    log.info "Salvataggio in documenti_contribuente"
                    def dc = new DocumentoContribuente(
                            titolo: "Messaggio inviato ad AppIO per ${it.contribuente.codFiscale}",
                            contribuente: Contribuente.findByCodFiscale(it.contribuente.codFiscale),
                            documento: messaggisticaService.zip(JsonOutput.toJson(msg)),
                            idMessaggio: msgId,
                            note: messaggioTemplate.note
                    )

                    contribuentiService.caricaDocumento(dc)

                    it.note = null
                } catch (Exception e) {
                    it.note = e.message
                    e.printStackTrace()
                    log.error(e)
                } finally {
                    it.appioId = attivita.id
                    it.save(failOnError: true, flush: true)
                }
            }

            log.info "Job per attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti conclusa."

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_COMPLETATA))

            def tempoElaborazione = ((System.currentTimeMillis() - nowElaborazione) as BigDecimal) / 1000
            log.info "Attività [${attivita.elaborazione.nomeElaborazione} - ${attivita.id}] eseguita in ${tempoElaborazione}s."
        } catch (Exception e) {
            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_ERRORE), e.message)
            e.printStackTrace()
        }
    }
}
