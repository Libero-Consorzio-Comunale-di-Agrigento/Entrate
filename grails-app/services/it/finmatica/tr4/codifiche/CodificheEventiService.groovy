package it.finmatica.tr4.codifiche

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.Eventi
import it.finmatica.tr4.TipoEvento
import it.finmatica.tr4.dto.EventiDTO
import it.finmatica.tr4.dto.TipoEventoDTO

@Transactional
class CodificheEventiService {

    def dataSource

    def salvaEvento(def eventiDTO) {
        eventiDTO.toDomain().save(flush: true, failOnError: true)
    }

    def salvaTipoEvento(def tipoEventoDTO) {
        tipoEventoDTO.toDomain().save(flush: true, failOnError: true)
    }

    def getTipoEventoDTO(def tipoEvento, def isModifica) {

        def dto

        // Controllo se esiste già un tipo evento con lo stesso id per aggiunta/clonazione
        if (!isModifica && TipoEvento.exists(tipoEvento.tipoEvento))
            return "Esiste già un Tipo Evento con lo stesso identificatore"

        dto = isModifica ? TipoEvento.get(tipoEvento.tipoEvento).toDTO() : new TipoEventoDTO()
        dto.tipoEvento = tipoEvento.tipoEvento
        dto.descrizione = tipoEvento.descrizione

        return dto
    }

    def getEventoDTO(def evento, def isModifica) {

        def dto

        dto = isModifica ? Eventi.createCriteria().get {
            eq('tipoEvento', evento.tipoEvento)
            eq('sequenza', evento.sequenza)
        }.toDTO() : new EventiDTO()

        dto.tipoEvento = evento.tipoEvento
        dto.sequenza = evento.sequenza
        dto.dataEvento = evento.dataEvento
        dto.descrizione = evento.descrizione
        dto.note = evento.note

        return dto
    }

    def getListaTipiEvento() {
        return TipoEvento.findAll()
                .sort { it.tipoEvento }
                .collect {
                    [tipoEvento : it.tipoEvento,
                     descrizione: it.descrizione]
                }
    }

    def getListaEventi() {
        return Eventi.findAll()
                .sort { it.sequenza }
                .collect {
                    [sequenza   : it.sequenza,
                     dataEvento : it.dataEvento,
                     descrizione: it.descrizione,
                     tipoEvento : it.tipoEvento,
                     note       : it.note]
                }
    }


    def eliminaTipoEvento(def tipoEventoDTO) {

        def messaggio = ""

        // Verifico se è possibile effettuare l'eliminazione
        messaggio = checkEliminaTipoEvento(tipoEventoDTO)

        // Eliminazione possibile
        if (messaggio.length() == 0)
            tipoEventoDTO.toDomain().delete(failOnError: true)

        return messaggio
    }

    def eliminaEvento(def eventoDTO) {

        def messaggio = ""

        // Verifico se è possibile effettuare l'eliminazione
        messaggio = checkEliminaEvento(eventoDTO)

        // Eliminazione possibile
        if (messaggio.length() == 0)
            eventoDTO.toDomain().delete(failOnError: true)

        return messaggio
    }

    def checkEliminaTipoEvento(def tipoEventoDTO) {

        def params = [tipoEventoDTO.tipoEvento]

        try {
            Sql sql = new Sql(dataSource)
            sql.call("{call TIPI_EVENTO_PD(?)}", params)
            return ''
        } catch (Exception e) {
            return e.message.substring('ORA-20006: '.length(), e.message.indexOf('\n'))
        }
    }

    def checkEliminaEvento(def eventoDTO) {

        def params = [eventoDTO.tipoEvento, eventoDTO.sequenza]

        try {
            Sql sql = new Sql(dataSource)
            sql.call("{call EVENTI_PD(?,?)}", params)
            return ''
        } catch (Exception e) {
            return e.message.substring('ORA-20006: '.length(), e.message.indexOf('\n'))
        }
    }

}
