package it.finmatica.tr4.elaborazioni


class TipoAttivitaElaborazioni implements Serializable, Comparable {

    Integer numOrdine

    static belongsTo = [tipoAttivita: TipoAttivita, tipoElaborazione: TipoElaborazione]

    static mapping = {
        table 'TIPI_ATTIVITA_ELABORAZIONE'
        version false

        id composite: ['tipoAttivita', 'tipoElaborazione']
        tipoAttivita column: 'tipo_attivita'
        tipoElaborazione column: 'tipo_elaborazione'

        sort numOrdine: 'asc'
    }

    static constraints = {
        numOrdine nullable: false
    }

    int compareTo(obj) {
        numOrdine <=> obj.numOrdine
    }
}
