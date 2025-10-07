package it.finmatica.tr4.servizianagraficimassivi

import groovy.sql.Sql

class SamCodiceCarica {

	String codCarica
	String descrizione

	static mapping = {
		id name: "codCarica", generator: "assigned"
		
		table "sam_codici_carica"
		version false
	}

	static constraints = {
		codCarica maxSize: 2
		descrizione nullable: true, maxSize: 100
	}
}
