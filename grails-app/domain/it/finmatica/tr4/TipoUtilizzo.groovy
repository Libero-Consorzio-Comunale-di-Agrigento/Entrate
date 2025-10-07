package it.finmatica.tr4

class TipoUtilizzo {

	String descrizione

	static mapping = {
		id column: "tipo_utilizzo", generator: "assigned"
		
		table "tipi_utilizzo"
		version false
	}
	
	static hasMany = [utilizziTributo: UtilizzoTributo]
	
	static constraints = {
		descrizione maxSize: 60
	}
}
