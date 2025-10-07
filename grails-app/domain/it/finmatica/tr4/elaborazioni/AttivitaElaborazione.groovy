package it.finmatica.tr4.elaborazioni

import it.finmatica.tr4.Modelli
import it.finmatica.tr4.comunicazioni.DettaglioComunicazione

class AttivitaElaborazione {

    def springSecurityService

    Date dataAttivita
    TipoAttivita tipoAttivita
    StatoAttivita statoAttivita
    Modelli modello
    String flagF24
    String utente
    Date dataVariazione
    String note
    TipoSpedizione tipoSpedizione
    String testoAppio

    String flagNotifica
    DettaglioComunicazione dettaglioComunicazione

    static belongsTo = [elaborazione: ElaborazioneMassiva]

    static transients = ['springSecurityService']

    static mapping = {
        id column: "ATTIVITA_ID", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "ATTIVITA_ELABORAZIONE_NR"]

        tipoAttivita column: "TIPO_ATTIVITA"
        statoAttivita column: "STATO_ATTIVITA"
        tipoSpedizione column: "TIPO_SPEDIZIONE"
        flagF24 column: "FLAG_F24"
        modello column: "MODELLO", ignoreNotFound: true

        columns {
            dettaglioComunicazione {
                column name: "tipo_tributo"
                column name: "tipo_comunicazione"
                column name: "sequenza_comunicazione"
            }
        }

        table "attivita_elaborazione"

        version false

    }

    static constraints = {
        dataAttivita nullable: true
        modello nullable: true
        flagF24 nullable: true
        utente nullable: true
        dataVariazione nullable: true
        note nullable: true
        tipoSpedizione nullable: true
        testoAppio nullable: true
        flagNotifica nullable: true
        dettaglioComunicazione nullable: true
    }

    def beforeInsert() {
        utente = springSecurityService.currentUser?.id
    }

    Map asMap() {
        this.class.declaredFields.findAll { !it.synthetic }.collectEntries {
            [(it.name): this."$it.name"]
        }
    }
}
