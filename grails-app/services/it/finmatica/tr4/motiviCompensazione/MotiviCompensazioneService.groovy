package it.finmatica.tr4.motiviCompensazione

import grails.transaction.Transactional
import it.finmatica.tr4.MotivoCompensazione
import it.finmatica.tr4.dto.MotivoCompensazioneDTO

@Transactional
class MotiviCompensazioneService {

    /**
     * @assert null != tipoTributo
     */
    Collection<MotivoCompensazioneDTO> getByCriteria(def criteria = [:]) {
        return getByCriteria_internal(criteria).toDTO()
    }

    /**
     * @assert null != tipoTributo
     */
    boolean exist(def criteria = [:]) {
        return getByCriteria_internal(criteria).size() > 0
    }

    /**
     * @assert null != tipoTributo
     */
    private static Collection<MotivoCompensazione> getByCriteria_internal(def criteria = [:]) {

        return MotivoCompensazione.createCriteria().list {
            if (criteria?.motivoCompensazione) {
                eq("id", criteria.motivoCompensazione)
            }
            if (criteria?.da) {
                gte("id", criteria.da as Long)
            }
            if (criteria?.a) {
                lte("id", criteria.a as Long)
            }
            if (criteria?.descrizione) {
                // org.grails.datastore.gorm.Criterion non funzionano con org.hibernate.criterion e non esiste un iLike
                // che permette di specificare il MatchMode ( org.hibernate.criterion.MatchMode)
                ilike((String) "descrizione", (String) criteria.descrizione)
            }
            order("id", 'asc')
        }
    }

    def salva(MotivoCompensazioneDTO dto) {
        dto.descrizione = dto.descrizione.toUpperCase()
        return dto.toDomain().save(flush: true, failOnError: true)
    }

    void elimina(MotivoCompensazioneDTO dto) {
        dto.toDomain().delete(failOnError: true)
    }

}
