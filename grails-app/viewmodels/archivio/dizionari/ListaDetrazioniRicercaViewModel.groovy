package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaDetrazioniRicercaViewModel extends RicercaViewModel {

    // Services
    CommonService commonService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.titolo = 'Ricerca Detrazioni'
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daDetrazione, filtro.aDetrazione, 'Detrazione')
        errors += validaEstremi(filtro.daDetrazioneBase, filtro.aDetrazioneBase, 'Detrazione base')
        errors += validaEstremi(filtro.daDetrazioneFiglio, filtro.aDetrazioneFiglio, 'Detrazione figlio')
        errors += validaEstremi(filtro.daDetrazioneMaxFigli, filtro.aDetrazioneMaxFigli, 'Detrazione max figli')
        errors += validaEstremi(filtro.daAnno, filtro.aAnno, 'Anno')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daDetrazione || filtro.aDetrazione ||
                filtro.daDetrazioneBase || filtro.aDetrazioneBase ||
                filtro.daDetrazioneFiglio || filtro.aDetrazioneFiglio ||
                filtro.daDetrazioneMaxFigli || filtro.aDetrazioneMaxFigli ||
                filtro.daAnno || filtro.aAnno ||
                filtro.flagPertinenze != 'Tutti')
    }

    @Override
    def getFiltroIniziale() {
        return [flagPertinenze: 'Tutti']
    }
}
