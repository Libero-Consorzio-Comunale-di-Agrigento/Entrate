package it.finmatica.tr4.codifiche

import grails.transaction.Transactional
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.dto.TipoTributoDTO

@Transactional
class CodificheTipoTributoService {

    def salvaTipoTributo(TipoTributoDTO tipoTributoDTO) {
        tipoTributoDTO.toDomain().save(flush: true, failOnError: true)
    }

    def getTipoTributoDTO(def tipoTributo) {

        def dto = TipoTributo.get(tipoTributo.tipoTributo).toDTO()
        dto.tipoTributo = tipoTributo.tipoTributo
        dto.descrizione = tipoTributo.descrizione
        dto.codEnte = tipoTributo.codEnte
        dto.contoCorrente = tipoTributo.contoCorrente
        dto.descrizioneCc = tipoTributo.descrizioneCc
        dto.testoBollettino = tipoTributo.testoBollettino
        dto.flagCanone = tipoTributo.flagCanone
        dto.flagTariffa = tipoTributo.flagTariffa
        dto.flagLiqRiog = tipoTributo.flagLiqRiog
        dto.ufficio = tipoTributo.ufficio
        dto.indirizzoUfficio = tipoTributo.indirizzoUfficio
        dto.tipoUfficio = tipoTributo.tipoUfficio
        dto.codUfficio = tipoTributo.codUfficio

        return dto
    }

    def getListaTipiTributo() {
        return TipoTributo.findAll()
                .sort { it.tipoTributo }
                .collect {
                    [tipoTributo     : it.tipoTributo,
                     descrizione     : it.descrizione,
                     codEnte         : it.codEnte,
                     contoCorrente   : it.contoCorrente,
                     descrizioneCc   : it.descrizioneCc,
                     testoBollettino : it.testoBollettino,
                     flagCanone      : it.flagCanone,
                     flagTariffa     : it.flagTariffa,
                     flagLiqRiog     : it.flagLiqRiog,
                     ufficio         : it.ufficio,
                     indirizzoUfficio: it.indirizzoUfficio,
                     codUfficio      : it.codUfficio,
                     tipoUfficio     : it.tipoUfficio]
                }
    }

}
