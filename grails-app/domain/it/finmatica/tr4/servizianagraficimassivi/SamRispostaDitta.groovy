package it.finmatica.tr4.servizianagraficimassivi

import java.util.Date;

class SamRispostaDitta {
	
	Long id

	String codFiscaleDitta
	Date dataDecorrenza
	Date dataFineCarica
	
	SamRisposta risposta
	
	SamCodiceRitorno codiceRitorno
	SamCodiceCarica codiceCarica

	static hasMany = []

	static mapping = {
		id column: "risposta_ditta", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "SAM_RISPOSTE_DITTA_NR"]
		risposta column: "risposta_interrogazione"
		codiceRitorno column: "cod_ritorno"
		codiceCarica column: "cod_carica"

		table "sam_risposte_ditta"
		version false
	}

	static constraints = {
		risposta nullable: false
		codiceRitorno nullable: false, maxSize: 10
		codFiscaleDitta nullable: true, maxSize: 16
		codiceCarica nullable: true, maxSize: 1
		dataDecorrenza nullable: true
		dataFineCarica nullable: true
	}
}

