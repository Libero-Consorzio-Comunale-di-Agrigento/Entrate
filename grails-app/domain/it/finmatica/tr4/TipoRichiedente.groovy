package it.finmatica.tr4

class TipoRichiedente {

	Integer id
	Integer tipoRichiedente
	String descrizione

	static mapping = {
		id name: "tipoRichiedente", generator: "assigned"
		table 'tipi_richiedente'
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
}
