package it.finmatica.tr4

class TipoCarica {

	String descrizione
	String codSoggetto
	String flagOnline

	static mapping = {
		id column: "tipo_carica", generator: "assigned"
		table 'tipi_carica'
		version false
	}

	static constraints = {
		descrizione nullable: true, maxSize: 60
		codSoggetto nullable: true, maxSize: 1
		flagOnline nullable: true, maxSize: 1
	}
}
