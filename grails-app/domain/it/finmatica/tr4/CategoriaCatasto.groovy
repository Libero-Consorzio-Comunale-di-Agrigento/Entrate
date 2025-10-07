package it.finmatica.tr4

import it.finmatica.tr4.tipi.SiNoType

class CategoriaCatasto implements Serializable {

	String categoriaCatasto
	String descrizione
	boolean flagReale
	String eccezione

	static mapping = {
		id name: "categoriaCatasto", generator: "assigned"
		table 'categorie_catasto'
		
		flagReale type: SiNoType
		sort "categoriaCatasto"
		version false
	}

	static constraints = {
		categoriaCatasto maxSize: 3
		descrizione maxSize: 200
		flagReale nullable: true, maxSize: 1
		eccezione nullable: true, maxSize: 1
	}
}
