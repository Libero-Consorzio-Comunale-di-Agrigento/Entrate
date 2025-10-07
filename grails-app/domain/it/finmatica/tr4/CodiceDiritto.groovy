package it.finmatica.tr4

class CodiceDiritto {

	String codDiritto
	Short ordinamento
	String descrizione
	String flagTrattaIscrizione
	String flagTrattaCessazione
	String note
	String eccezione

	static mapping = {
		id name: "codDiritto", generator: "assigned"
		
		table "codici_diritto"
		version false
	}

	static constraints = {
		codDiritto maxSize: 4
		descrizione maxSize: 60
		flagTrattaIscrizione nullable: true, maxSize: 1
		flagTrattaCessazione nullable: true, maxSize: 1
		note nullable: true, maxSize: 2000
		eccezione nullable: true, maxSize: 1
	}
}
