package it.finmatica.tr4.jobs

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.documentale.DocumentaleService
import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import it.finmatica.tr4.elaborazioni.*
import it.finmatica.tr4.email.MessaggisticaService
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.smartpnd.SmartPndService
import messaggistica.Messaggio
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class ElaborazioniInvioADocumentaleJob {

    private static Log log = LogFactory.getLog(ElaborazioniInvioADocumentaleJob)

    ElaborazioniService elaborazioniService
    DocumentaleService documentaleService
    ModelliService modelliService
    ContribuentiService contribuentiService
    MessaggisticaService messaggisticaService
    SmartPndService smartPndService
    CommonService commonService

    static triggers = {}

    def group = "ElaborazioniMassiveGroup"

    def description = "Invio a documentale"

    def concurrent = false

    def execute(context) {

        AttivitaElaborazione attivita = AttivitaElaborazione.get(context.mergedJobDataMap.get('attivita'))
        def tipoComunicazione = context.mergedJobDataMap.get('tipoComunicazione')

        try {
            def nowElaborazione = System.currentTimeMillis()

            ElaborazioneMassiva elaborazione = attivita.elaborazione
            def dettagli = elaborazioniService.listaDettagliDaElaborare(
                    elaborazione,
                    elaborazioniService.dettagliOrderBy
            )

            // Nel caso di pratiche A o L
            if (dettagli[0].pratica && dettagli[0].pratica.tipoPratica in ['A', 'L']) {
                // Si crea una lista costituita da liste di dettagli di eredi o dettagli di contribuenti nond eceduti
                dettagli = dettagli.groupBy { it.pratica }.values().collect { it.any { it.eredeSoggetto != null } ? it : it[0] }
            }


            // TODO: fix temporanea relativa a #71152#note-82
            if (smartPndService.smartPNDAbilitato() && dettagli.any { it instanceof Collection } && smartPndService.tassonomiaConPagamento(tipoComunicazione.codiceTassonomia)) {
                throw new Exception("La modalità eredi non è supportata per codici tassonomici con pagamento")
            }

            if (!smartPndService.smartPNDAbilitato() && dettagli.any { it instanceof Collection }) {
                throw new Exception("Invio al documentale non consentito in modalità eredi")
            }

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_IN_CORSO))

            log.info "Avvio job per attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti."

            dettagli.each { dett ->
                try {
                    elaboraDettaglio(context, attivita, dett)
                } catch (Exception ex) {
                    log.error("Errore in job per l'attività [${attivita.id}], contribuente [${dett.contribuente.codFiscale}] ", ex)
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

    private void elaboraDettaglio(def context, def attivita, def dettaglio) {

        def gestioneEredi = dettaglio instanceof Collection

        def notifica = context.mergedJobDataMap.get('notifica')
        def tipoComunicazione = context.mergedJobDataMap.get('tipoComunicazione')
        def dettaglioCorrente = gestioneEredi ? null : dettaglio

        try {

            def allegati = context.mergedJobDataMap.get('allegati')?.collect {
                [
                        nomeFile : it.nome,
                        documento: it.contenuto
                ]
            } ?: []

            if (notifica?.tipoNotifica in [
                    SmartPndService.TipoNotifica.EMAIL,
                    SmartPndService.TipoNotifica.PEC,
                    SmartPndService.TipoNotifica.NONE
            ]) {
                if (!gestioneEredi) {
                    inviaDocumenti([
                            context     : context,
                            elaborazione: dettaglioCorrente.elaborazione,
                            dettaglio   : dettaglioCorrente,
                            documenti   : [
                                    [
                                            nomeFile  : dettaglioCorrente.nomeFile,
                                            documento : DettaglioElaborazioneDocumento.get(dettaglioCorrente.id).documento,
                                            principale: true
                                    ],
                                    *allegati
                            ]
                    ])
                    dettaglioCorrente.note = null
                    dettaglioCorrente.documentaleId = attivita.id
                    dettaglioCorrente.save(failOnError: true, flush: true)
                } else {

                    dettaglio.each {
                        try {
                            dettaglioCorrente = it
                            inviaDocumenti([
                                    context     : context,
                                    erede       : it.eredeSoggetto.soggettoErede,
                                    elaborazione: dettaglioCorrente.elaborazione,
                                    dettaglio   : dettaglioCorrente,
                                    documenti   : [
                                            [
                                                    nomeFile  : dettaglioCorrente.nomeFile,
                                                    documento : DettaglioElaborazioneDocumento.get(dettaglioCorrente.id).documento,
                                                    principale: true
                                            ],
                                            *allegati
                                    ]
                            ])

                            dettaglioCorrente.note = null
                            dettaglioCorrente.documentaleId = attivita.id
                            dettaglioCorrente.save(failOnError: true, flush: true)
                        } catch (Exception ex) {
                            dettaglioCorrente.note = ex.message ?: ex.cause.message
                            dettaglioCorrente.save(failOnError: true, flush: true)
                            ex.printStackTrace()
                        }
                    }
                }
            } else if (notifica?.tipoNotifica == SmartPndService.TipoNotifica.PND) {

                def tassonomiaConPagamento = smartPndService.tassonomiaConPagamento(tipoComunicazione.codiceTassonomia)

                def fileName = ""
                if (gestioneEredi) {
                    fileName = dettaglio[0].nomeFile.replace("E1_", "")
                } else {
                    fileName = dettaglio.nomeFile
                }

                def contenutoPrincipale =
                        modelliService.separaAttoAvviso(DettaglioElaborazioneDocumento.get(gestioneEredi ? dettaglio[0].id : dettaglio.id).documento)

                if (contenutoPrincipale.avvisoAgid == null && tassonomiaConPagamento) {
                    throw new Exception("Non è stata eseguita attività ACQUISISCI AVVISO AgID")
                }

                def contenuto = contenutoPrincipale.stampa

                def documenti = [
                        [
                                nomeFile  : fileName,
                                documento : contenuto,
                                principale: true
                        ]
                ]

                if (contenutoPrincipale.avvisoAgid != null && tassonomiaConPagamento) {
                    documenti += [
                            nomeFile         : "avviso_agid_${gestioneEredi ? dettaglio[0].contribuente.codFiscale : dettaglio.contribuente.codFiscale}${commonService.fileExtension(contenutoPrincipale.avvisoAgid)}" as String,
                            documento        : contenutoPrincipale.avvisoAgid,
                            allegatoPagamento: true
                    ]
                }


                inviaDocumenti([
                        context     : context,
                        elaborazione: gestioneEredi ? dettaglio[0].elaborazione : dettaglio.elaborazione,
                        dettaglio   : gestioneEredi ? dettaglio[0] : dettaglio,
                        documenti   : documenti,
                        eredi       : gestioneEredi ? dettaglio.collect {
                            [
                                    id   : it.eredeSoggetto.soggettoErede.id,
                                    erede: true
                            ]
                        } : []
                ])

                if (gestioneEredi) {
                    dettaglio.each {
                        it.note = null
                        it.documentaleId = attivita.id
                        it.save(failOnError: true, flush: true)
                    }
                } else {
                    dettaglioCorrente.note = null
                    dettaglioCorrente.documentaleId = attivita.id
                    dettaglioCorrente.save(failOnError: true, flush: true)
                }

            }
        } catch (Exception ex) {
            if (gestioneEredi) {
                dettaglio.eredi.each {
                    it.note = ex?.message ?: ex?.cause?.message
                    it.save(failOnError: true, flush: true)
                }
            } else {
                dettaglioCorrente.note = ex?.message ?: ex?.cause?.message
                dettaglioCorrente.save(failOnError: true, flush: true)
            }

            ex.printStackTrace()
        }
    }

    private void inviaDocumenti(def params) {
        def tipoElaborazione = params.elaborazione.tipoElaborazione.id
        def tipoTributo = params.elaborazione.tipoTributo.tipoTributo
        def ruolo = params.elaborazione.ruolo
        def dettaglio = params.dettaglio
        def elaborazione = params.elaborazione
        def context = params.context
        def erede = params.erede

        def cliente = context.mergedJobDataMap.get('cliente')
        def notifica = context.mergedJobDataMap.get('notifica')
        def notificationFeePolicy = context.mergedJobDataMap.get('notificationFeePolicy')
        def physicalComType = context.mergedJobDataMap.get('physicalComType')
        def tipoComunicazione = context.mergedJobDataMap.get('tipoComunicazione')
        def comunicazioneTesto = context.mergedJobDataMap.get('comunicazioneTesto')
        def firma = context.mergedJobDataMap.get('firma')
        def oggetto = context.mergedJobDataMap.get('oggetto')
        def attivita = AttivitaElaborazione.get(context.mergedJobDataMap.get('attivita'))
        def documenti = params.documenti
        def eredi = params.eredi ?: []

        def documentoId
        def tipologia
        def tipoTributoRif
        def annoRif

        verificaInvio(context, dettaglio)

        // TODO: check if tipologia can use ElaborazioniService.recuperaTipoDocumentoDaElaborazione
        if (tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_IMPOSTA) {
            documentoId = modelliService.determinaElaborazione(tipoTributo, dettaglio.pratica?.id ?: 0, null)
            tipologia = 'B'
            tipoTributoRif = tipoTributo
            annoRif = elaborazione.anno
        } else if (tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_LETTERA_GENERICA){
            tipologia = 'G'
        } else {
            documentoId = ruolo ?: dettaglio.pratica.id
            tipologia = (ruolo != null ? 'S' : (elaborazione.tipoPratica == 'S' ? 'T' : 'P'))
            tipoTributoRif = null
            annoRif = null
        }

        def testo = null

        if (comunicazioneTesto?.tipoCanale?.id != TipiCanaleDTO.PND) {
            def testoGenerato = messaggisticaService.generaMessaggio(
                    Messaggio.TIPO.APP_IO_EMAIL,
                    comunicazioneTesto,
                    dettaglio.contribuente.codFiscale,
                    dettaglio.pratica?.anno ?: dettaglio.elaborazione.anno,
                    dettaglio.pratica?.id,
                    dettaglio.elaborazione.ruolo,
                    erede?.id
            )
            testo = testoGenerato?.testo + (firma?.trim() ? "\n$firma" : '')
            notifica.oggetto = oggetto ?: testoGenerato?.oggetto
        }

        String result = documentaleService.invioDocumento(
                dettaglio.contribuente.codFiscale,
                documentoId,
                tipologia,
                documenti,
                tipoTributoRif,
                annoRif,
                notifica,
                notificationFeePolicy,
                physicalComType,
                cliente?.amministrazione?.soggetto?.id,
                tipoComunicazione,
                null,
                null,
                testo,
                eredi,
                [
                        'ID_ELABORAZIONE_MASSIVA': elaborazione.id,
                        'ID_ATTIVITA_MASSIVA'    : attivita.id
                ],
                erede
        )

        if (!result.isNumber()) {
            throw new Exception(result)
        }
    }

    private void verificaInvio(def context, def dettaglio) {
        def notifica = context.mergedJobDataMap.get('notifica')
        def nomeFile = dettaglio.nomeFile
        def errorMessage = ""

        try {
            errorMessage = documentaleService.verificaInvioMsg(dettaglio.contribuente.codFiscale, nomeFile, notifica?.tipoNotifica, dettaglio.pratica)

            if (errorMessage.empty) {
                if (notifica?.tipoNotifica == SmartPndService.TipoNotifica.PEC &&
                        !contribuentiService.fRecapito(dettaglio.eredeSoggetto?.soggettoErede?.id ?: dettaglio.contribuente.soggetto.id, dettaglio.elaborazione.tipoTributo.tipoTributo, 3)) {
                    errorMessage = "PEC non presente per il soggetto."
                } else if (notifica?.tipoNotifica == SmartPndService.TipoNotifica.EMAIL &&
                        !contribuentiService.fRecapito(dettaglio.eredeSoggetto?.soggettoErede?.id ?: dettaglio.contribuente.soggetto.id, dettaglio.elaborazione.tipoTributo.tipoTributo, 2)) {
                    errorMessage = "Mail non presente per il soggetto."
                }
            }

            if (!errorMessage.empty) {
                throw new Exception(errorMessage)
            }
        } catch (Exception e) {
            throw e
        }
    }
}
