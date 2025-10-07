package it.finmatica.tr4

class MotivoSgravio {

	String descrizione

	static mapping = {
		id column: "motivo_sgravio", generator: "assigned"
		
		table "motivi_sgravio"
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
}
