package it.finmatica.tr4

class TipoContatto {

	Integer id
	Integer tipoContatto
	String descrizione
	//String tipoTributo

	static mapping = {
		id name: "tipoContatto", generator: "assigned"
		table 'tipi_contatto'
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
}
