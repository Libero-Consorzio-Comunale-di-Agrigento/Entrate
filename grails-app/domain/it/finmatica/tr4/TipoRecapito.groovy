package it.finmatica.tr4

class TipoRecapito {

	String descrizione

	static mapping = {
		id column: "tipo_recapito", generator: "assigned"
		
		table "tipi_recapito"
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
	
	String toString() {
		return "$id - $descrizione"
	}
}
