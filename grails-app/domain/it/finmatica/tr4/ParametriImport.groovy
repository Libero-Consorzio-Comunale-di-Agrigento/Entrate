package it.finmatica.tr4

import java.sql.Clob

class ParametriImport {

	String nome
	Clob parametro

	static mapping = {
		id name: "nome", generator: "assigned"
		version false
	}

	static constraints = {
		nome maxSize: 60
		parametro nullable: true
	}
}
