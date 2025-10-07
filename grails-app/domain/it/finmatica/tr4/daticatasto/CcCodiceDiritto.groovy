package it.finmatica.tr4.daticatasto

class CcCodiceDiritto {
	String codice
	String descrizione
	
	static mapping = {
		id name: "codice"
		table "web_cc_codici_diritto"
	}
    
}
