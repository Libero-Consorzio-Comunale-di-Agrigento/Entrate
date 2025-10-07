package it.finmatica.tr4

import java.io.Serializable;

import it.finmatica.so4.struttura.So4Amministrazione
import it.finmatica.tr4.tipi.SiNoType

import org.apache.commons.lang.builder.EqualsBuilder
import org.apache.commons.lang.builder.HashCodeBuilder

class CategoriaRaw implements Serializable {
	
	Short 				tributo
	Short 				categoria
	String 				descrizione
	Short 				categoriaRif
	String 				descrizionePrec
	String 				flagDomestica
	String 				flagGiorni
	Boolean				flagNoDepag
	
	String 				idCategoria
	
	static mapping = {
		id 				composite: ["tributo", "categoria" ]
		
		flagNoDepag type: SiNoType

		table "categorie"
		
		version false
	}

	static constraints = {
		descrizione 	maxSize: 100
		categoriaRif 	nullable: true
		descrizionePrec nullable: true, maxSize: 100
		flagDomestica 	nullable: true, maxSize: 1
		flagGiorni 		nullable: true, maxSize: 1
		flagNoDepag 	nullable: true
		
		idCategoria		nullable: false, maxSize: 20
	}
	
	def springSecurityService
	static transients = ['springSecurityService']
	
}
