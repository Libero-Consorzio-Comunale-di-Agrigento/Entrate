package archivio.dizionari

import it.finmatica.tr4.commons.TipoPratica
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaMotiviPraticaRicercaViewModel extends RicercaViewModel {

    Collection<TipoPratica> tipiPraticaAbilitati

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro,
         @ExecutionArgParam("tipiPraticaAbilitati") Collection<TipoPratica> tipiPraticaAbilitati) {
        super.init(w, filtro)

        this.tipiPraticaAbilitati = tipiPraticaAbilitati
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.da, filtro.a, 'Motivo Pratica')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.da || filtro.a || filtro.tipoPratica || filtro.motivo)
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
