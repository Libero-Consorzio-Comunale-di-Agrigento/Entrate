package archivio.dizionari

import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.Moltiplicatore
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.moltiplicatori.MoltiplicatoriService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioMoltiplicatoreViewModel {

    static enum TipoOperazione {
        INSERIMENTO, MODIFICA, CLONAZIONE, VISUALIZZAZIONE
    }


    // Componenti
    Window self

    OggettiCacheMap oggettiCacheMap

    // Services
    MoltiplicatoriService moltiplicatoriService
    CommonService commonService

    // Comuni
    def moltiplicatoreSelezionato
    def tipoOperazione
    def listaCategorieCatasto
    def annoSelezionato
    def labels


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("moltiplicatoreSelezionato") def ms,
         @ExecutionArgParam("tipoOperazione") def to,
         @ExecutionArgParam("anno") def ann) {

        this.self = w

        this.tipoOperazione = to
        this.annoSelezionato = ann

        initMoltiplicatore(ms)

        this.listaCategorieCatasto = moltiplicatoriService.getCategorieCatasto()

        labels = commonService.getLabelsProperties('dizionario')

    }

    // Eventi interfaccia
    @Command
    onSalva() {

        // Controllo valori input
        if (moltiplicatoreSelezionato.categoriaCatasto?.categoriaCatasto == null ||
                (moltiplicatoreSelezionato.moltiplicatore == null || moltiplicatoreSelezionato.moltiplicatore <= 0)) {

            def messaggio = "I campi Categoria Catasto e Moltiplicatore sono obbligatori!\n" +
                    "Inoltre il Moltiplicatore deve essere un valore positivo"
            Clients.showNotification(messaggio, Clients.NOTIFICATION_TYPE_WARNING, null, "middle_center", 5000, true)
            return
        }

        if (tipoOperazione == TipoOperazione.CLONAZIONE || tipoOperazione == TipoOperazione.INSERIMENTO) {

            // Controllo se esiste già un moltiplicatore con lo stesso id (anno-categoriaCatasto)
            if (moltiplicatoriService.existsMoltiplicatore(moltiplicatoreSelezionato)) {
                String unformatted = labels.get('dizionario.notifica.esistente')
                def message = String.format(unformatted,
                        'un Moltiplicatore',
                        "questa Categoria Catastale")

                Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)
                return
            }
        }

        moltiplicatoriService.salvaMoltiplicatore(moltiplicatoreSelezionato)
        oggettiCacheMap.refresh()

        Events.postEvent(Events.ON_CLOSE, self, [salvataggio: true])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }


    private def initMoltiplicatore(def moltiplicatore) {

        if (tipoOperazione == TipoOperazione.INSERIMENTO) {

            def newMoltiplicatore = new Moltiplicatore()
            newMoltiplicatore.categoriaCatasto = new CategoriaCatasto()
            newMoltiplicatore.anno = annoSelezionato as short

            this.moltiplicatoreSelezionato = newMoltiplicatore

        } else {
            this.moltiplicatoreSelezionato = moltiplicatore
        }

    }

}