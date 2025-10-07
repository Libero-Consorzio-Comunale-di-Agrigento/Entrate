package it.finmatica.tr4.imposte.supportoservizi

class FiltroRicercaSupportoServizi {

	String tipoTributo
	Short annoDa
	Short annoA
	def utenti
	Integer oggettiNumDa
	Integer oggettiNumA
	String tipoImmobili
	String tipologia
	def segnalazioniIniziali
	def segnalazioniUltime
	String codFiscale
	String cognome
	String nome
	String tipoPersona
	def tipiAtto
	Double differenzaImpostaDa
	Double differenzaImpostaA
	Double minPossessoDa
	Double minPossessoA

	/*
        Solo per i BandBox
    */
	def id
	def contribuente
	String cognomeNome

	FiltroRicercaSupportoServizi() {

		pulisci()
	}

	boolean isDirty() {

		return (this.tipoTributo != null) ||
				(this.annoDa != null) ||
				(this.annoA != null) ||
				(this.utenti.size() > 0) ||
				(this.oggettiNumDa != null) ||
				(this.oggettiNumA != null) ||
				(this.tipoImmobili != null) ||
				(this.tipologia != null) ||
				(this.segnalazioniIniziali.size() > 0) ||
				(this.segnalazioniUltime.size() > 0) ||
				(this.codFiscale != null) ||
				(this.cognome != null) ||
				(this.nome != null) ||
				(this.tipoPersona != null) ||
				(this.tipiAtto.size() > 0) ||
				(this.differenzaImpostaDa != null) ||
				(this.differenzaImpostaA != null) ||
				(this.minPossessoDa != null) ||
				(this.minPossessoA != null)
	}

	void pulisci() {

		this.tipoTributo = null
		this.annoDa = null
		this.annoA = null
		this.utenti = []
		this.oggettiNumDa = null
		this.oggettiNumA = null
		this.tipoImmobili = null
		this.tipologia = null
		this.segnalazioniIniziali = []
		this.segnalazioniUltime = []
		this.codFiscale = null
		this.cognome = null
		this.nome = null
		this.tipoPersona = null
		this.tipiAtto = []
		this.differenzaImpostaDa = null
		this.differenzaImpostaA = null
		this.minPossessoDa = null
		this.minPossessoA = null
	}

	def prepara() {

		def filtri = [
				tipoTributo         : this.tipoTributo,
				annoDa              : this.annoDa,
				annoA               : this.annoA,
				utenti              : this.utenti,
				oggettiNumDa        : this.oggettiNumDa,
				oggettiNumA         : this.oggettiNumA,
				tipoImmobili        : this.tipoImmobili,
				tipologia           : this.tipologia,
				segnalazioniIniziali: this.segnalazioniIniziali,
				segnalazioniUltime  : this.segnalazioniUltime,
				codFiscale          : this.codFiscale,
				cognome             : this.cognome,
				nome                : this.nome,
				tipoPersona         : this.tipoPersona,
				tipiAtto            : this.tipiAtto,
				differenzaImpostaDa : this.differenzaImpostaDa,
				differenzaImpostaA  : this.differenzaImpostaA,
				minPossessoDa       : this.minPossessoDa,
				minPossessoA        : this.minPossessoA,
		]

		return filtri
	}
}
