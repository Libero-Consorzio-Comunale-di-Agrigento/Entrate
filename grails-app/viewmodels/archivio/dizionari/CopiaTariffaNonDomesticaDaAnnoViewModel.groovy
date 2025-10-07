package archivio.dizionari


import it.finmatica.tr4.coefficientiNonDomestici.CoefficientiNonDomesticiService
import it.finmatica.tr4.dto.CoefficientiDomesticiDTO
import it.finmatica.tr4.dto.CoefficientiNonDomesticiDTO
import it.finmatica.tr4.dto.TariffaNonDomesticaDTO
import it.finmatica.tr4.tariffeNonDomestiche.TariffeNonDomesticheService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class CopiaTariffaNonDomesticaDaAnnoViewModel {

    // Componenti
    Window self

    // Services
    TariffeNonDomesticheService tariffeNonDomesticheService


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
        this.listaAnni = tariffeNonDomesticheService.getListaAnniDuplicabiliByCodiceTributo(codiceTributo)
        this.annoDaDuplicare = this.listaAnni[0]

    }

    // Eventi interfaccia

    @Command
    onOk() {
        def criteria = [
                'annoTributo': annoDaDuplicare,
                'codiceTributo' : codiceTributo
        ]

        tariffeNonDomesticheService.getByCriteria( criteria,false).each {
            TariffaNonDomesticaDTO elem ->
                def clone = elem.clone()
                clone.anno = annoSelezionato
                tariffeNonDomesticheService.salva(clone)
        }

        Events.postEvent(Events.ON_CLOSE, self, [anno: annoDaDuplicare])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

}
