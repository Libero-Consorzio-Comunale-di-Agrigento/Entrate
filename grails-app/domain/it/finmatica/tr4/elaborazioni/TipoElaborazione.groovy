package it.finmatica.tr4.elaborazioni

class TipoElaborazione {

    String id
    String descrizione
    SortedSet tipiAttivitaElaborazione

    static hasMany = [tipiAttivitaElaborazione: TipoAttivitaElaborazioni]

    static mapping = {
        table 'TIPI_ELABORAZIONE'
        version false

        id column: "TIPO_ELABORAZIONE", generator: 'assigned'
    }

    static constraints = {
        descrizione maxSize: 60
    }
}
