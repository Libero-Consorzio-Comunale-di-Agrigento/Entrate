package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaTariffeDomesticheRicercaViewModel extends RicercaViewModel {

    // Services
    CommonService commonService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {

        super.init(w, filtro)

        this.titolo = 'Ricerca Tariffe Domestiche'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daNumeroFamiliari, filtro.aNumeroFamiliari, 'Numero Familiari')
        errors += validaEstremi(filtro.daTariffaQuotaFissa, filtro.aTariffaQuotaFissa, 'Tariffa Quota Fissa - Ab. Principale')
        errors += validaEstremi(filtro.daTariffaQuotaFissaNoAp, filtro.aTariffaQuotaFissaNoAp, 'Tariffa Quota Fissa - Altre utenze')
        errors += validaEstremi(filtro.daTariffaQuotaVariabile, filtro.aTariffaQuotaVariabile, 'Tariffa Quota Variabile - Ab. Principale')
        errors += validaEstremi(filtro.daTariffaQuotaVariabileNoAp, filtro.aTariffaQuotaVariabileNoAp, 'Tariffa Quota Variabile - Altre utenze')
        errors += validaEstremi(filtro.daSvuotamentiMinimi, filtro.aSvuotamentiMinimi, 'Svuotamenti Minimi')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daNumeroFamiliari || filtro.aNumeroFamiliari ||
                filtro.daTariffaQuotaFissa || filtro.aTariffaQuotaFissa ||
                filtro.daTariffaQuotaVariabile || filtro.aTariffaQuotaVariabile ||
                filtro.daTariffaQuotaFissaNoAp || filtro.aTariffaQuotaFissaNoAp ||
                filtro.daTariffaQuotaVariabileNoAp || filtro.aTariffaQuotaVariabileNoAp ||
                filtro.daSvuotamentiMinimi || filtro.aSvuotamentiMinimi)
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
