package it.finmatica.tr4.sanzioni

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.GruppiSanzione
import it.finmatica.tr4.Sanzione
import it.finmatica.tr4.commons.CommonService
import org.hibernate.FetchMode

@Transactional
class SanzioniService {

    def dataSource
    def sessionFactory
    CommonService commonService

    def getListaSanzioni(def filtri) {

        def tipoCausaleDescrizione = [
                E   : "Imposta/Tassa Evasa",
                I   : "Interessi",
                O   : "Omesso Versamento",
                P   : "Parziale versamento",
                S   : "Spese di Notifica",
                T   : "Tardivo Versamento",
                TP30: "Tardivo Versamento (entro 30 GG)"
        ]

        def tipoRata = [
                0: 'Unica',
                1: 'Prima',
                2: 'Seconda',
                3: 'Terza',
                4: 'Quarta'
        ]

        def tipoVersamento = [
                A: 'Acconto',
                S: 'Saldo',
        ]

        return Sanzione.createCriteria().list {
            fetchMode("tipoTributo", FetchMode.JOIN)
            fetchMode('gruppoSanzione', FetchMode.JOIN)

            ge('codSanzione', 100 as Short)

            eq('tipoTributo.tipoTributo', filtri.tipoTributo)

            if (filtri.daCodice) {
                ge('codSanzione', filtri.daCodice as Short)
            }
            if (filtri.aCodice) {
                le('codSanzione', filtri.aCodice as Short)
            }
            if (filtri.descrizione) {
                ilike('descrizione', filtri.descrizione)
            }
            if (filtri.daPercentuale) {
                ge('percentuale', filtri.daPercentuale)
            }
            if (filtri.aPercentuale) {
                le('percentuale', filtri.aPercentuale)
            }
            if (filtri.daSanzione) {
                ge('sanzione', filtri.daSanzione)
            }
            if (filtri.aSanzione) {
                le('sanzione', filtri.aSanzione)
            }
            if (filtri.daSanzioneMinima) {
                ge('sanzione', filtri.daSanzioneMinima)
            }
            if (filtri.aSanzioneMinima) {
                le('sanzioneMinima', filtri.aSanzioneMinima)
            }
            if (filtri.daRiduzione) {
                ge('riduzione', filtri.daRiduzione)
            }
            if (filtri.aRiduzione) {
                le('riduzione', filtri.aRiduzione)
            }
            if (filtri.daRiduzione2) {
                ge('riduzione2', filtri.daRiduzione2)
            }
            if (filtri.aRiduzione2) {
                le('riduzione2', filtri.aRiduzione2)
            }
            if (filtri.flagImposta != null) {
                if (filtri.flagImposta) {
                    eq('flagImposta', 'S')
                } else {
                    isNull('flagImposta')
                }
            }
            if (filtri.flagInteressi != null) {
                if (filtri.flagInteressi) {
                    eq('flagInteressi', 'S')
                } else {
                    isNull('flagInteressi')
                }
            }
            if (filtri.flagPenaPecuniaria != null) {
                if (filtri.flagPenaPecuniaria) {
                    eq('flagPenaPecuniaria', 'S')
                } else {
                    isNull('flagPenaPecuniaria')
                }
            }
            if (filtri.flagCalcoloInteressi != null) {
                if (filtri.flagCalcoloInteressi) {
                    eq('flagCalcoloInteressi', 'S')
                } else {
                    isNull('flagCalcoloInteressi')
                }
            }
            if (filtri.codiceTributo) {
                eq('tributo', filtri.codiceTributo as Short)
            }
            if (filtri.codTributoF24) {
                ilike('codTributoF24', filtri.codTributoF24)
            }
            if (filtri.gruppoSanzione) {
                eq('gruppoSanzione.gruppoSanzione', filtri.gruppoSanzione)
            }
            if (filtri.anno) {
                and {
                    le('dataInizio', new GregorianCalendar(filtri.anno, 11, 31).time)
                    ge('dataFine', new GregorianCalendar(filtri.anno, 0, 1).time)
                }
            }

            if (filtri.daDataInizio) {
                ge('dataInizio', filtri.daDataInizio)
            }
            if (filtri.aDataInizio) {
                le('dataInizio', filtri.aDataInizio)
            }
            if (filtri.daDataFine) {
                ge('dataFine', filtri.daDataFine)
            }
            if (filtri.aDataFine) {
                le('dataFine', filtri.aDataFine)
            }

            order('codSanzione', 'asc')
            order('sequenza', 'desc')
        }.toDTO().collect { sanzioneDTO ->
            [
                    dto                 : sanzioneDTO,
                    tipoTributo         : sanzioneDTO.tipoTributo,
                    codSanzione         : sanzioneDTO.codSanzione,
                    sequenza            : sanzioneDTO.sequenza,
                    dataInizio          : sanzioneDTO.dataInizio,
                    dataFine            : sanzioneDTO.dataFine == Date.parse('dd/MM/yyyy', '31/12/9999') ? null : sanzioneDTO.dataFine,
                    descrizione         : sanzioneDTO.descrizione,
                    percentuale         : sanzioneDTO.percentuale,
                    sanzione            : sanzioneDTO.sanzione,
                    sanzioneMinima      : sanzioneDTO.sanzioneMinima,
                    riduzione           : sanzioneDTO.riduzione,
                    flagImposta         : sanzioneDTO.flagImposta,
                    flagInteressi       : sanzioneDTO.flagInteressi,
                    flagPenaPecuniaria  : sanzioneDTO.flagPenaPecuniaria,
                    gruppoSanzione      : sanzioneDTO.gruppoSanzione,
                    tributo             : sanzioneDTO.tributo,
                    flagCalcoloInteressi: sanzioneDTO.flagCalcoloInteressi,
                    riduzione2          : sanzioneDTO.riduzione2,
                    codTributoF24       : sanzioneDTO.codTributoF24,
                    flagMaggTares       : sanzioneDTO.flagMaggTares,
                    rata                : tipoRata[sanzioneDTO.rata as Integer],
                    tipologiaRuolo      : sanzioneDTO.tipologiaRuolo,
                    tipoCausale         : tipoCausaleDescrizione[sanzioneDTO.tipoCausale],
                    tipoVersamento      : tipoVersamento[sanzioneDTO.tipoVersamento],
                    utente              : sanzioneDTO.utente,
                    dataVariazione      : sanzioneDTO.dataVariazione?.format('dd/MM/yyyy')
            ]
        }
    }

