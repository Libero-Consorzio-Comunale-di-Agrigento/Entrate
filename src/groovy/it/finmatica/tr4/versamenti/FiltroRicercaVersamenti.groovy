package it.finmatica.tr4.versamenti

class FiltroRicercaVersamenti {

	def cognome = ""
	def cognomeNome = ""
	def nome = ""
	def cf = ""
	def fonte
	def tipoPratica
	def daAnno
	def aAnno
	def daDataPagamento
	def aDataPagamento = new Date().clearTime()
	def daDataProvvedimento
	def aDataProvvedimento = new Date().clearTime()
	def daDataRegistrazione
	def aDataRegistrazione = new Date().clearTime()
	def daImporto
	def aImporto
	def tipoVersamento
	def ruolo
	def progrDocVersamento
	def tipoOrdinamento = 'ALFA'
	def statoSoggetto = 'E'
	def statoPratica
	def rata
}
