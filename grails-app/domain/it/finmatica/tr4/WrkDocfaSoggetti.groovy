package it.finmatica.tr4

class WrkDocfaSoggetti implements Serializable {

    Integer documentoId
    Integer documentoMultiId
    Integer progrOggetto
    Integer progrSoggetto
    String denominazione
    String comuneNascita
    String provinciaNascita
    Date dataNascita
    String sesso
    String codiceFiscale
    String cognome
    String nome
    String tipo
    String flagCaricamento
    String regime
    Byte progressivoIntRif
    String specDiritto
    Long percPossesso
    String titolo
    Integer tr4Ni

    static mapping = {
        id composite: ["documentoId", "documentoMultiId", "progrOggetto", "progrSoggetto"]
        version false
        tr4Ni column: "TR4_NI"
    }

    static constraints = {
        denominazione nullable: true
        comuneNascita nullable: true
        provinciaNascita nullable: true
        dataNascita nullable: true
        sesso nullable: true
        codiceFiscale nullable: true
        cognome nullable: true
        nome nullable: true
        tipo nullable: true
        flagCaricamento nullable: true
        regime nullable: true
        progressivoIntRif nullable: true
        specDiritto nullable: true
        percPossesso nullable: true
        titolo nullable: true
        tr4Ni nullable: true
    }
}
