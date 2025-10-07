package archivio.dizionari


import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaZoneRicercaViewModel extends RicercaViewModel {

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Zone'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daCodice, filtro.aCodice, 'Codice')
        errors += validaEstremi(filtro.daDaAnno, filtro.aDaAnno, 'Da anno')
        errors += validaEstremi(filtro.daAAnno, filtro.aAAnno, 'A anno')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daDaAnno || filtro.aDaAnno ||
                filtro.daAAnno || filtro.aAAnno ||
                filtro.daCodice || filtro.aCodice ||
                filtro.denominazione
        )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
