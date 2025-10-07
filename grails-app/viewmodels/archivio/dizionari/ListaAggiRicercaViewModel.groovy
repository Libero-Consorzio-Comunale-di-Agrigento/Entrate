package archivio.dizionari


import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaAggiRicercaViewModel extends RicercaViewModel {

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Aggi'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daDataInizio, filtro.aDataInizio, 'Data Inizio')
        errors += validaEstremi(filtro.daDataFine, filtro.aDataFine, 'Data Fine')
        errors += validaEstremi(filtro.daGiornoInizio, filtro.aGiornoInizio, 'Giorno Inizio')
        errors += validaEstremi(filtro.daGiornoFine, filtro.aGiornoFine, 'Giorno Fine')
        errors += validaEstremi(filtro.daAliquota, filtro.aAliquota, 'Aliquota')
        errors += validaEstremi(filtro.daImportoMassimo, filtro.aImportoMassimo, 'Importo Massimo')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daDataInizio || filtro.aDataInizio ||
                filtro.daDataFine || filtro.aDataFine ||
                filtro.daGiornoInizio || filtro.aGiornoInizio ||
                filtro.daGiornoFine || filtro.aGiornoFine ||
                filtro.daAliquota || filtro.aAliquota ||
                filtro.daImportoMassimo || filtro.aImportoMassimo
        )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
