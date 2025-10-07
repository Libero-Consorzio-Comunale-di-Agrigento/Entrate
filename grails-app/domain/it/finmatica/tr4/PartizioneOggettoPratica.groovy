package it.finmatica.tr4

import it.finmatica.tr4.pratiche.OggettoPratica;

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class PartizioneOggettoPratica implements Serializable {

    TipoArea tipoArea

    Byte numero
    BigDecimal consistenzaReale
    BigDecimal consistenza
    String flagEsenzione
    String note
    Short sequenza

    static belongsTo = [oggettoPratica: OggettoPratica]

    static mapping = {
        id composite: ["oggettoPratica", "sequenza"]
        tipoArea column: "tipo_area"
        oggettoPratica column: "oggetto_pratica"
        table "partizioni_oggetto_pratica"
        version false
    }

    static constraints = {
        numero nullable: true
        flagEsenzione nullable: true, maxSize: 1
        note nullable: true, maxSize: 2000
        sequenza nullable: true
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append oggettoPratica
        builder.append sequenza
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append oggettoPratica, other.oggettoPratica
        builder.append sequenza, other.sequenza
        builder.isEquals()
    }
}
