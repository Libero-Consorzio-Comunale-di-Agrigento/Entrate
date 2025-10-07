package archivio.dizionari

import it.finmatica.tr4.commons.CommonService
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaAliquoteRicercaViewModel extends RicercaViewModel {

    // Services
    CommonService commonService

    Properties labels
    def tipoTributo

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro,
         @ExecutionArgParam("tipoTributo") def tipoTributo) {
        super.init(w, filtro)

        this.tipoTributo = tipoTributo
        this.labels = commonService.getLabelsProperties('dizionario')
    }

    @Override
    String getErroriFiltro() {
        String errors = ""
        errors += validaEstremi(filtro.daAliquota, filtro.aAliquota, labels.get('dizionario.aliquote.label.estesa.aliquota'))
        errors += validaEstremi(filtro.daAliquotaBase, filtro.aAliquotaBase, labels.get('dizionario.aliquote.label.estesa.aliquotaBase'))
        errors += validaEstremi(filtro.daAliquotaErariale, filtro.aAliquotaErariale, labels.get('dizionario.aliquote.label.estesa.aliquotaErariale'))
        errors += validaEstremi(filtro.daAliquotaStandard, filtro.aAliquotaStandard, labels.get('dizionario.aliquote.label.estesa.aliquotaStd'))
        errors += validaEstremi(filtro.daTipoAliquota, filtro.aTipoAliquota, labels.get('dizionario.aliquote.label.estesa.tipoAliquota'))
        errors += validaEstremi(filtro.daPercentualeSaldo, filtro.aPercentualeSaldo, labels.get('dizionario.aliquote.label.estesa.percSaldo'))
        errors += validaEstremi(filtro.daPercentualeOccupante, filtro.aPercentualeOccupante, labels.get('dizionario.aliquote.label.estesa.percOccupante'))
        errors += validaEstremi(filtro.daAnno, filtro.aAnno, labels.get('dizionario.aliquote.label.estesa.anno'))
        errors += validaEstremi(filtro.daRiduzioneImposta, filtro.aRiduzioneImposta, labels.get('dizionario.aliquote.label.estesa.riduzioneImposta'))
        errors += validaEstremi(filtro.daScadenzaMiniImu, filtro.aScadenzaMiniImu, labels.get('dizionario.aliquote.label.estesa.scadenzaMiniImu'))
        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.daAliquota || filtro.aAliquota ||
                filtro.daAliquotaBase || filtro.aAliquotaBase ||
                filtro.daAliquotaErariale || filtro.aAliquotaErariale ||
                filtro.daAliquotaStandard || filtro.aAliquotaStandard ||
                filtro.daTipoAliquota || filtro.aTipoAliquota ||
                filtro.daPercentualeSaldo || filtro.aPercentualeSaldo ||
                filtro.daPercentualeOccupante || filtro.aPercentualeOccupante ||
                filtro.countAlca != 'Tutti' ||
                filtro.abPrincipale != 'Tutti' ||
                filtro.pertinenze != 'Tutti' ||
                filtro.daAnno || filtro.aAnno ||
                filtro.descrizione ||
                filtro.riduzione != 'Tutti' ||
                filtro.daRiduzioneImposta ||
                filtro.aRiduzioneImposta ||
                filtro.note ||
                filtro.daScadenzaMiniImu ||
                filtro.aScadenzaMiniImu ||
                filtro.fabbricatiMerce != 'Tutti')
    }

    @Override
    def getFiltroIniziale() {
        return [countAlca      : 'Tutti',
                abPrincipale   : 'Tutti',
                pertinenze     : 'Tutti',
                riduzione      : 'Tutti',
                fabbricatiMerce: 'Tutti']
    }
}
