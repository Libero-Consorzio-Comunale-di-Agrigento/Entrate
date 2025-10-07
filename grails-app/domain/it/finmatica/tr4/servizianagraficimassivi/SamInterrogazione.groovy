package it.finmatica.tr4.servizianagraficimassivi

class SamInterrogazione {
	
	Long id
	String codFiscale
	String codFiscaleIniziale
	String identificativoEnte
	Long elaborazioneId
	Long attivitaId
	
	SamTipo tipo

	static hasMany = []

	static mapping = {
		id column: "interrogazione", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "SAM_INTERROGAZIONI_NR"]
		
		tipo column: "tipo"
		identificativoEnte : "identificativo_ente"
		elaborazioneId : "elaborazione_id"
		attivitaId: "attivita_id"
		
		table "sam_interrogazioni"
		version false
	}

	static constraints = {
		tipo nullable: false, maxSize: 15
		codFiscale nullable: false, maxSize: 16
		codFiscaleIniziale nullable: false, maxSize: 16
		identificativoEnte nullable: false, maxSize: 15
		attivitaId maxSize: 10, nullable: true
	}
}
