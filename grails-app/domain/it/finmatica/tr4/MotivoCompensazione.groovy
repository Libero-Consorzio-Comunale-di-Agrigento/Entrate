package it.finmatica.tr4

class MotivoCompensazione {

	String descrizione

	static mapping = {
		id column: "motivo_compensazione", generator: "assigned"
		
		table "motivi_compensazione"
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
}
