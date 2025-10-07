package it.finmatica.tr4.reports.F24

interface DatiF24Factory {
	DatiF24 creaDatiF24(String siglaComune, String tipoTributo, int tipoPagamento)
	DatiF24 creaDatiF24(String siglaComune)
	DatiF24 creaDatiF24(String siglaComune, def pratica, def tipo)
}
