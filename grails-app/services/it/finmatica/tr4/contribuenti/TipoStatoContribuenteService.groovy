package it.finmatica.tr4.contribuenti


import it.finmatica.tr4.TipoStatoContribuente
import it.finmatica.tr4.dto.TipoStatoContribuenteDTO

class TipoStatoContribuenteService {

    def listTipiStatoContribuente() {
        return TipoStatoContribuente.listOrderById().toDTO()
    }

    def existsAnyTipoStatoContribuente() {
        return TipoStatoContribuente.count() > 0
    }

    def newTipoStatoContribuente() {
        return new TipoStatoContribuenteDTO()
    }

    def existsTipoStatoContribuente(def id) {
        return TipoStatoContribuente.countById(id) > 0
    }

    void saveTipoStatoContribuente(TipoStatoContribuenteDTO tipoStatoContribuente) {
        tipoStatoContribuente.toDomain().save(flush: true, failOnError: true)
    }

    void deleteTipoStatoContribuente(TipoStatoContribuenteDTO tipoStatoContribuente) {
        tipoStatoContribuente.toDomain().delete(flush: true, failOnError: true)
    }
}
