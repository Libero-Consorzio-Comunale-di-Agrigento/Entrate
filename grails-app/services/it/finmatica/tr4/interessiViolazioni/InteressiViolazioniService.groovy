package it.finmatica.tr4.interessiViolazioni

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.DateInteressiViolazioni
import it.finmatica.tr4.dto.DateInteressiViolazioniDTO
import org.hibernate.SessionFactory
import org.hibernate.transform.AliasToEntityMapResultTransformer

import java.text.SimpleDateFormat
import java.sql.Date

@Transactional
class InteressiViolazioniService {

    SessionFactory sessionFactory
    def dataSource

    def getPraticaRivalutata(Long praticaId) {

        def filtri = [:]

        filtri << ['praticaId' : praticaId ]

        def sql = """
            select
                count(ogpr.oggetto_pratica) as  RIVALUTATI
              from
                pratiche_tributo prtr,
                oggetti_pratica ogpr
             where
                prtr.pratica = :praticaId and 
                prtr.tipo_tributo = 'ICI' and 
                ogpr.pratica = prtr.pratica and 
                ogpr.flag_valore_rivalutato = 'S'
        """

        def result = eseguiQuery(sql, filtri, null, true)

        if(result[0].RIVALUTATI > 0) {
            return true
        }

        return false
    }

    def getDatePerAnni(String tipoTributo, def impostazioni) {

        def lista = []

        Calendar now = GregorianCalendar.getInstance()
        def annoNow = now.get(Calendar.YEAR)

        Short anniMax = impostazioni.anniMax ?: 10
        Short annoDa = (impostazioni.annoDa ?: annoNow) as Short
        Short annoA = (impostazioni.annoA ?: annoDa) as Short
        if(annoA < annoDa) annoA = annoDa
        if((annoA - annoDa) > anniMax) annoA = annoDa + anniMax

        java.sql.Date dataEmissione

        if(impostazioni.dataEmissione) {
            dataEmissione = new java.sql.Date(impostazioni.dataEmissione.getTime())
        }
        else {
            dataEmissione = new java.sql.Date(now.getTimeInMillis())
        }

        for(Short anno = annoDa; anno <= annoA; anno++) {

            def dateList = DateInteressiViolazioni.createCriteria().list {
                eq('tipoTributo.tipoTributo', tipoTributo)
                eq('anno', anno)

                le('dataAttoDa', dataEmissione)
                or {
                    isNull('dataAttoA')
                    ge('dataAttoA', dataEmissione)
                }
            }
            def date = (dateList.size() > 0) ? dateList[0] : null

            def annualita = [
                anno : anno,
                dataInizio : date?.dataInizio,
                dataFine : date?.dataFine,
            ];

            lista << annualita
        }

        return lista
    }

    def getListaDate(def filtri) {

        List<DateInteressiViolazioniDTO> lista = DateInteressiViolazioni.createCriteria().list {
            if(filtri.annoDa) {
                ge('anno', filtri.annoDa as Short)
            }
            if(filtri.annoA) {
                le('anno', filtri.annoA as Short)
            }

            if(filtri.dataAttoDaDal) {
            	ge('dataAttoDa', filtri.dataAttoDaDal)
            }
            if(filtri.dataAttoDaAl) {
                le('dataAttoDa', filtri.dataAttoDaAl)
            }
            if(filtri.dataAttoADal) {
                ge('dataAttoA', filtri.dataAttoADal)
            }
            if(filtri.dataAttoAAl) {
                le('dataAttoA', filtri.dataAttoAAl)
            }

            if(filtri.dataInizioDal) {
                ge('dataInizio', filtri.dataInizioDal)
            }
            if(filtri.dataInizioAl) {
            	le('dataInizio', filtri.dataInizioAl)
            }
            if(filtri.dataFineDal) {
                ge('dataFine', filtri.dataFineDal)
            }
            if(filtri.dataFineAl) {
            	ge('dataFine', filtri.dataFineAl)
            }
            order('anno', 'desc')
            order('dataAttoDa', 'asc')

        } ?.toDTO(['TipoTributo'])

        return lista
    }

    def existsOverlappingDate(DateInteressiViolazioniDTO date) {

        def filtri = [:]

        filtri << ['anno' : date.anno ]
        filtri << ['dataAttoDa' : date.dataAttoDa ]
        filtri << ['dataAttoA' : (date.dataAttoA) ? date.dataAttoA : new java.sql.Date(253402210800000) ]

        String sql = """
            select
                 count(*) as overlaps
             from
                 date_interessi_violazioni daiv
            where
                 daiv.anno = :anno
             and daiv.data_atto_da <> :dataAttoDa
             and ((daiv.data_atto_da <= :dataAttoA and
                   nvl(daiv.data_atto_a,to_date('31/12/9999','dd/mm/YYYY')) >= :dataAttoDa)
             )
        """

        def result = eseguiQuery(sql, filtri, null, true)

        if(result[0].OVERLAPS > 0) {
            return true
        }

        return false
    }

    def salvaDate(DateInteressiViolazioni date) {
        date.save(failOnError: true, flush: true)
    }

    def eliminaDate(DateInteressiViolazioni date) {
        date.delete(failOnError: true, flush: true)
    }

    def validaDate(DateInteressiViolazioniDTO date) {

        def errors = []

        if (!date.anno) {
            errors << 'Anno obbligatorio'
        }

        if (!date.dataAttoDa) {
            errors << 'Data Atto Da obbligatoria'
        }

        if (date.dataAttoA) {
            if (date.dataAttoDa) {
                if (date.dataAttoA < date.dataAttoDa) {
                    errors << 'Data Atto A non valida'
                }
            }
            else {
                errors << 'Data Atto A non valida'
            }
        }

        if (!date.dataInizio) {
            errors << 'Data Inizio obbligatoria'
        }
        if (date.dataFine) {
            if (date.dataInizio) {
                if (date.dataInizio > date.dataFine) {
                    errors << 'Data Fine non valida'
                }
            }
        }
        else {
            errors << 'Data Fine obbligatoria'
        }

        return errors
    }

    def preparaDateInteressi(def listaDate, def impostazioni) {

        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd")

        String dateInizio = ''
        String dateFine = ''
        String date

        listaDate.each { it ->
            date = sdf.format(it.dataInizio)
            dateInizio += date
            date = sdf.format(it.dataFine)
            dateFine += date
        }

        impostazioni.dateInizio = dateInizio
        impostazioni.dateFine = dateFine
    
        return impostazioni
    }

    private eseguiQuery(def query, def filtri, def paging, def wholeList = false) {

        filtri = filtri ?: [:]

        if (!query || query.isEmpty()) {
            throw new RuntimeException("Query non specificata.")
        }

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(query)
        sqlQuery.with {

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            filtri.each { k, v ->
                setParameter(k, v)
            }

            if (!wholeList) {
                setFirstResult(paging.offset)
                setMaxResults(paging.max)
            }
            list()
        }
    }
}
