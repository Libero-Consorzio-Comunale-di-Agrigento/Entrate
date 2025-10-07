package it.finmatica.tr4.coefficientiDomestici

import it.finmatica.tr4.CoefficientiDomestici
import it.finmatica.tr4.dto.CoefficientiDomesticiDTO


class CoefficientiDomesticiService {

    def getListaCoefficientiDomestici(def filtro = [:]) {
        def elenco = CoefficientiDomestici.createCriteria().list {
            if (filtro.anno) {
                eq('anno', filtro.anno as Short)
            }
            if (filtro.daNumeroFamiliari) {
                ge('numeroFamiliari', filtro.daNumeroFamiliari as Byte)
            }
            if (filtro.aNumeroFamiliari) {
                le('numeroFamiliari', filtro.aNumeroFamiliari as Byte)
            }
            if (filtro.daCoeffAdattamento) {
                ge('coeffAdattamento', filtro.daCoeffAdattamento)
            }
            if (filtro.aCoeffAdattamento) {
                le('coeffAdattamento', filtro.aCoeffAdattamento)
            }
            if (filtro.daCoeffProduttivita) {
                ge('coeffProduttivita', filtro.daCoeffProduttivita)
            }
            if (filtro.aCoeffProduttivita) {
                le('coeffProduttivita', filtro.aCoeffProduttivita)
            }
            if (filtro.daCoeffAdattamentoNoAp) {
                ge('coeffAdattamentoNoAp', filtro.daCoeffAdattamentoNoAp)
            }
            if (filtro.aCoeffAdattamentoNoAp) {
                le('coeffAdattamentoNoAp', filtro.aCoeffAdattamentoNoAp)
            }
            if (filtro.daCoeffProduttivitaNoAp) {
                ge('coeffProduttivitaNoAp', filtro.daCoeffProduttivitaNoAp)
            }
            if (filtro.aCoeffProduttivitaNoAp) {
                le('coeffProduttivitaNoAp', filtro.aCoeffProduttivitaNoAp)
            }

            order('anno', 'desc')
            order('numeroFamiliari', 'asc')
        }

        def listaCoefficientiDomestici = []

        elenco.collect({ cd ->
            def coefficienteDomestico = [
                    dto                  : cd.toDTO(),
                    anno                 : cd.anno,
                    numeroFamiliari      : cd.numeroFamiliari,
                    coeffAdattamento     : cd.coeffAdattamento,
                    coeffProduttivita    : cd.coeffProduttivita,
                    coeffAdattamentoNoAp : cd.coeffAdattamentoNoAp,
                    coeffProduttivitaNoAp: cd.coeffProduttivitaNoAp
            ]

            listaCoefficientiDomestici << coefficienteDomestico
        })

        return listaCoefficientiDomestici
    }

    def getCountCoefficientiDomesticiByAnno(def anno) {
        return CoefficientiDomestici.countByAnno(anno)
    }

    def salvaCoefficienteDomestico(CoefficientiDomesticiDTO coefficienteDomestico) {
        coefficienteDomestico.toDomain().save(failOnError: true, flush: true)
    }

    def eliminaCoefficienteDomestico(CoefficientiDomesticiDTO coefficienteDomestico) {
        coefficienteDomestico.toDomain().delete(failOnError: true, flush: true)
    }

    def existsCoefficienteDomestico(CoefficientiDomesticiDTO coefficienteDomestico) {
        return CoefficientiDomestici.findByAnnoAndNumeroFamiliari(coefficienteDomestico.anno, coefficienteDomestico.numeroFamiliari) != null
    }

    def getListaAnniDuplicaDaAnno() {
        return CoefficientiDomestici.createCriteria().list {
            projections {
                distinct('anno')
                order('anno', 'desc')
            }
        }
    }
}

