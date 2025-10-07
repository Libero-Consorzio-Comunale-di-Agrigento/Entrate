package sportello.contribuenti

import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.commons.TipoPratica
import it.finmatica.tr4.contribuenti.ContribuentiService
import it.finmatica.tr4.dto.ContribuenteDTO
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class OggettiDaDatiMetriciViewModel {

    def self

    // Service
    ContribuentiService contribuentiService

    // Model
    ContribuenteDTO contribuente
    short anno
    List listaDatiMetrici = []
    def datoMetricoSelezionato
    List<OggettiDaDatiMetriciDettaglioQuadroViewModel> listaDettagli = []

    def dettaglioAperto = null
    Map oggettiDaGenerare = [:]
    def immobili

    def tipoPratica = 'D'

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("contribuente") ContribuenteDTO contribuente,
         @ExecutionArgParam("anno") short anno,
         @ExecutionArgParam("immobili") def immobili
    ) {

        this.self = w
        this.contribuente = contribuente
        this.anno = anno
        this.immobili = immobili

        this.listaDatiMetrici = contribuentiService
                .caricaDatiMetriciNonPresentiInArchivio(contribuente.codFiscale, immobili, anno)

    }

    @Command
    def onOpenDetail(@BindingParam("rowNum") def rowNum) {
        dettaglioAperto = recuperaDmDaRowNum(rowNum)
    }

    @GlobalCommand
    def aggiungiDettaglio(@BindingParam("dettaglio") OggettiDaDatiMetriciDettaglioQuadroViewModel dettaglio) {
        listaDettagli << dettaglio
        dettaglio.inizializza(anno, dettaglioAperto)
        dettaglioAperto = null
    }

    @GlobalCommand
    def ogettoDaGenerare(@BindingParam("rowNum") BigDecimal rowNum, @BindingParam("aggiungi") Boolean aggiungi) {

        oggettiDaGenerare[rowNum] = aggiungi
        BindUtils.postNotifyChange(null, null, this, "oggettiDaGenerare")
    }


    @Command
    def onInserisciOggetti() {
        def valida = []

        def dmDaProcessare = listaDettagli.findAll {
            it.dettaglioAssociato.rowNum in
                    oggettiDaGenerare.findAll { it.value }.collect { it.key }
        }

        if (dmDaProcessare.empty) {
            Clients.showNotification("Nessun oggetto selezionato per la creazione.", Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            return
        }

        dmDaProcessare.each {
            valida += it.valida()
            if (valida.size() > 0) {
                valida.add(0, "Impossibile aggiungere l'immobile [${it.dettaglioAssociato.immobile}]:")
                Clients.showNotification(valida.join("\n"), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            }
        }

        if (valida.size() > 0) {
            return
        }

        // Inserimento oggetti da dati metrici

        def oggettiDaInserire = []
        dmDaProcessare.each {
            oggettiDaInserire << (recuperaDmDaRowNum(it.rowNum) + it.properties)
        }

        try {
            def pratica = contribuentiService.creaOggettiTarsuDaDatiMetrici(contribuente, anno, oggettiDaInserire, tipoPratica)
            Events.postEvent(Events.ON_CLOSE, self, [dichiarazioneCreata: true, pratica: pratica])
        } catch (Exception e) {
            if (e instanceof Application20999Error) {
                Clients.showNotification(e.getMessage(), Clients.NOTIFICATION_TYPE_ERROR, self, "before_center", 5000, true)
            } else {
                throw e
            }
        }


    }

    @Command
    def onCambiaAnno() {
        listaDatiMetrici = contribuentiService
                .caricaDatiMetriciNonPresentiInArchivio(contribuente.codFiscale, immobili, anno)

        BindUtils.postNotifyChange(null, null, this, "listaDatiMetrici")
    }

    @Command
    def onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }

    private recuperaDmDaRowNum(def rowNum) {
        return listaDatiMetrici.find {
            it.rowNum == rowNum
        }
    }
}
