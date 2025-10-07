package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ViolazioniDettagliOgim implements Serializable {

    Long pratica
    BigDecimal detrazione
    BigDecimal detrazioneAcconto
    BigDecimal detrazioneSaldo
    BigDecimal numFabbricatiAbImu
    BigDecimal numFabbricatiRuraliImu
    BigDecimal numFabbricatiAltriImu
    BigDecimal numFabbricatiAbIci
    BigDecimal numFabbricatiAltriIci
    BigDecimal numFabbricatiFabbDImu

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append pratica
        builder.append detrazione
        builder.append detrazioneAcconto
        builder.append detrazioneSaldo
        builder.append numFabbricatiAbImu
        builder.append numFabbricatiRuraliImu
        builder.append numFabbricatiAltriImu
        builder.append numFabbricatiAbIci
        builder.append numFabbricatiAltriIci
        builder.append numFabbricatiFabbDImu
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append pratica, other.pratica
        builder.append detrazione, other.detrazione
        builder.append detrazioneAcconto, other.detrazioneAcconto
        builder.append detrazioneSaldo, other.detrazioneSaldo
        builder.append numFabbricatiAbImu, other.numFabbricatiAbImu
        builder.append numFabbricatiRuraliImu, other.numFabbricatiRuraliImu
        builder.append numFabbricatiAltriImu, other.numFabbricatiAltriImu
        builder.append numFabbricatiAbIci, other.numFabbricatiAbIci
        builder.append numFabbricatiAltriIci, other.numFabbricatiAltriIci
        builder.append numFabbricatiFabbDImu, other.numFabbricatiFabbDImu
        builder.isEquals()
    }

    static mapping = {
        id composite: ["pratica", "detrazione", "detrazioneAcconto", "detrazioneSaldo", "numFabbricatiAbImu", "numFabbricatiRuraliImu", "numFabbricatiAltriImu", "numFabbricatiAbIci", "numFabbricatiAltriIci", "numFabbricatiFabbDImu"]
        version false
        numFabbricatiFabbDImu column: "num_fabbricati_fabb_d_imu"
    }

    static constraints = {
        pratica nullable: true
        detrazione nullable: true
        detrazioneAcconto nullable: true
        detrazioneSaldo nullable: true
        numFabbricatiAbImu nullable: true
        numFabbricatiRuraliImu nullable: true
        numFabbricatiAltriImu nullable: true
        numFabbricatiAbIci nullable: true
        numFabbricatiAltriIci nullable: true
        numFabbricatiFabbDImu nullable: true
    }
}
