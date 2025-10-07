package it.finmatica.tr4.datiesterni

import it.finmatica.so4.struttura.So4Amministrazione;

import java.io.Serializable;
import java.math.BigDecimal;
import java.sql.Blob
import java.util.Date;

class FornituraAEM implements Serializable {

	DocumentoCaricato	documentoCaricato
	Integer 			progressivo
	
	String		tipoRecord
	String		desTipoRecord
	
	Date		dataFornitura
	Short		progrFornitura

	Date		dataRipartizione
	Short		progrRipartizione
	Date		dataBonifico

	String		tipoImposta
	String		desTipoImposta
	
	String		codProvincia
	String		denProvincia

	Integer		numeroContoTu

	String		codValuta
	BigDecimal	importoAccredito
	
	Date		dataMandato
	BigDecimal	codMovimento

	static mapping = {
		id	composite: ["documentoCaricato", "progressivo"]
		
		documentoCaricato column: "documento_id"
		
		desTipoRecord	column: "des_tipo_record", updatable : false
		desTipoImposta	column: "des_tipo_imposta", updatable : false
		denProvincia	column: "den_provincia", updatable : false

		table "forniture_ae_m"
		
		version false
	}

	static constraints = {
		tipoRecord				nullable: false, maxSize: 2
		dataFornitura			nullable: false
		progrFornitura			nullable: false
		
		codProvincia			nullable: true, maxSize: 3
		codValuta				nullable: true, maxSize: 3
		tipoImposta				nullable: true, maxSize: 1
		importoAccredito		nullable: true
		progrRipartizione		nullable: true
		dataBonifico			nullable: true
		dataMandato				nullable: true
		dataRipartizione		nullable: true
		numeroContoTu			nullable: true
		codMovimento			nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
}
