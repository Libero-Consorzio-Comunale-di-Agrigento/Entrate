package archivio.dizionari


import it.finmatica.tr4.dto.TariffaDTO
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaTariffeRicercaViewModel extends RicercaViewModel {

    def tipoTributo

    // Comuni
    def listCodiciTributo = []
    def listTipologie = [
            [codice: null, descrizione: ""],
            [codice: TariffaDTO.TAR_TIPOLOGIA_PERMANENTE, descrizione: "Permanente"],
            [codice: TariffaDTO.TAR_TIPOLOGIA_TEMPORANEA, descrizione: "Temporaneo"],
            [codice: TariffaDTO.TAR_TIPOLOGIA_ESENZIONE, descrizione: "Esenzione"],
    ]

    def listTipologieCalcolo = [
            [codice: null, descrizione: ""],
            [codice: TariffaDTO.TAR_CALCOLO_LIMITE_CONSISTENZA, descrizione: "Consistenza"],
            [codice: TariffaDTO.TAR_CALCOLO_LIMITE_GIORNI, descrizione: "Giornate"]
    ]

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("tipoTributo") def tipoTributo,
         @ExecutionArgParam("filtro") def filtro) {
        super.init(w, filtro)

        this.tipoTributo = tipoTributo

//        this.filtroRuoloSelected = 'Tutti'

        this.titolo = 'Ricerca Tariffe'
    }

    @Override
    String getErroriFiltro() {
        boolean isCUNI = this.tipoTributo.tipoTributo == 'CUNI'

        String errors = ""
        errors += validaEstremi(filtro.daTipoTariffa, filtro.aTipoTariffa, 'Tip.Tariffa')

        errors += validaEstremi(filtro.daTariffaQuotaFissa, filtro.aTariffaQuotaFissa, isCUNI ? 'Base' : 'Tar.Quota Fissa')
        errors += validaEstremi(filtro.daPercRiduzione, filtro.aPercRiduzione, isCUNI ? '% Riduz. o Magg.' : '%Rid.M.T.')
        errors += validaEstremi(filtro.daTariffa, filtro.aTariffa, isCUNI ? 'Coeff.' : 'Tariffa')
        errors += validaEstremi(filtro.daTariffaSuperiore, filtro.aTariffaSuperiore, isCUNI ? 'Coeff.Sup.' : 'Tar.Sup.')

        errors += validaEstremi(filtro.daRiduzioneQuotaFissa, filtro.aRiduzioneQuotaFissa, '%Rid.QF')
        errors += validaEstremi(filtro.daRiduzioneQuotaFissaVariabile, filtro.aRiduzioneQuotaFissaVariabile, '%Rid.QV')

        errors += validaEstremi(filtro.daLimite, filtro.aLimite, 'Limite')

        errors += validaEstremi(filtro.daTariffaPrec, filtro.aTariffaPrec, 'Tar.Prec.')
        errors += validaEstremi(filtro.daLimitePrec, filtro.aLimitePrec, 'Lim.Prec.')
        errors += validaEstremi(filtro.daTariffaSuperiorePrec, filtro.aTariffaSuperiorePrec, 'Tar.Sup.Prec.')

        return errors
    }

    @Override
    boolean isFiltroAttivo() {
        return (filtro.descrizione ||
                filtro.tipologiaTariffa?.codice ||
                filtro.daTipoTariffa != null || filtro.aTipoTariffa != null ||
                filtro.daTariffaQuotaFissa || filtro.aTariffaQuotaFissa ||
                filtro.daPercRiduzione || filtro.aPercRiduzione ||
                filtro.daTariffa || filtro.aTariffa ||
                filtro.daLimite || filtro.aLimite ||
                filtro.daTariffaSuperiore || filtro.aTariffaSuperiore ||
                filtro.daRiduzioneQuotaFissa || filtro.aRiduzioneQuotaFissa ||
                filtro.daRiduzioneQuotaFissaVariabile || filtro.aRiduzioneQuotaFissaVariabile ||
                filtro.daTariffaPrec || filtro.aTariffaPrec ||
                filtro.daLimitePrec || filtro.aLimitePrec ||
                filtro.daTariffaSuperiorePrec || filtro.aTariffaSuperiorePrec ||
                filtro.flagRuolo != 'Tutti' ||
                filtro.flagTariffaBase != 'Tutti' ||
                filtro.flagNoDepag != 'Tutti' ||
                filtro.tipologiaCalcolo)
    }

    @Override
    def getFiltroIniziale() {
        return [flagRuolo       : 'Tutti',
                flagTariffaBase : 'Tutti',
                flagNoDepag     : 'Tutti']
    }
}
