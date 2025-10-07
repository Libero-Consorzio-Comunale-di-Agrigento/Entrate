package it.finmatica.tr4.archivio

import it.finmatica.tr4.dto.CategoriaCatastoDTO
import it.finmatica.tr4.dto.TipoOggettoDTO
import it.finmatica.tr4.dto.TipoUtilizzoDTO

import java.text.DecimalFormat

class FiltroRicercaOggettoPerVia {

	int id
	def tipoOggetto
	String indirizzo
	String codiceVie

	String numCivDa
	String numCivA
	String tipoNumeroCivico = "T"

	Long progressivo
	String cessato = "n"
	Long situazioneAnno
	BigDecimal renditaDa
	BigDecimal renditaA
	BigDecimal consDa
	BigDecimal consA

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

	boolean cbStampaProprietari = false
	boolean cbStampaCessati = false
	boolean cbAbitazionePrincipale = false
	boolean cbEsclusi = false
	boolean cbRidotti = false

	def tipoUtilizzo
	Long situazioneAnnoRif

	def ordinamento ="indirizzo"

	LinkedHashMap<Object, Object> listaCampiRicerca = [:]

	def getListaCampiRicerca(def tipiTributo) {
		String pattern = "#######.00"
		DecimalFormat valuta = new DecimalFormat(pattern)

		if (tipoOggetto){
		   if(!(tipoOggetto.key.equals("Tutti"))) {
			   listaCampiRicerca << ['tipo_oggetto': tipoOggetto.key]
		   }
		}
		if (codiceVie) {
			listaCampiRicerca << ['indirizzo': codiceVie]
		}
		if (numCivDa || numCivA) {
			listaCampiRicerca << ['civico_da': (numCivDa?numCivDa:"")]
			listaCampiRicerca << ['civico_a' : (numCivA?numCivA:"")]
		}
		if (tipoNumeroCivico){
			listaCampiRicerca << ['tipo_numero_civico': tipoNumeroCivico]
		}
		if (progressivo) {
			listaCampiRicerca << ['oggetto': progressivo]
		}
		if (cessato == "s") {
			listaCampiRicerca << ['cessato': 'S']
		}
		else {
			listaCampiRicerca << ['cessato': 'N']
		}
		if (situazioneAnno) {
			listaCampiRicerca << ['situazione_anno': situazioneAnno]
		}
		if (renditaDa || renditaA) {
			listaCampiRicerca << ['rendita_da': (renditaDa?valuta.format(renditaDa).replaceAll(",","."):"")]
			listaCampiRicerca << ['rendita_a': (renditaA?valuta.format(renditaA).replaceAll(",","."):"")]
		}
		if (consDa || consA) {
			listaCampiRicerca << ['cons_da': (consDa?valuta.format(consDa).replaceAll(",","."):"")]
			listaCampiRicerca << ['cons_a': (consA?valuta.format(consA).replaceAll(",","."):"")]
	    }
		if (partita){
			listaCampiRicerca << ['partita': partita]
		}
		if (sezione){
			listaCampiRicerca << ['sezione': sezione]
		}
		if (foglio){
			listaCampiRicerca << ['foglio': foglio]
		}
		if (numero){
			listaCampiRicerca << ['numero': numero]
		}
		if (subalterno){
			listaCampiRicerca << ['subalterno': subalterno]
		}
		if (zona){
			listaCampiRicerca << ['zona': zona]
		}
		if (protocolloCatasto){
			listaCampiRicerca << ['protocollo_catasto': protocolloCatasto]
		}
		if (annoCatasto){
			listaCampiRicerca << ['anno_catasto': annoCatasto]
		}
		if (categoriaCatasto){
			listaCampiRicerca << ['categoria': categoriaCatasto.categoriaCatasto]
		}

		if (classeCatasto) {
			listaCampiRicerca << ['classe': classeCatasto]
		}

		listaCampiRicerca << ['stampa_proprietari': (cbStampaProprietari)?'S':'N']
		listaCampiRicerca << ['stampa_cessati': (cbStampaCessati)?'S':'N']
		listaCampiRicerca << ['abitazione_principale': (cbAbitazionePrincipale)?'S':'N']
		listaCampiRicerca << ['esclusi': (cbEsclusi)?'S':'N']
		listaCampiRicerca << ['ridotti': (cbRidotti)?'S':'N']

		if (tipoUtilizzo){
			if(!(tipoUtilizzo.key.equals("Tutti"))) {
				listaCampiRicerca << ['tipo_utilizzo': tipoUtilizzo.key]
			}
		}
		if (situazioneAnnoRif) {
			listaCampiRicerca << ['situazioneAnnoRif': situazioneAnnoRif]
		}
		if (ordinamento == "indirizzo") {
			listaCampiRicerca << ['ordinamento': 'indirizzo']
		}
		else {
			listaCampiRicerca << ['ordinamento': 'estremi']
		}

		if(tipiTributo){
            int num = 0
			for (def t : tipiTributo.entrySet()) {
				if(t.getValue()) {
					num++
				}
			}
			//Se sono tutti settati allora non passo nessuna condizione così tira fuori anche altri tipi di tributo
			if(num != tipiTributo.size()){
				listaCampiRicerca << ['tipiTributo': tipiTributo]
			}
		}

		return listaCampiRicerca
	}


}
