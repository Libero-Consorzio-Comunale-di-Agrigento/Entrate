package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class MotiviDetrazione implements Serializable {

    Short motivoDetrazione
    String tipoTributo
    String descrizione

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append motivoDetrazione
        builder.append tipoTributo
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append((Short) motivoDetrazione, (Short) other.motivoDetrazione)
        builder.append tipoTributo, other.tipoTributo
        builder.isEquals()
    }

    static mapping = {
        id composite: ["tipoTributo", "motivoDetrazione"], generator: "assigned"

        table "motivi_detrazione"
        version false
    }

    static constraints = {
        motivoDetrazione maxSize: 2
        tipoTributo maxSize: 5
        descrizione maxSize: 60
    }
}
