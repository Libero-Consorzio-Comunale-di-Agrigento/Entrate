package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaInteressiRicercaViewModel extends RicercaViewModel {

    // Services
    CommonService commonService

    def listTipiInteresse = [
            [codice: null, descrizione: ''],
            [codice: 'G', descrizione: 'Giornaliero'],
            [codice: 'L', descrizione: 'Legale'],
            [codice: 'S', descrizione: 'Semestrale'],
            [codice: 'R', descrizione: 'Rateazione'],
            [codice: 'D', descrizione: 'Dilazione'],
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Interessi'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daDataInizio, filtro.aDataInizio, 'Data Inizio')
        errors += validaEstremi(filtro.daDataFine, filtro.aDataFine, 'Data Fine')
        errors += validaEstremi(filtro.daAliquota, filtro.aAliquota, 'Aliquota')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daDataInizio || filtro.aDataInizio ||
                filtro.daDataFine || filtro.aDataFine ||
                filtro.daAliquota || filtro.aAliquota ||
                filtro.tipoInteresse?.codice
        )
    }

    @Override
    def getFiltroIniziale() {
        return [tipoInteresse: listTipiInteresse[0]]
    }
}
