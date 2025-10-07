package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ClasseSuperficie implements Serializable {

	ScaglioneReddito	anno
	SettoreAttivita 	settore
	Integer 			classe
	BigDecimal 			imposta

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append anno
		builder.append settore
		builder.append classe
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append anno, other.anno
		builder.append settore, other.settore
		builder.append classe, other.classe
		builder.isEquals()
	}
	
	static mapping = {
		id 				composite: ["anno", "settore", "classe"]
		settore	column: "settore"
		anno	column: "anno"
		classe  column: "classe"
		table 	"classi_superficie"
		version false
	}

	static constraints = {
		imposta nullable: true
	}
}
