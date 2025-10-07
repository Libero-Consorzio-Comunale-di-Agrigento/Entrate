package it.finmatica.tr4.servizianagraficimassivi

class SamFonteDomSede {

	String fonte
	String descrizione

	static hasMany = [ ]

	static mapping = {
		id name: "fonte", generator: "assigned"
		
		table "sam_fonti_dom_sede"
		version false
	}

	static constraints = {
		fonte nullable: false, maxSize: 2
		descrizione maxSize: 100
	}
}
