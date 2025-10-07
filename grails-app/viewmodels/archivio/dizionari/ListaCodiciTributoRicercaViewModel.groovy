package archivio.dizionari


import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaCodiciTributoRicercaViewModel extends RicercaViewModel {

    def tipoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro,
         @ExecutionArgParam("tipoTributo") def tipoTributo) {
        super.init(w, filtro)

        this.tipoTributo = tipoTributo

        this.titolo = 'Ricerca Codici Tributo'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daCodice, filtro.aCodice, 'Codice')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daCodice || filtro.aCodice ||
                filtro.nome ||
                filtro.descrizione ||
                filtro.tributoPrecedente ||
                filtro.contoCorrente ||
                filtro.descrizioneCc ||
                filtro.flagStampaCc != 'Tutti' ||
                filtro.flagRuolo != 'Tutti' ||
                filtro.flagCalcoloInteressi != 'Tutti' ||
                filtro.codEntrata)
    }

    @Override
    def getFiltroIniziale() {
        return [
                flagStampaCc        : 'Tutti',
                flagRuolo           : 'Tutti',
                flagCalcoloInteressi: 'Tutti'
        ]
    }
}
