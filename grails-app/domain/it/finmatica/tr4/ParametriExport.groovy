package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ParametriExport implements Serializable, Comparable<ParametriExport> {

    TipiExport tipoExport
    Byte parametroExport
    String nomeParametro
    String tipoParametro
    String formatoParametro
    String ultimoValore
    String flagObbligatorio
    String valorePredefinito
    Byte ordinamento
    String flagNonVisibile
    String querySelezione

    int hashCode() {
        def builder = new HashCodeBuilder()
        builder.append tipoExport.id
        builder.append parametroExport
        builder.toHashCode()
    }

    boolean equals(other) {
        if (other == null) return false
        def builder = new EqualsBuilder()
        builder.append tipoExport.id, other.tipoExport.id
        builder.append parametroExport, other.parametroExport
        builder.isEquals()
    }

    static mapping = {
        id composite: ["tipoExport", "parametroExport"]
        tipoExport column: "tipo_export"
        version false
    }

    static constraints = {
        nomeParametro maxSize: 100
        tipoParametro maxSize: 1
        formatoParametro maxSize: 100
        ultimoValore nullable: true, maxSize: 2000
        flagObbligatorio nullable: true, maxSize: 1
        valorePredefinito nullable: true, maxSize: 2000
        ordinamento nullable: true
        flagNonVisibile nullable: true, maxSize: 1
        querySelezione nullable: true
    }

    @Override
    int compareTo(ParametriExport o) {
        tipoExport.id <=> o.tipoExport.id ?:
                parametroExport <=> o.parametroExport
    }
}
