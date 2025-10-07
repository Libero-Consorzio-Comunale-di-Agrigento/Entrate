package it.finmatica.tr4

class CaricoTarsu {

    Short anno
    BigDecimal addizionaleEca
    BigDecimal maggiorazioneEca
    BigDecimal addizionalePro
    BigDecimal commissioneCom
    BigDecimal nonDovutoPro
    BigDecimal compensoMinimo
    BigDecimal compensoMassimo
    BigDecimal percCompenso
    BigDecimal limite
    BigDecimal tariffaDomestica
    BigDecimal tariffaNonDomestica
    BigDecimal aliquota
    String flagLordo
    String flagSanzioneAddP
    String flagSanzioneAddT
    String flagInteressiAdd
    Short mesiCalcolo
    BigDecimal ivaFattura
    BigDecimal maggiorazioneTares
    String flagMaggAnno
    Integer modalitaFamiliari
    String flagNoTardivo
    String flagTariffeRuolo
    String rataPerequative
    String flagTariffaPuntuale
    BigDecimal costoUnitario

    static mapping = {
        id name: "anno", generator: "assigned"

        flagSanzioneAddP column: "FLAG_SANZIONE_ADD_P"
        flagSanzioneAddT column: "FLAG_SANZIONE_ADD_T"

        table "carichi_tarsu"
        version false
    }

    static constraints = {
        addizionaleEca nullable: true
        maggiorazioneEca nullable: true
        addizionalePro nullable: true
        commissioneCom nullable: true
        nonDovutoPro nullable: true
        compensoMinimo nullable: true
        compensoMassimo nullable: true
        percCompenso nullable: true
        limite nullable: true
        tariffaDomestica nullable: true, scale: 5
        tariffaNonDomestica nullable: true, scale: 5
        aliquota nullable: true
        flagLordo nullable: true, maxSize: 1
        flagSanzioneAddP nullable: true, maxSize: 1
        flagSanzioneAddT nullable: true, maxSize: 1
        flagInteressiAdd nullable: true, maxSize: 1
        mesiCalcolo nullable: true, maxSize: 1
        ivaFattura nullable: true
        maggiorazioneTares nullable: true
        flagMaggAnno nullable: true, maxSize: 1
        modalitaFamiliari nullable: true
        flagNoTardivo nullable: true
        flagTariffeRuolo nullable: true
        rataPerequative nullable: true, inList: ['T', 'P', 'U']
        flagTariffaPuntuale nullable: true
        costoUnitario nullable: true, scale: 8
    }

    def springSecurityService
    static transients = ['springSecurityService']
}
