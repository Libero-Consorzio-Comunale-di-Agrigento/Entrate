package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CodiceF24 implements Serializable {

    String tributo
    String descrizione
    String rateazione
    TipoTributo tipoTributo
    String descrizioneTitr
    String tipoCodice
    String flagStampaRateazione

    //DatiContabili datiContabili
    //static belongsTo = [datiContabili: DatiContabili]

    static mapping = {
        id composite: ["tributo", "tipoTributo", "descrizioneTitr"]
        tributo         column: "tributo_f24"
        tipoTributo		column: "tipo_tributo"
        descrizioneTitr column: "descrizione_titr"

        table "codici_f24"
        version false
    }

    static constraints = {
        tributo maxSize: 4
        descrizione maxSize: 1000
        rateazione nullable: true, maxSize: 4
        tipoTributo maxSize: 5
        descrizioneTitr maxSize: 5
        tipoCodice maxSize: 1
        flagStampaRateazione nullable: true, inList	: ["S"]
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append tipoTributo.tipoTributo
        builder.append tributo
        builder.append descrizioneTitr
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append tipoTributo.tipoTributo, other.tipoTributo.tipoTributo
        builder.append tributo, other.tributo
        builder.append descrizioneTitr, other.descrizioneTitr
        builder.isEquals()
    }
}
