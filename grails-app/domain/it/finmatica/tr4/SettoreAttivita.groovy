package it.finmatica.tr4

class SettoreAttivita {

	long settore
	String descrizione

	static mapping = {
		id name: "settore", generator: "assigned"
		table 'settori_attivita'
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
}
