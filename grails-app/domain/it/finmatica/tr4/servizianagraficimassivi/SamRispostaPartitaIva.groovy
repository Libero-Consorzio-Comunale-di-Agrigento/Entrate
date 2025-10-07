package it.finmatica.tr4.servizianagraficimassivi

class SamRispostaPartitaIva {
	
	Long id
	
	String partitaIva
	String codAttivita
	String tipologiaCodifica
	String stato
	Date dataCessazione
	String partitaIvaConfluenza
	
	SamRisposta risposta
	
	SamCodiceRitorno codiceRitorno
	SamTipoCessazione tipoCessazione
	
	static hasMany = []

	static mapping = {
		id column: "risposta_partita_iva", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "SAM_RISPOSTE_PARTITA_IVA_NR"]
		risposta column: "risposta_interrogazione"
		codiceRitorno column: "cod_ritorno"
		tipoCessazione column: "tipo_cessazione"

		table "sam_risposte_partita_iva"
		version false
	}

	static constraints = {
		risposta nullable: false
		codiceRitorno nullable: false, maxSize: 10
		tipoCessazione nullable: true, maxSize: 16
		dataCessazione nullable: true
		partitaIvaConfluenza nullable: true
	}
}

