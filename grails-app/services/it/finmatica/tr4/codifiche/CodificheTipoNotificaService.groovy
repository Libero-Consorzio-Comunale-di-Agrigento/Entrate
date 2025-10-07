package it.finmatica.tr4.codifiche

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.TipoNotifica
import it.finmatica.tr4.dto.TipoNotificaDTO

@Transactional
class CodificheTipoNotificaService {

    def dataSource

    def getListaTipiNotifica() {
        return TipoNotifica.findAll()
                .sort { it.tipoNotifica }
                .toDTO()
    }

    def salvaTipoNotifica(TipoNotificaDTO tipoNotificaDTO){
        tipoNotificaDTO.toDomain().save(failOnError: true, flush: true)
    }

    def existsTipoNotifica(def id){
        return TipoNotifica.exists(id)
    }

    def eliminaTipoNotifica(TipoNotificaDTO tipoNotificaDTO){

        def messaggio = ""

        messaggio = checkTipoNotificaEliminabile(tipoNotificaDTO)

        // Eliminazione possibile
        if (messaggio.length() == 0) {
            tipoNotificaDTO.toDomain().delete(failOnError: true, flush: true)
        }

        return messaggio
    }

    def checkTipoNotificaEliminabile(def tipoNotificaDTO) {

        String call = "{call TIPI_NOTIFICA_PD(?)}"

        def params = []

        params << tipoNotificaDTO.tipoNotifica

        Sql sql = new Sql(dataSource)
        sql.call(call, params)
        return ''

    }

}
