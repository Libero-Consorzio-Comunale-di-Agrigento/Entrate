package it.finmatica.tr4.caricamento

class UtenzaTipiUtenza implements Serializable {

    String tipoFornitura
    String tipoUtenza
    String descrizione
    String descrizioneBreve

    static hasMany = [utenzaDatiFornitura: UtenzaDatiFornitura]

    static mapping = {

        id composite: ["tipoFornitura", "tipoUtenza"]
        descrizioneBreve column: "DESCR_BREVE"

        version false

        table "UTENZE_TIPI_UTENZA"
    }

}
