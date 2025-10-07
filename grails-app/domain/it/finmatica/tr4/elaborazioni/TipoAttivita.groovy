package it.finmatica.tr4.elaborazioni

class TipoAttivita {

    String descrizione

    static hasMany = [tipiAttivitaElaborazione: TipoAttivitaElaborazioni]

    static mapping = {
        id column: "tipo_attivita", generator: "assigned"

        table "tipi_attivita"
        version false
    }
}
