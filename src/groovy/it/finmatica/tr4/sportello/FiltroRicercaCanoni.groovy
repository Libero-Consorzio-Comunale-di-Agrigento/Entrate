package it.finmatica.tr4.sportello

class FiltroRicercaCanoni {
	
	String descrizione
	String indirizzo
	String localita
	Short codPro
	Short codCom
	Double daKMDa
	Double daKMA
	Double aKMDa
	Double aKMA
	Double latitudineDa
	Double latitudineA
	Double longitudineDa
	Double longitudineA
	Double aLatitudineDa
	Double aLatitudineA
	Double aLongitudineDa
	Double aLongitudineA
	def concessioneDa
	def concessioneA
	def dataConcessioneDa
	def dataConcessioneA
	def flagNullaOsta
	def tariffa
	def esenzione
	
	FiltroRicercaCanoni() {
		pulisci()
	}
	
	def pulisci() {
		
		this.descrizione = null
		this.indirizzo = null
		this.localita = null
		this.codPro = null
		this.codCom = null
		this.daKMDa = null
		this.daKMA = null
		this.aKMDa = null
		this.aKMA = null
		this.latitudineDa = null
		this.latitudineA = null
		this.longitudineDa = null
		this.longitudineA = null
		this.aLatitudineDa = null
		this.aLatitudineA = null
		this.aLongitudineDa = null
		this.aLongitudineA = null
		this.concessioneDa = null
		this.concessioneA = null
		this.dataConcessioneDa = null
		this.dataConcessioneA = null
        this.flagNullaOsta = null
		this.tariffa = null
		this.esenzione = null
	}
	
	Boolean isDirty() {
		
		return (this.descrizione != null) ||
				(this.indirizzo != null) ||
				(this.localita != null) ||
                (this.codPro != null) ||
                (this.codCom != null) ||
                (this.daKMDa != null) ||
                (this.daKMA != null) ||
                (this.aKMDa != null) ||
                (this.aKMA != null) ||
				(this.latitudineDa != null) ||
				(this.latitudineA != null) ||
				(this.longitudineDa != null) ||
				(this.longitudineA != null) ||
				(this.aLatitudineDa != null) ||
				(this.aLatitudineA != null) ||
				(this.aLongitudineDa != null) ||
				(this.aLongitudineA != null) ||
                (this.concessioneDa != null) ||
                (this.concessioneA != null) ||
                (this.dataConcessioneDa != null) ||
                (this.dataConcessioneA != null) ||
                (this.flagNullaOsta != null) ||
                (this.tariffa != null) ||
				(this.esenzione != null)
	}
}
