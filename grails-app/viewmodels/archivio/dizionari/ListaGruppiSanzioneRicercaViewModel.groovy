package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaGruppiSanzioneRicercaViewModel extends RicercaViewModel {

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
        errors += validaEstremi(filtro.daGruppoSanzione, filtro.aGruppoSanzione, 'Codice')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daGruppoSanzione || filtro.aGruppoSanzione ||
                filtro.descrizione ||
                filtro.flagStampaTotale != null
        )
    }

    @Override
    def getFiltroIniziale() {
        return [
                radioFlagStampaTotale: 'Tutti',
        ]
    }
}
