package it.finmatica.ad4

import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import org.apache.commons.lang.builder.HashCodeBuilder

class Ad4ComuneStorico implements Serializable {
    Integer comune
    Long provinciaStato
    Date dal
    Date al

    Ad4ComuneTr4 comuneTr4

    boolean equals(other) {
        if (!(other instanceof Ad4ComuneStorico)) {
            return false
        }

        other.comune == comune && other.provinciaStato == provinciaStato
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        if (comune) builder.append(comune)
        if (provinciaStato) builder.append(provinciaStato)
        builder.toHashCode()
    }

    static mapping = {
        table 'ad4_vista_comuni_storici'
        id generator: 'assigned', composite: ['comune', 'provinciaStato']

        columns {
            comuneTr4 {
                column name: 'comune'
                column name: 'provincia_stato'
            }
        }

        comuneTr4 insertable: false, updateable: false

        version false
    }

    static constraints = {
    }
}
