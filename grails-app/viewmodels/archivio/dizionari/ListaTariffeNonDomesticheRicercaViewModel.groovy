package archivio.dizionari

import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaTariffeNonDomesticheRicercaViewModel extends RicercaViewModel {

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Tariffe Non Domestiche'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daCategoria, filtro.aCategoria, 'Categoria')
        errors += validaEstremi(filtro.daTariffaQuotaFissa, filtro.aTariffaQuotaFissa, 'Tariffa Quota Fissa')
        errors += validaEstremi(filtro.daTariffaQuotaVariabile, filtro.aTariffaQuotaVariabile, 'Tariffa Quota Variabile')
        errors += validaEstremi(filtro.daImportoMinimi, filtro.aImportoMinimi, 'Importo Minimi')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daCategoria != null || filtro.aCategoria != null ||
                filtro.daTariffaQuotaFissa != null || filtro.aTariffaQuotaFissa != null ||
                filtro.daTariffaQuotaVariabile != null || filtro.aTariffaQuotaVariabile != null ||
                filtro.daImportoMinimi != null || filtro.aImportoMinimi != null)
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
