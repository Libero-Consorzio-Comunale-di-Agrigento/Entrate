package archivio.dizionari


import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaUtilizziRicercaViewModel extends RicercaViewModel {

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w,filtro)

        this.titolo = 'Ricerca Utilizzi'
    }

    @Override
    String getErroriFiltro(){
        String errors = ""
        errors += validaEstremi(filtro.daUtilizzo, filtro.aUtilizzo, 'Utilizzo')
        return errors
    }

    @Override
    boolean isFiltroAttivo(){
        return ( filtro.daUtilizzo || filtro.daUtilizzo || filtro.descrizione)
    }

    @Override
    def getFiltroIniziale(){
        return [:]
    }
}
