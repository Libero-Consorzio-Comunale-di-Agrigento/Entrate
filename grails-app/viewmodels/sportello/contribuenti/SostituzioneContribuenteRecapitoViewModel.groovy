package sportello.contribuenti

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.soggetti.SoggettiService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Event
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Messagebox
import org.zkoss.zul.Window

import java.text.SimpleDateFormat

class SostituzioneContribuenteRecapitoViewModel {


    //Services
    SoggettiService soggettiService
    CommonService commonService

    // Componenti
    Window self

    //Comuni
    def soggOrigine
    def ultimoStatoOrigine
    def soggDestinazione
    def ultimoStatoDestinazione

    def recapitoSelezionato
    def listaRecapiti
    def listaRecapitiEliminati

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("soggOrigine") def so,
         @ExecutionArgParam("soggDestinazione") def sd) {

        this.self = w
        this.soggOrigine = so
        this.soggDestinazione = sd

        this.listaRecapitiEliminati = []

        if (soggOrigine.stato) {
            ultimoStatoOrigine = soggOrigine.stato.descrizione
            if (soggOrigine.dataUltEve) {
                ultimoStatoOrigine += " il " + soggOrigine.dataUltEve.format('dd/MM/yyyy')
            }
        }
        if (soggDestinazione.stato) {
            ultimoStatoDestinazione = soggDestinazione.stato.descrizione
            if (soggDestinazione.dataUltEve) {
                ultimoStatoDestinazione += " il " + soggDestinazione.dataUltEve.format('dd/MM/yyyy')
            }
        }

        onRefresh()

    }

    def onRefresh() {

        listaRecapiti = []
        listaRecapiti.addAll(soggettiService.getListaRecapiti(soggOrigine.id))
        listaRecapiti.addAll(soggettiService.getListaRecapiti(soggDestinazione.id))

        // Ordinamento per rendere più evidenti eventuali sovrapposizioni
        listaRecapiti.sort {
            r1, r2 ->
                r1.tipoRecapito.descrizione <=> r2.tipoRecapito.descrizione ?:
                        r1.tipoTributo?.tipoTributo <=> r2.tipoTributo?.tipoTributo ?:
                                r1.dal <=> r2.dal ?:
                                        r1.al <=> r2.al
        }

        recapitoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaRecapiti")
        BindUtils.postNotifyChange(null, null, this, "recapitoSelezionato")
    }

    @Command
    def onSalva() {

        def result = controllaIntersezioni()

        if (!result) {
            Clients.showNotification("Esistono periodi intersecanti per Tipo Tributo e Tipo Recapito", Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 3000, true)
            return
        }


        def title = "Conferma operazione"
        def message = "Si sta per sostituire\n\nil contribuente\n" +
                "- ${soggOrigine.codFiscale}  N.I. ${soggOrigine.id}\n\ncon il contribuente\n" +
                "- ${soggDestinazione.codFiscale}  N.I. ${soggDestinazione.id}\n\nSicuri di voler procedere ?"

        Messagebox.show(message, title, Messagebox.YES | Messagebox.NO, Messagebox.QUESTION,
                new org.zkoss.zk.ui.event.EventListener<Event>() {
                    void onEvent(Event e) {
                        if (Messagebox.ON_YES.equals(e.getName())) {
                            sostituisciContribuente()
                        }
                    }
                }
        )

    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    @Command
    def onModificaRecapito() {

        commonService.creaPopup("/archivio/recapito.zul",
                self,
                [
                        recapito: recapitoSelezionato,
                        modifica: true,
                        salva   : false
                ],
                { event ->
                    if (event.data) {
                    }
                }
        )

    }

    @Command
    def onEliminaRecapito() {

        String msg = "Procedere con l'eliminazione del recapito?"
        Messagebox.show(msg, "Eliminazione Recapito", Messagebox.OK | Messagebox.CANCEL,
                Messagebox.QUESTION, new org.zkoss.zk.ui.event.EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName().equals("onOK")) {
                    rimuoviRecapito()
                }
            }
        })


    }

    @Command
    onOpenSituazioneContribuente(@BindingParam("cont") def tipoContribuente) {

        def ni = tipoContribuente == "origine" ? soggOrigine?.id : soggDestinazione?.id

        if (!ni) {
            Clients.showNotification("Contribuente non trovato."
                    , Clients.NOTIFICATION_TYPE_INFO, null, "middle_center", 3000, true)
            return
        }
        Clients.evalJavaScript("window.open('standalone.zul?sezione=CONTRIBUENTE&idSoggetto=${ni}','_blank');")
    }

    private def rimuoviRecapito() {
        listaRecapitiEliminati << recapitoSelezionato
        listaRecapiti.remove(recapitoSelezionato)

        recapitoSelezionato = null

        BindUtils.postNotifyChange(null, null, this, "listaRecapiti")
        BindUtils.postNotifyChange(null, null, this, "recapitoSelezionato")
    }

    // Controlla se esistono intersezioni tra date dei recapiti dei due contribuenti per tipo tributo e tipo recapito
    private def controllaIntersezioni() {

        def listaTemp = []
        listaTemp.addAll(listaRecapiti)

        SimpleDateFormat sdf = new SimpleDateFormat("dd/mm/yyyy")

        for (def rec in listaRecapiti) {

            listaTemp.remove(rec)

            for (def recapito in listaTemp) {

                if (rec.tipoTributo?.tipoTributo == recapito.tipoTributo?.tipoTributo &&
                        rec.tipoRecapito.id == recapito.tipoRecapito.id) {

                    def dalRec = recapito.dal ?: sdf.parse("01/01/1900")
                    def alRec = recapito.al ?: sdf.parse("31/12/3000")
                    def dalRecCurrent = rec.dal ?: sdf.parse("01/01/1900")
                    def alRecCurrent = rec.al ?: sdf.parse("31/12/3000")

                    if (commonService.isOverlapping(dalRec, alRec, dalRecCurrent, alRecCurrent)) {
                        return false
                    }
                }
            }
        }

        return true
    }

    private sostituisciContribuente() {

        Long procResult
        String procMessagge

        String msgBoxTitle
        String msgBoxMessage
        def msgBoxIcon

        try {

            def applyResult =
                    soggettiService.sostituisciContribuenteRecapiti(soggOrigine, soggDestinazione, listaRecapiti, listaRecapitiEliminati)
            procResult = applyResult.result
            procMessagge = applyResult.messaggio

            if (procResult == 0) {
                msgBoxTitle = "Informazione"
                msgBoxMessage = "Contribuente sostituito con successo"
                msgBoxIcon = Messagebox.INFORMATION
            }

        } catch (def e) {

            if (e instanceof Application20999Error) {

                def errorNum = e.errorCode
                def errorMessage = e.message

                switch (errorNum) {
                    case 1:
                    case 2:
                    default:
                        msgBoxTitle = "Attenzione"
                        msgBoxMessage = errorMessage
                        msgBoxIcon = Messagebox.EXCLAMATION
                        break
                    case 3:
                        msgBoxTitle = "Errore"
                        msgBoxMessage = errorMessage
                        msgBoxIcon = Messagebox.ERROR
                        break
                }
            }

        }


        Messagebox.show(msgBoxMessage, msgBoxTitle, Messagebox.OK, msgBoxIcon, new org.zkoss.zk.ui.event.EventListener() {

            void onEvent(Event event) throws Exception {

                if (event.getName().equals("onOK") && procResult == 0) {
                    Events.postEvent(Events.ON_CLOSE, self, [completato: true])
                }
            }
        })

    }

}
