package sportello.contribuenti

import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.StatoContribuenteService
import it.finmatica.tr4.dto.StatoContribuenteDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class StatoContribuenteViewModel {

    static final enum OpenMode {
        CREATE,
        READ,
        UPDATE,
        DELETE
    }

    Window self

    StatoContribuenteService statoContribuenteService
    CompetenzeService competenzeService

    def statoContribuente
    def tipiTributo
    def tipiStatoContribuente
    def readOnly = false

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("action") @Default('OpenMode.CREATE') OpenMode action,
         @ExecutionArgParam("codFiscale") String codFiscale,
         @ExecutionArgParam("tipiTributo") List<String> tipiTributo,
         @ExecutionArgParam("statoContribuente") StatoContribuenteDTO statoContribuente
    ) {
        self = w

        switch (action) {
            case OpenMode.CREATE:
                initCreate(codFiscale, tipiTributo)
                break
            case OpenMode.UPDATE:
                initUpdate(statoContribuente, tipiTributo)
                break
            case OpenMode.READ:
                initRead(statoContribuente)
                break
            default:
                throw new IllegalArgumentException("Invalid action")
        }
    }

    @Command
    void onSave() {
        if (readOnly) {
            throw new IllegalStateException("Cannot save read-only stato contribuente")
        }

        if (statoContribuenteService.existsStatoContribuente(statoContribuente)) {
            Clients.showNotification("Esiste già uno stato per questo Tributo, Data e Anno",
                    Clients.NOTIFICATION_TYPE_ERROR, null, "middle_center", 3000, true)
            return
        }

        saveAndClose()
    }

    @Command
    void onClose() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private void saveAndClose() {
        statoContribuenteService.saveStatoContribuente(statoContribuente)
        Events.postEvent(Events.ON_CLOSE, self, true)
    }

    private void initCreate(def codFiscale, def tipiTributo) {
        if (codFiscale == null) {
            throw new IllegalArgumentException("codFiscale cannot be null")
        }
        if (tipiTributo == null || tipiTributo.empty) {
            throw new IllegalArgumentException("tipiTributo must be a list with one element")
        }


        caricaTipiTributo(tipiTributo)
        caricaTipiStatoContribuente()

        this.tipiTributo = this.tipiTributo.findAll { competenzeService.tipoAbilitazioneUtente(it.tipoTributo) == 'A' }

        def newStatoContribuente = statoContribuenteService.createStatoContribuente([
                codFiscale           : codFiscale,
                tipoTributo          : this.tipiTributo.first(),
                tipoStatoContribuente: this.tipiStatoContribuente.first()
        ])
        statoContribuente = newStatoContribuente
    }

    private void initUpdate(def statoContribuente, def tipiTributo) {
        if (statoContribuente == null) {
            throw new IllegalArgumentException("statoContribuente cannot be null")
        }
        if (tipiTributo == null || tipiTributo.isEmpty()) {
            throw new IllegalArgumentException("tipiTributo must be a list with one element")
        }

        caricaTipiTributo(tipiTributo)
        caricaTipiStatoContribuente()

        this.statoContribuente = statoContribuenteService.getStatoContribuente(statoContribuente)
    }

    private void initRead(def statoContribuente) {
        if (statoContribuente == null) {
            throw new IllegalArgumentException("statoContribuente cannot be null")
        }

        readOnly = true
        tipiTributo = [statoContribuente.tipoTributo]
        tipiStatoContribuente = [statoContribuente.stato]

        this.statoContribuente = statoContribuenteService.getStatoContribuente(statoContribuente)
    }

    private void caricaTipiTributo(def tipiTributoSelected) {
        this.tipiTributo = OggettiCache.TIPI_TRIBUTO.valore.findAll {
            it.tipoTributo in tipiTributoSelected
        }.sort { it.tipoTributo }
    }

    private void caricaTipiStatoContribuente() {
        def tipiStatoContribuente = statoContribuenteService.listTipiStatoContribuente()
        if (tipiStatoContribuente.isEmpty()) {
            throw new IllegalArgumentException("Nessun tipo stato contribuente trovato")
        }
        this.tipiStatoContribuente = tipiStatoContribuente
    }

}
