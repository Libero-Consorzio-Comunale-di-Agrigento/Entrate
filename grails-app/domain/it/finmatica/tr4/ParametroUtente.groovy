package it.finmatica.tr4

class ParametroUtente {

    def springSecurityService

    String utente
    String valore
    Date dataVariazione

    static belongsTo = [tipoParametro: TipoParametro]

    static mapping = {
        id column: 'id', generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "PARAMETRI_UTENTE_NR"]
        tipoParametro column: "tipo_parametro"
        table "parametri_utente"

        version false
    }

    static constraints = {
        dataVariazione nullable: true
        utente nullable: true
    }


    def beforeInsert() {
        utente = springSecurityService.currentUser.id
        dataVariazione = new Date()
    }

    def beforeUpdate() {
        dataVariazione = new Date()
    }
}
