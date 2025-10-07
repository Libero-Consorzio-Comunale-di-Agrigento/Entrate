package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class MoltiplicatoriRicercaViewModel extends RicercaViewModel {

    // Services
    CommonService commonService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Moltiplicatori'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.da, filtro.a, 'Moltiplicatore')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.da ||
                filtro.a ||
                filtro.categoriaCatasto ||
                filtro.descrizione
        )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
