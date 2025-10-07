package it.finmatica.tr4

class InstallazioneParametro {

	String id
	String parametro
	String valore
	String descrizione

	static mapping = {
		id name: "parametro", generator: "assigned"
		table 	"installazione_parametri"
		version false
	}

	static constraints = {
		parametro maxSize: 10
		valore nullable: true, maxSize: 2000
		descrizione nullable: true, maxSize: 200
	}
}
