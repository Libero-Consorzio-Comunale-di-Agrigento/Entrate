package it.finmatica.tr4

class Si4TipiAbilitazione {

	String tipoAbilitazione
	String descrizione

	static hasMany = [si4Abilitazionis: Si4Abilitazioni]

	static mapping = {
		id column: "ID_TIPO_ABILITAZIONE", generator: "assigned"
		version false
		table "SI4_TIPI_ABILITAZIONE"
	}

	static constraints = {
		tipoAbilitazione maxSize: 2, unique: true
		descrizione nullable: true, maxSize: 2000
	}
}
