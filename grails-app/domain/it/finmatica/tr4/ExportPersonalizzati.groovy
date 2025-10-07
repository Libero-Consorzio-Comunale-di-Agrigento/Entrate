package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ExportPersonalizzati implements Serializable {

	Integer tipoExport
	String codiceIstat
	String descrizione

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append tipoExport
		builder.append codiceIstat
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append tipoExport, other.tipoExport
		builder.append codiceIstat, other.codiceIstat
		builder.isEquals()
	}

	static mapping = {
		id composite: ["tipoExport", "codiceIstat"]
		version false
	}

	static constraints = {
		codiceIstat maxSize: 6
		descrizione nullable: true, maxSize: 200
	}
}
