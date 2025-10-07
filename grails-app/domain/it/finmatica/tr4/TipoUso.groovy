package it.finmatica.tr4

class TipoUso {

	//long tipoUso
	String descrizione

	static mapping = {
		id column: "tipo_uso", generator: "assigned"
		
		table "tipi_uso"
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
}
