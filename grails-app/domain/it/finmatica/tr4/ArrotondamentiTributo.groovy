package it.finmatica.tr4

import java.io.Serializable;

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class ArrotondamentiTributo implements Serializable {
	
	CodiceTributo 		codiceTributo
	Integer 			sequenza
	
	Integer 			arrConsistenza
	Double				consistenzaMinima
	Integer 			arrConsistenzaReale
	Double				consistenzaMinimaReale

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append codiceTributo
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append codiceTributo, other.codiceTributo
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}

	static mapping = {
		id 				composite: ["codiceTributo", "sequenza"]
		
		codiceTributo	column: "tributo"
		
		table "arrotondamenti_tributo"
		
		version false
	}

	static constraints = {
		arrConsistenza 			nullable: true
		consistenzaMinima 		nullable: true
		arrConsistenzaReale 	nullable: true
		consistenzaMinimaReale 	nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
}
