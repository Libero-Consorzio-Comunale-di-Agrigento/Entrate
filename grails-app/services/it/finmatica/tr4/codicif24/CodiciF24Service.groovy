package it.finmatica.tr4.codicif24

import grails.transaction.Transactional
import it.finmatica.tr4.BeneficiariTributo
import it.finmatica.tr4.CodiceF24
import it.finmatica.tr4.dto.BeneficiariTributoDTO
import it.finmatica.tr4.dto.CodiceF24DTO
import org.hibernate.SessionFactory

@Transactional
class CodiciF24Service {

    SessionFactory sessionFactory
    def dataSource

    def getListaCodiciF24(def tipoTributo, def filtro = [:]) {

        CodiceF24.createCriteria().list {

            eq('tipoTributo.tipoTributo', tipoTributo)

            if (filtro?.tributo?.trim()) {
                eq('tributo', filtro.tributo.trim())
            }

            if (filtro?.descrizione?.trim()) {
                'ilike'('descrizione', filtro.descrizione.trim())
            }

            if (filtro?.tipoRateazione) {
                eq('rateazione', filtro.tipoRateazione)
            }

            if (filtro?.tipoCodice) {
                eq('tipoCodice', filtro.tipoCodice)
            }

            if (filtro && filtro.stampaRateazione != 'E') {
                if (filtro.stampaRateazione == 'S') {
                    eq('flagStampaRateazione', filtro.stampaRateazione)
                } else if (filtro.stampaRateazione == 'N') {
                    isNull('flagStampaRateazione')
                }

            }

            order("tributo", "desc")

        }.toDTO()
    }

    def salvaCodiceF24(CodiceF24DTO codiceF24) {
        return codiceF24.toDomain().save(failOnError: true, flush: true)
    }

    def eliminaCodiceF24(CodiceF24 codiceF24) {
        codiceF24.delete(failOnError: true, flush: true)
    }

    def getCodiceF24(def tipoTributo) {
        return CodiceF24.createCriteria().get {
            eq('tipoTributo', tipoTributo)
        }
    }

    def getBeneficiari(CodiceF24DTO codiceF24) {

        List<BeneficiariTributoDTO> beneficiari

        String tributo = codiceF24?.tributo
        beneficiari = BeneficiariTributo.findAllByTributoF24(tributo)?.toDTO()

        return beneficiari
    }

    def salvaBeneficiario(BeneficiariTributoDTO beneficiario) {
        return beneficiario.toDomain().save(failOnError: true, flush: true)
    }

    def eliminaBeneficiario(BeneficiariTributoDTO beneficiario) {

        BeneficiariTributo beneficiarioRaw = beneficiario.getDomainObject()
        beneficiarioRaw.delete(failOnError: true, flush: true)
    }
}
