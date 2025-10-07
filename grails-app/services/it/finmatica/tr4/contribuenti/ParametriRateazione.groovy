package it.finmatica.tr4.contribuenti

class ParametriRateazione {
    def readOnly = false
    def dataRateazione
    def tassoAnnuo
    def interessiMora
    def numeroRata
    def tipologia
    def importoRata
    def calcoloRate
    boolean intRateSoloEvasa
    boolean oneriRiscossione
    def scadenzaPrimaRata

    // Sola lettura
    def versatoPreRateazione
    def importoPratica

    def getImportoDaRateizzare() {
        return (importoPratica ?: 0) + (interessiMora ?: 0) - (versatoPreRateazione ?: 0)
    }
}
