package archivio.dizionari

import it.finmatica.tr4.SpeseIstruttoria
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.speseIstruttoria.SpeseIstruttoriaService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioSpeseIstruttoriaViewModel {

    static enum TipoOperazione {
        INSERIMENTO(true, true),
        CLONAZIONE(true, true),
        MODIFICA(true, false),
        VISUALIZZAZIONE(false, false)

        boolean canEdit
        boolean canEditKey

        TipoOperazione(boolean canEdit, boolean canEditKey) {
            this.canEdit = canEdit
            this.canEditKey = canEditKey
        }
    }

    // Services
    SpeseIstruttoriaService speseIstruttoriaService
    CommonService commonService

    // Componenti
    Window self

    // Comuni
    def spesa
    def tipoTributo
    TipoOperazione tipoOperazione
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("spesa") def sp,
         @ExecutionArgParam("tipoOperazione") TipoOperazione tipoOperazione) {
        this.self = w

        this.tipoTributo = tt
        this.spesa = sp ?: new SpeseIstruttoria(tipoTributo: tipoTributo)
        this.tipoOperazione = tipoOperazione
        this.labels = commonService.getLabelsProperties('dizionario')
    }

    @Command
    onSalva() {

        def errori = controllaParametri()

        if (errori.size() > 0) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }

        if (spesa.anno != null && spesa.daImporto != null && tipoOperazione.canEditKey &&
                speseIstruttoriaService.existsSpeseIstruttoria(tipoTributo, spesa.anno, spesa.daImporto)) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted,
                    "una Spesa Istruttoria",
                    "questo Anno e Importo Da")

            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
            return
        }

        if (isOverlappingAndNotify()) {
            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [spesa: spesa])
    }

    def isOverlappingAndNotify() {
        if (speseIstruttoriaService.existsOverlappingSpesaIstruttoria(spesa)) {
            Clients.showNotification("Esistono Importi intersecanti per questo Anno",
                    Clients.NOTIFICATION_TYPE_ERROR,
                    self, "top_center", 3000, true)
            return true
        }
        return false
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }


    private def controllaParametri() {

        def errori = []

        if (spesa.anno == null) {
            errori << "Il campo Anno è obbligatorio"
        }
        if (spesa.daImporto == null) {
            errori << "Il campo Importo Da è obbligatorio"
        }

        if (spesa.aImporto == null) {
            errori << "Il campo Importo A è obbligatorio"
        }

        if (spesa.spese == null && spesa.percInsolvenza == null ||
                spesa.spese != null && spesa.percInsolvenza != null) {
            errori << "I campi Spese e % Insolvenza non sono coerenti"
        }

        if (spesa.daImporto > spesa.aImporto) {
            errori << 'Importo Da maggiore di Importo A'
        }

        if (spesa.daImporto > new BigDecimal("99999999.99")) {
            errori << 'Importo Da troppo grande'
        }

        if (spesa.aImporto > new BigDecimal("99999999.99")) {
            errori << 'Importo A troppo grande'
        }

        if (spesa.spese > new BigDecimal("9999.99")) {
            errori << 'Spese troppo grande'
        }

        if (spesa.percInsolvenza > new BigDecimal("99.99")) {
            errori << ' % Insolvenza troppo grande'
        }

        return errori
    }

}
