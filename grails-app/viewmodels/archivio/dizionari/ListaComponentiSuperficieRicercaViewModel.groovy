package archivio.dizionari


import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaComponentiSuperficieRicercaViewModel extends archivio.dizionari.RicercaViewModel {

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Componenti Superficie'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daAnno, filtro.aAnno, 'Anno')
        errors += validaEstremi(filtro.daNumeroFamiliari, filtro.aNumeroFamiliari, 'Numero Familiari')
        errors += validaEstremi(filtro.daDaConsistenza, filtro.aDaConsistenza, 'Da Consistenza')
        errors += validaEstremi(filtro.daaConsistenza, filtro.aaConsistenza, 'A Consistenza')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daAnno || filtro.aAnno
                || filtro.daNumeroFamiliari || filtro.aNumeroFamiliari
                || filtro.daDaConsistenza || filtro.aDaConsistenza
                || filtro.daaConsistenza || filtro.aaConsistenza
        )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
