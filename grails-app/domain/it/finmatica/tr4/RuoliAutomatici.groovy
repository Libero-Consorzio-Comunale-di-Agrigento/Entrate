package it.finmatica.tr4

class RuoliAutomatici {

    TipoTributo tipoTributo
    Date daData
    Date aData
    Ruolo ruolo
    String utente
    String note

    def springSecurityService

    static mapping = {
        id column: "id", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "RUOLI_AUTOMATICI_NR"]

        ruolo column: "ruolo"
        tipoTributo column: "tipo_tributo"

        version false
    }

    static constraints = {
        note nullable: true
    }

    static transients = ['springSecurityService']

    def beforeValidate() {
        utente = utente ?: springSecurityService.currentUser?.id
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser?.id
    }

    def beforeUpdate() {
        utente = springSecurityService.currentUser?.id
    }
}
