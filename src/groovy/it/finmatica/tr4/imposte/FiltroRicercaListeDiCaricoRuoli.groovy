package it.finmatica.tr4.imposte

class FiltroRicercaListeDiCaricoRuoli {

    Short daAnno = null
    Short aAnno = null
    Short daAnnoEmissione = null
    Short aAnnoEmissione = null
    Long daProgEmissione = null
    Long aProgEmissione = null
    Date daDataEmissione = null
    Date aDataEmissione = null
    Date daDataInvio = null
    Date aDataInvio = null
    Long daNumeroRuolo = null
    Long aNumeroRuolo = null
    def tipoRuolo = null
    def specieRuolo = null
    def tipoEmissione = null
    Integer codiceTributo = null
    String tipoTributo = null

    Boolean isDirty() {
        return (daAnno != null || aAnno != null ||
                daAnnoEmissione != null || aAnnoEmissione != null ||
                daProgEmissione != null || aProgEmissione != null ||
                daDataEmissione != null || aDataEmissione != null ||
                daDataInvio != null || aDataInvio != null ||
                daNumeroRuolo != null || aNumeroRuolo != null ||
                specieRuolo != null || tipoEmissione != null ||
                tipoRuolo != null || codiceTributo != null)
    }

    def svuotaTutto() {

        daAnno = null
        aAnno = null
        daAnnoEmissione = null
        aAnnoEmissione = null
        daProgEmissione = null
        aProgEmissione = null
        daDataEmissione = null
        aDataEmissione = null
        daDataInvio = null
        aDataInvio = null
        daNumeroRuolo = null
        aNumeroRuolo = null
        tipoRuolo = null
        specieRuolo = null
        tipoEmissione = null
        codiceTributo = null
        tipoTributo = null
    }

    ///
    /// Comune Contribuenti, Utenze ed Eccedenze
    ///
    String cognome = null
    String nome = null
    String codFiscale = null

    ///
    /// Comune Contribuenti ed Utenze
    ///
    def hasPEC = null

    ///
    /// Solo contribuenti
    ///
    def hasVersamenti = null

    ///
    /// Solo pratiche
    ///
    def tipoPratica = "T"
    def numeroDa = null
    def numeroA = null
    def dataNotificaDa = null
    def dataNotificaA = null
    def dataEmissioneDa = null
    def dataEmissioneA = null

    ///
    /// Flag utilizzati per forzare refresh liste
    ///
    Boolean changedDetails = false;
    Boolean changedUtenze = false;
    Boolean changedPratiche = false;

    def preparaRicercaDetails(FiltroRicercaListeDiCaricoRuoliDetails parRicerca) {

        parRicerca.cognome = cognome
        parRicerca.nome = nome
        parRicerca.codFiscale = codFiscale
        parRicerca.hasPEC = hasPEC
        parRicerca.hasVersamenti = hasVersamenti

        return parRicerca;
    }

    def applicaRicercaDetails(FiltroRicercaListeDiCaricoRuoliDetails parRicerca) {

        cognome = parRicerca.cognome
        nome = parRicerca.nome
        codFiscale = parRicerca.codFiscale
        hasPEC = parRicerca.hasPEC
        hasVersamenti = parRicerca.hasVersamenti

        changedUtenze = true;
    }

    Boolean isDirtyDetails() {
        return (cognome != null) || (nome != null) || (codFiscale != null) || (hasPEC != null) || (hasVersamenti != null)
    }

    Boolean isChangedDetails() {
        Boolean result = changedDetails;
        changedDetails = false;
        return result;
    }

    def preparaRicercaUtenze(FiltroRicercaListeDiCaricoRuoliUtenze parRicerca) {

        parRicerca.cognome = cognome
        parRicerca.nome = nome
        parRicerca.codFiscale = codFiscale
        parRicerca.hasPEC = hasPEC

        return parRicerca;
    }

    def applicaRicercaUtenze(FiltroRicercaListeDiCaricoRuoliUtenze parRicerca) {

        cognome = parRicerca.cognome
        nome = parRicerca.nome
        codFiscale = parRicerca.codFiscale
        hasPEC = parRicerca.hasPEC

        changedDetails = true;
    }

    def preparaRicercaEccedenze(FiltroRicercaListeDiCaricoRuoliEccedenze parRicerca) {

        parRicerca.cognome = cognome
        parRicerca.nome = nome
        parRicerca.codFiscale = codFiscale

        return parRicerca;
    }

    def applicaRicercaEccedenze(FiltroRicercaListeDiCaricoRuoliEccedenze parRicerca) {

        cognome = parRicerca.cognome
        nome = parRicerca.nome
        codFiscale = parRicerca.codFiscale

        changedDetails = true;
    }

    Boolean isDirtyUtenze() {
        return (cognome != null) || (nome != null) || (codFiscale != null) || (hasPEC != null)
    }

    Boolean isDirtyEccedenze() {
        return (cognome != null) || (nome != null) || (codFiscale != null)
    }

    Boolean isChangedUtenze() {
        Boolean result = changedUtenze;
        changedUtenze = false;
        return result;
    }

    def preparaRicercaPratiche(FiltroRicercaListeDiCaricoRuoliPratiche parRicerca) {

        parRicerca.cognome = cognome
        parRicerca.nome = nome
        parRicerca.codFiscale = codFiscale
        parRicerca.hasPEC = hasPEC
        parRicerca.hasVersamenti = hasVersamenti
        parRicerca.tipoPratica = tipoPratica
        parRicerca.numeroDa = numeroDa
        parRicerca.numeroA = numeroA
        parRicerca.dataNotificaDa = dataNotificaDa
        parRicerca.dataNotificaA = dataNotificaA
        parRicerca.dataEmissioneDa = dataEmissioneDa
        parRicerca.dataEmissioneA = dataEmissioneA

        return parRicerca;
    }

    def applicaRicercaPratiche(FiltroRicercaListeDiCaricoRuoliPratiche parRicerca) {

        cognome = parRicerca.cognome
        nome = parRicerca.nome
        codFiscale = parRicerca.codFiscale
        hasPEC = parRicerca.hasPEC
        hasVersamenti = parRicerca.hasVersamenti
        tipoPratica = parRicerca.tipoPratica
        numeroDa = parRicerca.numeroDa
        numeroA = parRicerca.numeroA
        dataNotificaDa = parRicerca.dataNotificaDa
        dataNotificaA = parRicerca.dataNotificaA
        dataEmissioneDa = parRicerca.dataEmissioneDa
        dataEmissioneA = parRicerca.dataEmissioneA

        changedDetails = true;
    }

    Boolean isDirtyPratiche() {
        return (cognome != null) ||
                (nome != null) ||
                (codFiscale != null) ||
                (hasPEC != null) ||
                (hasVersamenti != null) ||
                (tipoPratica != "T") ||
                (numeroDa != null) ||
                (numeroA != null) ||
                (dataNotificaDa != null) ||
                (dataNotificaA != null) ||
                (dataEmissioneDa != null) ||
                (dataEmissioneA != null)
    }

    Boolean isChangedPratiche() {
        Boolean result = changedPratiche;
        changedPratiche = false;
        return result;
    }
}
