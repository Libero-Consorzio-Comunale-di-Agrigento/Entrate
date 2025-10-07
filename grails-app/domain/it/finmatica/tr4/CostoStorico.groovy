package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente
import it.finmatica.tr4.pratiche.OggettoPratica;

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CostoStorico implements Serializable {

	Short anno
	BigDecimal costo
	Ad4Utente	utente
	Date lastUpdated
	String note

	static belongsTo = [oggettoPratica: OggettoPratica]
	

	static mapping = {
		id 				composite: ["oggettoPratica", "anno"]
		oggettoPratica	column: "oggetto_pratica"
		lastUpdated column: "data_variazione", sqlType: 'Date'
		utente column: "utente", ignoreNotFound: true
		table	"costi_storici"
		version false
	}

	static constraints = {
		costo 			nullable: true
		utente 			nullable: true, maxSize: 8
		lastUpdated 	nullable: true
		note 			nullable: true, maxSize: 2000
	}
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append oggettoPratica
		builder.append anno
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append oggettoPratica, other.oggettoPratica
		builder.append anno, other.anno
		builder.isEquals()
	}
}
