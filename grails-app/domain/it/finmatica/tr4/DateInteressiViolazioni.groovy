package it.finmatica.tr4

import it.finmatica.tr4.commons.*
import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class DateInteressiViolazioni implements Serializable, Comparable<DateInteressiViolazioni> {

    TipoTributo tipoTributo
    Short anno
    Date dataAttoDa
    Date dataAttoA
    Date dataInizio
    Date dataFine

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append tipoTributo
        builder.append anno
        builder.append dataAttoDa
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append tipoTributo, other.tipoTributo
        builder.append anno, other.anno
        builder.append dataAttoDa, other.dataAttoDa
        builder.isEquals()
    }

    static mapping = {
        id          composite: ["tipoTributo", "anno", "dataAttoDa"]
        anno        column: "anno"
        tipoTributo column: "tipo_tributo"
        dataAttoDa  column: "data_atto_da"
        dataAttoA   column: "data_atto_a"
        dataInizio  column: "data_inizio"
        dataFine    column: "data_fine"

        table 'date_interessi_violazioni'
        version false
    }

    static constraints = {
        tipoTributo     nullable: false, maxSize: 5
        anno            nullable: false
        dataAttoDa      nullable: false
        dataAttoA       nullable: true
        dataInizio      nullable: true
        dataFine        nullable: true
    }

    int compareTo(DateInteressiViolazioni obj) {
        tipoTributo?.tipoTributo <=> obj?.tipoTributo.tipoTributo ?:
                                                anno <=> obj?.anno ?:
                                                    dataAttoDa <=> obj?.dataAttoDa
    }
}
