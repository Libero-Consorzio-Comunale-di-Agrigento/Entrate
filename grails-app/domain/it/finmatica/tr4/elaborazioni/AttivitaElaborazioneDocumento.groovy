package it.finmatica.tr4.elaborazioni

class AttivitaElaborazioneDocumento {

    byte[] documento

    static mapping = {
        id column: "ATTIVITA_ID", generator: "assigned"

        table "attivita_elaborazione"

        version false
    }

    static constraints = {
        documento nullable: true
    }
}
