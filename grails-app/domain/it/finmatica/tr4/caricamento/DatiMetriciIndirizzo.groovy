package it.finmatica.tr4.caricamento

class DatiMetriciIndirizzo implements Serializable {

    Short codToponimo
    String toponimo
    String denom
    Integer codice
    String civico1
    String civico2
    String civico3
    String fonte
    String delibera
    String localita
    BigDecimal km
    String cap

    static belongsTo = [uiu: DatiMetriciUiu]

    static mapping = {
        id column: "indirizzi_id"
        uiu column: "uiu_id"

        version false

        table "dati_metrici_indirizzi"
    }

    static constraints = {
        codToponimo nullable: true
        toponimo nullable: true
        denom nullable: true
        codice nullable: true
        civico1 nullable: true
        civico2 nullable: true
        civico3 nullable: true
        fonte nullable: true
        delibera nullable: true
        localita nullable: true
        km nullable: true
        cap nullable: true
    }
}
