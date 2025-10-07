package it.finmatica.tr4.caricamento

class DatiMetriciEsitoAgenzia implements Serializable {
    Short esitoSup
    String esitoAgg

    static belongsTo = [uiu: DatiMetriciUiu]

    static mapping = {
        id column: "esiti_agenzia_id"
        uiu column: "uiu_id"

        version false

        table "dati_metrici_esiti_agenzia"
    }

    static constraints = {
        esitoSup nullable: true
        esitoAgg nullable: true
    }
}
