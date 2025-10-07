package it.finmatica.tr4

import it.finmatica.tr4.tipi.SiNoType

class Categoria {
	
	//CodiceTributo 			tributo
	Short 					categoria
	String 					descrizione
	Short 					categoriaRif
	String 					descrizionePrec
	String 					flagDomestica
	String 					flagGiorni
	Boolean					flagNoDepag
	
	static belongsTo = [codiceTributo: CodiceTributo]
	
	static hasMany = [tariffe: Tariffa]
	
	static mapping = {
		id				column: "id_categoria", generator: "assigned"
		codiceTributo	column: "tributo"
		
		flagNoDepag type: SiNoType

		table "web_categorie"
		
		version false
	}

	static constraints = {
		descrizione 	maxSize: 100
		categoriaRif 	nullable: true
		descrizionePrec nullable: true, maxSize: 100
		flagDomestica 	nullable: true, maxSize: 1
		flagGiorni 		nullable: true, maxSize: 1
		flagNoDepag 	nullable: true
	}
	
	def springSecurityService
	static transients = ['springSecurityService']

	def beforeInsert() {
		this.descrizione = this.descrizione?.toUpperCase()
		this.descrizionePrec = this.descrizionePrec?.toUpperCase()
	}

	def beforeUpdate() {
		this.descrizione = this.descrizione?.toUpperCase()
		this.descrizionePrec = this.descrizionePrec?.toUpperCase()
	}
	
}
