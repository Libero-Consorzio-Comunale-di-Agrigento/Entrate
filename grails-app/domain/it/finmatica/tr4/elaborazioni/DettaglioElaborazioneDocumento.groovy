package it.finmatica.tr4.elaborazioni

class DettaglioElaborazioneDocumento {

    byte[] documento

    static mapping = {
        id column: "DETTAGLIO_ID", "assigned"

        table "dettagli_elaborazione"

        version false

    }

    static constraints = {
        documento nullable: true
    }
}
