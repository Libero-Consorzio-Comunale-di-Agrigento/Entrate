package it.finmatica.tr4.comunicazioni.payload.builder

enum FlagSospeso {
    YES("Y"),
    NO("N")

    final value

    private FlagSospeso(String value) {
        this.value = value
    }

}
