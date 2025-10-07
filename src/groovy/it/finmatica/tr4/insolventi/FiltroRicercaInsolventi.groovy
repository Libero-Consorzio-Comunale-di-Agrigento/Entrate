package it.finmatica.tr4.insolventi

class FiltroRicercaInsolventi {

    // Filtri
    String cognome
    String nome
    String codFiscale
    Integer codContribuente
    def impA
    def impDa
    Boolean aRuolo
    def ruolo
    Boolean insolventi
    Boolean rimborsi
    Boolean pagCorretti


    // Filtri elenco Generale
    Short annoDa
    Short annoA
    Date notificaDal
    Date notificaAl
    String tipo = "Tutti"
    String filtroRuolo = "Tutti"
    String tipoTributo
    String filtroVersamenti = "Tutti"
    String filtroIngiunzione = "Tutti"
    Boolean soloTardivi = false
    String praticheRateizzate = "Tutti"

    Map filtroTipiAtto = [
            imp: true,
            liq: true,
            acc: true,
    ]


    ///
    /// Autoniomi
    ///
    def tributo

    ///
    /// Autoniomi elenco Generale
    ///


    FiltroRicercaInsolventi() {

        pulisciFiltri()
    }

    def pulisciFiltri(Boolean insolventiGenerale = false) {

        cognome = null
        nome = null
        codFiscale = null
        codContribuente = null
        annoDa = null
        impA = null
        aRuolo = !insolventiGenerale
        ruolo = null
        insolventi = true
        rimborsi = true
        pagCorretti = false
        annoA = null
        impDa = null
        notificaDal = null
        notificaAl = null
        filtroRuolo = "Tutti"
        tipo = "Tutti"
        praticheRateizzate = "Tutti"
    }

    def filtroAttivo(Boolean insolventiGenerale = false) {

        return (cognome != null) ||
                (nome != null) ||
                (codFiscale != null) ||
                (codContribuente != null) ||
                (annoDa != null) ||
                (impA != null) ||
                ((aRuolo ?: false) == insolventiGenerale) ||
                (ruolo != null) ||
                (insolventi != true) ||
                (rimborsi != true) ||
                (pagCorretti != false) ||
                (annoA != null) ||
                (impDa != null) ||
                (notificaDal != null) ||
                (notificaAl != null) ||
                (tipo != "Tutti") ||
                (filtroRuolo != "Tutti") ||
                (praticheRateizzate != "Tutti")
    }

    FiltroRicercaInsolventi clone(Boolean insolventiGenerale = false) {

        FiltroRicercaInsolventi result = new FiltroRicercaInsolventi()

        result.cognome = this.cognome
        result.nome = this.nome
        result.codFiscale = this.codFiscale
        result.codContribuente = this.codContribuente
        result.impDa = this.impDa
        result.impA = this.impA
        result.aRuolo = this.aRuolo
        result.ruolo = this.ruolo
        result.insolventi = this.insolventi
        result.rimborsi = this.rimborsi
        result.pagCorretti = this.pagCorretti

        result.annoDa = this.annoDa
        result.annoA = this.annoA
        result.notificaDal = this.notificaDal
        result.notificaAl = this.notificaAl
        result.tipo = this.tipo
        result.filtroRuolo = this.filtroRuolo
        result.filtroTipiAtto = this.filtroTipiAtto
        result.soloTardivi = this.soloTardivi
        result.tipo = this.tipoTributo
        result.praticheRateizzate = this.praticheRateizzate

        return result
    }
}
