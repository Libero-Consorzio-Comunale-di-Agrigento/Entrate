package it.finmatica.tr4

class WsLog {

    enum LOG_TYPE {
        SMART_PND,
        DEPAG,
        PORTALE
    }

    LOG_TYPE tipo
    Date data
    String logRichiesta
    String logRisposta
    String logErrore
    String tipoCallback
    Long idComunicazione
    String idback
    String codIuv
    String codFiscale
    String endpoint

    static mapping = {
        id generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "WS_LOG_NR"]
        tipo enumType: 'string'
        data sqlType: 'Date'

        table "ws_log"
        version false
    }

    static constraints = {
        logRichiesta nullable: true
        logRisposta nullable: true
        logErrore nullable: true
        tipoCallback nullable: true, maxSize: 30
        idComunicazione nullable: true
        idback nullable: true, maxSize: 4000
        codIuv nullable: true, maxSize: 35
        codFiscale nullable: true, maxSize: 16
        endpoint nullable: true, maxSize: 2000
    }
}
