package it.finmatica.tr4

class ContributiIfel implements Serializable {

    Short anno
    BigDecimal aliquota

    static mapping = {
        id composite: ["anno"]

        table 'contributi_ifel'
        version false
    }

    static constraints = {
        aliquota nullable: true, scale: 4
    }
}
