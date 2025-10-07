package it.finmatica.tr4.caricamento

class DatiMetriciEsitoComune {

    Short riscontro
    Short istanza
    Short richiestaPlan

    static belongsTo = [uiu: DatiMetriciUiu]

    static mapping = {
        id column: "esiti_comune_id"
        uiu column: "uiu_id"

        version false

        table "dati_metrici_esiti_comune"
    }

    static constraints = {
        riscontro nullable: true
        istanza nullable: true
        richiestaPlan nullable: true
    }
}
