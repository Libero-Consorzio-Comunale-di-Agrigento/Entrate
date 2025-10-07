package archivio.dizionari

import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.ExecutionArgParam
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaCarichiRicercaViewModel extends archivio.dizionari.RicercaViewModel {

    def listaModalita

    @Init
    init(@ContextParam(ContextType.COMPONENT) Window w,
         @ExecutionArgParam("filtro") def filtro,
         @ExecutionArgParam("listaModalita") def listaModalita) {

        super.init(w, filtro)

        this.listaModalita = listaModalita
        this.titolo = 'Ricerca Carichi'
    }

    @Override
    String getErroriFiltro() {
        return controllaParametri()
    }

    @Override
    boolean isFiltroAttivo() {

        return (filtro.daAnno != null || filtro.aAnno != null
                || filtro.daAddizionaleEca != null  || filtro.aAddizionaleEca != null
                || filtro.daMaggiorazioneEca != null  || filtro.aMaggiorazioneEca != null
                || filtro.daAddizionaleEca != null  || filtro.aAddizionaleEca != null
                || filtro.daAddizionalePro != null || filtro.aAddizionalePro != null
                || filtro.daNonDovutoPro != null  || filtro.aNonDovutoPro != null
                || filtro.daCommissioneCom != null  || filtro.aCommissioneCom != null
                || filtro.daTariffaDomestica != null  || filtro.aTariffaDomestica != null
                || filtro.daTariffaNonDomestica != null  || filtro.aTariffaNonDomestica != null
                || filtro.daAliquota != null  || filtro.aAliquota != null
                || filtro.daIvaFattura != null  || filtro.aIvaFattura != null
                || filtro.daCompensoMinimo != null  || filtro.aCompensoMinimo != null
                || filtro.daCompensoMassimo != null  || filtro.aCompensoMassimo != null
                || filtro.daPercCompenso != null  || filtro.aPercCompenso != null
                || filtro.daLimite != null  || filtro.aLimite != null
                || filtro.flagLordo != "T"
                || filtro.flagSanzioneAddP != "T"
                || filtro.flagSanzioneAddT != "T"
                || filtro.flagInteressiAdd != "T"
                || filtro.daMaggiorazioneTares != null  || filtro.aMaggiorazioneTares != null
                || filtro.daMesiCalcolo != null  || filtro.aMesiCalcolo != null
                || filtro.flagMaggAnno != "T"
                || filtro.modalitaFamiliari
                || filtro.flagNoTardivo != "T"
                || filtro.flagTariffeRuolo != "T"
                || filtro.rataPerequative != "X"
                || filtro.flagTariffaPuntuale != "T"
                || filtro.daCostoUnitario != null  || filtro.aCostoUnitario != null
        )
    }

    @Override
    def getFiltroIniziale() {
        return [
            flagLordo           : "T",
            flagSanzioneAddP    : "T",
            flagSanzioneAddT    : "T",
            flagInteressiAdd    : "T",
            flagMaggAnno        : "T",
            flagNoTardivo       : "T",
            flagTariffeRuolo    : "T",
            rataPerequative     : "X",
            flagTariffaPuntuale : "T"
        ]
    }

    private String controllaParametri() {
        String errors = ''

        errors += validaEstremi(filtro.daAnno, filtro.aAnno, 'Anno')
        errors += validaEstremi(filtro.daAddizionaleEca, filtro.aAddizionaleEca, 'Addizionale Eca')
        errors += validaEstremi(filtro.daMaggiorazioneEca, filtro.aMaggiorazioneEca, 'Maggiorazione Eca')
        errors += validaEstremi(filtro.daAddizionalePro, filtro.aAddizionalePro, 'Addizionale Pro')
        errors += validaEstremi(filtro.daNonDovutoPro, filtro.aNonDovutoPro, 'Non Dovuto Pro')
        errors += validaEstremi(filtro.daCommissioneCom, filtro.aCommissioneCom, 'Commissione Com')
        errors += validaEstremi(filtro.daTariffaDomestica, filtro.aTariffaDomestica, 'Tariffa Domestica')
        errors += validaEstremi(filtro.daTariffaNonDomestica, filtro.aTariffaNonDomestica, 'Tariffa Non Domestica')
        errors += validaEstremi(filtro.daAliquota, filtro.aAliquota, 'Aliquota')
        errors += validaEstremi(filtro.daIvaFattura, filtro.aIvaFattura, 'Iva Fattura')
        errors += validaEstremi(filtro.daCompensoMinimo, filtro.aCompensoMinimo, 'Compenso Minimo')
        errors += validaEstremi(filtro.daCompensoMassimo, filtro.aCompensoMassimo, 'Compenso Massimo')
        errors += validaEstremi(filtro.daPercCompenso, filtro.aPercCompenso, 'Percentuale Compenso Compenso')
        errors += validaEstremi(filtro.daLimite, filtro.aLimite, 'Limite')
        errors += validaEstremi(filtro.daMesiCalcolo, filtro.aMesiCalcolo, 'Mesi Calcolo')
        errors += validaEstremi(filtro.daMaggiorazioneTares, filtro.aMaggiorazioneTares, 'Maggiorazione TARES')
        errors += validaEstremi(filtro.daCostoUnitario, filtro.aCostoUnitario, 'Costo Unitario')

        return errors
    }
}
