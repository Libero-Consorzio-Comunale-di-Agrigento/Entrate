package ufficiotributi.imposte

import it.finmatica.tr4.DatoGenerale
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.imposte.ListeDiCaricoRuoliService
import org.apache.log4j.Logger
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.util.media.AMedia
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Filedownload
import org.zkoss.zul.Window

class InviaConsorzioViewModel {


    private static final Logger log = Logger.getLogger(InviaConsorzioViewModel.class)

    // services
    ListeDiCaricoRuoliService listeDiCaricoRuoliService

    // componenti
    Window self

    // Model
    def elencoRuoli
    def elencoIdRuoli
    def tipoTributo
    def tipoTracciato
    def testoDialog

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("elencoIdRuoli") List<Long> elencoIdRuoli,
         @ExecutionArgParam("tipoTributo") def tipoTributo) {

        this.self = w
        this.elencoIdRuoli = elencoIdRuoli
        this.tipoTributo = tipoTributo

        this.elencoRuoli = Ruolo.findAllByIdInList(elencoIdRuoli)

        determinaTracciato()
    }

    @Command
    def onChangeTracciato() {
        BindUtils.postNotifyChange(null, null, this, "raggruppamento")
    }

    @Command
    def onGeneraTrasmissione() {

        def message = validaGeneraTrasmissione(tipoTracciato)
        if (!message.empty) {
            Events.postEvent(Events.ON_CLOSE, self, null)
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return
        }

        def tracciato = listeDiCaricoRuoliService.generaTrasmissione(elencoIdRuoli, tipoTracciato)

        AMedia amedia = new AMedia(tracciato.nomeFile, "", "text/plain", tracciato.data.bytes)
        Filedownload.save(amedia)
    }

    private determinaTracciato() {
        // Tutti i ruoli sono coattivi
        if (elencoRuoli.findAll { it.specieRuolo }.size() == elencoRuoli.size()) {
            tipoTracciato = ListeDiCaricoRuoliService.Tracciato.T600
        } else if (elencoRuoli.findAll { !it.specieRuolo }.size() == elencoRuoli.size()) {
            // Tutti i ruoli sono ordinari
            tipoTracciato = ListeDiCaricoRuoliService.Tracciato.T290
        } else {
            Events.postEvent(Events.ON_CLOSE, self, null)
            Clients.showNotification("I ruoli selezionati devono essere tutti della stessa specie", Clients.NOTIFICATION_TYPE_ERROR, self, "top_center", 5000, true)
            return
        }

        testoDialog = "Verra' generato il tracciato ${tipoTracciato.code}.\nProcedere?"
    }

    private String validaGeneraTrasmissione(def tipoTracciato) {

        def message = ""

        if (tipoTracciato == ListeDiCaricoRuoliService.Tracciato.T290) {
            // Verifica data scadenza prima rata
            def dateScadenza = Ruolo.findAllByIdInList(elencoRuoli.collect { it.id })
                    .collect { it.scadenzaPrimaRata }

            if (dateScadenza.unique().size() > 1) {
                message = "Presenza di Date Scadenza Prima Rata incongruenti\n"
            }

            if (dateScadenza.find { it == null } != null) {
                message += "Presenza di Date Scadenza Prima Rata non valorizzate\n"
            }

            if (dateScadenza.find { !(it.getAt(Calendar.MONTH) in [2, 4, 6, 9, 11]) } != null) {
                message += "Presenza di Date Scadenza Prima Rata errate\n"
            }

            def codComuneRuolo = DatoGenerale.findByChiave(Long.valueOf(1)).codComuneRuolo

            if (codComuneRuolo == null || codComuneRuolo.trim().empty) {
                message = "Codice Comune Ruolo non valorizzato\n"
            }

            if (tipoTributo.codEnte == null || tipoTributo.codEnte.trim().empty) {
                message += "Codice Ente per il tripo tributo [${tipoTributo.getTipoTributoAttuale()}] non valorizzato\n"
            }
        } else if (tipoTracciato == ListeDiCaricoRuoliService.Tracciato.T600) {
            if (Ruolo.countByIdInListAndInvioConsorzioIsNotNull(elencoIdRuoli) > 0) {
                message = "Sono presenti ruoli gia' inviati a consorzio\n"
            }

            if (Ruolo.countByIdInListAndScadenzaPrimaRataLessThan(elencoIdRuoli, new Date()) > 0) {
                message += "La scadenza della prima rata e' antecedente alla data odierna\n"
            }
        }


        def elencoRuoli = Ruolo.findAllByIdInList(elencoIdRuoli)

        def erroreAnnoEmissione = elencoRuoli.collect { it.annoEmissione }.unique().size() > 1

        if (erroreAnnoEmissione) {
            message += "I ruoli selezionati devono avere tutti lo stesso anno di emissione\n"
        }

        return message
    }

    @Command
    def onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

}
