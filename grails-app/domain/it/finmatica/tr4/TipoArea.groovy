package it.finmatica.tr4

class TipoArea {

	String descrizione

	static mapping = {
		id column: "tipo_area", generator: "assigned"
		table	"tipi_area"
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
}
