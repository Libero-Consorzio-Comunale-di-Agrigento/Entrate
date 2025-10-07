package it.finmatica.tr4

class WrkEncContitolari implements Serializable {

    Long documentoId
    Integer progrDichiarazione
    Integer progrContitolare
    String tipoImmobile
    Integer progrImmobile
    Integer numOrdine
    String denominazione
    String codFiscale
    String indirizzo
    String numCiv
    String scala
    String piano
    String interno
    String cap
    String comune
    String provincia
    BigDecimal percPossesso
    BigDecimal detrazione
    String firmaContitolare
    Long tr4Ni
    Date dataVariazione
    String utente
    String sesso
    Date dataNascita
    String comuneNascita
    String provinciaNascita

    static mapping = {
        id composite: ['documentoId', 'progrDichiarazione', 'progrContitolare', 'tipoImmobile', 'progrImmobile']
        version false
        table "WRK_ENC_CONTITOLARI"
    }

    static constraints = {
        denominazione nullable: true
        codFiscale nullable: true
        indirizzo nullable: true
        numCiv nullable: true
        scala nullable: true
        piano nullable: true
        interno nullable: true
        cap nullable: true
        comune nullable: true
        provincia nullable: true
        percPossesso nullable: true
        detrazione nullable: true
        firmaContitolare nullable: true
        tr4Ni nullable: true
        dataVariazione nullable: true
        utente nullable: true
        sesso nullable: true
        dataNascita nullable: true
        comuneNascita nullable: true
        provinciaNascita nullable: true
    }
}
