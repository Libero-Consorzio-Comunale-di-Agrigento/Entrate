package it.finmatica.tr4.servizianagraficimassivi

class SamFonteDecesso {

	String fonteDecesso
	String descrizione

	static hasMany = [ ]

	static mapping = {
		id name: "fonteDecesso", generator: "assigned"
		
		table "sam_fonti_decesso"
		version false
	}

	static constraints = {
		fonteDecesso nullable: false, maxSize: 2
		descrizione maxSize: 100
	}
}
