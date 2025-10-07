package it.finmatica.tr4.pratiche

import it.finmatica.tr4.Contribuente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class StoRapportoTributo implements Serializable, Comparable<StoRapportoTributo> {

	Contribuente 	contribuente
	Integer 		sequenza
	String 			tipoRapporto

	StoPraticaTributo pratica
	
	static mapping = {
		id 				composite: ["pratica", "sequenza"]
		pratica 		column: "pratica"
		contribuente 	column: "cod_fiscale"
		
		table 			'sto_rapporti_tributo'
		version false
	}

	static constraints = {
		contribuente maxSize: 16
		tipoRapporto nullable: true, maxSize: 1
		sequenza	 nullable: true
	}
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append pratica
		builder.append sequenza
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append pratica, other.pratica
		builder.append sequenza, other.sequenza
		builder.isEquals()
	}
	
	int compareTo(StoRapportoTributo obj) {
		obj.pratica.anno <=> pratica.anno?: pratica.id <=> obj.pratica.id?: obj.sequenza <=> sequenza
	}
}
