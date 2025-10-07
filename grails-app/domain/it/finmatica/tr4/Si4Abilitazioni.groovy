package it.finmatica.tr4

class Si4Abilitazioni {

	Si4TipiAbilitazione si4TipiAbilitazione
	Si4TipiOggetto si4TipiOggetto

	static hasMany = [si4Competenzes: Si4Competenze]
	static belongsTo = [Si4TipiAbilitazione, Si4TipiOggetto]

	static mapping = {
		id column: "ID_ABILITAZIONE", generator: "assigned"
		version false
		table "SI4_ABILITAZIONI"
		si4TipiAbilitazione column: "ID_TIPO_ABILITAZIONE"
		si4TipiOggetto		column: "ID_TIPO_OGGETTO"
	}
}
