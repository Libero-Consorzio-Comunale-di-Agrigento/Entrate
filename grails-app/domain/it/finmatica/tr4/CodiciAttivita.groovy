package it.finmatica.tr4

class CodiciAttivita {

	String id
	String codAttivita
	String descrizione
	String flagReale

	static mapping = {
		id name: "codAttivita", generator: "assigned"
		version false
	}

	static constraints = {
		codAttivita maxSize: 5
		descrizione nullable: true, maxSize: 250
		flagReale nullable: true, maxSize: 1
	}
}
