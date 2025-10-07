package it.finmatica.tr4.servizianagraficimassivi

import it.finmatica.tr4.servizianagraficimassivi.SamCodiceCarica
import it.finmatica.tr4.servizianagraficimassivi.SamCodiceRitorno

class SamRispostaRap {
	
	Long id
	
	String codFiscaleRap
	Date dataDecorrenza
	Date dataFineCarica
	
	SamRisposta risposta
	
	SamCodiceRitorno codiceRitorno
	SamCodiceCarica codiceCarica
	
	static hasMany = []

	static mapping = {
		id column: "risposta_rap", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "SAM_RISPOSTE_RAP_NR"]
		risposta column: "risposta_interrogazione"
		codiceRitorno column: "cod_ritorno"
		codiceCarica column: "cod_carica"
	
		table "sam_risposte_rap"
		version false
	}

	static constraints = {
		risposta nullable: false
		codiceRitorno nullable: false, maxSize: 10
		codFiscaleRap nullable: true, maxSize: 16
		codiceCarica nullable: true, maxSize: 1
		dataDecorrenza nullable: true
		dataFineCarica nullable: true
	}
}
