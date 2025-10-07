package it.finmatica.tr4.bonificaDati.docfa

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.WrkDocfaOggetti
import it.finmatica.tr4.WrkDocfaSoggetti
import it.finmatica.tr4.WrkDocfaTestata
import it.finmatica.tr4.datiesterni.DocumentoCaricato
import org.hibernate.criterion.CriteriaSpecification

@Transactional
class BonificaDocfaService {

    def dataSource
    def springSecurityService

    def getAnomalie(def sortBy = null, def filtro = [:]) {

        def lista = WrkDocfaTestata.createCriteria().list() {

            createAlias("causale", "causale",
                    CriteriaSpecification.INNER_JOIN)

            if (filtro.documento && (filtro.documento as HashMap).documentoId) {
                eq("documentoId", ((filtro.documento as HashMap).documentoId as BigDecimal).intValue())
            }


            if (!sortBy || sortBy.property == 'dichiarante') {
                order("cognomeDic", sortBy ? sortBy.direction : 'asc')
                order("nomeDic", sortBy ? sortBy.direction : 'asc')
            } else {
                order(sortBy.property, sortBy.direction)
            }
        }

        return lista.toDTO(['causale'])
    }

    def getDocumentoMulti(def wrkDocfa) {
        def docCaricato = DocumentoCaricato.findById(wrkDocfa.documentoId)
        def docMulti = docCaricato.documentiCaricatiMulti.find { it.id == wrkDocfa.documentoMultiId }

        return docMulti
    }

    def getOggetti(def wrkDocfa, def params = [:], def sortBy = null) {

        params.max = params?.max ?: 10
        params.offset = params.activePage * params.max

        def lista = WrkDocfaOggetti.createCriteria().list(params) {
            eq('documentoId', wrkDocfa.documentoId)
            eq('documentoMultiId', wrkDocfa.documentoMultiId)

            order('progrOggetto', 'asc')
        }

        return [
                record      : lista.collect { it },
                numeroRecord: lista.totalCount
        ]
    }

    def getSoggetti(def wrkDocfaOggetto, def params = [:], def sortBy = null) {

        params.max = params?.max ?: 10
        params.offset = params.activePage * params.max

        def lista = WrkDocfaSoggetti.createCriteria().list(params) {
            eq('documentoId', wrkDocfaOggetto.documentoId)
            eq('documentoMultiId', wrkDocfaOggetto.documentoMultiId)
            eq('progrOggetto', wrkDocfaOggetto.progrOggetto)

            order('progrSoggetto', 'asc')
        }

        return [
                record      : lista.collect { it },
                numeroRecord: lista.totalCount
        ]
    }

    def caricaSoggettiDocfa(def wrkDocfa) {

        def messaggi = ""

        Sql sql = new Sql(dataSource)
        sql.call('{call CARICA_SOGGETTI_DOCFA(?, ?, ?)}'
                , [
                wrkDocfa.documentoId,
                wrkDocfa.documentoMultiId,
                Sql.VARCHAR

        ], { res ->
            if (res && !res.isEmpty()) {
                messaggi = res.substring(1, res.length())
            }
        })

        return messaggi
    }

    def convalidaDocfa(def wrkDocfa) {
        try {
            def messaggi = ""

            Sql sql = new Sql(dataSource)
            sql.call('{call CONVALIDA_DOCFA(?, ?, ?, ?)}'
                    , [
                    wrkDocfa.documentoId,
                    wrkDocfa.documentoMultiId,
                    springSecurityService.currentUser.id,
                    Sql.VARCHAR

            ], { res ->
                if (res && !res.isEmpty()) {
                    messaggi = res.substring(1, res.length())
                }
            })

            return messaggi
        } catch (Exception e) {

            return e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
        }
    }
}
