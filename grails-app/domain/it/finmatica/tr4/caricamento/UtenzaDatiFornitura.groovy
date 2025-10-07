package it.finmatica.tr4.caricamento

class UtenzaDatiFornitura implements Serializable {

    String identificativoUtenza
    Short annoRiferimento
    String codCatastaleUtenza
    String codFiscaleErogante
    String codFiscaleTitolare
    String tipoSoggetto
    String datiAnagraficiTitolare
    String indirizzoUtenza
    String capUtenza
    BigDecimal ammontareFatturato
    BigDecimal consumoFatturato
    Short mesiFatturazione

    static belongsTo = [utenzaFornitura: UtenzaFornitura]
    static hasOne = [tipoUtenza: UtenzaTipiUtenza]

    static mapping = {
        id column: "dati_fornitura_id"
        utenzaFornitura column: "forniture_id"

        columns {
            tipoUtenza {
                column name: "tipo_fornitura"
                column name: "tipo_utenza"
            }
        }

        version false

        table "utenze_dati_fornitura"
    }

    static constraints = {
        annoRiferimento nullable: true
        codCatastaleUtenza nullable: true
        codFiscaleErogante nullable: true
        codFiscaleTitolare nullable: true
        tipoSoggetto nullable: true
        datiAnagraficiTitolare nullable: true
        tipoUtenza nullable: true
        indirizzoUtenza nullable: true
        capUtenza nullable: true
        ammontareFatturato nullable: true
        consumoFatturato nullable: true
        mesiFatturazione nullable: true
    }
}
