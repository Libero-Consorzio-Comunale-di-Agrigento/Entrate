package it.finmatica.tr4.caricamento

class DatiMetrici implements Serializable {

    String ambiente
    BigDecimal superficieAmbiente
    BigDecimal altezza
    BigDecimal altezzaMax

    static belongsTo = [uiu: DatiMetriciUiu]


    static mapping = {
        id column: "id"
        uiu column: "uiu_id"

        version false

        table "dati_metrici"
    }


    static constraints = {
        altezza nullable: true
        altezzaMax nullable: true
        superficieAmbiente nullable: true
        ambiente nullable: true
    }
}
