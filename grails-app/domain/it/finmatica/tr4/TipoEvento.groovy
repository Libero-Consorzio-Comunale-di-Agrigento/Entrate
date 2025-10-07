package it.finmatica.tr4

class TipoEvento {

	String tipoEvento
	String descrizione

	static mapping = {
		id name: "tipoEvento", generator: "assigned"
		table "tipi_evento"
		
		version false
	}

	static constraints = {
		tipoEvento maxSize: 1
		descrizione nullable: true, maxSize: 60
	}
}