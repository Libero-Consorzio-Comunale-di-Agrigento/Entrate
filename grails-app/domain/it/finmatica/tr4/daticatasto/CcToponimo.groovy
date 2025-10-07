package it.finmatica.tr4.daticatasto

class CcToponimo {

	String descrizione
	
	static mapping = {
		id column: "id_toponimo"
		version false
		table "web_cc_toponimi"
	}
}
