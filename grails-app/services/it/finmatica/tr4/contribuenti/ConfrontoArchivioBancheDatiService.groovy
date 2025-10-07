package it.finmatica.tr4.contribuenti

import grails.transaction.NotTransactional
import it.finmatica.tr4.TipoOggetto
import it.finmatica.tr4.commons.OggettiCache

import java.text.SimpleDateFormat

class ConfrontoArchivioBancheDatiService {

    private def DM_PERCRID = 80.0

    ContribuentiService contribuentiService

    @NotTransactional
    def aggiornaDifferenzeOggettiCatasto(def listaOggetti, def oggettiDaCatasto, def immobiliNonAssociatiCatasto, def cbTributi, def anno) {

        def pulisciTesto = { t -> t?.replaceFirst("^0*", "")?.trim() }

        def differenzeOggetti = [:]

        if (!abilitaConfronti(listaOggetti.size())) {
            return differenzeOggetti
        }

        immobiliNonAssociatiCatasto.clear()
        immobiliNonAssociatiCatasto << this.immobiliNonAssociatiCatasto(listaOggetti, oggettiDaCatasto, cbTributi)

        listaOggetti.findAll {
            it.tipoTributo in ['ICI', 'TASI'] && it.idImmobile != null && it.rigaCatastoSelezionata != null
        }.each { a ->

            if (a.idImmobile != null && a.rigaCatastoSelezionata != null) {

                def k = "${a.uuid}"

                def oggCat = oggettiDaCatasto.find { c ->
                    c.IDIMMOBILE == a.idImmobile && c.RIGA == a.rigaCatastoSelezionata
                }

                def anomaliaPerPoss = (oggCat.POSSESSOPERC == null && a.percPossesso == null) ||
                        ((oggCat.POSSESSOPERC ?: 0) - (a.percPossesso ?: 0)).abs() > (0.1 as BigDecimal)
                def anomaliaRendita = false
                // Terreno
                if (a.tipoOggetto == 1) {
                    anomaliaRendita = (oggCat.REDDITODOMINICALE == null && a.rendita == null) ||
                            (oggCat.REDDITODOMINICALE != a.rendita)
                } else {
                    anomaliaRendita = (oggCat.RENDITA == null && a.rendita == null) ||
                            (oggCat.RENDITA != a.rendita)
                }

                SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd")
                def dataInizio = [oggCat.DATAINIZIOVALIDITA, oggCat.DATAEFFICACIAINIZIO].max { it }
                def dataFine = [oggCat.DATAFINEVALIDITA ?: sdf.parse("99991231"), oggCat.DATAEFFICACIAFINE ?: sdf.parse("99991231")].min { it }

                differenzeOggetti[k] = [idImmobile      : oggCat.IDIMMOBILE,
                                        riga            : oggCat.RIGA,
                                        rendita         : anomaliaRendita,
                                        classe          : a.tipoOggetto == 1 ? false : (pulisciTesto(oggCat.CLASSECATASTO) != pulisciTesto(a.classeCatasto)),
                                        categoriaCatasto: a.tipoOggetto == 1 ? false : (pulisciTesto(oggCat.CATEGORIACATASTO) != pulisciTesto(a.categoriaCatasto)),
                                        percPossesso    : anomaliaPerPoss,
                                        sez             : pulisciTesto(oggCat.SEZIONE) != pulisciTesto(a.sezione),
                                        fgl             : pulisciTesto(oggCat.FOGLIO) != pulisciTesto(a.foglio),
                                        num             : pulisciTesto(oggCat.NUMERO) != pulisciTesto(a.numero),
                                        sub             : pulisciTesto(oggCat.SUBALTERNO) != pulisciTesto(a.subalterno),
                                        mesiPossesso    : anno != 'Tutti' ?
                                                contribuentiService
                                                        .calcolaMesi(dataInizio, dataFine, anno as Integer)?.mp != a.mesiPossesso
                                                : false,
                                        oggetto         : false
                ]

            }
        }

        return differenzeOggetti
    }

    @NotTransactional
    def immobiliNonAssociatiCatasto(def listaOggetti, def oggettiDaCatasto, def cbTributi) {
        def immobiliNonAssociati = oggettiDaCatasto.collect { it.RIGA_IMMOBILE }.unique().findAll {
            (cbTributi.ICI &&
                    TipoOggetto.get(oggettiDaCatasto.find { c -> c.RIGA_IMMOBILE == it }.TIPOOGGETTO == 'F' ? 3 : 1)
                            .oggettiTributo.find { it.tipoTributo.tipoTributo == 'ICI' } &&
                    !(it in listaOggetti.findAll {
                        it.tipoTributo in ['ICI']
                    }.collect { "${it.idImmobile}-${it.rigaCatastoSelezionata}" }.unique())) ||
                    (cbTributi.TASI &&
                            TipoOggetto.get(oggettiDaCatasto.find { c -> c.RIGA_IMMOBILE == it }.TIPOOGGETTO == 'F' ? 3 : 1)
                                    .oggettiTributo.find { it.tipoTributo.tipoTributo == 'TASI' } &&
                            !(it in listaOggetti.findAll {
                                it.tipoTributo in ['TASI']
                            }.collect { "${it.idImmobile}-${it.rigaCatastoSelezionata}" }.unique()))
        }.collectEntries { [(it): true] }

        return immobiliNonAssociati
    }

