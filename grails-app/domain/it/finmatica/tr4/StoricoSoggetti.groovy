package it.finmatica.tr4

import it.finmatica.ad4.autenticazione.Ad4Utente

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class StoricoSoggetti implements Serializable {

	Date dal
	Date al
	String codFiscale
	String cognomeNome
	Byte fascia
	Byte stato
	String sesso
	Long codFam
	String rapportoPar
	Byte sequenzaPar
	Date dataNas
	Short codProNas
	Short codComNas
	Short codProRes
	Short codComRes
	Integer cap
	String denominazioneVia
	Integer codVia
	Integer numCiv
	String suffisso
	String scala
	String piano
	Byte interno
	String partitaIva
	String rappresentante
	String indirizzoRap
	Short codProRap
	Short codComRap
	String codFiscaleRap
	Short tipoCarica
	String tipo
	String cognome
	String nome
	Ad4Utente	utente
	Date lastUpdated
	String note
	Long niPresso
	String intestatarioFam
	Fonte fonte
	
	static belongsTo =  [soggetto: Soggetto]
	
	int hashCode() {
		def builder = new HashCodeBuilder()
		builder.append ni
		builder.append dal
		builder.toHashCode()
	}

	boolean equals(other) {
		if (other == null) return false
		def builder = new EqualsBuilder()
		builder.append ni, other.ni
		builder.append dal, other.dal
		builder.isEquals()
	}

	static mapping = {
		id 			composite: ["soggetto", "dal"]
		soggetto 	column: "ni"
		fonte		column: "fonte"
		utente		column: "utente"
		version false
		
		dal				sqlType:'Date'
		al				sqlType:'Date'
		lastUpdated		column: "data_variazione", sqlType:'Date'
		dataNas			sqlType:'Date'
	}

	static constraints = {
		codFiscale 			nullable: true, maxSize: 16
		cognomeNome 		maxSize: 60
		fascia 				nullable: true
		stato 				nullable: true
		sesso 				nullable: true, maxSize: 1
		codFam 				nullable: true
		rapportoPar 		nullable: true, maxSize: 2
		sequenzaPar 		nullable: true
		dataNas 			nullable: true
		codProNas 			nullable: true
		codComNas 			nullable: true
		codProRes 			nullable: true
		codComRes 			nullable: true
		cap 				nullable: true
		denominazioneVia 	nullable: true, maxSize: 60
		codVia 				nullable: true
		numCiv 				nullable: true
		suffisso 			nullable: true, maxSize: 5
		scala 				nullable: true, maxSize: 5
		piano 				nullable: true, maxSize: 5
		interno 			nullable: true
		partitaIva 			nullable: true, maxSize: 11
		rappresentante 		nullable: true, maxSize: 40
		indirizzoRap 		nullable: true, maxSize: 50
		codProRap 			nullable: true
		codComRap 			nullable: true
		codFiscaleRap 		nullable: true, maxSize: 16
		tipoCarica 			nullable: true
		tipo 				maxSize: 1
		cognome 			nullable: true, maxSize: 60
		nome 				nullable: true, maxSize: 36
		utente 				maxSize: 8
		note 				nullable: true, maxSize: 2000
		niPresso 			nullable: true
		intestatarioFam 	nullable: true, maxSize: 60
		fonte 				nullable: true
	}
}
