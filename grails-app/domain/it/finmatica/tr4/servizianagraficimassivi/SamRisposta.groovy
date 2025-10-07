package it.finmatica.tr4.servizianagraficimassivi

import java.util.Date;

import it.finmatica.ad4.autenticazione.Ad4Utente;

class SamRisposta {
	
	Long id
	
	String tipoRecord
	String codFiscale
	String cognome
	String nome
	String denominazione
	String sesso
	Date dataNascita
	String comuneNascita
	String provinciaNascita
	String comuneDomicilio
	String provinciaDomicilio
	String capDomicilio
	String indirizzoDomicilio
	Date dataDomicilio
	Date dataDecesso
	String presenzaEstinzione
	Date dataEstinzione
	String partitaIva
	String statoPartitaIva
	String codAttivita
	String tipologiaCodifica
	Date dataInizioAttivita
	Date dataFineAttivita
	String comuneSedeLegale
	String provinciaSedeLegale
	String capSedeLegale
	String indirizzoSedeLegale
	Date dataSedeLegale
	String codFiscaleRap
	Date dataDecorrenzaRap
	Long documentoId
	
	SamInterrogazione interrogazione
	
	SamCodiceRitorno codiceRitorno
	SamFonteDomSede fonteDomicilio
	SamFonteDecesso fonteDecesso
	SamFonteDomSede fonteSedeLegale
	SamCodiceCarica codiceCarica

	Ad4Utente utente
	Date lastUpdated
	
	static hasMany = []

	static mapping = {
		id column: "risposta_interrogazione", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "SAM_RISPOSTE_NR"]
		interrogazione column: "interrogazione"
		codiceRitorno column: "cod_ritorno"
		fonteDomicilio column: "fonte_domicilio"
		fonteDecesso column: "fonte_decesso"
		fonteSedeLegale column: "fonte_sede_legale"
		codiceCarica column: "cod_carica"
		documentoId column: "documento_id"
		
		utente column: "utente"
		lastUpdated column: "data_variazione", sqlType: 'Date'
		
		table "sam_risposte"
		version false
	}

	static constraints = {
		tipoRecord nullable: false, maxSize: 1
		interrogazione nullable: false
		codFiscale nullable: true, maxSize: 16
		codiceRitorno nullable: false, maxSize: 10
		cognome nullable: true, maxSize: 40
		nome nullable: true, maxSize: 40
		denominazione nullable: true, maxSize: 150
		sesso nullable: true, maxSize: 1
		dataNascita nullable: true
		comuneNascita nullable: true, maxSize: 45
		provinciaNascita nullable: true, maxSize: 2
		comuneDomicilio nullable: true, maxSize: 45
		provinciaDomicilio nullable: true, maxSize: 2
		capDomicilio nullable: true, maxSize: 5
		indirizzoDomicilio nullable: true, maxSize: 35
		fonteDomicilio nullable: true, maxSize: 1
		dataDomicilio nullable: true
		fonteDecesso nullable: true, maxSize: 1
		dataDecesso nullable: true
		presenzaEstinzione nullable: true, maxSize: 1
		dataEstinzione nullable: true
		partitaIva nullable: true, maxSize: 11
		statoPartitaIva nullable: true, maxSize: 1
		codAttivita nullable: true, maxSize: 6
		tipologiaCodifica nullable: true, maxSize: 1
		dataInizioAttivita nullable: true
		dataFineAttivita nullable: true
		comuneSedeLegale nullable: true, maxSize: 45
		provinciaSedeLegale nullable: true, maxSize: 2
		capSedeLegale nullable: true, maxSize: 5
		indirizzoSedeLegale nullable: true, maxSize: 35
		fonteSedeLegale nullable: true, maxSize: 1
		dataSedeLegale nullable: true
		codFiscaleRap nullable: true, maxSize: 16
		codiceCarica nullable: true, maxSize: 1
		dataDecorrenzaRap nullable: true
		documentoId nullable: true
		
		utente maxSize: 8
		lastUpdated nullable: true
	}
}

