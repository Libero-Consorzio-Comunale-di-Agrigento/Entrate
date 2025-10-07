package it.finmatica.tr4.tariffeDomestiche

import it.finmatica.tr4.TariffaDomestica
import it.finmatica.tr4.dto.TariffaDomesticaDTO

class TariffeDomesticheService {

    def getListaTariffeDomestiche(def filtro = [:]) {
        def elenco = TariffaDomestica.createCriteria().list {
            if (filtro.anno) {
                eq('anno', filtro.anno as Short)
            }
            if (filtro.daNumeroFamiliari) {
                ge('numeroFamiliari', filtro.daNumeroFamiliari as Byte)
            }
            if (filtro.aNumeroFamiliari) {
                le('numeroFamiliari', filtro.aNumeroFamiliari as Byte)
            }
            if (filtro.daTariffaQuotaFissa) {
                ge('tariffaQuotaFissa', filtro.daTariffaQuotaFissa)
            }
            if (filtro.aTariffaQuotaFissa) {
                le('tariffaQuotaFissa', filtro.aTariffaQuotaFissa)
            }
            if (filtro.daTariffaQuotaVariabile) {
                ge('tariffaQuotaVariabile', filtro.daTariffaQuotaVariabile)
            }
            if (filtro.aTariffaQuotaVariabile) {
                le('tariffaQuotaVariabile', filtro.aTariffaQuotaVariabile)
            }
            if (filtro.daTariffaQuotaFissaNoAp) {
                ge('tariffaQuotaFissaNoAp', filtro.daTariffaQuotaFissaNoAp)
            }
            if (filtro.aTariffaQuotaFissaNoAp) {
                le('tariffaQuotaFissaNoAp', filtro.aTariffaQuotaFissaNoAp)
            }
            if (filtro.daTariffaQuotaVariabileNoAp) {
                ge('tariffaQuotaVariabileNoAp', filtro.daTariffaQuotaVariabileNoAp)
            }
            if (filtro.aTariffaQuotaVariabileNoAp) {
                le('tariffaQuotaVariabileNoAp', filtro.aTariffaQuotaVariabileNoAp)
            }
            if (filtro.daSvuotamentiMinimi) {
                ge('svuotamentiMinimi', filtro.daSvuotamentiMinimi as Short)
            }
            if (filtro.aSvuotamentiMinimi) {
                le('svuotamentiMinimi', filtro.aSvuotamentiMinimi as Short)
            }

            order('anno', 'desc')
            order('numeroFamiliari', 'asc')
        }

        def listaTariffeDomestiche = []

        elenco.collect({ td ->
            def tariffaDomestica = [
                    dto                         : td.toDTO(),
                    anno                        : td.anno,
                    numeroFamiliari             : td.numeroFamiliari,
                    tariffaQuotaFissa           : td.tariffaQuotaFissa,
                    tariffaQuotaVariabile       : td.tariffaQuotaVariabile,
                    tariffaQuotaFissaNoAp       : td.tariffaQuotaFissaNoAp,
                    tariffaQuotaVariabileNoAp   : td.tariffaQuotaVariabileNoAp,
                    svuotamentiMinimi           : td.svuotamentiMinimi
            ]

            listaTariffeDomestiche << tariffaDomestica
        })

        return listaTariffeDomestiche
    }

    def getCountTariffeDomesticheByAnno(def anno) {
        return TariffaDomestica.countByAnno(anno)
    }

    def salvaTariffaDomestica(TariffaDomesticaDTO tariffaDomestica) {
        tariffaDomestica.toDomain().save(failOnError: true, flush: true)
    }

    def eliminaTariffaDomestica(TariffaDomesticaDTO tariffaDomestica) {
        tariffaDomestica.toDomain().delete(failOnError: true, flush: true)
    }

    def existsTariffaDomestica(TariffaDomesticaDTO tariffaDomestica) {
        return TariffaDomestica.findByAnnoAndNumeroFamiliari(tariffaDomestica.anno, tariffaDomestica.numeroFamiliari) != null
    }

    def getListaAnniDuplicaDaAnno() {
        return TariffaDomestica.createCriteria().list {
            projections {
                distinct('anno')
                order('anno', 'desc')
            }
        }
    }
}

