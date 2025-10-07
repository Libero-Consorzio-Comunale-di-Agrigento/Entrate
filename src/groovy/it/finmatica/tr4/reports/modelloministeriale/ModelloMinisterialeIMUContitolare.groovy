package it.finmatica.tr4.reports.modelloministeriale

import it.finmatica.tr4.Soggetto

class ModelloMinisterialeIMUContitolare implements ModelloMinisterialeVisitable {

    def numOrdine

    def codFiscale
    def nomeCognome
    def comuneNascita
    def provinciaNascita

    def giornoNascita
    def meseNascita
    def annoNascita
    def sesso

    def via
    def cap
    def comune
    def provincia

    def codStatoEstero
    def percPossesso
    def detrAbPrincipale


    ModelloMinisterialeIMUContitolare(def dati) {
        gestioneDati(dati)
    }

    @Override
    def accept(ModelloMinisterialeVisitor visitor) {
        return visitor.visit(this)
    }

    def numeraContitolare(def num) {
        this.numOrdine = num
    }


    private def gestioneDati(def dati) {
        this.codFiscale = dati["COD_FISCALE"]

        Soggetto soggetto = Soggetto.findByCodFiscale(this.codFiscale)
        this.nomeCognome = dati["COGNOME_NOME"].replace('/', ' ')

        this.comuneNascita = soggetto?.comuneNascita?.ad4Comune?.denominazione
        this.provinciaNascita = soggetto?.comuneNascita?.ad4Comune?.provincia?.sigla

        if (soggetto?.dataNas) {
            Calendar cal = Calendar.getInstance();
            cal.setTime(soggetto.dataNas);
            this.giornoNascita = (cal.get(Calendar.DAY_OF_MONTH) as String).padLeft(2, '0')
            this.meseNascita = (cal.get(Calendar.MONTH) as String).padLeft(2, '0')
            this.annoNascita = (cal.get(Calendar.YEAR) as String).substring(2, 4)
        }

        this.sesso = soggetto?.sesso

        this.via = dati["INDIRIZZO_SOGG"]
        this.cap = dati["CAP"]
        this.comune = soggetto?.comuneResidenza?.ad4Comune?.denominazione
        this.provincia = soggetto?.comuneResidenza?.ad4Comune?.provincia?.sigla

        this.codStatoEstero = ""

        this.percPossesso = dati["PERC_POSSESSO"]

        this.detrAbPrincipale = dati["DETRAZIONE"]

    }

}