    @NotTransactional
    def aggiornaDifferenzeOggettiDatiMetrici(def listaOggetti, def listaDatiMetrici, def immobiliNonAssociatiDatiMetrici, def cbTributi, def anno) {

        DM_PERCRID = (OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DM_PERCRID' }?.valore?.trim() as Double) ?: 80.0
        def differenzeOggetti = [:]

        if (!abilitaConfronti(listaOggetti.size())) {
            return differenzeOggetti
        }

        immobiliNonAssociatiDatiMetrici.clear()
        immobiliNonAssociatiDatiMetrici << this.immobiliNonAssociatiDatiMetrici(listaOggetti, listaDatiMetrici)

        listaOggetti.findAll { it.idImmobile != null && it.tipoTributo == 'TARSU' }.each { o ->
            def dm = listaDatiMetrici.find { o.idImmobile == it.immobile }
            if (dm != null) {
                differenzeOggetti[(o.uuid)] = [
                        idImmobile      : dm.immobile,
                        categoriaCatasto: dm.categoriaCat != o.categoriaCatasto,
                        sez             : dm.sezioneCat != o.sezione,
                        fgl             : dm.foglioCat != o.foglio,
                        num             : dm.numeroCat != o.numero,
                        sub             : dm.subalternoCat != o.subalterno,
                        superficie      : o.consistenza < (dm.superficieNum * ((DM_PERCRID as BigDecimal) / 100)) || o.consistenza > dm.superficieNum
                ]
            }
        }

        return differenzeOggetti
    }

    @NotTransactional
    def immobiliNonAssociatiDatiMetrici(def listaOggetti, def listaDatiMetrici) {

        if (!abilitaConfronti(listaOggetti.size())) {
            return [:]
        }

        def immobiliNonAssociati = listaDatiMetrici.findAll {
            listaOggetti.find { ogg ->
                return ogg.idImmobile == it.immobile && ogg.tipoTributo == 'TARSU'
            } == null
        }.collectEntries { [(it.immobile): true] }

        return immobiliNonAssociati
    }

    void creaAssociazioneOggettiConCatasto(def listaOggetti, def oggettiDaCatasto, def cbTributi, def cbTipiPratica) {

        if (!abilitaConfronti(listaOggetti.size())) {
            return
        }

        // Costruzione degli oggetti catastali associati
        def oggettiAssociati = []
        listaOggetti.findAll {
            cbTributi[it.tipoTributo] && cbTipiPratica[it.tipoPratica]
        }.findAll { it.idImmobile != null }.each {
            it.righeCatasto = oggettiDaCatasto
                    .findAll { c -> c.IDIMMOBILE == it.idImmobile && c.TIPOOGGETTO == (it.tipoOggetto == 3 ? 'F' : 'T') }
                    .collect { it.RIGA }
                    .sort { it }
            it.righeCatasto = [null] + it.righeCatasto

            if (!("${it.idImmobile}-${it.tipoTributo}" in oggettiAssociati)) {
                // Primo oggetto associato allo stesso idImmobile, si setta il primo in catasto
                oggettiAssociati.add("${it.idImmobile}-${it.tipoTributo}")
                it.rigaCatastoSelezionata = it.righeCatasto[1]
            }
        }
    }

    void creaAssociazioneOggettiConDatiMetrici(def listaOggetti, def listaDatiMetrici, def cbTributi, def cbTipiPratica, def datiMetriciAssociati) {

        if (!abilitaConfronti(listaOggetti.size())) {
            return
        }

        datiMetriciAssociati.clear()

        listaOggetti.findAll {
            cbTributi[it.tipoTributo] && cbTipiPratica[it.tipoPratica]
        }.findAll { it.idImmobile != null }.each {
            def dame = listaDatiMetrici.find { dm -> dm.immobile == it.idImmobile }
            if (dame) {
                datiMetriciAssociati << [(it.idImmobile): dame.RIGA]
            }
        }
    }

    @NotTransactional
    def oggettoCatastoSelezionato(def oggettoSelezionato, def oggettiDaCatasto) {

        def immobileCatastoSelezionato = null

        if (oggettoSelezionato?.idImmobile) {
            if (oggettoSelezionato.rigaCatastoSelezionata) {
                immobileCatastoSelezionato = oggettiDaCatasto.find {
                    it.IDIMMOBILE == oggettoSelezionato.idImmobile && it.RIGA == oggettoSelezionato.rigaCatastoSelezionata
                }
            } else {
                immobileCatastoSelezionato = oggettiDaCatasto.find {
                    it.IDIMMOBILE == oggettoSelezionato.idImmobile
                }
            }
        }

        return immobileCatastoSelezionato
    }

    @NotTransactional
    def datiMetriciSelezionato(def oggettoSelezionato, def listaDatiMetrici) {

        def datiMetriciSelezionato = null

        if (oggettoSelezionato?.idImmobile) {
            datiMetriciSelezionato = listaDatiMetrici.find {
                it.immobile == oggettoSelezionato.idImmobile
            }
        }

        return datiMetriciSelezionato
    }

    def abilitaConfronti(def numOggetti) {

        def soglia = getParametroDisabilitaAlgoritmi()
        def abilita = !(numOggetti > soglia)

        return abilita
    }

    private getParametroDisabilitaAlgoritmi() {

        def valore = OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'SC_OGG_VER' }?.valore

        return valore?.isNumber() ? valore as Integer : Integer.MAX_VALUE
    }
}
