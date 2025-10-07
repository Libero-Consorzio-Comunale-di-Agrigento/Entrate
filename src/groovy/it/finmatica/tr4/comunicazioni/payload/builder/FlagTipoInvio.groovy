package it.finmatica.tr4.comunicazioni.payload.builder

enum FlagTipoInvio {
    TO("TO"),
    CC("CC"),
    CCR("CCR")

    final value

    private FlagTipoInvio(String value) {
        this.value = value
    }

}
