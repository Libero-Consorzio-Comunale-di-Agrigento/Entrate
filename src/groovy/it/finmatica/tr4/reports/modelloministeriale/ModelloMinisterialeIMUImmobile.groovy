package it.finmatica.tr4.reports.modelloministeriale

class ModelloMinisterialeIMUImmobile implements ModelloMinisterialeVisitable {

    def numOrdine

    def caratteristiche
    def indirizzo

    def sezione
    def foglio
    def particella
    def subalterno
    def categoria
    def classe
    def t_u
    def numProtocollo
    def annoCatastale

    def riduzioni
    def valore
    def percPossesso
    def esenzione
    def giorno
    def mese
    def anno
    def detrAbPrincipale

    def acquisto
    def cessione
    def altro
    def descAltro

    def agenziaEntrate
    def estremiTitolo
    def inizioTermineAgevolazione
    def equiparazioneAbPrincipale
    def nonDispTipo
    def nonDispAutorita
    def nonDispDataDenuncia

    ModelloMinisterialeIMUImmobile(def dati) {
        gestioneDati(dati)
    }

    @Override
    def accept(ModelloMinisterialeVisitor visitor) {
        return visitor.visit(this)
    }

    def numeraImmobile(def num) {
        this.numOrdine = num
    }

    private def gestioneDati(def dati) {
        this.caratteristiche = dati["TIPO_OGGETTO"]
        this.indirizzo = dati["INDIRIZZO_COMPLETO"]

        this.sezione = dati["SEZIONE"]
        this.foglio = dati["FOGLIO"]
        this.particella = dati["NUMERO"]
        this.subalterno = dati["SUBALTERNO"]
        this.categoria = dati["CATEGORIA_CATASTO"]
        this.classe = dati["CLASSE_CATASTO"]
        this.t_u = "" // T se censito catasto terreno, U se catasto urbano
        this.numProtocollo = dati["PROTOCOLLO_CATASTO"]
        this.annoCatastale = dati["ANNO_CATASTO"]

        this.valore = dati["VALORE"]
        this.percPossesso = dati["PERC_POSSESSO"]
        this.esenzione = dati["COD_ESENZIONE"]
        this.riduzioni = dati["COD_RIDUZIONE"]

        if (dati["DATA_EVENTO"]) {
            def datiData = dati["DATA_EVENTO"].toString().split("-")
            this.giorno = datiData[2]
            this.mese = datiData[1]
            this.anno = datiData[0][2..-1] // Recupera le ultime due cifre dell'anno
        }

        this.detrAbPrincipale = dati["DETRAZIONE"]

        this.acquisto = dati["TITOLO"] == "A"
        this.cessione = dati["TITOLO"] == "C"
        this.altro = ""
        this.descAltro = ""

        this.agenziaEntrate = ""
        this.estremiTitolo = dati["ESTREMI_TITOLO"]
        this.inizioTermineAgevolazione = null
        this.equiparazioneAbPrincipale = null
        this.nonDispTipo = null
        this.nonDispAutorita = null
        this.nonDispDataDenuncia = null

    }


}
