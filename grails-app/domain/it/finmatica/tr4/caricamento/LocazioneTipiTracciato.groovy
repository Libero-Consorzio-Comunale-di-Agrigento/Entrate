package it.finmatica.tr4.caricamento

class LocazioneTipiTracciato implements Serializable {

    Date dataInizio
    Date dataFine
    String tracciato
    Long titoloDocumento

    static mapping = {

        id column: "TIPO_TRACCIATO"

        version false

        table "LOCAZIONI_TIPI_TRACCIATO"
    }
}
