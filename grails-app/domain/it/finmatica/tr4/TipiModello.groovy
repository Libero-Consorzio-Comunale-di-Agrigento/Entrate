package it.finmatica.tr4

class TipiModello {

    String tipoModello
    String descrizione
    String tipoPratica

    static hasMany = [modelli: Modelli]

    static mapping = {
        id name: "tipoModello", generator: "assigned"
        version false
    }

    static constraints = {
        tipoModello maxSize: 10
        descrizione nullable: true, maxSize: 60
    }
}
