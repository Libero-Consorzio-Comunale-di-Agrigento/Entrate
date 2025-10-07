package archivio.dizionari


import it.finmatica.tr4.dto.TariffaDomesticaDTO
import it.finmatica.tr4.tariffeDomestiche.TariffeDomesticheService
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class CopiaTariffeDomesticheDaAnnoViewModel {

    // Componenti
    Window self

    // Services
    TariffeDomesticheService tariffeDomesticheService


    // Comuni
    def annoSelezionato
    def listaAnni
    def annoDaDuplicare

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") def ann) {

        this.self = w

        this.annoSelezionato = ann
        this.listaAnni = tariffeDomesticheService.getListaAnniDuplicaDaAnno()
        this.annoDaDuplicare = this.listaAnni[0]

    }

    // Eventi interfaccia

    @Command
    onOk() {

        def coefficientiDomesticiDaAnno = tariffeDomesticheService.getListaTariffeDomestiche([anno: annoDaDuplicare])

        coefficientiDomesticiDaAnno.each {
            creaESalvaClone(it)
        }

        Events.postEvent(Events.ON_CLOSE, self, [anno: annoDaDuplicare])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    private def creaESalvaClone(def tariffaDomestica) {

        def cloneTariffaDomestica = new TariffaDomesticaDTO()

        cloneTariffaDomestica.anno = annoSelezionato as Short
        cloneTariffaDomestica.numeroFamiliari = tariffaDomestica.numeroFamiliari
        cloneTariffaDomestica.tariffaQuotaFissa = tariffaDomestica.tariffaQuotaFissa
        cloneTariffaDomestica.tariffaQuotaVariabile = tariffaDomestica.tariffaQuotaVariabile
        cloneTariffaDomestica.tariffaQuotaFissaNoAp = tariffaDomestica.tariffaQuotaFissaNoAp
        cloneTariffaDomestica.tariffaQuotaVariabileNoAp = tariffaDomestica.tariffaQuotaVariabileNoAp
        cloneTariffaDomestica.svuotamentiMinimi = tariffaDomestica.svuotamentiMinimi

        tariffeDomesticheService.salvaTariffaDomestica(cloneTariffaDomestica)
    }
}
