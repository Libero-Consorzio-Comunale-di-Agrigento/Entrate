package archivio.dizionari


import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaOggettoTributoRicercaViewModel extends RicercaViewModel {

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.da, filtro.a, 'Tipo Oggetto')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.da || filtro.a || filtro.descrizione)
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
