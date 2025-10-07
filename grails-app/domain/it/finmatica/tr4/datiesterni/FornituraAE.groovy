package it.finmatica.tr4.datiesterni

import it.finmatica.so4.struttura.So4Amministrazione;

import java.io.Serializable;
import java.sql.Blob

class FornituraAE implements Serializable {

	DocumentoCaricato	documentoCaricato
	Integer 			progressivo
	
	String		tipoRecord
	
	Date		dataFornitura
	Short		progrFornitura
	
	Date		dataRipartizione
	Short		progrRipartizione
	Date		dataBonifico
	Integer		progrDelega
	Short		progrRiga
	
	Integer		codEnte
	String		tipoEnte
	
	Integer		cab
	String		codFiscale
	Short		flagErrCodFiscale
	Date		dataRiscossione
	String		codEnteComunale
	String		codTributo
	Short		flagErrCodTributo
	Short		rateazione
	Short		annoRif
	Short		flagErrAnno
	String		codValuta
	BigDecimal	importoDebito
	BigDecimal	importoCredito
	Short		ravvedimento
	Short		immobiliVariati
	Short		acconto
	Short		saldo
	Short		numFabbricati
	Short		flagErrDati
	BigDecimal	detrazione
	String		cognomeDenominazione
	String		codFiscaleOrig
	String		nome
	String		sesso
	Date		dataNas
	String		comuneStato
	String		provincia
	
	String		tipoImposta
	
	String		codFiscale2
	String		codIdentificativo2
	String		idOperazione
	
	String		stato
	String		codEnteBeneficiario
	BigDecimal	importoAccredito
	Date		dataMandato
	Short		progrMandato
	BigDecimal	importoRecupero
	Integer		periodoRipartizioneOrig
	Short		progrRipartizioneOrig
	Date		dataBonificoOrig
	String		tipoRecupero
	String		desRecupero
	BigDecimal	importoAnticipazione
	BigDecimal	cro
	Date		dataAccreditamento
	Date		dataRipartizioneOrig
	String		iban
	String		sezioneContoTu
	Integer		numeroContoTu
	BigDecimal	codMovimento
	String		desMovimento
	Date		dataStornoScarto
	Date		dataElaborazioneNuova
	Short		progrElaborazioneNuova
	String		tipoOperazione
	Date		dataOperazione
	String		tipoTributo
	String		descrizioneTitr
	
	Short		annoAcc
	Integer		numeroAcc
	
	String		numeroProvvisorio
	Date		dataProvvisorio
	
	BigDecimal	importoNetto
	BigDecimal	importoIfel
	BigDecimal	importoLordo
	
	Short		codProvincia

	static mapping = {
		id	composite: ["documentoCaricato", "progressivo"]
		
		documentoCaricato column: "documento_id"
		codFiscale2 column: "cod_fiscale_2"
		codIdentificativo2 column: "cod_identificativo_2"
		
		table "forniture_ae"
		
		version false
	}

	static constraints = {
		tipoRecord				nullable: false, maxSize: 2
		dataFornitura			nullable: false
		progrFornitura			nullable: false
		
		dataRipartizione		nullable: true
		progrRipartizione		nullable: true
		dataBonifico			nullable: true
		progrDelega				nullable: true
		progrRiga				nullable: true
		codEnte					nullable: true
		tipoEnte				nullable: true, maxSize: 1
		cab						nullable: true
		codFiscale				nullable: true, maxSize: 16
		flagErrCodFiscale		nullable: true
		dataRiscossione			nullable: true
		codEnteComunale			nullable: true, maxSize: 4
		codTributo				nullable: true, maxSize: 4
		flagErrCodTributo		nullable: true
		rateazione				nullable: true
		annoRif					nullable: true
		flagErrAnno				nullable: true
		codValuta				nullable: true, maxSize: 3
		importoDebito			nullable: true
		importoCredito			nullable: true
		ravvedimento			nullable: true
		immobiliVariati			nullable: true
		acconto					nullable: true
		saldo					nullable: true
		numFabbricati			nullable: true
		flagErrDati				nullable: true
		detrazione				nullable: true
		cognomeDenominazione	nullable: true, maxSize: 60
		codFiscaleOrig			nullable: true, maxSize: 16
		nome					nullable: true, maxSize: 20
		sesso					nullable: true, maxSize: 1
		dataNas					nullable: true
		comuneStato				nullable: true, maxSize: 25
		provincia				nullable: true, maxSize: 2
		tipoImposta				nullable: true, maxSize: 3
		codFiscale2				nullable: true, maxSize: 16
		codIdentificativo2		nullable: true, maxSize: 2
		idOperazione			nullable: true, maxSize: 18
		stato					nullable: true, maxSize: 1
		codEnteBeneficiario		nullable: true, maxSize: 4
		importoAccredito		nullable: true
		dataMandato				nullable: true
		progrMandato			nullable: true
		importoRecupero			nullable: true
		periodoRipartizioneOrig	nullable: true
		progrRipartizioneOrig	nullable: true
		dataBonificoOrig		nullable: true
		tipoRecupero			nullable: true, maxSize: 3
		desRecupero				nullable: true, maxSize: 200
		importoAnticipazione	nullable: true
		cro						nullable: true
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
		tipoOperazione			nullable: true, maxSize: 1
		dataOperazione			nullable: true
		tipoTributo				nullable: true, maxSize: 5
		descrizioneTitr			nullable: true, maxSize: 5
		
		annoAcc					nullable: true
		numeroAcc				nullable: true
		
		numeroProvvisorio		nullable: true, maxSize: 10
		dataProvvisorio			nullable: true
		
		importoNetto			nullable: true
		importoIfel				nullable: true
		importoLordo			nullable: true

		codProvincia			nullable: true, maxSize: 3
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
}
