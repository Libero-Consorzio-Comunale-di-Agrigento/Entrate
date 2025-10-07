package it.finmatica.tr4

class AnciVar {

	String tipoRecord
	String dati
	Integer numeroPacco
	Integer progressivoRecord
	String dati1
	String dati2
	String dati3

	static mapping = {
		id column: "PROGRESSIVO", generator: "assigned"
		version false
		dati1 column: "DATI_1"
		dati2 column: "DATI_2"
		dati3 column: "DATI_3"
	}

	static constraints = {
		tipoRecord maxSize: 1
		dati maxSize: 17
		dati1 maxSize: 215
		dati2 nullable: true, maxSize: 242
		dati3 nullable: true, maxSize: 10
	}
}
