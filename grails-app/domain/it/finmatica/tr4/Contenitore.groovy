package it.finmatica.tr4

class Contenitore {

    String descrizione
    String unitaDiMisura
    BigDecimal capienza

    static mapping = {
        id column: 'cod_contenitore', generator: 'assigned'
        table 'CONTENITORI'
        version false
    }

    static constraints = {
        descrizione nullable: true, maxSize: 60
        unitaDiMisura nullable: true, maxSize: 20
        capienza nullable: true
    }
}