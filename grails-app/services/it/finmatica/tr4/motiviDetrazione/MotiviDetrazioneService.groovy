package it.finmatica.tr4.motiviDetrazione

import grails.transaction.Transactional
import it.finmatica.tr4.MotiviDetrazione
import it.finmatica.tr4.dto.MotiviDetrazioneDTO

@Transactional
class MotiviDetrazioneService {

    /**
     * @assert null != tipoTributo
     */
    Collection<MotiviDetrazioneDTO> getByCriteria(String tipoTributo, def criteria = [:]) {
        return getByCriteriaInternal(tipoTributo, criteria).toDTO()
    }

    /**
     * @assert null != tipoTributo
     */
    boolean exist(String tipoTributo, def criteria = [:]) {
        return getByCriteriaInternal(tipoTributo, criteria).size() > 0
    }

    /**
     * @assert null != tipoTributo
     */
    private static Collection<MotiviDetrazione> getByCriteriaInternal(String tipoTributo, def criteria = [:]) {

        return MotiviDetrazione.createCriteria().list {
            if (criteria?.motivoDetrazione) {
                eq("motivoDetrazione", criteria.motivoDetrazione)
            }
            eq("tipoTributo", tipoTributo)
            if (criteria?.da) {
                gte("motivoDetrazione", criteria.da as Short)
            }
            if (criteria?.a) {
                lte("motivoDetrazione", criteria.a as Short)
            }
            if (criteria?.descrizione) {
                // org.grails.datastore.gorm.Criterion non funzionano con org.hibernate.criterion e non esiste un iLike
                // che permette di specificare il MatchMode ( org.hibernate.criterion.MatchMode)
                ilike((String) "descrizione", criteria.descrizione)
            }
            order("motivoDetrazione", 'asc')
        }
    }


    def salva(MotiviDetrazioneDTO dto) {
        dto.descrizione = dto.descrizione.toUpperCase()
        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(MotiviDetrazioneDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }

}
