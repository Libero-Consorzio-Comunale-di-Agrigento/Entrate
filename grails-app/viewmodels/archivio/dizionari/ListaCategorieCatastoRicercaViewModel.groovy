package archivio.dizionari

import it.finmatica.tr4.categorieCatasto.CategorieCatastoService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaCategorieCatastoRicercaViewModel extends RicercaViewModel {

    def tipoTributo

    def tipiTrattamento

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro,
         @ExecutionArgParam("tipoTributo") def tipoTributo) {
        super.init(w, filtro)

        this.tipoTributo = tipoTributo

        this.titolo = 'Ricerca Categorie Catasto'

        this.tipiTrattamento = CategorieCatastoService.TIPI_TRATTAMENTO
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.categoriaCatasto ||
                filtro.descrizione ||
                filtro.flagReale != 'Tutti' ||
                filtro.eccezione)
    }

    @Override
    def getFiltroIniziale() {
        return [flagReale:'Tutti']
    }
}