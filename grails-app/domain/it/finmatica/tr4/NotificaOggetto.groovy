package it.finmatica.tr4

import it.finmatica.tr4.pratiche.PraticaTributo

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class NotificaOggetto implements Serializable, Comparable<NotificaOggetto> {

	
	Contribuente contribuente
	Short annoNotifica
	PraticaTributo pratica
	Date lastUpdated
	String note
	
	static belongsTo = [oggetto: Oggetto]
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggetto?.id
		builder.append contribuente?.codFiscale
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append oggetto?.id, other.oggetto.id
		builder.append contribuente.codFiscale, other.contribuente.codFiscale
		builder.isEquals()
	}

	static mapping = {
		id composite: ["oggetto", "contribuente"]
		
		oggetto 		column: "oggetto"
		contribuente 	column: "cod_fiscale"
		pratica			column: "pratica"
		lastUpdated		column: "data_variazione", sqlType: 'Date'
		table "notifiche_oggetto"
		version false
	}

	static constraints = {
		contribuente maxSize: 16
		pratica nullable: true
		lastUpdated nullable: true
		note nullable: true, maxSize: 2000
	}
	
	int compareTo(NotificaOggetto obj) {
		oggetto?.id				 <=> obj?.oggetto?.id?:
		contribuente?.codFiscale <=> obj?.contribuente.codFiscale?:
		annoNotifica			 <=> obj.annoNotifica
	}
}
