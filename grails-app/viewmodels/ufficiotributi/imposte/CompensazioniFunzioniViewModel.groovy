package ufficiotributi.imposte

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.imposte.CompensazioniService
import it.finmatica.tr4.jobs.CalcoloCompensazioniJob
import it.finmatica.tr4.jobs.GeneraVersamentiInCompensazioneJob
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class CompensazioniFunzioniViewModel {

    static enum TipoFunzione {
        CALCOLO_COMPENSAZIONI("calcoloCompensazioni"),
        GENERA_VERSAMENTI("generaVersamenti"),
        GENERA_VERSAMENTI_JOB("generaVersamentiJob"),
        CALCOLO_COMPENSAZIONI_IMPOSTE_JOB("calcoloCompensazioniImposteJob")

        String value

        private TipoFunzione(String value) {
            this.value = value
        }

        String getValue() {
            return value
        }

    }

    //Services
    CompensazioniService compensazioniService
    def springSecurityService

    // Componenti
    Window self

    //Comuni
    def tipoFunzione
    def titolo
    def listaTipiTributo
    def listaAnni
    def listaMotivi
    def listaTipiImposta
    def listaFonti
    def parametri
    def codFiscale
    def anno


    /**
     * D: Disabled
     * H: Hidden
     * N: Normal (Default)
     */
    def modalitaCodFiscale
    def modalitaAnno

    def datiContribuenti

    def nomeTipoTributo
    def motivoCompensazione

    // mascheraPadre
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoFunzione") def tipoFunzione,
         @ExecutionArgParam("codFiscale") def codFiscale,
         @ExecutionArgParam("modalitaCodFiscale") @Default('N') def modalitaCodFiscale,
         @ExecutionArgParam("modalitaAnno") @Default('N') def modalitaAnno,
         @ExecutionArgParam("datiContribuenti") @Default("null") def dc,
         @ExecutionArgParam("anno") def an,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("motivoCompensazione") def mc) {

        this.self = w
        this.codFiscale = codFiscale
        this.modalitaCodFiscale = modalitaCodFiscale
        this.modalitaAnno = modalitaAnno
        this.datiContribuenti = dc
        this.tipoFunzione = tipoFunzione
        this.anno = an
        this.nomeTipoTributo = tt
        this.motivoCompensazione = mc


        this.titolo = this.tipoFunzione in [
                TipoFunzione.CALCOLO_COMPENSAZIONI, TipoFunzione.CALCOLO_COMPENSAZIONI_IMPOSTE_JOB] ?
                "Calcolo Compensazioni" : "Inserimento Versamenti da Compensazioni"
        caricaDati()
        initParametri()
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onOk() {

        def numVersamenti = null

        //Trasformo in maiuscolo
        if (parametri.codFiscale) {
            parametri.codFiscale = parametri.codFiscale.toUpperCase()
        }

        if (tipoFunzione == TipoFunzione.CALCOLO_COMPENSAZIONI) {

            compensazioniService.calcoloCompensazioni(
                    [
                            tipoTributo        : parametri.tipoTributo,
                            anno               : parametri.anno,
                            codFiscale         : parametri.codFiscale,
                            limiteDiff         : parametri.limiteDiff,
                            motivoCompensazione: parametri.motivo.motivoCompensazione,
                            user               : springSecurityService.currentUser.id,
                            tipoImposta        : parametri.tipoImposta.codice
                    ])

        } else if (tipoFunzione == TipoFunzione.GENERA_VERSAMENTI) {

            numVersamenti = compensazioniService.generaVersamenti(
                    [
                            tipoTributo: parametri.tipoTributo,
                            anno       : parametri.anno,
                            codFiscale : parametri.codFiscale,
                            fonte      : parametri.fonte.codice,
                            motivo     : parametri.motivo.motivoCompensazione,
                            user       : springSecurityService.currentUser.id,
                    ])

        } else if (tipoFunzione == TipoFunzione.CALCOLO_COMPENSAZIONI_IMPOSTE_JOB) {

            try {
                CalcoloCompensazioniJob.triggerNow([
                        codiceUtenteBatch: springSecurityService.currentUser.id,
                        codiciEntiBatch  : springSecurityService.principal.amministrazione.codice,
                        lista            : datiContribuenti.lista,
                        parametriCalcolo :
                                [

                                        tipoTributo        : parametri.tipoTributo,
                                        anno               : datiContribuenti.anno,
                                        codFiscale         : parametri.codFiscale,
                                        limiteDiff         : parametri.limiteDiff,
                                        motivoCompensazione: parametri.motivo.motivoCompensazione,
                                        user               : springSecurityService.currentUser.id,
                                        tipoImposta        : parametri.tipoImposta.codice
                                ]
                ])
                onChiudi()
            } catch (Exception ex) {
                if (ex instanceof Application20999Error) {
                    Clients.showNotification(ex.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                } else {
                    throw ex
                }
            }
        } else if (tipoFunzione == TipoFunzione.GENERA_VERSAMENTI_JOB) {

            try {
                GeneraVersamentiInCompensazioneJob.triggerNow([
                        codiceUtenteBatch: springSecurityService.currentUser.id,
                        codiciEntiBatch  : springSecurityService.principal.amministrazione.codice,
                        lista            : datiContribuenti.lista,
                        parametriCalcolo :
                                [
                                        tipoTributo: parametri.tipoTributo,
                                        anno       : datiContribuenti.anno + 1,
                                        motivo     : parametri.motivo.motivoCompensazione,
                                        user       : springSecurityService.currentUser.id,
                                        fonte      : parametri.fonte.codice
                                ]
                ])
                onChiudi()
            } catch (Exception ex) {
                if (ex instanceof Application20999Error) {
                    Clients.showNotification(ex.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
                } else {
                    throw ex
                }
            }
        }

        Events.postEvent(Events.ON_CLOSE, self, [messaggio: "", numVersamenti: numVersamenti])
    }

    private def caricaDati() {

        if (tipoFunzione == TipoFunzione.CALCOLO_COMPENSAZIONI) {
            listaTipiTributo = compensazioniService.getTipiTributo()
            listaAnni = compensazioniService.getAnniCalcoloCompensazioni()
            listaMotivi = compensazioniService.getMotivi()
            listaTipiImposta = compensazioniService.getTipiImpostaCalcoloCompensazioni()
        } else if (tipoFunzione == TipoFunzione.GENERA_VERSAMENTI) {
            listaTipiTributo = compensazioniService.getTipiTributo()
            listaAnni = compensazioniService.getAnniGeneraVersamento("TARSU", 'D')
            listaMotivi = compensazioniService.getMotivi()
            listaFonti = compensazioniService.getFontiGeneraVersamento()
        } else if (tipoFunzione == TipoFunzione.CALCOLO_COMPENSAZIONI_IMPOSTE_JOB) {
            listaTipiTributo = compensazioniService.getTipiTributo()
            listaAnni = []
            listaAnni << datiContribuenti.anno
            listaMotivi = compensazioniService.getMotivi()
            listaTipiImposta = compensazioniService.getTipiImpostaCalcoloCompensazioni()
        } else if (tipoFunzione == TipoFunzione.GENERA_VERSAMENTI_JOB) {
            listaTipiTributo = compensazioniService.getTipiTributo()
            listaMotivi = compensazioniService.getMotivi()
            listaFonti = compensazioniService.getFontiGeneraVersamento()
        }
    }

    private def initParametri() {

        if (tipoFunzione == TipoFunzione.CALCOLO_COMPENSAZIONI) {
            parametri = [
                    tipoTributo: "TARSU",
                    desTitr    : "TARI",
                    anno       : listaAnni[0],
                    codFiscale : codFiscale,
                    limiteDiff : null,
                    motivo     : listaMotivi[0],
                    tipoImposta: listaTipiImposta[0]
            ]
        } else if (tipoFunzione == TipoFunzione.GENERA_VERSAMENTI) {

            def parametroFonte = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'FONT_COMP' }?.valore

            def motivo = motivoCompensazione ? listaMotivi.find {
                it.motivoCompensazione = motivoCompensazione
            } : listaMotivi[0]

            parametri = [
                    tipoTributo: "TARSU",
                    desTitr    : nomeTipoTributo ?: "TARI",
                    anno       : anno ?: listaAnni[0],
                    codFiscale : codFiscale,
                    motivo     : motivo,
                    fonte      : listaFonti.find {
                        it.codice == parametroFonte as Integer
                    }
            ]
        } else if (tipoFunzione == TipoFunzione.GENERA_VERSAMENTI_JOB) {

            def parametroFonte = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'FONT_COMP' }?.valore

            def motivo = motivoCompensazione ? listaMotivi.find {
                it.motivoCompensazione = motivoCompensazione
            } : listaMotivi[0]

            parametri = [
                    tipoTributo: "TARSU",
                    desTitr    : "TARI",
                    anno       : anno,
                    motivo     : motivo,
                    fonte      : listaFonti.find {
                        it.codice == parametroFonte as Integer
                    }
            ]
        } else if (tipoFunzione == TipoFunzione.CALCOLO_COMPENSAZIONI_IMPOSTE_JOB) {
            parametri = [
                    tipoTributo: "TARSU",
                    desTitr    : "TARI",
                    anno       : datiContribuenti.anno,
                    codFiscale : codFiscale,
                    limiteDiff : null,
                    motivo     : listaMotivi[0],
                    tipoImposta: listaTipiImposta[0]
            ]
        }
    }
}
