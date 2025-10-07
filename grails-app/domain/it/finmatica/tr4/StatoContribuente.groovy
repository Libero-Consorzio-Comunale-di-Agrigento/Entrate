package it.finmatica.tr4

class StatoContribuente {
    Contribuente contribuente
    TipoTributo tipoTributo
    TipoStatoContribuente stato
    Date dataStato
    Short anno
    String utente
    Date lastUpdated
    String note

    def springSecurityService

    static mapping = {
        table 'stati_contribuente'
        version false

        id generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "stati_contribuente_nr"]
        contribuente column: "cod_fiscale"
        tipoTributo column: "tipo_tributo"
        stato column: "tipo_stato_contribuente"
        lastUpdated column: "data_variazione", sqlType: 'Date'
        dataStato sqlType: 'Date'
    }

    static constraints = {
        note nullable: true
        utente maxSize: 8
        note maxSize: 2000
    }

    def beforeValidate() {
        utente = springSecurityService.currentUser.utente
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser.utente
    }

}
