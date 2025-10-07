package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class CoefficientiDomesticiRicercaViewModel extends RicercaViewModel {

    // Services
    CommonService commonService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Coefficienti Domestici'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daNumeroFamiliari, filtro.aNumeroFamiliari, 'Numero Familiari')
        errors += validaEstremi(filtro.daCoeffAdattamento, filtro.aCoeffAdattamento, 'Coeff. Adattamento - Ab. Principale')
        errors += validaEstremi(filtro.daCoeffAdattamentoNoAp, filtro.aCoeffAdattamentoNoAp, 'Coeff. Adattamento - Altre utenze')
        errors += validaEstremi(filtro.daCoeffProduttivita, filtro.aCoeffProduttivita, 'Coeff. Produttività - Ab. Principale')
        errors += validaEstremi(filtro.daCoeffProduttivitaNoAp, filtro.aCoeffProduttivitaNoAp, 'Coeff. Produttività - Altre utenze')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daNumeroFamiliari || filtro.aNumeroFamiliari ||
                filtro.daCoeffAdattamento || filtro.aCoeffAdattamento ||
                filtro.daCoeffProduttivita || filtro.aCoeffProduttivita ||
                filtro.daCoeffAdattamentoNoAp || filtro.aCoeffAdattamentoNoAp ||
                filtro.daCoeffProduttivitaNoAp || filtro.aCoeffProduttivitaNoAp )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
