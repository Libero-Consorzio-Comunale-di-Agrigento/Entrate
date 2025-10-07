package it.finmatica.tr4.datiesterni

class TitoloDocumento {

	String descrizione
	String tipoCaricamento
	String estensioneMulti
	String estensioneMulti2
	
	String nomeBean
	String nomeMetodo
	
	static hasMany = [parametriImport: ParametroImport]
	
	static mapping = {
		id column: "titolo_documento", generator: "assigned"
		
		table "titoli_documento"
		version false
	}

	static constraints = {
		descrizione nullable: true, maxSize: 100
		tipoCaricamento nullable: true, maxSize: 10
		estensioneMulti nullable: true, maxSize: 10
		estensioneMulti2 nullable: true, maxSize: 10
		
		nomeBean    nullable: true
		nomeMetodo	nullable: true
	}
}
