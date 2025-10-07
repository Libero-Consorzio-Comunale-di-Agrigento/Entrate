package it.finmatica.tr4

class WrkEncTestata implements Serializable {

    Long documentoId
    Integer progrDichiarazione
    Integer annoDichiarazione
    Integer annoImposta
    String codComune
    String codFiscale
    String denominazione
    String telefono
    String email
    String indirizzo
    String numCiv
    String scala
    String piano
    String interno
    String cap
    String comune
    String provincia
    Integer numImmobiliA
    Integer numImmobiliB
    BigDecimal imuDovuta
    BigDecimal eccedenzaImuDicPrec
    BigDecimal eccedenzaImuDicPrecF24
    BigDecimal rateImuVersate
    BigDecimal imuDebito
    BigDecimal imuCredito
    BigDecimal tasiDovuta
    BigDecimal eccedenzaTasiDicPrec
    BigDecimal eccedenzaTasiDicPrecF24
    BigDecimal tasiRateVersate
    BigDecimal tasiDebito
    BigDecimal tasiCredito
    BigDecimal imuCreditoDicPresente
    BigDecimal creditoImuRimborso
    BigDecimal creditoImuCompensazione
    BigDecimal tasiCreditoDicPresente
    BigDecimal creditoTasiRimborso
    BigDecimal creditoTasiCompensazione
    Date dataVariazione
    String utente
    Long tr4Ni
    Long tr4PraticaIci
    Long tr4PraticaTasi
    String firmaDichiarazione
    String sesso
    Date dataNascita
    String comuneNascita
    String provinciaNascita
    String codiceTracciato
    String nome

    static mapping = {
        id composite: ["documentoId", "progrDichiarazione"]
        version false
        tr4PraticaIci column: "TR4_PRATICA_ICI"
        tr4PraticaTasi column: "TR4_PRATICA_TASI"
        tr4Ni column: "TR4_NI"
        numImmobiliA column: "NUM_IMMOBILI_A"
        numImmobiliB column: "NUM_IMMOBILI_B"
        eccedenzaImuDicPrecF24 column: "ECCEDENZA_IMU_DIC_PREC_F24"
        eccedenzaTasiDicPrecF24 column: "ECCEDENZA_TASI_DIC_PREC_F24"
        table "WRK_ENC_TESTATA"
    }

    static constraints = {
        annoDichiarazione nullable: true
        annoImposta nullable: true
        codComune nullable: true
        codFiscale nullable: true
        denominazione nullable: true
        telefono nullable: true
        email nullable: true
        indirizzo nullable: true
        numCiv nullable: true
        scala nullable: true
        piano nullable: true
        interno nullable: true
        cap nullable: true
        comune nullable: true
        provincia nullable: true
        numImmobiliA nullable: true
        numImmobiliB nullable: true
        imuDovuta nullable: true
        eccedenzaImuDicPrec nullable: true
        eccedenzaImuDicPrecF24 nullable: true
        rateImuVersate nullable: true
        imuDebito nullable: true
        imuCredito nullable: true
        tasiDovuta nullable: true
        eccedenzaTasiDicPrec nullable: true
        eccedenzaTasiDicPrecF24 nullable: true
        tasiRateVersate nullable: true
        tasiDebito nullable: true
        tasiCredito nullable: true
        imuCreditoDicPresente nullable: true
        creditoImuRimborso nullable: true
        creditoImuCompensazione nullable: true
        tasiCreditoDicPresente nullable: true
        creditoTasiRimborso nullable: true
        creditoTasiCompensazione nullable: true
        dataVariazione nullable: true
        utente nullable: true
        tr4Ni nullable: true
        tr4PraticaIci nullable: true
        tr4PraticaTasi nullable: true
        firmaDichiarazione nullable: true
        sesso nullable: true
        dataNascita nullable: true
        comuneNascita nullable: true
        provinciaNascita nullable: true
        codiceTracciato nullable: true
        nome nullable: true
    }
}

