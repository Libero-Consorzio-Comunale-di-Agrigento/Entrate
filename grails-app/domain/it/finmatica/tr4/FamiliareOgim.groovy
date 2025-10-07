package it.finmatica.tr4

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class FamiliareOgim implements Serializable {

	OggettoImposta oggettoImposta
	Date dal
	Date al
	Short numeroFamiliari
	String dettaglioFaog
	String dettaglioFaogBase
	Date lastUpdated
	String note

	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggettoImposta
		builder.append dal
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append oggettoImposta, other.oggettoImposta
		builder.append dal, other.dal
		builder.isEquals()
	}

	static mapping = {
		id composite: ["oggettoImposta", "dal"]
		
		oggettoImposta	column: "oggetto_imposta"
		dal             sqlType: 'Date'
		al              sqlType: 'Date'
		lastUpdated  	column: "data_variazione", sqlType: 'Date'
		
		table	'familiari_ogim'
		
		version false
	}

	static constraints = {
		al nullable: true
		dettaglioFaog nullable: true, maxSize: 2000
		dettaglioFaogBase nullable: true, maxSize: 2000
		note nullable: true, maxSize: 2000
	}
}
