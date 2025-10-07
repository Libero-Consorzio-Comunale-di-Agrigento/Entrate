package it.finmatica.tr4


import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class TariffaNonDomestica implements Serializable {

    Short anno
    Short tributo
    Short categoria
    BigDecimal tariffaQuotaFissa
    BigDecimal tariffaQuotaVariabile
    BigDecimal importoMinimi

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append anno
        builder.append tributo
        builder.append categoria
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append anno, other.anno
        builder.append tributo, other.tributo
        builder.append categoria, other.categoria
        builder.isEquals()
    }

    static mapping = {
        id composite: ["categoria", "tributo", "anno"]
        table "tariffe_non_domestiche"
        version false
    }

    static constraints = {
        tariffaQuotaFissa scale: 5
        tariffaQuotaVariabile scale: 5
        importoMinimi nullable: true, scale: 5
    }
}
