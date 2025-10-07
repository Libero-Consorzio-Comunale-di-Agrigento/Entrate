package it.finmatica.tr4.comunicazioni.payload.builder

enum FlagFirma {
    DA_FIRMARE_MANUALMENTE("DF"),
    DA_FIRMARE_AUTOMATICAMENTE("FA"),
    DA_NON_FIRMARE("NF")

    final value

    private FlagFirma(String value) {
        this.value = value
    }

    static FlagFirma findByValue(String value) {
        switch (value) {
            case "DF":
                return DA_FIRMARE_MANUALMENTE
            case "FA":
                return DA_FIRMARE_AUTOMATICAMENTE
            case "NF":
                return DA_NON_FIRMARE
        }
    }

}
