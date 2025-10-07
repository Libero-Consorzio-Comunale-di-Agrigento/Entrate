package it.finmatica.tr4.servizianagraficimassivi

class SamCodiceRitorno {

	String codRitorno
	String descrizione
	String riscontro
	String esito
	
	static hasMany = [ ]

	static mapping = {
		id name: "codRitorno", generator: "assigned"
		
		table "sam_codici_ritorno"
		version false
	}

	static constraints = {
		codRitorno nullable: false, maxSize: 10
		descrizione maxSize: 100
		riscontro maxSize: 200
		esito maxSize: 2
	}
}
