package archivio.dizionari


import it.finmatica.tr4.coefficientiNonDomestici.CoefficientiNonDomesticiService
import it.finmatica.tr4.dto.CoefficientiDomesticiDTO
import it.finmatica.tr4.dto.CoefficientiNonDomesticiDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class CopiaCoefficientiNonDomesticiDaAnnoViewModel {

    // Componenti
    Window self

    // Services
    CoefficientiNonDomesticiService coefficientiNonDomesticiService


    // Comuni
    def annoSelezionato
    def listaAnni
    def annoDaDuplicare
    def codiceTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") def anno,
         @ExecutionArgParam("codiceTributo") def codiceTributo) {

        this.self = w

        this.codiceTributo = codiceTributo
        this.annoSelezionato = anno
        this.listaAnni = coefficientiNonDomesticiService.getListaAnniDuplicabiliByCodiceTributo(codiceTributo)
        this.annoDaDuplicare = this.listaAnni[0]

    }

    // Eventi interfaccia

    @Command
    onOk() {
        def criteria = [
                'annoTributo': annoDaDuplicare,
                'codiceTributo' : codiceTributo
        ]

        coefficientiNonDomesticiService.getByCriteria( criteria,false).each {
            CoefficientiNonDomesticiDTO elem ->
                def clone = elem.clone()
                clone.anno = annoSelezionato
                coefficientiNonDomesticiService.salva(clone)
        }

        Events.postEvent(Events.ON_CLOSE, self, [anno: annoDaDuplicare])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

}
