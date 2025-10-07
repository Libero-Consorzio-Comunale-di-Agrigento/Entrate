package it.finmatica.tr4

import it.finmatica.tr4.commons.TipoOccupazione;

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Scadenza implements Serializable {

    Short anno
    Short sequenza
    String tipoScadenza
    Short rata
    String tipoVersamento
    Date dataScadenza

    TipoTributo tipoTributo
	
    String gruppoTributo
	TipoOccupazione tipoOccupazione

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append tipoTributo.tipoTributo
        builder.append anno
        builder.append sequenza
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append tipoTributo.tipoTributo, other.tipoTributo.tipoTributo
        builder.append anno, other.anno
        builder.append sequenza, other.sequenza
        builder.isEquals()
    }

    static mapping = {
        id composite: ["tipoTributo", "anno", "sequenza"]
        tipoTributo column: "tipo_tributo"
        dataScadenza sqlType: 'Date', column: 'DATA_SCADENZA'
		
		gruppoTributo column: "gruppo_tributo"
        tipoOccupazione enumType: 'string'
		
        table "scadenze"
        version false
    }

    static constraints = {
        tipoTributo maxSize: 5
        tipoScadenza maxSize: 1, inList: ['D', 'V', 'T', 'R']
        rata nullable: true, inList: [(short) 0, (short) 1, (short) 2, (short) 3, (short) 4, (short) 5, (short) 6]

        tipoVersamento nullable: true, inList: ['A', 'S', 'U']
		
        gruppoTributo nullable: true, maxSize: 10
        tipoOccupazione nullable: true, maxSize: 1
    }
}