    def salvaSanzione(def sanzione) {
        sanzione.save(failOnError: true, flush: true)
    }

    def existsSanzione(def sanzione) {
        Sanzione.countByTipoTributoAndCodSanzioneAndSequenza(sanzione.tipoTributo.toDomain(), sanzione.codSanzione, sanzione.sequenza) > 0
    }

    def creaSanzione(def sanzione) {
        if (sanzione.codSanzione < 1000) {
            throw new IllegalArgumentException('Impossibile salvare sanzione con codice ' + sanzione.codSanzione)
        }
        if (Sanzione.findByTipoTributoAndCodSanzioneAndSequenza(sanzione.tipoTributo, sanzione.codSanzione, sanzione.sequenza)) {
            throw new IllegalArgumentException('Esiste già una sanzione con codice ' + sanzione.codSanzione + ' per ' + sanzione.tipoTributo.tipoTributoAttuale)
        }
        sanzione.sequenza = getNextSequenza(sanzione.tipoTributo.tipoTributo, sanzione.codSanzione)
        sanzione.save(failOnError: true, flush: true)
    }

    def eliminaSanzione(def sanzione) {
        if (sanzione.codSanzione < 1000) {
            throw new IllegalArgumentException('Impossibile eliminare sanzione con codice ' + sanzione.codSanzione)
        }
        sanzione.delete(failOnError: true, flush: true)
    }

    def getListaGruppiSanzione(def filter = [:]) {
        GruppiSanzione.createCriteria().list {
            if (filter.daGruppoSanzione) {
                ge('gruppoSanzione', filter.daGruppoSanzione as Short)
            }
            if (filter.aGruppoSanzione) {
                le('gruppoSanzione', filter.aGruppoSanzione as Short)
            }
            if (filter.descrizione) {
                ilike('descrizione', filter.descrizione)
            }
            if (filter.flagStampaTotale != null) {
                if (filter.flagStampaTotale) {
                    eq('stampaTotale', 'S')
                } else {
                    isNull('stampaTotale')
                }
            }
        }.toDTO()
    }

