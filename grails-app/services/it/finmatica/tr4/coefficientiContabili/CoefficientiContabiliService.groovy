package it.finmatica.tr4.coefficientiContabili


import it.finmatica.tr4.CoefficientiContabili
import it.finmatica.tr4.dto.CoefficientiContabiliDTO

class CoefficientiContabiliService {

    def getListaCoefficientiContabili(def filtro = [:]) {
        def elenco = CoefficientiContabili.createCriteria().list {
            if (filtro.anno) {
                eq('anno', filtro.anno as Short)
            }
            if (filtro.daAnnoCoeff) {
                ge('annoCoeff', filtro.daAnnoCoeff as Short)
            }
            if (filtro.aAnnoCoeff) {
                le('annoCoeff', filtro.aAnnoCoeff as Short)
            }
            if (filtro.daCoeff) {
                ge('coeff', filtro.daCoeff)
            }
            if (filtro.aCoeff) {
                le('coeff', filtro.aCoeff)
            }

            order('anno', 'desc')
            order('annoCoeff', 'asc')
        }

        def listaCoefficientiContabili = []

        elenco.collect({ cc ->
            def coefficienteContabile = [:]

            coefficienteContabile.dto = cc.toDTO()
            coefficienteContabile.anno = cc.anno
            coefficienteContabile.annoCoeff = cc.annoCoeff
            coefficienteContabile.coeff = cc.coeff

            listaCoefficientiContabili << coefficienteContabile
        })

        return listaCoefficientiContabili

    }

    def getCountCoefficientiContabiliByAnno(def anno) {
        return CoefficientiContabili.countByAnno(anno)
    }

    def salvaCoefficienteContabile(CoefficientiContabiliDTO coefficienteContabile) {
        coefficienteContabile.toDomain().save(failOnError: true, flush: true)
    }

    def eliminaCoefficienteContabile(CoefficientiContabiliDTO coefficienteContabile) {
        coefficienteContabile.toDomain().delete(failOnError: true, flush: true)
    }

    def existsCoefficienteContabile(CoefficientiContabiliDTO coefficienteContabile) {
        return CoefficientiContabili.findByAnnoAndAnnoCoeff(coefficienteContabile.anno, coefficienteContabile.annoCoeff) != null
    }

    def getListaAnniDuplicaDaAnno() {
        return CoefficientiContabili.createCriteria().list {
            projections {
                distinct('anno')
                order('anno', 'desc')
            }
        }
    }
}

