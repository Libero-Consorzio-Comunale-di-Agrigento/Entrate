package it.finmatica.tr4

class TipoOggetto {

	long tipoOggetto
	String descrizione

	static hasMany = [ oggettiTributo:		OggettoTributo
					 , rivalutazioniRendita: RivalutazioneRendita]
	
	static mapping = {
		id name: "tipoOggetto", generator: "assigned"
		
		table "tipi_oggetto"
		sort "tipoOggetto"
		version false
	}

	static constraints = {
		descrizione maxSize: 60
	}
}
