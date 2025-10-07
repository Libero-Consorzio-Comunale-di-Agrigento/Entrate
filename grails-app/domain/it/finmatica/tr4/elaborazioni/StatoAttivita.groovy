package it.finmatica.tr4.elaborazioni

class StatoAttivita {

    String descrizione

    static mapping = {
        id column: "stato_attivita", generator: "assigned"

        table "stati_attivita"
        version false
    }
}
