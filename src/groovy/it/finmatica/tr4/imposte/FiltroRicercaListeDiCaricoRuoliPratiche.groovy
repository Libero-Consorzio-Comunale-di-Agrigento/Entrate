package it.finmatica.tr4.imposte

class FiltroRicercaListeDiCaricoRuoliPratiche {

    String cognome = null
    String nome = null
    String codFiscale = null
    def hasVersamenti = null
    def hasPEC = null

    /* T - Tutti
     * L - Liquidazioni
     * A - Accertamenti
     */
    def tipoPratica = "T"

    def numeroDa = null
    def numeroA = null
    def dataNotificaDa = null
    def dataNotificaA = null
    def dataEmissioneDa = null
    def dataEmissioneA = null

}
