package it.finmatica.tr4

import java.util.Date;

import it.finmatica.ad4.autenticazione.Ad4Utente

class RataImposta {

	Contribuente contribuente
	TipoTributo tipoTributo
	OggettoImposta oggettoImposta
	
	Short rata
	Short anno
	BigDecimal imposta
	Integer contoCorrente
	Ad4Utente	utente
	String note
	Long numBollettino
	BigDecimal addizionaleEca
	BigDecimal maggiorazioneEca
	BigDecimal addizionalePro
	BigDecimal iva
	BigDecimal impostaRound
	Date dataScadenza
	BigDecimal maggiorazioneTares
	
	static hasMany = [ versamenti: Versamento ]
	
	static mapping = {
		id 				column: "rata_imposta", generator: "assigned"
		contribuente	column: "cod_fiscale"
		tipoTributo		column: "tipo_tributo"
		oggettoImposta  column: "oggetto_imposta"
		utente	column: "utente"
		table "rate_imposta"
		version false
	}

	static constraints = {
		tipoTributo maxSize: 5
		oggettoImposta nullable: true
		imposta nullable: true
		contoCorrente nullable: true
		utente maxSize: 8
		note nullable: true, maxSize: 2000
		numBollettino nullable: true
		addizionaleEca nullable: true
		maggiorazioneEca nullable: true
		addizionalePro nullable: true
		iva nullable: true
		impostaRound nullable: true
		rata inList: [0, 1, 2, 3, 4, 11, 12, 22]
		dataScadenza nullable: true
		maggiorazioneTares nullable: true
	}
}
