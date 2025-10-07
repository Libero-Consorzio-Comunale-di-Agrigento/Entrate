package it.finmatica.tr4.comunicazioni.payload.builder

enum FlagTipoDestinatario {
    PERSONA_FISICA("PF"),
    AZIENDA("AZ")

    final value

    private FlagTipoDestinatario(String value) {
        this.value = value
    }

}
