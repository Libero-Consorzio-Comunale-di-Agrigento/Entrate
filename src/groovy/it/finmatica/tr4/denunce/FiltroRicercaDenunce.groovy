package it.finmatica.tr4.denunce

import it.finmatica.tr4.dto.FonteDTO
import it.finmatica.tr4.sportello.FiltroRicercaCanoni

class FiltroRicercaDenunce {

    String cognomeNome = ""
    String cognome = ""
    String nome = ""
    String cf = ""
    Long numeroIndividuale
    Integer codContribuente

    String daNumero
    String aNumero
    Short daAnno
    Short aAnno
    Long daNumeroPratica
    Long aNumeroPratica
    Boolean filtroDocVisibile
    HashMap<BigDecimal,String> document

    FonteDTO fonte
    Date daData
    Date aData = new Date().clearTime()
    boolean dichiaranti
    boolean frontespizio
    boolean flagEsclusione
    boolean doppie
    boolean flagAbitazionePrincipale
	
	def codiciTributo = []
	def tipiTariffa = []

    def tipoPratica
    boolean flagAnnullamento

	FiltroRicercaCanoni filtriAggiunti
}
