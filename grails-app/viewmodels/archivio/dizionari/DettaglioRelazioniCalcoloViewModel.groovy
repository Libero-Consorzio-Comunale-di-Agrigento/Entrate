package archivio.dizionari

import it.finmatica.tr4.RelazioneOggettoCalcolo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.relazioniCalcolo.RelazioniCalcoloService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class DettaglioRelazioniCalcoloViewModel {

    // Services
    RelazioniCalcoloService relazioniCalcoloService
    CommonService commonService


    // Componenti
    Window self

    // Comuni
    def relazione
    def modifica
    def tipoTributo
    def anno

    def listaTipiOggetto
    def listaCategorieCatasto
    def listaTipiAliquota

    def labels


    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tt,
         @ExecutionArgParam("anno") def an,
         @ExecutionArgParam("relazione") def rl,
         @ExecutionArgParam("modifica") def md) {

        this.self = w

        this.tipoTributo = tt
        this.relazione = rl ?: new RelazioneOggettoCalcolo()
        this.modifica = md
        this.anno = an

        this.listaTipiOggetto = relazioniCalcoloService.getListaTipiOggetto(tipoTributo)
        this.listaCategorieCatasto = [null] + relazioniCalcoloService.getListaCategoriaCatasto(anno)
        this.listaTipiAliquota = relazioniCalcoloService.getListaTipiAliquota(tipoTributo, anno)

        this.labels = commonService.getLabelsProperties('dizionario')

    }

    @Command
    onSalva() {

        relazione.anno = anno

        def errori = controllaParametri()

        if (!errori.empty) {
            Clients.showNotification(errori.join("\n"), Clients.NOTIFICATION_TYPE_WARNING, self, "before_center", 3000, true)
            return
        }

        if (relazioniCalcoloService.existsRelazioneCalcolo(relazione)) {
            String unformatted = labels.get('dizionario.notifica.esistente')
            def message = String.format(unformatted, 'una Relazione Calcolo', 'questo Tipo Oggetto, Categoria Catasto e Tipo Aliquota ')

            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, self, "middle_center", 3000, true)

            return
        }

        Events.postEvent(Events.ON_CLOSE, self, [relazione: relazione])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, null)
    }


    private def controllaParametri() {

        def errori = []

        if (relazione.tipoOggetto == null) {
            errori << "Il Tipo Oggetto è obbligatorio"
        }
        if (relazione.tipoAliquota == null) {
            errori << "Il Tipo Aliquota è obbligatorio"
        }

        return errori
    }

}
