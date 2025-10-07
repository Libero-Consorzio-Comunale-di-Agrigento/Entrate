package it.finmatica.tr4

class Anadev {
    String descrizione
    Boolean segnalazione
    String flagStato


    static mapping = {
        id column: "cod_ev", generator: "assigned"
        flagStato	column: "flag_stato"

        table "web_anadev"

        version false
    }

    static constraints = {
        descrizione nullable: true
        segnalazione nullable: true
        flagStato nullable: true
    }
}
