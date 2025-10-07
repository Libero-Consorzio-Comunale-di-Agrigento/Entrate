package it.finmatica.tr4.elaborazioni

import it.finmatica.tr4.TipoTributo

class ElaborazioneMassiva {

    def springSecurityService

    String nomeElaborazione
    Date dataElaborazione
    TipoTributo tipoTributo
	String gruppoTributo
    String tipoPratica
    Long ruolo
    String utente
    Date dataVariazione
    String note
	Short anno
    TipoElaborazione tipoElaborazione

    static transients = ['springSecurityService']

    static hasMany = [
            attivita: AttivitaElaborazione,
            dettagli: DettaglioElaborazione
    ]

    static mapping = {
        id column: "ELABORAZIONE_ID", 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "ELABORAZIONI_MASSIVE_NR"]
        tipoTributo column: "tipo_tributo"
        tipoElaborazione column: 'tipo_elaborazione'
        
        gruppoTributo column: "gruppo_tributo"

        table 'ELABORAZIONI_MASSIVE'

        version false
    }

    static constraints = {
        dataElaborazione nullable: true
        tipoTributo nullable: true
		gruppoTributo nullable: true
        tipoPratica nullable: true
        ruolo nullable: true
        utente nullable: true
        dataVariazione nullable: true
        note nullable: true
        anno nullable: true
        tipoElaborazione nullable: true
    }

    def beforeInsert() {
        utente = utente ?: springSecurityService.currentUser?.id
    }

    Map asMap() {
        this.class.declaredFields.findAll { !it.synthetic }.collectEntries {
            [ (it.name):this."$it.name" ]
        }
    }
}
