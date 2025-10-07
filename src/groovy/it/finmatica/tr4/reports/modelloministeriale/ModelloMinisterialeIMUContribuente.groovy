package it.finmatica.tr4.reports.modelloministeriale

class ModelloMinisterialeIMUContribuente implements ModelloMinisterialeVisitable {

    def codFiscale
    def prefissoTelefono
    def numeroTelefono
    def email

    def cognome
    def nome
    def giornoNascita
    def meseNascita
    def annoNascita
    def sesso

    def comuneNascita
    def provinciaNascita

    def via
    def cap
    def comune
    def provincia
    def codStatoEstero

    ModelloMinisterialeIMUContribuente(def contribuente, def dati) {
        gestioneDati(contribuente, dati)
    }

    @Override
    def accept(ModelloMinisterialeVisitor visitor) {
        return visitor.visit(this)
    }

    private def gestioneDati(def contribuente, def dati) {

        this.codFiscale = contribuente?.codFiscale
        this.prefissoTelefono = dati["PREFISSO_TELEFONICO"]
        this.numeroTelefono = dati["NUM_TELEFONICO"]
        this.email = ""

        this.cognome = contribuente?.soggetto?.cognome
        this.nome = contribuente?.soggetto?.nome
        this.sesso = contribuente?.soggetto?.sesso

        if (contribuente?.soggetto?.dataNas) {
            Calendar cal = Calendar.getInstance();
            cal.setTime(contribuente.soggetto.dataNas);
            this.giornoNascita = (cal.get(Calendar.DAY_OF_MONTH) as String).padLeft(2, '0')
            this.meseNascita = (cal.get(Calendar.MONTH) as String).padLeft(2, '0')
            this.annoNascita = (cal.get(Calendar.YEAR) as String).substring(2, 4)
        }

        this.comuneNascita = contribuente?.soggetto?.comuneNascita?.ad4Comune?.denominazione
        this.provinciaNascita = contribuente?.soggetto?.comuneNascita?.ad4Comune?.provincia?.sigla

        this.via = contribuente?.soggetto?.denominazioneVia
        this.cap = contribuente?.soggetto?.cap
        this.comune = contribuente?.soggetto?.comuneResidenza?.ad4Comune?.denominazione
        this.provincia = contribuente?.soggetto?.comuneResidenza?.ad4Comune?.provincia?.sigla
        this.codStatoEstero = ""

    }
}
