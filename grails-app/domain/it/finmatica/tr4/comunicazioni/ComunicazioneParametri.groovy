package it.finmatica.tr4.comunicazioni

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ComunicazioneParametri implements Serializable {

    String tipoTributo
    String tipoComunicazione
    String descrizione
    String flagFirma
    String flagProtocollo
    String flagPec
    String tipoDocumento
    String titoloDocumento
    String pkgVariabili
    String variabiliClob

    static mapping = {
        id generator: "assigned", composite: ['tipoTributo', 'tipoComunicazione']

        table "comunicazione_parametri"
        version false
    }

    static constraints = {
        tipoTributo maxSize: 5
        tipoComunicazione maxSize: 3
        descrizione nullable: true, maxSize: 100
        flagFirma nullable: true, maxSize: 1
        flagProtocollo nullable: true, maxSize: 1
        flagPec nullable: true, maxSize: 1
        tipoDocumento nullable: true, maxSize: 3
        titoloDocumento nullable: true, maxSize: 200
        pkgVariabili nullable: true, maxSize: 100
        variabiliClob nullable: true
    }

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append tipoTributo
        builder.append tipoComunicazione
        builder.toHashCode()
    }

    boolean equals(other) {
        if (null == other) return false
        def builder = new EqualsBuilder()
        builder.append tipoTributo, other.tipoTributo
        builder.append tipoComunicazione, other.tipoComunicazione
        builder.isEquals()
    }
}
