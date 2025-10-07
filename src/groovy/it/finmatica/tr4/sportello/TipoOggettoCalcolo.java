package it.finmatica.tr4.sportello;

public enum TipoOggettoCalcolo {
    TERRENO("Terreni Agricoli:"),
    AREA("Aree Fabbricabili:"),
    ABITAZIONE_PRINCIPALE("Abitazione Principale:"),
    RURALE("Rurali Uso Strumentale:"),
    ALTRO_FABBRICATO("Altri Fabbricati:"),
    FABBRICATO_D("Uso Produttivo:"),
    DETRAZIONE("Detrazione:"),
    TOTALE("TOTALE:"),
    FABBRICATO_MERCE("Fabbricati Merce:");


    private final String descrizione;

    public String getValore() {
        return this.toString();
    }

    private TipoOggettoCalcolo(String descrizione) {
        this.descrizione = descrizione;
    }

    public String getDescrizione() {
        return this.descrizione;
    }
}
