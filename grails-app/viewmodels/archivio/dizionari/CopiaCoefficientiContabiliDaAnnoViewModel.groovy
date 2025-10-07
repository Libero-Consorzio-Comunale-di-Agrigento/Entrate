package archivio.dizionari


import it.finmatica.tr4.coefficientiContabili.CoefficientiContabiliService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCacheMap
import it.finmatica.tr4.dto.CoefficientiContabiliDTO
import it.finmatica.tr4.moltiplicatori.MoltiplicatoriService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class CopiaCoefficientiContabiliDaAnnoViewModel {

    // Componenti
    Window self

    // Services
    CommonService commonService
    MoltiplicatoriService moltiplicatoriService
    CoefficientiContabiliService coefficientiContabiliService
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
        this.listaAnni = coefficientiContabiliService.getListaAnniDuplicaDaAnno()
        this.annoDaDuplicare = this.listaAnni[0]

    }

    // Eventi interfaccia

    @Command
    onOk() {

        def coefficientiContabiliDaAnno = coefficientiContabiliService.getListaCoefficientiContabili([anno: annoDaDuplicare])

        coefficientiContabiliDaAnno.each {
            creaESalvaClone(it)
        }

        Events.postEvent(Events.ON_CLOSE, self, [anno: annoDaDuplicare])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    private def creaESalvaClone(def coefficienteContabile) {

        def cloneCoefficienteContabile = new CoefficientiContabiliDTO()
        cloneCoefficienteContabile.coeff = coefficienteContabile.coeff
        cloneCoefficienteContabile.annoCoeff = coefficienteContabile.annoCoeff
        cloneCoefficienteContabile.anno = annoSelezionato as Short

        coefficientiContabiliService.salvaCoefficienteContabile(cloneCoefficienteContabile)

    }
}
