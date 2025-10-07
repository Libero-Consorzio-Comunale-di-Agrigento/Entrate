package it.finmatica.tr4.pratiche

import java.io.Serializable;

import it.finmatica.tr4.*
import it.finmatica.tr4.commons.*

class CreditoRavvedimento implements Serializable, Comparable<CreditoRavvedimento> {

	Short sequenza
	
	String descrizione
	Short anno
	Short rata
	Long ruolo
	Date dataPagamento
	BigDecimal importoVersato
	BigDecimal sanzioni
	BigDecimal interessi
	BigDecimal altro
	String codIUV
    String note

    String utente
    Date lastUpdated

    static belongsTo = [pratica: PraticaTributo]

    static mapping = {
        id composite: ["pratica", "sequenza"]
		
        pratica				column: "pratica"
        anno				column: "anno"
		rata				column: "rata"
		importoVersato		column: "importo_versato"
		dataPagamento		column: "data_pagamento", sqlType: 'Date'
		ruolo				column: "ruolo"
		codIUV				column: "cod_iuv"
		note				column: "note"
		
        utente				column: "utente"
        lastUpdated			column: "data_variazione", sqlType: 'Date'

        table 'crediti_ravvedimento'

        version false
    }

    static constraints = {
	
		sequenza		nullable: false, maxSize: 4
		
		descrizione		nullable: false, maxSize: 200
		anno			nullable: false, maxSize: 4
		rata			nullable: false, maxSize: 2
		ruolo			nullable: true, maxSize: 10
		dataPagamento	nullable: false
		importoVersato	nullable: false
		sanzioni		nullable: true
		interessi		nullable: true
		altro			nullable: true
		codIUV			nullable: true, maxSize: 35
        note			nullable: true, maxSize: 2000
		
        utente			maxSize: 8
        lastUpdated		nullable: true
    }
	
	int compareTo(CreditoRavvedimento obj) {
		obj.pratica <=> pratica ?: obj.sequenza <=> sequenza
	}
}
