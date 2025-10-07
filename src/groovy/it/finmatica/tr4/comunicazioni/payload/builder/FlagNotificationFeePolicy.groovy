package it.finmatica.tr4.comunicazioni.payload.builder

enum FlagNotificationFeePolicy {
    DELIVERY_MODE("DELIVERY_MODE"),
    FLAT_RATE("FLAT_RATE")

    final value

    private FlagNotificationFeePolicy(String value) {
        this.value = value
    }

    static FlagNotificationFeePolicy findByValue(String value) {
        switch (value) {
            case "DELIVERY_MODE":
                return DELIVERY_MODE
            case "FLAT_RATE":
                return FLAT_RATE
        }
    }

}
