package it.finmatica.tr4.jobs


import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.RuoloContribuente
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.elaborazioni.DettaglioElaborazione
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.elaborazioni.StatoAttivita
import it.finmatica.tr4.elaborazioni.TipoAttivita
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class CreazioneElaborazioneJob {

    private static Log log = LogFactory.getLog(CreazioneElaborazioneJob)

    ElaborazioniService elaborazioniService
    CommonService commonService

    static triggers = {}

    def group = "ElaborazioniMassiveGroup"

    def description = "Creazione elaborazione"

    def concurrent = false

    def execute(context) {

        def nomeElaborazione = context.mergedJobDataMap.get('nomeElaborazione')
        def tipoElaborazione = context.mergedJobDataMap.get('tipoElaborazione')
        def tipoTributo = context.mergedJobDataMap.get('tipoTributo')
		def gruppoTributo = context.mergedJobDataMap.get('gruppoTributo')
        def tipoPratica = context.mergedJobDataMap.get('tipoPratica')
        def ruolo = context.mergedJobDataMap.get('ruolo')
        def anno = context.mergedJobDataMap.get('anno')
        def dettagli = context.mergedJobDataMap.get('dettagli')
        def utente = context.mergedJobDataMap.get('codiceUtenteBatch')
        def creaElaborazioniSeparate = context.mergedJobDataMap.get('creaElaborazioniSeparate')
        def creaElaborazioniAAT = context.mergedJobDataMap.get('creaElaborazioniAAT')
        def creaDettagliEredi = context.mergedJobDataMap.get('creaDettagliEredi')
        def selectAllDetails = context.mergedJobDataMap.get('selectAllDetails')
        def autoExportAnagrTrib = context.mergedJobDataMap.get('autoExportAnagrTrib')

        log.info("Avvio creazione elaborazione massiva.")

        if ((ruolo != null) && (dettagli == null)) {
            dettagli = RuoloContribuente.findAllByRuolo(Ruolo.get(ruolo))
                    .collect { [codFiscale: it.contribuente.codFiscale] }.unique()
        }

        try {

            def elab = null

            def execTime = commonService.timeMe {
                elab = elaborazioniService.creaElaborazione(
                        [
                                nomeElaborazione: nomeElaborazione,
                                tipoElaborazione: tipoElaborazione,
                                tipoTributo     : tipoTributo,
                                tipoPratica     : tipoPratica,
								gruppoTributo   : gruppoTributo,
                                ruolo           : ruolo,
                                anno            : anno,
                                utente          : utente
                        ],
                        dettagli,
                        creaElaborazioniSeparate ?: false,
                        creaElaborazioniAAT ?: false,
                        creaDettagliEredi ?: false,
                        selectAllDetails
                )
            }

            log.info("Creazione elaborazione emassiva eseguita in ${execTime}.")

            if (autoExportAnagrTrib) {

                def ta = TipoAttivita.get(ElaborazioniService.TIPO_ATTIVITA_GENERA_ANGR_TRIB)
                def att =
                        [
                                elaborazione : elab.id,
                                tipoAttivita : ta,
                                statoAttivita: StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_INSERITO)
                        ]

                List<DettaglioElaborazione> dettagliTotali = elaborazioniService.listaDettagliDaElaborare(
                        elab,
                        elaborazioniService.dettagliOrderBy
                ).collate(10000)

                dettagliTotali.each {
                    AnagrafeTributariaOutputJob.triggerNow([
                            'codiceUtenteBatch': utente,
                            attivita           : elaborazioniService.creaAttivita(att).id,
                            'dettaglio'        : it
                    ])
                }

            }
        } catch (Exception e) {
            e.printStackTrace()
        }
    }
}
