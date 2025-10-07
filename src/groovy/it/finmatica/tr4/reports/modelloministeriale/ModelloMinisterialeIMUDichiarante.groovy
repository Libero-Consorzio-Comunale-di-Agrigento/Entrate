package it.finmatica.tr4.reports.modelloministeriale

import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.tr4.Soggetto

class ModelloMinisterialeIMUDichiarante implements ModelloMinisterialeVisitable {

    def codFiscale
    def codCarica

    def cognome
    def nome
    def prefissoTelefono
    def numeroTelefono
    def email

    def via
    def cap
    def comune
    def provincia
    def codStatoEstero

    ModelloMinisterialeIMUDichiarante(def dati) {
        gestioneDati(dati)
    }

    @Override
    def accept(ModelloMinisterialeVisitor visitor) {
        return visitor.visit(this)
    }

    private def gestioneDati(def dati) {

        this.codFiscale = dati["COD_FISCALE"]
        this.codCarica = dati["TIPO_CARICA"]


        def codFiscale = dati["COD_FISCALE_DEN"]

        def dichiarante = Soggetto.findByCodFiscale(codFiscale)

        if (dichiarante) {
            this.cognome = dichiarante.cognome
            this.nome = dichiarante.nome
        }

        this.prefissoTelefono = ""
        this.numeroTelefono = ""
        this.email = ""

        this.via = dati["INDIRIZZO_DEN"]

        if (dati["COD_COM_DEN"] && dati["COD_PRO_DEN"]) {
            def comune = Ad4ComuneTr4.findByComuneAndProvinciaStato(dati["COD_COM_DEN"], dati["COD_PRO_DEN"]).ad4Comune

            this.comune = comune?.denominazione
            this.cap = comune.cap
            this.provincia = comune?.provincia?.sigla
        }

        this.codStatoEstero = ""
    }


}
