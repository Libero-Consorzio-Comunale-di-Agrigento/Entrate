package sportello.contribuenti

import grails.plugins.springsecurity.SpringSecurityService
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.jobs.CalcoloAccertamentiJob
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

class CalcoloAccertamentiViewModel {

    // componenti
    Window self

    SpringSecurityService springSecurityService
    ImposteService imposteService
    CompetenzeService competenzeService

    // --
    boolean asynch

    def parametriCalcolo = [:]
    String tributo = ''
    def elaborazioneEseguita = false

    /**
     * D: Disabled
     * H: Hidden
     * N: Normal (Default)
     */
    def modalitaCognomeNomeCodFiscale = 'N'
    def modalitaAnno = 'N'

    def listaContribuenti

    // Parametri per il caso in cui il tributo non viene passato (Situazione Contribuente)
    def abilitaComboTributi = false
    def listaTipiTributo = []
    def tipoTributoSelezionato

    def elencoFlagSollecitati = [
            [codice: 'T', descrizione: 'Tutti'],
            [codice: 'S', descrizione: 'Già sollecitati'],
            [codice: 'N', descrizione: 'Non sollecitati'],
    ]

    @NotifyChange(["cognomeNome", "codiceFiscale", "parametriCalcolo"])
    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tributo") String tt,
         @ExecutionArgParam("cognomeNome") @Default("") String cn,
         @ExecutionArgParam("codFiscale") @Default("") String cf,
         @ExecutionArgParam("anno") Integer anno,
         @ExecutionArgParam("modalitaCognomeNomeCodFiscale") @Default("N") String modalitaCognomeNomeCodFiscale,
         @ExecutionArgParam("modalitaAnno") @Default("N") String modalitaAnno,
         @ExecutionArgParam("listaContribuenti") def listaContribuenti,
         @ExecutionArgParam("asynch") @Default("false") boolean asynch
    ) {

        self = w

        tributo = tt
        this.asynch = asynch || listaContribuenti

        this.listaContribuenti = listaContribuenti

        this.modalitaCognomeNomeCodFiscale = modalitaCognomeNomeCodFiscale
        this.modalitaAnno = modalitaAnno

        parametriCalcolo.tributo = tt
        parametriCalcolo.anno = anno ?: Calendar.getInstance().get(Calendar.YEAR)
        parametriCalcolo.codiceTributo = -1        // AUTOMATICO : -1 -> Usa oggetti_pratica.tributo
        parametriCalcolo.daCategoria = 1        // AUTOMATICO : Usati per Between su oggetti_pratica.catgeoria
        parametriCalcolo.aCategoria = 9999
        parametriCalcolo.cognomeNome = cn
        parametriCalcolo.codFiscale = cf
        parametriCalcolo.limiteInferiore = -99999999.00
        parametriCalcolo.limiteSuperiore = 99999999.00
        parametriCalcolo.dataInteressiDa = null
        parametriCalcolo.dataInteressiA = null

        /// Questi al momento disponibili solo per TARSU, CUNI

        parametriCalcolo.tipoSollecitati = 'T'
        parametriCalcolo.dataSollecitoDal = null
        parametriCalcolo.dataSollecitoAl = null
        parametriCalcolo.dataNotificaSolDal = null
        parametriCalcolo.dataNotificaSolAl = null
        parametriCalcolo.speseNotifica = true

        if (!tt) {
            initComboTributi()
        }
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, {
            elaborazioneEseguita:
            elaborazioneEseguita
        })
    }

    @Command
    onCalcolaAccertamenti() {

        if (!parametriCalcolo.tributo in ['CUNI', 'TARSU']) {
            parametriCalcolo.tipoSollecitati = 'T'
        }

        /// Siccome la procedure li gestisce, in cai 'T' e 'N' ripuliamo date
        if (parametriCalcolo.tipoSollecitati != 'S') {
            parametriCalcolo.dataSollecitoDal = null
            parametriCalcolo.dataSollecitoAl = null
            parametriCalcolo.dataNotificaSolDal = null
            parametriCalcolo.dataNotificaSolAl = null
        }

        if (!valida()) {
            return
        }

        String messaggio = "Verranno eliminate le pratiche non numerate e non notificate.\n" +
                "Si vuole confermare l'esecuzione del calcolo?"
        Messagebox.show(messaggio, "Attenzione",
                Messagebox.YES | Messagebox.NO, Messagebox.EXCLAMATION,
                new org.zkoss.zk.ui.event.EventListener() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            calcolaAccertamenti()
                        }
                    }
                }
        )
    }

    private def calcolaAccertamenti() {
        if (!asynch) {
            try {
                calcolaAccertamentiSynch()
            } catch (Exception ex) {
                manageException(ex)
            }
        } else {
            calcolaAccertamentiAsynch()
        }
    }


    private def calcolaAccertamentiSynch() {
        imposteService.calcoloAccertamenti(parametriCalcolo)
        elaborazioneEseguita = true
        onChiudi()
    }

    private def calcolaAccertamentiAsynch() {
        try {
            CalcoloAccertamentiJob.triggerNow(
                    [
                            codiceUtenteBatch: springSecurityService.currentUser.id,
                            codiciEntiBatch  : springSecurityService.principal.amministrazione.codice,
                            listaContribuenti: listaContribuenti,
                            parametriCalcolo : parametriCalcolo
                    ]
            )
            elaborazioneEseguita = true
            onChiudi()

        } catch (Exception ex) {
            manageException(ex)
        }
    }

    private def manageException(Exception ex) {
        if (ex instanceof Application20999Error) {
            Clients.showNotification(ex.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
        } else {
            throw ex
        }
    }

    @NotifyChange(["parametriCalcolo"])
    @Command
    def onCheckRiOg() {
        if (parametriCalcolo.flagVersamenti && !parametriCalcolo.annoRiferimento) {
            parametriCalcolo.flagVersamenti = false
        }
    }

    @Command
    def onCambioTributo() {

        if (tipoTributoSelezionato) {
            parametriCalcolo.tributo = tipoTributoSelezionato.tipoTributo
            tributo = tipoTributoSelezionato.tipoTributo
            BindUtils.postNotifyChange(null, null, this, "parametriCalcolo")
            BindUtils.postNotifyChange(null, null, this, "tributo")
        }
    }

    def valida() {

        def errori = []

        if (!parametriCalcolo?.cognomeNome && !parametriCalcolo?.codFiscale && modalitaCognomeNomeCodFiscale != 'H') {
            errori << "Obbligatorio specificare 'Cognome e Nome' o 'Codice Fiscale'"
        }

        if (!parametriCalcolo.anno) {
            errori << "Specicare un valore per 'Anno'"
        }

        if (parametriCalcolo.limiteInferiore > parametriCalcolo.limiteSuperiore) {
            errori << "I campi 'Limite inferiore' e 'Limite superiore' sono incoerenti."
        }


        if (parametriCalcolo.dataInteressiDa && parametriCalcolo.dataInteressiA && parametriCalcolo.dataInteressiDa > parametriCalcolo.dataInteressiA) {
            errori << "I campi Interessi: 'Da data' e 'A data' sono incoerenti."
        }

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return false
        }

        return true
    }

    def tipoTributo() {
        return TipoTributo.get(tributo).getTipoTributoAttuale()
    }

    private def initComboTributi() {
        abilitaComboTributi = true

        listaTipiTributo = competenzeService.tipiTributoUtenzaScrittura()
                .findAll { it.tipoTributo in ['TARSU', 'CUNI', 'TOSAP', 'ICP'] }


        tipoTributoSelezionato = listaTipiTributo[0]

        onCambioTributo()
    }
}
