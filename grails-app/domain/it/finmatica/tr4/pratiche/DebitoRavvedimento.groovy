package it.finmatica.tr4.pratiche

import java.io.Serializable;
import java.util.Date;

import it.finmatica.tr4.*
import it.finmatica.tr4.commons.*

class DebitoRavvedimento implements Serializable, Comparable<DebitoRavvedimento> {
	
    Long ruolo
	
	Date scadenzaPrimaRata
	Date scadenzaRata2
	Date scadenzaRata3
	Date scadenzaRata4
	
	BigDecimal importoPrimaRata
	BigDecimal importoRata2
	BigDecimal importoRata3
	BigDecimal importoRata4
	
	BigDecimal versatoPrimaRata
	BigDecimal versatoRata2
	BigDecimal versatoRata3
	BigDecimal versatoRata4

	BigDecimal maggiorazioneTaresPrimaRata
	BigDecimal maggiorazioneTaresRata2
	BigDecimal maggiorazioneTaresRata3
	BigDecimal maggiorazioneTaresRata4

	String note

	String utente
    Date lastUpdated

    static belongsTo = [pratica: PraticaTributo]

	static mapping = {
		id composite: ["pratica", "ruolo"]

        pratica				column: "pratica"
		ruolo				column: "ruolo"
		
		scadenzaPrimaRata	sqlType: 'Date', column: 'scadenza_prima_rata'
		scadenzaRata2		sqlType: 'Date', column: 'scadenza_rata_2'
		scadenzaRata3		sqlType: 'Date', column: 'scadenza_rata_3'
		scadenzaRata4		sqlType: 'Date', column: 'scadenza_rata_4'
		
		importoPrimaRata	column: 'importo_prima_rata'
		importoRata2		column: 'importo_rata_2'
		importoRata3		column: 'importo_rata_3'
		importoRata4		column: 'importo_rata_4'
		
		versatoPrimaRata	column: 'versato_prima_rata'
		versatoRata2		column: 'versato_rata_2'
		versatoRata3		column: 'versato_rata_3'
		versatoRata4		column: 'versato_rata_4'
		
		maggiorazioneTaresPrimaRata		column: 'maggiorazione_tares_prima_rata'
		maggiorazioneTaresRata2		column: 'maggiorazione_tares_rata_2'
		maggiorazioneTaresRata3		column: 'maggiorazione_tares_rata_3'
		maggiorazioneTaresRata4		column: 'maggiorazione_tares_rata_4'

		utente				column: "utente"
		lastUpdated			column: "data_variazione", sqlType: 'Date'

		table 'debiti_ravvedimento'
		version false
	}

	static constraints = {
		ruolo				nullable: true
		
        scadenzaPrimaRata	nullable: false
        scadenzaRata2		nullable: true
        scadenzaRata3		nullable: true
        scadenzaRata4		nullable: true
		
		importoPrimaRata	nullable: false
		importoRata2		nullable: true
		importoRata3		nullable: true
		importoRata4		nullable: true
		
		versatoPrimaRata	nullable: true
		versatoRata2		nullable: true
		versatoRata3		nullable: true
		versatoRata4		nullable: true
	
		maggiorazioneTaresPrimaRata	nullable: true
		maggiorazioneTaresRata2		nullable: true
		maggiorazioneTaresRata3		nullable: true
		maggiorazioneTaresRata4		nullable: true

        note				nullable: true, maxSize: 2000
		
        utente				maxSize: 8
        lastUpdated			nullable: true
    }
	
	int compareTo(DebitoRavvedimento obj) {
		obj.pratica <=> pratica ?: obj.ruolo <=> obj
	}
}
