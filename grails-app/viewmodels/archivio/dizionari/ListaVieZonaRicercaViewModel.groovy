package archivio.dizionari

import it.finmatica.tr4.tributiminori.CanoneUnicoService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaVieZonaRicercaViewModel extends RicercaViewModel {

    CanoneUnicoService canoneUnicoService
    def listLato

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        listLato = canoneUnicoService.getListaLati()
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daCodice, filtro.aCodice, 'Codice')
        errors += validaEstremi(filtro.daSequenza, filtro.aSequenza, 'Sequenza')
        errors += validaEstremi(filtro.daDaNumCiv, filtro.aDaNumCiv, 'Da Civico')
        errors += validaEstremi(filtro.daANumCiv, filtro.aANumCiv, 'A Civico')
        errors += validaEstremi(filtro.daDaChilometro, filtro.aDaChilometro, 'Da KM')
        errors += validaEstremi(filtro.daAChilometro, filtro.aAChilometro, 'A KM')
        errors += validaEstremi(filtro.daDaAnno, filtro.aDaAnno, 'Da anno')
        errors += validaEstremi(filtro.daAAnno, filtro.aAAnno, 'A anno')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daCodice || filtro.aCodice ||
                filtro.daSequenza || filtro.aSequenza ||
                filtro.denomUff ||
                filtro.daDaNumCiv || filtro.aDaNumCiv ||
                filtro.daANumCiv || filtro.aANumCiv ||
                filtro.flagPari != 'Tutti' ||
                filtro.flagDispari != 'Tutti' ||
                filtro.daDaChilometro || filtro.aDaChilometro ||
                filtro.daAChilometro || filtro.aAChilometro ||
                filtro.lato ||
                filtro.daDaAnno || filtro.aDaAnno ||
                filtro.daAAnno || filtro.aAAnno
        )
    }

    @Override
    def getFiltroIniziale() {
        return [flagPari   : 'Tutti',
                flagDispari: 'Tutti']
    }
}
