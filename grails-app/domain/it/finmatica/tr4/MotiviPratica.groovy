package it.finmatica.tr4


import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class MotiviPratica implements Serializable {

    String tipoTributo
    Short sequenza
    Short anno
    String tipoPratica
    String motivo

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append tipoTributo
        builder.append sequenza
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append tipoTributo, other.tipoTributo
        builder.append sequenza, other.sequenza
        builder.isEquals()
    }

    static mapping = {
        id composite: ["tipoTributo", "sequenza"]
        version false
    }

    static constraints = {
        tipoTributo maxSize: 5
        anno nullable: true
        tipoPratica nullable: true, maxSize: 1
        motivo maxSize: 2000
    }
}
