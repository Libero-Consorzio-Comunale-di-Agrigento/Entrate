package it.finmatica.tr4.archivio

import it.finmatica.tr4.dto.CategoriaCatastoDTO
import it.finmatica.tr4.dto.FonteDTO
import it.finmatica.tr4.dto.TipoOggettoDTO
import it.finmatica.tr4.dto.TipoTributoDTO

import java.text.DecimalFormat

class FiltroRicercaOggetto {

	int id
	Integer immobile
	String tipoOggettoCatasto = "F"
	String tipoOggettoCatastoMultiplo = "F"
	TipoOggettoDTO tipoOggetto
	Long progressivo
	String indirizzoCompleto
	String indirizzo
	String numCiv
	def interno
	String descrizione
	String scala
	String suffisso
	BigDecimal valoreDa
	BigDecimal valoreA
	BigDecimal renditaDa
	BigDecimal renditaA
	String cessato = "n"
	String partita
	String sezione
	String foglio
	String zona
	String subalterno
	String numero
	String protocolloCatasto
	Short annoCatasto
	CategoriaCatastoDTO categoriaCatasto
	String classeCatasto
	FonteDTO fonte
	boolean inPratica
	TipoTributoDTO tipoTributo
	Date dataCessazioneDal
	Date dataCessazioneAl
	String codEcografico
	Date validitaDal
    Date validitaAl
	Date validitaFineDal
	Date validitaFineAl
	BigDecimal consistenzaDa
	BigDecimal consistenzaA
	BigDecimal latitudineDa
	BigDecimal latitudineA
	BigDecimal longitudineDa
	BigDecimal longitudineA
	BigDecimal aLatitudineDa
	BigDecimal aLatitudineA
	BigDecimal aLongitudineDa
	BigDecimal aLongitudineA
	String note

	def filtriSoggetto = [  contribuente:	"s"
		, cognomeNome:	""
		, cognome:		""
		, nome:			""
		, codFiscale:		""
		, indirizzo:		""
		, id:				null]

	Map cbTributi = [ TASI: true
		, IMU: true
		, TARI: true
		, COSAP: true
		, PUBBLICITA: true ]

	Map cbTipiPratica = [ D: false
		, A: false
		, L: false]

	String getCampiRicerca() {

		String pattern = "#,###.00"
		DecimalFormat valutaFormat = new DecimalFormat("${pattern} €")
		DecimalFormat numeroFormat = new DecimalFormat(pattern)

		String filtri = ""

		if (descrizione)
			filtri += "Descrizione: $descrizione, "
		if (progressivo)
			filtri += "Oggetto: $progressivo, "
		if (tipoOggetto)
			filtri += "Tipo ogg.: ${tipoOggetto.tipoOggetto}, "
		if (fonte)
			filtri += "Fonte: ${fonte.fonte}, "
		if (codEcografico)
			filtri += "Cod. Ecog.: ${codEcografico}, "
		if (indirizzo)
			filtri += "Indirizzo: $indirizzo, "
		if (numCiv || suffisso || interno) {
			filtri += "Civico: " + numCiv?:"" + (suffisso?" / $suffisso":"") + (interno?" - $interno":"")
			filtri += ", "
		}
		if (cessato == "s")
			filtri += "Cessato: Si, "
		if (dataCessazioneDal || dataCessazioneAl)
			filtri += "Cessazione: " + (dataCessazioneDal? "dal " + dataCessazioneDal.format("dd/MM/yyyy"):"") + (dataCessazioneAl? " al " + dataCessazioneAl.format("dd/MM/yyyy"):"") + ", "
		if (partita)
			filtri += "Partita: $partita, "
		if (sezione)
			filtri += "Sezione: $sezione, "
		if (foglio)
			filtri += "Foglio: $foglio, "
		if (numero)
			filtri += "Numero: $numero, "
		if (subalterno)
			filtri += "Sub: $subalterno, "
		if (zona)
			filtri += "Zona: $zona, "
		if (protocolloCatasto)
			filtri += "Prot.: $protocolloCatasto, "
		if (annoCatasto)
			filtri += "Anno: $annoCatasto, "
		if (categoriaCatasto)
			filtri += "Categoria: ${categoriaCatasto.categoriaCatasto}, "
		if (classeCatasto)
			filtri += "Classe: $classeCatasto, "
		if (valoreDa || valoreA)
			filtri += "Valore: " + (valoreDa? "da " + valutaFormat.format(valoreDa):"") + (valoreA? " a " + valutaFormat.format(valoreA):"") + ", "
        if (renditaDa || renditaA)
            filtri += "Rendita: " + (renditaDa? "da " + valutaFormat.format(renditaDa):"") + (renditaA? " a " + valutaFormat.format(renditaA):"") + ", "
		if (filtriSoggetto.cognome)
			filtri +="Cognome: ${filtriSoggetto.cognome},"
		if (filtriSoggetto.nome)
			filtri +="Name: ${filtriSoggetto.nome},"
		if (filtriSoggetto.codFiscale)
			filtri +="Codice Fiscale: ${filtriSoggetto.codFiscale},"
		if (consistenzaDa || consistenzaA)
			filtri += "Consistenza: " + (consistenzaDa? "da " + numeroFormat.format(consistenzaDa):"") + (consistenzaA? " a " + numeroFormat.format(consistenzaA):"") + ", "
		if (latitudineDa || latitudineA)
			filtri += "Latitudine Da: " + (latitudineDa? "da " + numeroFormat.format(latitudineDa):"") + (latitudineA? " a " + numeroFormat.format(latitudineA):"") + ", "
		if (longitudineDa || longitudineA)
			filtri += "Longitudine Da: " + (longitudineDa? "da " + numeroFormat.format(longitudineDa):"") + (longitudineA? " a " + numeroFormat.format(longitudineA):"") + ", "
		if (aLatitudineDa || aLatitudineA)
			filtri += "Latitudine A: " + (aLatitudineDa? "da " + numeroFormat.format(aLatitudineDa):"") + (aLatitudineA? " a " + numeroFormat.format(aLatitudineA):"") + ", "
		if (aLongitudineDa || aLongitudineA)
			filtri += "Longitudine A: " + (aLongitudineDa? "da " + numeroFormat.format(aLongitudineDa):"") + (aLongitudineA? " a " + numeroFormat.format(aLongitudineA):"") + ", "
		if (note)
			filtri += "Note: $note, "

		String tributi = ""
		cbTributi.each {
			tributi += (it.value ? it.key + ", " : "")
		}
		if (tributi) {
			tributi = "Tributi: ${tributi}"
			//Se è selezionato il checkbox inPratica allora si aggiunge la condizione tipi tributi
			if(inPratica)
				filtri += tributi
		}

		String tipiPratica = ""
		cbTipiPratica.each {
			switch(it.key) {
				case "D":
					tipiPratica += it.value ? "Dichiarazione, " : ""
					break
				case "A":
					tipiPratica += it.value ? "Accertamento, " : ""
					break
				case "L":
					tipiPratica += it.value ? "Liquidazione, " : ""
					break
			}
		}
		if (tipiPratica) {
			tipiPratica = "Tipi pratica: ${tipiPratica}"
			filtri += tipiPratica
		}

		if (filtri) {
			return filtri.substring(0, filtri.lastIndexOf(","))
		}
		else
			return ""
	}
}
