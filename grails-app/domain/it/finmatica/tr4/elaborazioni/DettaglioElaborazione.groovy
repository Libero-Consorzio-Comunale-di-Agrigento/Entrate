package it.finmatica.tr4.elaborazioni

import it.finmatica.tr4.Contribuente
import it.finmatica.tr4.EredeSoggetto
import it.finmatica.tr4.pratiche.PraticaTributo

class DettaglioElaborazione {

    PraticaTributo pratica
    Contribuente contribuente
    String flagSelezionato
    Long stampaId
    Long documentaleId
    Long tipografiaId
    Long avvisoAgidId
    Long appioId
    Long anagrId
	Long controlloAtId
	Long allineamentoAtId
    String nomeFile
    Integer numPagine
    // byte[] documento
    String utente
    Date dataVariazione
    String note
    EredeSoggetto eredeSoggetto

    static belongsTo = [elaborazione: ElaborazioneMassiva]

    static mapping = {
        id column: "DETTAGLIO_ID", generator: 'it.finmatica.tr4.NrIdGenerator', params: [storedProcedure: "DETTAGLI_ELABORAZIONE_NR"]
        pratica column: "pratica"
        contribuente column: "cod_fiscale"
        columns {
            eredeSoggetto {
                column name: "ni"
                column name: "ni_erede"
            }
        }

        table "dettagli_elaborazione"

        version false
    }

    static constraints = {
        pratica nullable: true
        contribuente nullable: true
        flagSelezionato nullable: true
        stampaId nullable: true
        documentaleId nullable: true
        tipografiaId nullable: true
        avvisoAgidId nullable: true
        nomeFile nullable: true
        numPagine nullable: true
        // documento nullable: true
        utente nullable: true
        dataVariazione nullable: true
        note nullable: true
        appioId nullable: true
        anagrId nullable: true
		controlloAtId nullable: true
		allineamentoAtId nullable: true
        eredeSoggetto nullable: true
    }

    Map asMap() {
        this.class.declaredFields.findAll { !it.synthetic }.collectEntries {
            [(it.name): this."$it.name"]
        }
    }
}
