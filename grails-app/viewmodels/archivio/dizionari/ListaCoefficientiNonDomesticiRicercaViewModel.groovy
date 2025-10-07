package archivio.dizionari


import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaCoefficientiNonDomesticiRicercaViewModel extends archivio.dizionari.RicercaViewModel {

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Coefficienti Non Domestici'
    }

    @Override
    String getErroriFiltro() {
        String errors = ''

        errors += validaEstremi(filtro.daCategoria, filtro.aCategoria, 'Categoria')
        errors += validaEstremi(filtro.daCoefficientePotenziale, filtro.aCoefficientePotenziale, 'Coefficiente Potenziale')
        errors += validaEstremi(filtro.daCoefficienteProduzione, filtro.aCoefficienteProduzione, 'Coefficiente Produzione')

        return errors
    }

    @Override
    boolean isFiltroAttivo() {

        return (filtro.daCategoria || filtro.aCategoria
                || filtro.daCoefficientePotenziale || filtro.aCoefficientePotenziale
                || filtro.daCoefficienteProduzione || filtro.aCoefficienteProduzione
        )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }

}
