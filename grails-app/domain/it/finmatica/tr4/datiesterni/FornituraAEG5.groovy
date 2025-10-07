package it.finmatica.tr4.datiesterni

import it.finmatica.so4.struttura.So4Amministrazione;

import java.io.Serializable;
import java.math.BigDecimal;
import java.sql.Blob
import java.util.Date;

class FornituraAEG5 implements Serializable {

	DocumentoCaricato	documentoCaricato
	Integer 			progressivo
	
	String		tipoRecord
	String		desTipoRecord
	
	Date		dataFornitura
	Short		progrFornitura
	
	String		statoMandat
	String		desStatoMandato
	String		codEnteComunale
	String		codValuta
	BigDecimal	importoAccredito
	
	BigDecimal	cro
	Date		dataAccreditamento
	Date		dataRipartizioneOrig
	Short		progrRipartizioneOrig
	Date		dataBonificoOrig
		
	String		tipoImposta
	String		desTipoImposta
	
	String		iban
	String		sezioneContoTu
	Integer		numeroContoTu
	BigDecimal	codMovimento
	String		desMovimento
	Date		dataStornoScarto
	Date		dataElaborazioneNuova
	Short		progrElaborazioneNuova

	static mapping = {
		id	composite: ["documentoCaricato", "progressivo"]
		
		documentoCaricato column: "documento_id"
		
		desTipoRecord	column: "des_tipo_record", updatable : false
		desStatoMandato	column: "des_stato_mandato", updatable : false
		desTipoImposta	column: "des_tipo_imposta", updatable : false

		table "forniture_ae_g5"
		
		version false
	}

	static constraints = {
		tipoRecord				nullable: false, maxSize: 2
		dataFornitura			nullable: false
		progrFornitura			nullable: false
		
		codEnteComunale			nullable: true, maxSize: 4
		codValuta				nullable: true, maxSize: 3
		tipoImposta				nullable: true, maxSize: 1
		statoMandat				nullable: true, maxSize: 1
		importoAccredito		nullable: true
		progrRipartizioneOrig	nullable: true
		dataBonificoOrig		nullable: true
		dataAccreditamento		nullable: true
		dataRipartizioneOrig	nullable: true
		iban					nullable: true, maxSize: 34
		sezioneContoTu			nullable: true, maxSize: 3
		numeroContoTu			nullable: true
		codMovimento			nullable: true
		desMovimento			nullable: true, maxSize: 45
		dataStornoScarto		nullable: true
		dataElaborazioneNuova	nullable: true
		progrElaborazioneNuova	nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
}
