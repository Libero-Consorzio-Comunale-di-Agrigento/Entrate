package it.finmatica.tr4

class Edificio {

	Short 	numUi
	String 	descrizione
	Long 	amministratore
	String	note

	static mapping = {
		id column: "edificio", generator: "assigned"
		
		table "edifici"
		version false
	}

	static constraints = {
		numUi 			nullable: true
		descrizione 	nullable: true, maxSize: 60
		amministratore 	nullable: true
		note 			nullable: true, maxSize: 2000
	}
}
