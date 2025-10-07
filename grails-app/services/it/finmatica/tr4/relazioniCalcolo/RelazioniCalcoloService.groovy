package it.finmatica.tr4.relazioniCalcolo

import grails.transaction.Transactional
import it.finmatica.tr4.*
import it.finmatica.tr4.commons.OggettiCache
import it.finmatica.tr4.moltiplicatori.MoltiplicatoriService
import org.hibernate.FetchMode

@Transactional
class RelazioniCalcoloService {

    MoltiplicatoriService moltiplicatoriService

    def noneRelazioneCalcoloForAnno(def tipoTributo, def anno) {
        RelazioneOggettoCalcolo.createCriteria().count {
            eq("tipoAliquota.tipoTributo.tipoTributo", tipoTributo)
            eq("anno", anno as Short)
        } == 0
    }

    def getListaRelazioniCalcolo(def tipoTributo, def anno = null, def filtri = [:]) {

        return RelazioneOggettoCalcolo.createCriteria().list {
            fetchMode('categoriaCatasto', FetchMode.JOIN)
            fetchMode('tipoAliquota', FetchMode.JOIN)
            fetchMode('tipoOggetto', FetchMode.JOIN)

            eq("tipoAliquota.tipoTributo.tipoTributo", tipoTributo)
            if (anno) {
                eq("anno", anno as Short)
            }

            if (filtri?.daTipoOggetto != null) {
                ge("tipoOggetto.tipoOggetto", filtri.daTipoOggetto.tipoOggetto)
            }

            if (filtri?.aTipoOggetto != null) {
                le("tipoOggetto.tipoOggetto", filtri.aTipoOggetto.tipoOggetto)
            }

            if (filtri?.daCatCatasto != null) {
                ge("categoriaCatasto.categoriaCatasto", filtri.daCatCatasto.categoriaCatasto)
            }

            if (filtri?.aCatCatasto != null) {
                le("categoriaCatasto.categoriaCatasto", filtri.aCatCatasto.categoriaCatasto)
            }

            if (filtri?.daTipoAliquota != null) {
                ge("tipoAliquota.tipoAliquota", filtri.daTipoAliquota.tipoAliquota)
            }

            if (filtri?.aTipoAliquota != null) {
                le("tipoAliquota.tipoAliquota", filtri.aTipoAliquota.tipoAliquota)
            }

            order('anno', 'desc')
            order("tipoOggetto")
            order("categoriaCatasto")
            order("tipoAliquota")
        }

    }

    List getMissingTipiAliquotaForAnno(List tipiAliquoteNeeded, def anno) {
        def aliquote = OggettiCache.ALIQUOTE.valore.findAll { it.anno == anno }
        if (aliquote.empty) {
            return tipiAliquoteNeeded
        }

        def existingTipiAliquote = aliquote.collect { hashTipoAliquota(it.tipoAliquota) }.unique()

        List missing = tipiAliquoteNeeded.findAll {
            def needed = hashTipoAliquota(it)
            !(needed in existingTipiAliquote)
        }

        return missing
    }

    private def hashTipoAliquota(def tipoAliquota) {
        return "$tipoAliquota.tipoTributo.tipoTributo$tipoAliquota.tipoAliquota"
    }

    List getMissingCategorieCatastoForAnno(List categorieCatastoNeeded, def anno) {
        def moltiplicatori = moltiplicatoriService.getListaMoltiplicatori([anno: anno])
        if (moltiplicatori.empty) {
            return categorieCatastoNeeded
        }

        def existingCategorieCatasto = moltiplicatori.collect { it.categoriaCatasto.categoriaCatasto }.unique()

        List missing = categorieCatastoNeeded.findAll {
            return it && !(it.categoriaCatasto in existingCategorieCatasto)
        }

        return missing
    }

    def cloneListaRelazioneCalcolo(def list, def annoTarget) {
        list.each { current ->
            def brandNew = new RelazioneOggettoCalcolo()
            brandNew.anno = annoTarget
            brandNew.tipoAliquota = current.tipoAliquota
            brandNew.tipoOggetto = current.tipoOggetto
            brandNew.save(failOnError: true, flush: true)
        }
    }

    def existsRelazioneCalcolo(def relazione) {
        RelazioneOggettoCalcolo.createCriteria().count {
            if (relazione.id) {
                ne('id', relazione.id)
            }
            eq('anno', relazione.anno)
            eq('tipoOggetto.tipoOggetto', relazione.tipoOggetto.tipoOggetto)
            if (relazione.categoriaCatasto) {
                eq('categoriaCatasto.categoriaCatasto', relazione.categoriaCatasto.categoriaCatasto)
            } else {
                isNull('categoriaCatasto')
            }
            eq('tipoAliquota', relazione.tipoAliquota)
        } > 0
    }

    def salvaRelazioneCalcolo(def rel) {
        rel.save(failOnError: true, flush: true)
    }

    def eliminaRelazioneCalcolo(def rel) {
        rel.delete(failOnError: true, flush: true)
    }

    def getListaTipiOggetto(def tipoTributo) {

        def oggTributo = OggettoTributo.createCriteria().list {
            eq("tipoTributo.tipoTributo", tipoTributo)
        }

        def tipiOggetti = TipoOggetto.createCriteria().list {
            'in'("tipoOggetto", oggTributo.collect { it.tipoOggetto.tipoOggetto })
        }.sort { it.tipoOggetto }

        return tipiOggetti
    }

    def getListaCategoriaCatasto(def anno) {
        return Moltiplicatore.createCriteria().list {
            eq("anno", anno as short)
        }.collect {
            it.categoriaCatasto
        }.sort { it.categoriaCatasto }
    }

    def getListaTipiAliquota(def tipoTributo, def anno) {
        return Aliquota.createCriteria().list {
            like("tipoAliquota.tipoTributo.tipoTributo", tipoTributo)
            eq("anno", anno as short)
        }.collect {
            it.tipoAliquota
        }.sort {
            it.tipoAliquota
        }
    }

    def getListaAnniDuplicaDaAnno(def tipoTributo) {
        return RelazioneOggettoCalcolo.createCriteria().list {
            projections {
                distinct('anno')
            }
            eq('tipoAliquota.tipoTributo.tipoTributo', tipoTributo)
            order('anno', 'desc')
        }
    }
}
