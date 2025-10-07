package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Aliquota implements Serializable {

    TipoAliquota tipoAliquota
    short anno
    BigDecimal aliquota
    String flagAbPrincipale
    String flagPertinenze
    BigDecimal aliquotaBase
    BigDecimal aliquotaErariale
    BigDecimal aliquotaStd
    BigDecimal percSaldo
    BigDecimal percOccupante
    String flagRiduzione
    BigDecimal riduzioneImposta
    String note
    Date scadenzaMiniImu
    String flagFabbricatiMerce

    static mapping = {
        id composite: ["anno", "tipoAliquota"]

        columns {
            tipoAliquota {
                column name: "tipo_tributo"
                column name: "tipo_aliquota"
            }
        }

        table "aliquote"
        version false
    }

    static constraints = {
        flagAbPrincipale nullable: true, maxSize: 1
        flagPertinenze nullable: true, maxSize: 1
        flagFabbricatiMerce nullable: true, maxSize: 1
        aliquotaBase nullable: true
        aliquotaErariale nullable: true
        aliquotaStd nullable: true
        percSaldo nullable: true
        percOccupante nullable: true
        flagRiduzione nullable: true, maxSize: 1
        riduzioneImposta nullable: true
        note nullable: true
        scadenzaMiniImu nullable: true
        flagFabbricatiMerce nullable: true, maxSize: 1
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append anno
        builder.append tipoAliquota.tipoAliquota
        builder.append tipoAliquota.tipoTributo.tipoTributo
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append anno, other.anno
        builder.append tipoAliquota.tipoAliquota, other.tipoAliquota.tipoAliquota
        builder.append tipoAliquota.tipoTributo.tipoTributo, other.tipoAliquota.tipoTributo.tipoTributo
        builder.isEquals()
    }

}
