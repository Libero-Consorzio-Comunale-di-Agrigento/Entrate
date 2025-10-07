package it.finmatica.tr4.categorieCatasto

import it.finmatica.tr4.CategoriaCatasto
import it.finmatica.tr4.dto.CategoriaCatastoDTO

class CategorieCatastoService {

    static def TIPI_TRATTAMENTO = [
            [eccezione: null, descrizione: 'Normale'],
            [eccezione: 'E', descrizione: 'Esenzione'],
            [eccezione: 'N', descrizione: 'Non Trattare']
    ]

    def getListaCategorieCatasto(def filtro) {
        def elenco = CategoriaCatasto.createCriteria().list {
            if (filtro.categoriaCatasto) {
                ilike('categoriaCatasto', filtro.categoriaCatasto)
            }
            if (filtro.descrizione) {
                ilike('descrizione', filtro.descrizione)
            }
            if (filtro.flagReale != null) {
                if (filtro.flagReale) {
                    eq('flagReale', true)
                } else {
                    isNull('flagReale')
                }
            }
            if (filtro.eccezione) {
                eq('eccezione', filtro.eccezione)
            }

            order('categoriaCatasto', 'asc')
        }

        def listaCategorieCatasto = []

        elenco.collect({ cc ->
            def categoriaCatasto = [:]

            categoriaCatasto.dto = cc.toDTO()
            categoriaCatasto.categoriaCatasto = cc.categoriaCatasto
            categoriaCatasto.descrizione = cc.descrizione
            categoriaCatasto.flagReale = cc.flagReale
            categoriaCatasto.eccezione = TIPI_TRATTAMENTO.find({ it.eccezione == cc.eccezione }).descrizione

            listaCategorieCatasto << categoriaCatasto
        })

        return listaCategorieCatasto

    }

    def salvaCategoriaCatasto(CategoriaCatastoDTO categoriaCatasto) {
        categoriaCatasto.toDomain().save(failOnError: true, flush: true)
    }

    def eliminaCategoriaCatasto(CategoriaCatastoDTO categoriaCatasto) {
        categoriaCatasto.toDomain().delete(failOnError: true, flush: true)
    }

    def existsCategoriaCatasto(CategoriaCatastoDTO categoriaCatasto) {
        return CategoriaCatasto.findByCategoriaCatasto(categoriaCatasto.categoriaCatasto) != null
    }
}
