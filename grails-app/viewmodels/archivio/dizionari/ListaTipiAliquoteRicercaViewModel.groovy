package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaTipiAliquoteRicercaViewModel extends RicercaViewModel {

    // Services
    CommonService commonService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Tipi Aliquote'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.da, filtro.a, 'Tipo aliquota')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.da ||
                filtro.a ||
                filtro.descrizione)
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
