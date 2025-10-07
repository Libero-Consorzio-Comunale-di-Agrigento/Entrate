package it.finmatica.tr4.daticatasto

class CodiceQualita {
	String descrizione
	
	static mapping = {
		id column: "id_codice_qualita"
		table "web_cc_codici_qualita"	
	}
    
}
