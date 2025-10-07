package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Aggio implements Serializable {

    String tipoTributo
    Short sequenza
    Date dataInizio
    Date dataFine
    Integer giornoInizio
    Integer giornoFine
    BigDecimal aliquota
    BigDecimal importoMassimo

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
        dataInizio column: "data_inizio", sqlType: 'Date'
        dataFine column: "data_fine", sqlType: 'Date'
        giornoInizio column: "giorno_inizio"
        giornoFine column: "giorno_fine"
        importoMassimo column: "importo_massimo"

        table "aggi"
        version false
    }

    static constraints = {
        tipoTributo maxSize: 5
        aliquota scale: 4
        giornoInizio maxSize: 4
        giornoFine maxSize: 4
        importoMassimo nullable: true
    }
}
