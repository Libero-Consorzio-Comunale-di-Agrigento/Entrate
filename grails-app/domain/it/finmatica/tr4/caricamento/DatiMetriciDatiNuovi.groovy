package it.finmatica.tr4.caricamento

class DatiMetriciDatiNuovi implements Serializable {

    BigDecimal superficieTot
    BigDecimal superficieConv
    Date inizioValidita
    Date fineValidita
    String comune
    String progStrada
    Date dataCertificazione
    Date dataProvv
    String protocolloProvv
    String codStradaCom

    static belongsTo = [uiu: DatiMetriciUiu]

    static mapping = {
        id column: "dati_nuovi_id"
        uiu column: "uiu_id"

        version false

        table "dati_metrici_dati_nuovi"
    }

    static constraints = {
        superficieTot nullable: true
        superficieConv nullable: true
        inizioValidita nullable: true
        fineValidita nullable: true
        comune nullable: true
        progStrada nullable: true
        dataCertificazione nullable: true
        dataProvv nullable: true
        protocolloProvv nullable: true
        codStradaCom nullable: true
    }
}
