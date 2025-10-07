package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaContenitoriRicercaViewModel extends RicercaViewModel {

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
        errors += validaEstremi(filtro.daCodice, filtro.aCodice, 'Codice')
        errors += validaEstremi(filtro.daCapienza, filtro.aCapienza, 'Capienza')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daCodice || filtro.aCodice ||
                filtro.descrizione ||
                filtro.unitaDiMisura ||
                filtro.daCapienza || filtro.aCapienza
        )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
