package it.finmatica.tr4.caricamento

class DatiMetriciUiu implements Serializable {

    Integer idUiu
    Integer progressivo
    String categoria
    Byte beneComune
    BigDecimal superficie

    static belongsTo = [testata: DatiMetriciTestata]
    static hasOne = [ubicazione: DatiMetriciUbicazione]

    static hasMany = [
            esitiAgenzia  : DatiMetriciEsitoAgenzia,
            esitiComune   : DatiMetriciEsitoComune,
            identificativi: DatiMetriciIdentificativi,
            indirizzi     : DatiMetriciIndirizzo,
            soggetti      : DatiMetriciSoggetto,
            datiMetrici   : DatiMetrici,
            datiNuovi     : DatiMetriciDatiNuovi

    ]

    static mapping = {
        id column: "uiu_id"
        testata column: "testate_id"

        version false

        table "dati_metrici_uiu"
    }

    static constraints = {
        idUiu nullable: true
        progressivo nullable: true
        categoria nullable: true
        beneComune nullable: true
        superficie nullable: true
        ubicazione nullable: true
    }
}
