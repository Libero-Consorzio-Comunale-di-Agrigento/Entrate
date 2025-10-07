package it.finmatica.tr4.jobs

import com.aspose.words.SaveFormat
import document.FileNameGenerator
import groovyx.gpars.GParsPool
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.elaborazioni.AttivitaElaborazione
import it.finmatica.tr4.elaborazioni.ElaborazioniService
import it.finmatica.tr4.elaborazioni.StatoAttivita
import it.finmatica.tr4.modelli.ModelliService
import it.finmatica.tr4.soggetti.SoggettiService
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class ElaborazioniGeneraDocumentiJob {

    private final def MAX_P_ELAB = "MAX_P_ELAB"

    ModelliService modelliService
    CommonService commonService

    private static Log log = LogFactory.getLog(ElaborazioniGeneraDocumentiJob)

    ElaborazioniService elaborazioniService
    SoggettiService soggettiService

    static triggers = {}

    def group = "ElaborazioniMassiveGroup"

    def description = "Generazione dei documenti"

    def concurrent = false

    def maxDocuments = 10

    def execute(context) {

        def maxThreads = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == MAX_P_ELAB }?.valore as Integer ?: 1

        def nowElaborazione = System.currentTimeMillis()

        AttivitaElaborazione attivita = AttivitaElaborazione.get(context.mergedJobDataMap.get('attivita'))
        def tipiF24 = context.mergedJobDataMap.get('tipiF24')

        def dettagli = elaborazioniService.listaDettagliDaElaborare(
                attivita.elaborazione,
                elaborazioniService.dettagliOrderBy
        )

        def tipoTributo = attivita.elaborazione.tipoTributo.tipoTributo
        def tipoElaborazione = attivita.elaborazione.tipoElaborazione.id

        def ridotto = context.mergedJobDataMap.get('ridotto')


        try {

            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_IN_CORSO))

            log.info("Avvio attvità ${attivita.id} - ${attivita.tipoAttivita.descrizione} per ${dettagli.size()} documenti.")

            def mapDettagli = [:]
            def index = 0
            dettagli.collate(maxDocuments).each { mapDettagli << [(index++): it] }

            def annoRuolo = (attivita.elaborazione.ruolo ?: -1) != -1 ? Ruolo.get(attivita.elaborazione.ruolo).annoRuolo : null

            GParsPool.withPool(maxThreads) {
                mapDettagli.eachParallel {

                    log.info "Generazione pdf avvio processo [$it.key]"

                    def indexDoc = 0
                    def numDoc = it.value.size()
                    def nThread = it.key
                    it.value.each { dettaglioElaborazione ->

                        def params = [:]
                        params.MODELLO = attivita.modello.modello
                        if (!(attivita.modello.tipoModello.tipoModello in ['ACC_TARIR%', 'ACC_D_TAR%', 'ACC_I_TAR%',
                                                                           "ACC_D_ICI%"])) {
                            params.MODELLO_RIMB = attivita.modello.modello
                        }
                        params.allegaF24 = attivita.flagF24
                        params.FORMAT = SaveFormat.PDF

                        params.TIPO_TRIBUTO = attivita.elaborazione.tipoTributo.tipoTributo
                        params.GRUPPO_TRIBUTO = attivita.elaborazione.gruppoTributo
                        params.RUOLO = attivita.elaborazione.ruolo

                        params.ridotto = ridotto

                        def now = System.currentTimeMillis()

                        if (tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_PRATICHE) {
                            params.PRATICA = dettaglioElaborazione.pratica?.id
                            params.VETT_PRAT = dettaglioElaborazione.pratica?.id
                            if (attivita.elaborazione.tipoTributo.tipoTributo in ['CUNI', 'ICP', 'TOSAP']) {
                                params.TIPO = "ACC_$tipoTributo%" as String
                            }
                        }

                        if (tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_RUOLI) {
                            params.TIPO = "COM_$tipoTributo%"
                        }

                        if (tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_IMPOSTA) {
                            params.ANNO = attivita.elaborazione.anno
                            params.TIPO = "COM_${tipoTributo}%"
                            params.RUOLO = -1
                            params.PRATICA = dettaglioElaborazione.pratica?.id ?: -1
                        }

                        if (tipoElaborazione == ElaborazioniService.TIPO_ELABORAZIONE_LETTERA_GENERICA) {
                            params.TIPO = 'GEN%'
                            params.NI = dettaglioElaborazione.contribuente.soggetto.id
                        }

                        params.CF = dettaglioElaborazione.contribuente.codFiscale

                        if ((params.TIPO as String) in ['COM_ICI%', 'COM_TASI%']) {
                            params.tipiF24 = tipiF24
                            params.ANNO = annoRuolo ?: params.ANNO
                        }

                        params.niErede = dettaglioElaborazione.eredeSoggetto?.soggettoErede?.id

                        def nomeFile

                        switch (tipoElaborazione) {
                            case ElaborazioniService.TIPO_ELABORAZIONE_PRATICHE:
                                def generatorTitle
                                switch (dettagli[0].pratica.tipoPratica) {
                                    case 'A':
                                        generatorTitle = FileNameGenerator.GENERATORS_TITLES.ACC
                                        break
                                    case 'L':
                                        generatorTitle = FileNameGenerator.GENERATORS_TITLES.LIQ
                                        break
                                    default:
                                        generatorTitle = FileNameGenerator.GENERATORS_TITLES.SOL
                                        break
                                }

                                nomeFile = FileNameGenerator.generateFileName(
                                        FileNameGenerator.GENERATORS_TYPE.MODELLI,
                                        generatorTitle,
                                        [
                                                idDocumento        : params.PRATICA,
                                                codFiscale       : params.CF,
                                                numeroOrdineErede: dettaglioElaborazione.eredeSoggetto?.numeroOrdine
                                        ]
                                )
                                break
                            case ElaborazioniService.TIPO_ELABORAZIONE_RUOLI:
                                nomeFile = FileNameGenerator.generateFileName(
                                        FileNameGenerator.GENERATORS_TYPE.MODELLI,
                                        FileNameGenerator.GENERATORS_TITLES.COM,
                                        [
                                                idDocumento        : params.RUOLO,
                                                codFiscale       : params.CF
                                        ]
                                )
                                break
                            case ElaborazioniService.TIPO_ELABORAZIONE_IMPOSTA:
                                def elaborazione = modelliService.determinaElaborazione(tipoTributo, params.PRATICA, null)
                                nomeFile = FileNameGenerator.generateFileName(
                                        FileNameGenerator.GENERATORS_TYPE.MODELLI,
                                        FileNameGenerator.GENERATORS_TITLES.COM,
                                        [
                                                tipoTributo   : tipoTributo,
                                                anno          : params.ANNO,
                                                idElaborazione: elaborazione,
                                                codFiscale    : params.CF
                                        ]
                                )
                                break
                            case ElaborazioniService.TIPO_ELABORAZIONE_LETTERA_GENERICA:
                                nomeFile = FileNameGenerator.generateFileName(
                                        FileNameGenerator.GENERATORS_TYPE.MODELLI,
                                        FileNameGenerator.GENERATORS_TITLES.LGE,
                                        [modello   : params.MODELLO,
                                         codFiscale: params.CF])
                                break
                            default:
                                nomeFile = FileNameGenerator.generateFileName(
                                        FileNameGenerator.GENERATORS_TYPE.MODELLI,
                                        FileNameGenerator.GENERATORS_TITLES.GEN,
                                        [
                                                idDocumento        : 0,
                                                codFiscale       : params.CF
                                        ]
                                )
                                break
                        }

                        def documento = generaDocumento(params)

                        elaborazioniService.elaboraDettaglio(
                                dettaglioElaborazione.id,
                                attivita.id,
                                documento instanceof Exception ? null : commonService.addExtension(nomeFile, documento),
                                documento,
                                ElaborazioniService.TIPO_ATTIVITA.STAMPA)

                        def tempo = ((System.currentTimeMillis() - now) as BigDecimal) / 1000

                        log.info "[$nThread]: generato documento ${++indexDoc} di ${numDoc} in ${tempo}s. "
                    }
                }
            }
            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_COMPLETATA))

            def tempoElaborazione = ((System.currentTimeMillis() - nowElaborazione) as BigDecimal) / 1000
            log.info "Attività [${attivita.elaborazione.nomeElaborazione} - ${attivita.id}] eseguita in ${tempoElaborazione}s."
        } catch (Exception e) {
            elaborazioniService.cambiaStatoAttivita(attivita, StatoAttivita.get(ElaborazioniService.STATO_ATTIVITA_ERRORE), e.message)
            e.printStackTrace()
        }
    }

    /**
     * LIQ/ACC: PRATICA, CF, MODELLO, MODELLO_RIMB, PRATICA, allegaF24, ridotto
     **/
    private def generaDocumento(def params) {

        def fileStampa = null
        def error = null
        try {
            fileStampa = modelliService.stampaModello(params)

        } catch (Exception e) {
            error = e
            log.error(e)
        }

        if (error) {
            error.printStackTrace()
            return error
        } else {
            return fileStampa
        }
    }
}
