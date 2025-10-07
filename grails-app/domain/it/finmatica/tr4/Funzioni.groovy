package it.finmatica.tr4

import it.finmatica.tr4.tipi.SiNoType

class Funzioni {

    String funzione
    String descrizione
    boolean flagVisibile

    static mapping = {
        id name: "funzione", generator: "assigned"
        version false

        flagVisibile type: SiNoType

        table "funzioni"
    }

    static constraints = {
        funzione maxSize: 40
        descrizione maxSize: 200
    }
}
