package it.finmatica.tr4

class Fonte {

	long id
	long fonte
	String descrizione

	static mapping = {
		id 		name: "fonte", generator: "assigned"
		table 	'fonti'
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
}
