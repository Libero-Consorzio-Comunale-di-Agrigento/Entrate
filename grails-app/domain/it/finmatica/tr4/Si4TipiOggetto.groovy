package it.finmatica.tr4

class Si4TipiOggetto {

	String tipoOggetto
	String descrizione

	static hasMany = [si4Abilitazionis: Si4Abilitazioni]

	static mapping = {
		id column: "ID_TIPO_OGGETTO", generator: "assigned"
		version false
		table "SI4_TIPI_OGGETTO"
	}

	static constraints = {
		tipoOggetto maxSize: 30, unique: true
		descrizione nullable: true, maxSize: 2000
	}
}
