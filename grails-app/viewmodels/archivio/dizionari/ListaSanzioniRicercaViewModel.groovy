package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.sanzioni.SanzioniService
import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.*
import org.zkoss.zul.Window

class ListaSanzioniRicercaViewModel extends RicercaViewModel {

    def tipoTributo
    def listaCodiciTributo
    def listaGruppiSanzione

    def labels

    SanzioniService sanzioniService
    CommonService commonService

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        filtro.radioFlagImposta = filtro.radioFlagImposta ?: 'Tutti'
        filtro.radioFlagInteressi = filtro.radioFlagInteressi ?: 'Tutti'
        filtro.radioFlagPenaPecuniaria = filtro.radioFlagPenaPecuniaria ?: 'Tutti'
        filtro.radioFlagCalcoloInteressi = filtro.radioFlagCalcoloInteressi ?: 'Tutti'

        this.labels = commonService.getLabelsProperties('dizionario')

        this.tipoTributo = tipoTributo

        this.listaCodiciTributo = [null]
        this.listaCodiciTributo.addAll(OggettiCache.CODICI_TRIBUTO.valore.findAll { it?.tipoTributo?.tipoTributo == this.tipoTributo })

        this.listaGruppiSanzione = [null]
        this.listaGruppiSanzione.addAll(sanzioniService.getListaGruppiSanzione())
    }

    @Override
    @Command
    svuotaFiltri() {

        def anno = filtro.anno

        filtro = [:]

        filtro.anno = anno

        filtro.radioFlagImposta = 'Tutti'
        filtro.radioFlagInteressi =  'Tutti'
        filtro.radioFlagPenaPecuniaria = 'Tutti'
        filtro.radioFlagCalcoloInteressi = 'Tutti'

        BindUtils.postNotifyChange(null, null, this, "filtro")
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daCodice, filtro.aCodice, 'Codice')
        errors += validaEstremi(filtro.daPercentuale, filtro.aPercentuale, 'Percentuale')
        errors += validaEstremi(filtro.daSanzione, filtro.aSanzione, 'Sanzione')
        errors += validaEstremi(filtro.daSanzioneMinima, filtro.aSanzioneMinima, 'Sanzione Minima')
        errors += validaEstremi(filtro.daRiduzione, filtro.aRiduzione, 'Riduzione')
        errors += validaEstremi(filtro.daRiduzione2, filtro.aRiduzione2, 'Riduzione 2')
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daCodice || filtro.aCodice ||
                filtro.descrizione ||
                filtro.daPercentuale || filtro.aPercentuale ||
                filtro.daSanzione || filtro.aSanzione ||
                filtro.daSanzioneMinima || filtro.aSanzioneMinima ||
                filtro.daDataInizio || filtro.aDataInizio ||
                filtro.daDataFine || filtro.aDataFine ||
                filtro.daRiduzione || filtro.aRiduzione ||
                filtro.daRiduzione2 || filtro.aRiduzione2 ||
                filtro.flagImposta != null ||
                filtro.flagInteressi != null ||
                filtro.flagPenaPecuniaria != null ||
                filtro.flagCalcoloInteressi != null ||
                filtro.codiceTributo ||
                filtro.codTributoF24 ||
                filtro.gruppoSanzione
        )
    }

}
