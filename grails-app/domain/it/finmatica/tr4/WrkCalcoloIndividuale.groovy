package it.finmatica.tr4

class WrkCalcoloIndividuale {

	BigDecimal accontoTerreni
	BigDecimal saldoTerreni
	BigDecimal totTerreni
	BigDecimal accontoAree
	BigDecimal saldoAree
	BigDecimal totAree
	BigDecimal accontoAb
	BigDecimal accontoAltri
	BigDecimal saldoAb
	BigDecimal totAb
	BigDecimal saldoAltri
	BigDecimal totAltri
	BigDecimal accontoDetrazione
	BigDecimal saldoDetrazione
	BigDecimal totDetrazione
	BigDecimal totaleTerreni
	BigDecimal numeroFabbricati
	BigDecimal accontoDetrazioneImponibile
	BigDecimal saldoDetrazioneImponibile
	BigDecimal totDetrazioneImponibile
	BigDecimal accontoRurali
	BigDecimal saldoRurali
	BigDecimal totRurali
	BigDecimal accontoTerreniErar
	BigDecimal saldoTerreniErar
	BigDecimal totTerreniErar
	BigDecimal accontoAreeErar
	BigDecimal saldoAreeErar
	BigDecimal totAreeErar
	BigDecimal accontoAltriErar
	BigDecimal saldoAltriErar
	BigDecimal totAltriErar
	BigDecimal numFabbricatiAb
	BigDecimal numFabbricatiRurali
	BigDecimal numFabbricatiAltri
	BigDecimal accontoFabbricatiD
	BigDecimal saldoFabbricatiD
	BigDecimal totFabbricatiD
	BigDecimal accontoFabbricatiDErar
	BigDecimal saldoFabbricatiDErar
	BigDecimal totFabbricatiDErar
	BigDecimal numFabbricatiD

	static mapping = {
		id column: "PRATICA", generator: "assigned"
		version false
		accontoFabbricatiD		column: "acconto_fabbricati_d"
		saldoFabbricatiD        column:	"saldo_fabbricati_d"
		totFabbricatiD          column:	"tot_fabbricati_d"
		accontoFabbricatiDErar  column: "acconto_fabbricati_d_erar"
		saldoFabbricatiDErar    column:	"saldo_fabbricati_d_erar"
		totFabbricatiDErar      column: "tot_fabbricati_d_erar"
		numFabbricatiD          column: "num_fabbricati_d"
	}

	static constraints = {
		accontoTerreni nullable: true
		saldoTerreni nullable: true
		totTerreni nullable: true
		accontoAree nullable: true
		saldoAree nullable: true
		totAree nullable: true
		accontoAb nullable: true
		accontoAltri nullable: true
		saldoAb nullable: true
		totAb nullable: true
		saldoAltri nullable: true
		totAltri nullable: true
		accontoDetrazione nullable: true
		saldoDetrazione nullable: true
		totDetrazione nullable: true
		totaleTerreni nullable: true
		numeroFabbricati nullable: true
		accontoDetrazioneImponibile nullable: true
		saldoDetrazioneImponibile nullable: true
		totDetrazioneImponibile nullable: true
		accontoRurali nullable: true
		saldoRurali nullable: true
		totRurali nullable: true
		accontoTerreniErar nullable: true
		saldoTerreniErar nullable: true
		totTerreniErar nullable: true
		accontoAreeErar nullable: true
		saldoAreeErar nullable: true
		totAreeErar nullable: true
		accontoAltriErar nullable: true
		saldoAltriErar nullable: true
		totAltriErar nullable: true
		numFabbricatiAb nullable: true
		numFabbricatiRurali nullable: true
		numFabbricatiAltri nullable: true
		accontoFabbricatiD nullable: true
		saldoFabbricatiD nullable: true
		totFabbricatiD nullable: true
		accontoFabbricatiDErar nullable: true
		saldoFabbricatiDErar nullable: true
		totFabbricatiDErar nullable: true
		numFabbricatiD nullable: true
	}
}
