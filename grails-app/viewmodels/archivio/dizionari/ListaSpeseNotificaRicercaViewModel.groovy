package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.speseNotifica.SpeseNotificaService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaSpeseNotificaRicercaViewModel extends RicercaViewModel {

    CommonService commonService
    SpeseNotificaService speseNotificaService
    def labels
    def listaTipiNotifica

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.labels = commonService.getLabelsProperties('dizionario')
        this.listaTipiNotifica = [null] + speseNotificaService.getListaTipiNotifica()
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daImporto, filtro.aImporto, 'Importo')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.descrizione ||
                filtro.descrizioneBreve ||
                filtro.daImporto || filtro.aImporto ||
                filtro.tipoNotifica
        )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
