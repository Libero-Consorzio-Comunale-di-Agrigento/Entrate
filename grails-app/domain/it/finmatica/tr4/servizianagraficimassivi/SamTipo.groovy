package it.finmatica.tr4.servizianagraficimassivi

class SamTipo {

	String tipo
	String descrizione

	static hasMany = [ ]

	static mapping = {
		id name: "tipo", generator: "assigned"
		
		table "sam_tipi"
		version false
	}

	static constraints = {
		tipo nullable: false, maxSize: 15
		descrizione maxSize: 100
	}
}
