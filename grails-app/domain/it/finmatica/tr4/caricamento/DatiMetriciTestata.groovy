package it.finmatica.tr4.caricamento

import it.finmatica.tr4.datiesterni.DocumentoCaricato

class DatiMetriciTestata {

    Integer documentoId
    String tipologia
    String iscrizione
    Date dataIniziale
    Short nFile
    Short nFileTot
    String comune
    Date dataEstrazione
    Integer totUiu

    static hasMany = [
            uiu: DatiMetriciUiu
    ]

    static mapping = {
        id column: "testate_id"
        uiu column: "uiu_id"
        documentoCaricato column: "documento_id"

        version false

        table "dati_metrici_testate"
    }

    static constraints = {
        iscrizione nullable: true
        dataIniziale nullable: true
        nFile nullable: true
        nFileTot nullable: true
        comune nullable: true
        dataEstrazione nullable: true
        totUiu nullable: true
    }
}
