package it.finmatica.tr4.pratiche

import it.finmatica.tr4.TipoAtto
import it.finmatica.tr4.TipoStato
import it.finmatica.tr4.tipi.SiNoType

class IterPratica implements Serializable {

    Date data
    String motivo
    String note

    String utente
    Date dataVariazione

    TipoStato stato
    TipoAtto tipoAtto
    PraticaTributo pratica
    boolean flagAnnullamento

    def springSecurityService

    static transients = ['springSecurityService']

    static mapping = {
        id column: "iter_pratica", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "ITER_PRATICA_NR"]
        stato column: "stato"
        tipoAtto column: "tipo_atto"
        pratica column: "pratica"
        flagAnnullamento type: SiNoType

        version false
    }

    static constraints = {
        note nullable: true
        motivo nullable: true
        stato nullable: true
        tipoAtto nullable: true
    }

    def beforeValidate() {
        if (springSecurityService.currentUser) {
            utente = springSecurityService.currentUser.id
            dataVariazione = new Date()
        }
    }

    def beforeInsert() {
        if (springSecurityService.currentUser) {
            utente = springSecurityService.currentUser.id
            dataVariazione = new Date()
        }
    }

    def beforeUpdate() {
        if (springSecurityService.currentUser) {
            utente = springSecurityService.currentUser.id
            dataVariazione = new Date()
        }
    }

}
