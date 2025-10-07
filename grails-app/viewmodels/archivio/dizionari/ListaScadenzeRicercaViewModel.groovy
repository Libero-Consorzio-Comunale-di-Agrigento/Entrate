package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaScadenzeRicercaViewModel extends RicercaViewModel {

    // Services
    CommonService commonService


    def listRata = [
            [codice: null, descrizione: ""],
            [codice: 0, descrizione: "Unica"],
            [codice: 1, descrizione: "Prima"],
            [codice: 2, descrizione: "Seconda"],
            [codice: 3, descrizione: "Terza"],
            [codice: 4, descrizione: "Quarta"],
            [codice: 5, descrizione: "Quinta"],
            [codice: 6, descrizione: "Sesta"]
    ]
    def listTipo = [
            [codice: null, descrizione: ""],
            [codice: 'D', descrizione: "Dichiarazione"],
            [codice: 'V', descrizione: "Versamento"],
            [codice: 'R', descrizione: "Ravvedimento"],
            [codice: 'T', descrizione: "Terremoto"]
    ]
    def listVersamento = [
            [codice: null, descrizione: ""],
            [codice: 'A', descrizione: "Acconto"],
            [codice: 'S', descrizione: "Saldo"],
            [codice: 'U', descrizione: "Unico"]
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Scadenze'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.da, filtro.a, 'Scadenza')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.da ||
                filtro.a ||
                filtro.tipoVersamento ||
                filtro.rata ||
                filtro.tipoScadenza
        )
    }

    @Override
    def getFiltroIniziale() {
        return [:]
    }
}
