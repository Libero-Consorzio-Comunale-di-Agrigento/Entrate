package archivio.dizionari

import it.finmatica.tr4.Moltiplicatore
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.moltiplicatori.MoltiplicatoriService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class CopiaMoltiplicatoriDaAnnoViewModel {

    // Componenti
    Window self

    // Services
    CommonService commonService
    MoltiplicatoriService moltiplicatoriService
    OggettiCacheMap oggettiCacheMap


    // Comuni
    def annoSelezionato
    def listaAnni
    def annoDaDuplicare

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") def ann) {

        this.self = w

        this.annoSelezionato = ann
        this.listaAnni = moltiplicatoriService.getListaAnniDuplicaDaAnno()
        this.annoDaDuplicare = this.listaAnni[0]

    }

    // Eventi interfaccia

    @Command
    onOk() {

        def moltiplicatoriDaAnno = moltiplicatoriService.getMoltiplicatoriDaAnno(annoDaDuplicare)

        moltiplicatoriDaAnno.each {
            creaESalvaClone(it)
        }

        oggettiCacheMap.refresh()

        Events.postEvent(Events.ON_CLOSE, self, [anno: annoDaDuplicare])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    private def creaESalvaClone(def moltiplicatore) {

        def cloneMoltiplicatore = new Moltiplicatore()
        cloneMoltiplicatore.categoriaCatasto = moltiplicatore.categoriaCatasto
        cloneMoltiplicatore.anno = annoSelezionato as Short
        cloneMoltiplicatore.moltiplicatore = moltiplicatore.moltiplicatore

        moltiplicatoriService.salvaMoltiplicatore(cloneMoltiplicatore)

    }
}
