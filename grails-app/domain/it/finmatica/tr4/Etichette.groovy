package it.finmatica.tr4

class Etichette {

	Byte etichetta
	String descrizione
	BigDecimal altezza
	BigDecimal larghezza
	Short righe
	Boolean colonne
	BigDecimal spazioTraRighe
	BigDecimal spazioTraColonne
	String modulo
	String orientamento
	BigDecimal sopra
	BigDecimal sinistra
	String note

	static mapping = {
		id name: "etichetta", generator: "assigned"
		version false
	}

	static constraints = {
		descrizione maxSize: 60
		righe nullable: true
		modulo maxSize: 1
		orientamento nullable: true, maxSize: 1
		sopra nullable: true
		sinistra nullable: true
		note nullable: true, maxSize: 2000
	}
}
