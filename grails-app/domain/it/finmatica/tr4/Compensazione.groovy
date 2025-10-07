package it.finmatica.tr4


import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class Compensazione implements Serializable {

    Long id
    String codFiscale
    String tipoTributo
    Short anno
    MotivoCompensazione motivoCompensazione
    BigDecimal compensazione
    String utente
    String flagAutomatico
    String note
    Date lastUpdated
    String versamento

    static transients = ['versamento']

    static mapping = {
        id column: 'id_compensazione', generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "COMPENSAZIONI_NR"]

        codFiscale column: "cod_fiscale"
        tipoTributo column: "tipo_tributo"
        anno column: "anno"
        motivoCompensazione column: "motivo_compensazione"
        lastUpdated column: "data_variazione", sqlType: 'Date'
        utente column: "utente"
        note column: "note"

        table "compensazioni"
        version false
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append id
        builder.append codFiscale
        builder.append tipoTributo
        builder.append anno
        builder.append motivoCompensazione.id
        builder.append compensazione
        builder.append flagAutomatico
        builder.append note
        builder.append lastUpdated
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append id, other.id
        builder.append codFiscale, other.codFiscale
        builder.append tipoTributo, other.tipoTributo
        builder.append anno, other.anno
        builder.append motivoCompensazione.id, other.motivoCompensazione.id
        builder.append compensazione, other.compensazione
        builder.append flagAutomatico, other.flagAutomatico
        builder.append note, other.note
        builder.append lastUpdated, other.lastUpdated
        builder.isEquals()
    }

    static constraints = {
        codFiscale nullable: true
        tipoTributo nullable: true, maxSize: 5
        anno nullable: true
        motivoCompensazione nullable: true, maxSize: 2
        compensazione nullable: true
        utente nullable: true, maxSize: 8
        lastUpdated nullable: true
        note nullable: true, maxSize: 2000
        flagAutomatico nullable: true, maxSize: 1
    }
}
