package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaGruppiTributoRicercaViewModel extends RicercaViewModel {

    CommonService commonService
    def labels

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.labels = commonService.getLabelsProperties('dizionario')
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.gruppoTributo ||
                filtro.descrizione
        )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}