package it.finmatica.tr4.sgravio

import grails.transaction.Transactional
import it.finmatica.tr4.MotivoSgravio
import it.finmatica.tr4.dto.MotivoSgravioDTO

@Transactional
class MotivoSgravioService {

    Collection<MotivoSgravioDTO> getByCriteria(def criteria = [:]) {
        return MotivoSgravio.createCriteria().list {

            // I cast sono necessari :
            //      il tipo "Number" viene interpretato da Hibernate come java.lang.Long
            //      i parametri Java vengono interpretati come java.Lang.Integer
            if (criteria?.da) {
                gte('id', (Long) criteria.da)
            }
            if (criteria?.a) {
                lte('id', (Long) criteria.a)
            }
            if (criteria?.descrizione) {
                // org.grails.datastore.gorm.Criterion non funzionano con org.hibernate.criterion e non esiste un iLike
                // che permette di specificare il MatchMode ( org.hibernate.criterion.MatchMode)
                ilike("descrizione", criteria.descrizione)
            }

            order('id', 'asc')
        }.toDTO()
    }

    /**
     * @assert null != dto
     * @assert null != dto.id
     */
    MotivoSgravioDTO exist(MotivoSgravioDTO dto) {
        return MotivoSgravio.get(dto?.id)?.toDTO()
    }

    def salva(MotivoSgravioDTO dto) {
        dto.descrizione = dto.descrizione.toUpperCase()
        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(MotivoSgravioDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }
}
