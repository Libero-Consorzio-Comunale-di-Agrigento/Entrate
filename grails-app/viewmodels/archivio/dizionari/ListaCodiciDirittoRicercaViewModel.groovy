package archivio.dizionari

import it.finmatica.tr4.codiciDiritto.CodiciDirittoService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaCodiciDirittoRicercaViewModel extends RicercaViewModel {

    def tipoTributo

    def tipiTrattamento

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro,
         @ExecutionArgParam("tipoTributo") def tipoTributo) {
        super.init(w, filtro)

        this.tipoTributo = tipoTributo

        this.titolo = 'Ricerca Codici Diritto'

        this.tipiTrattamento = [null] + CodiciDirittoService.TIPI_TRATTAMENTO
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.codDiritto ||
                filtro.daOrdinamento || filtro.aOrdinamento ||
                filtro.descrizione ||
                filtro.eccezione)
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}