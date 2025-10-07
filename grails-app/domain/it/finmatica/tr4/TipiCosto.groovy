package it.finmatica.tr4

class TipiCosto {

	String tipoCosto
	String descrizione

	static mapping = {
		id name: "tipoCosto", generator: "assigned"
		version false
	}

	static constraints = {
		tipoCosto maxSize: 8
		descrizione nullable: true, maxSize: 100
	}
}
