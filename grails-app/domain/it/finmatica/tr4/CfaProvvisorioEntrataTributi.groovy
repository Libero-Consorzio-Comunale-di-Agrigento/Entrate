package it.finmatica.tr4

import it.finmatica.so4.struttura.So4Amministrazione;

import java.io.Serializable;
import java.sql.Blob

class CfaProvvisorioEntrataTributi implements Serializable {

	Short		esercizio
	String		numeroProvvisorio
	Date		dataProvvisorio
	
	String		descrizione
	BigDecimal	importo
	String		desBen
	String		idFlussoTesoreria
	String		note

	static mapping = {
		id	composite: ["esercizio", "numeroProvvisorio", "dataProvvisorio" ]
		
		table "cfa_provvisori_entrata_tributi"
		
		version false
	}

	static constraints = {
		esercizio			nullable: false
		
		numeroProvvisorio	nullable: false, maxSize: 10
		dataProvvisorio		nullable: false
		
		descrizione			nullable: true, maxSize: 140
		importo				nullable: true
		desBen				nullable: true, maxSize: 50
		idFlussoTesoreria	nullable: true, maxSize: 500
		note				nullable: true, maxSize: 4000
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
}