    def existsGruppoSanzione(def gruppoSanzione) {
        GruppiSanzione.createCriteria().count {
            eq('gruppoSanzione', gruppoSanzione.gruppoSanzione)
        } > 0
    }

    def salvaGruppoSanzione(def gruppoSanzione) {
        gruppoSanzione.save(failOnError: true, flush: true)
    }

    def eliminaGruppoSanzione(def gruppoSanzione) {
        gruppoSanzione.delete(failOnError: true, flush: true)
    }

    def getSanzioniSpeseNotificaRicalcolabili(def tipoTributo) {
        Sanzione.createCriteria().list {
            eq('tipoCausale', 'S')
            ge('codSanzione', 100 as Short)
            isNotNull('sanzione')
            gt('sanzione', 0 as BigDecimal)
            eq('tipoTributo.tipoTributo', tipoTributo.tipoTributo)
            order('codSanzione')
            order('sequenza', 'desc')
        }.toDTO()
    }

    def presenzaDiSovrapposizioni(def sanzione) {
        return Sanzione.createCriteria().count {

            eq('codSanzione', sanzione.codSanzione)
            ne('sequenza', sanzione.sequenza)

            eq('tipoTributo.tipoTributo', sanzione.tipoTributo.tipoTributo)

            ge('dataFine', sanzione.dataInizio)
            le('dataInizio', sanzione.dataFine)
        } > 0
    }

    def getNextSequenza(def tipoTributo, def codSanzione) {

        Short newSequenza = 1

        Sql sql = new Sql(dataSource)
        sql.call('{call SANZIONI_NR(?, ?, ?)}',
                [
                        tipoTributo,
                        codSanzione,
                        Sql.NUMERIC
                ],
                { newSequenza = it }
        )

        return newSequenza
    }

    @Transactional
    def archiviaEDuplica(def tipoTributo, def dataChiusura) {

        def sanzioni = Sanzione.createCriteria().list {
            ge('codSanzione', 100 as Short)
            eq('tipoTributo.tipoTributo', tipoTributo)
            eq('dataFine', Date.parse('dd/MM/yyyy', '31/12/9999'))
            lt('dataInizio', dataChiusura)
        }

        sanzioni.each { sanzione ->
            sanzione.dataFine = dataChiusura
            sanzione.save(failOnError: true, flush: true)
        }

        sanzioni.each {
            def nuovaSanzione = commonService.clona(it)
            nuovaSanzione.sequenza = getNextSequenza(tipoTributo, it.codSanzione)
            nuovaSanzione.dataInizio = dataChiusura + 1
            nuovaSanzione.dataFine = Date.parse('dd/MM/yyyy', '31/12/9999')
            nuovaSanzione.save(failOnError: true, flush: true)
        }

    }

    @Transactional
    def ripristinaPeriodoPrecedente(def tipoTributo) {

        def update = """
                    update sanzioni sanz
                        set 
                         sanz.data_fine = to_date('31129999', 'DDMMYYYY')
                    where sanz.cod_sanzione = :codSanzione
                      and sanz.sequenza = :sequenza
                      and sanz.tipo_tributo = :tipoTributo
                    """

        def sanzioni = Sanzione.createCriteria().list {
            ge('codSanzione', 100 as Short)
            ne('sequenza', 1 as Short)
            eq('tipoTributo.tipoTributo', tipoTributo)
            eq('dataFine', Date.parse('dd/MM/yyyy', '31/12/9999'))
        }

        if (sanzioni.empty) {
            throw new Application20999Error("Non è possibile ripristinare il periodo precedente per il tributo ${tipoTributo}")
        }

        sanzioni.each {

            it.delete(failsOnError: true)
            def sanzionePrecedente = Sanzione.findByTipoTributoAndSequenzaAndCodSanzione(it.tipoTributo, (it.sequenza - 1) as Short, it.codSanzione)
            sanzionePrecedente.dataFine = Date.parse('dd/MM/yyyy', '31/12/9999')
            sanzionePrecedente.save(failOnError: true, flush: true)

        }
    }
}
