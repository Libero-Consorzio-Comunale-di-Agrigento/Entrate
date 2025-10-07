package it.finmatica.tr4

import groovy.transform.EqualsAndHashCode
import it.finmatica.tr4.pratiche.IterPratica

@EqualsAndHashCode(includes = ['tipoStato'])
class TipoStato {

    String id
    String tipoStato
    String descrizione
	Integer numOrdine

    static hasMany = [
        iter: IterPratica
    ]

    static mapping = {
        id name: "tipoStato", generator: "assigned"
        table 'tipi_stato'

        version false
    }

    static constraints = {
        tipoStato maxSize: 2
        descrizione nullable: true, maxSize: 60
		numOrdine nullable: true, maxSize: 5
    }
}
