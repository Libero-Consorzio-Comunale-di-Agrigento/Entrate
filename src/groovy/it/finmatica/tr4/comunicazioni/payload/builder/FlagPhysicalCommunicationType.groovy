package it.finmatica.tr4.comunicazioni.payload.builder

enum FlagPhysicalCommunicationType {
    AR_REGISTERED_LETTER("AR_REGISTERED_LETTER"),
    REGISTERED_LETTER_890("REGISTERED_LETTER_890")

    final value

    private FlagPhysicalCommunicationType(String value) {
        this.value = value
    }

    static FlagPhysicalCommunicationType findByValue(String value) {
        switch (value) {
            case "AR_REGISTERED_LETTER":
                return AR_REGISTERED_LETTER
            case "REGISTERED_LETTER_890":
                return REGISTERED_LETTER_890
        }
    }

}
