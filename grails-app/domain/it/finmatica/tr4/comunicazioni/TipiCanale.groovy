package it.finmatica.tr4.comunicazioni

// TODO presa ad esempio la struttura del domain MotivoSgravio
class TipiCanale {

    String descrizione

    static mapping = {
        id column: "tipo_canale", generator: "assigned"

        table "tipi_canale"
        version false
    }

    static constraints = {
        descrizione maxSize: 100
    }

}
