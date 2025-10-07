package it.finmatica.tr4

class SogeiDic {

	String tipoRecord
	String dati
	Long numContrib
	Integer progrContrib

	static mapping = {
		id column: "PROGRESSIVO", generator: "assigned"
		version false
	}

	static constraints = {
		tipoRecord maxSize: 1
		dati maxSize: 124
	}
}
