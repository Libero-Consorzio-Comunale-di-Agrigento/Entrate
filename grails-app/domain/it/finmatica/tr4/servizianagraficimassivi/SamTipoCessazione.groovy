package it.finmatica.tr4.servizianagraficimassivi

class SamTipoCessazione {

	String tipoCessazione
	String descrizione

	static hasMany = [ ]

	static mapping = {
		id name: "tipoCessazione", generator: "assigned"
		
		table "sam_tipi_cessazione"
		version false
	}

	static constraints = {
		tipoCessazione nullable: false, maxSize: 1
		descrizione maxSize: 100
	}
}
