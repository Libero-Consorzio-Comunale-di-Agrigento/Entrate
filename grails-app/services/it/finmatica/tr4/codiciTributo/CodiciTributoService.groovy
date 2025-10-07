package it.finmatica.tr4.codiciTributo

import grails.transaction.Transactional
import it.finmatica.tr4.CodiceTributo
import it.finmatica.tr4.dto.CodiceTributoDTO

@Transactional
class CodiciTributoService {

    Collection<CodiceTributoDTO> getByCriteria(String tipoTributo) {
        return CodiceTributo.createCriteria().list {
            eq("tipoTributo.tipoTributo", tipoTributo)
            order("id", 'asc')
        }.toDTO(['TipoTributo'])
    }

}
