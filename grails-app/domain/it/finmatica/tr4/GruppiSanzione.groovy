package it.finmatica.tr4

class GruppiSanzione {

	Short gruppoSanzione
	String descrizione
	String stampaTotale

	static mapping = {
		id name: "gruppoSanzione", generator: "assigned"
		version false
	}

	static constraints = {
		descrizione maxSize: 60
		stampaTotale nullable: true, maxSize: 1
	}
}
