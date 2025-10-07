package it.finmatica.tr4

class WrkDocfaOggetti implements Serializable {
    Integer documentoId
    Integer documentoMultiId
    Integer progrOggetto
    String tipoOperazione
    String sezione
    String foglio
    String numero
    String subalterno
    Long codVia
    String indirizzo
    String numCivico
    String piano
    String scala
    String interno
    String zona
    String categoria
    String classe
    String consistenza
    Short superficieCatastale
    Long rendita
    Integer tr4Oggetto

    static mapping = {
        id composite: ["documentoId", "documentoMultiId", "progrOggetto"]
        version false
        tr4Oggetto column: "TR4_OGGETTO"
    }

    static constraints = {
        tipoOperazione nullable: true
        sezione nullable: true
        foglio nullable: true
        numero nullable: true
        subalterno nullable: true
        codVia nullable: true
        indirizzo nullable: true
        numCivico nullable: true
        piano nullable: true
        scala nullable: true
        interno nullable: true
        zona nullable: true
        categoria nullable: true
        classe nullable: true
        consistenza nullable: true
        superficieCatastale nullable: true
        rendita nullable: true
        tr4Oggetto nullable: true
    }
}
