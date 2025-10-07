package archivio.dizionari


import it.finmatica.tr4.coefficientiDomestici.CoefficientiDomesticiService
import it.finmatica.tr4.dto.CoefficientiDomesticiDTO
import org.zkoss.bind.annotation.*
import org.zkoss.zk.ui.event.Events
import org.zkoss.zul.Window

class CopiaCoefficientiDomesticiDaAnnoViewModel {

    // Componenti
    Window self

    // Services
    CoefficientiDomesticiService coefficientiDomesticiService


    // Comuni
    def annoSelezionato
    def listaAnni
    def annoDaDuplicare

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("anno") def ann) {

        this.self = w

        this.annoSelezionato = ann
        this.listaAnni = coefficientiDomesticiService.getListaAnniDuplicaDaAnno()
        this.annoDaDuplicare = this.listaAnni[0]

    }

    // Eventi interfaccia

    @Command
    onOk() {

        def coefficientiDomesticiDaAnno = coefficientiDomesticiService.getListaCoefficientiDomestici([anno: annoDaDuplicare])

        coefficientiDomesticiDaAnno.each {
            creaESalvaClone(it)
        }

        Events.postEvent(Events.ON_CLOSE, self, [anno: annoDaDuplicare])
    }

    @Command
    onChiudi() {
        Events.postEvent(Events.ON_CLOSE, self, [:])
    }

    private def creaESalvaClone(def coefficienteDomestico) {

        def cloneCoefficienteDomestico = new CoefficientiDomesticiDTO()
        cloneCoefficienteDomestico.anno = annoSelezionato as Short
        cloneCoefficienteDomestico.numeroFamiliari = coefficienteDomestico.numeroFamiliari
        cloneCoefficienteDomestico.coeffAdattamento = coefficienteDomestico.coeffAdattamento
        cloneCoefficienteDomestico.coeffProduttivita = coefficienteDomestico.coeffProduttivita
        cloneCoefficienteDomestico.coeffAdattamentoNoAp = coefficienteDomestico.coeffAdattamentoNoAp
        cloneCoefficienteDomestico.coeffProduttivitaNoAp = coefficienteDomestico.coeffProduttivitaNoAp


        coefficientiDomesticiService.salvaCoefficienteDomestico(cloneCoefficienteDomestico)

    }
}
