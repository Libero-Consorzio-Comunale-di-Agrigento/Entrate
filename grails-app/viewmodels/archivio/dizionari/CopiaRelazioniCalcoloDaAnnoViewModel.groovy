package archivio.dizionari


import it.finmatica.tr4.RelazioneOggettoCalcolo
import it.finmatica.tr4.relazioniCalcolo.RelazioniCalcoloService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zk.ui.util.Clients
import org.zkoss.zul.Window

class CopiaRelazioniCalcoloDaAnnoViewModel {

    // Componenti
    Window self

    // Services
    RelazioniCalcoloService relazioniCalcoloService


    // Comuni
    def annoSelezionato
    def listaAnni
    def annoDaDuplicare
    def tipoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") def ann,
         @ExecutionArgParam("tipoTributo") def tt) {

        this.self = w

        this.annoSelezionato = ann
        this.tipoTributo = tt
        this.listaAnni = relazioniCalcoloService.getListaAnniDuplicaDaAnno(tipoTributo)
        this.annoDaDuplicare = this.listaAnni[0]

    }

    @Command
    onOk() {

        def relazioniDaAnno = relazioniCalcoloService.getListaRelazioniCalcolo(tipoTributo, annoDaDuplicare, null)

        def categorieCatastoDaAnno = relazioniDaAnno.categoriaCatasto.unique()
        def missingCategorieCatasto = relazioniCalcoloService.getMissingCategorieCatastoForAnno(categorieCatastoDaAnno, annoSelezionato)
        if (!missingCategorieCatasto.empty) {
            def message = "Moltiplicatori mancanti su Anno $annoSelezionato"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 3000, true)
            return
        }

        def tipiAliquoteDaAnno = relazioniDaAnno.tipoAliquota.unique()
        def missingTipiAliquote = relazioniCalcoloService.getMissingTipiAliquotaForAnno(tipiAliquoteDaAnno, annoSelezionato)
        if (!missingTipiAliquote.empty) {
            def invalidTipiAliquoteDescription = missingTipiAliquote.collect { "$it.tipoAliquota - $it.descrizione" }
            def message = "Aliquote mancanti su Anno $annoSelezionato e Tipi Aliquota:\n${invalidTipiAliquoteDescription.join('\n')}"
            Clients.showNotification(message, Clients.NOTIFICATION_TYPE_ERROR, null, "before_center", 5000, true)
            return
        }

        relazioniDaAnno.each {
            creaESalvaClone(it)
        }

        Events.postEvent(Events.ON_CLOSE, self, [anno: annoDaDuplicare])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    private def creaESalvaClone(def relazione) {

        def cloneRelazione = new RelazioneOggettoCalcolo()
        cloneRelazione.categoriaCatasto = relazione.categoriaCatasto
        cloneRelazione.anno = annoSelezionato as Short
        cloneRelazione.tipoOggetto = relazione.tipoOggetto
        cloneRelazione.tipoAliquota = relazione.tipoAliquota

        relazioniCalcoloService.salvaRelazioneCalcolo(cloneRelazione)
    }
}
