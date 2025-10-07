package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class CoefficientiContabiliRicercaViewModel extends RicercaViewModel {

    // Services
    CommonService commonService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Coefficienti Contabili'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daAnnoCoeff, filtro.aAnnoCoeff, 'Anno Coefficiente')
        errors += validaEstremi(filtro.daCoeff, filtro.aCoeff, 'Coefficiente')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daAnnoCoeff || filtro.aAnnoCoeff ||
                filtro.daCoeff || filtro.aCoeff)
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
