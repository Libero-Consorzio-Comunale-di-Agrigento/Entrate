package it.finmatica.tr4.imposte

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.Compensazione
import it.finmatica.tr4.MotivoCompensazione
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.jobs.Tr4AfcElaborazioneService
import org.hibernate.SessionFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.text.DecimalFormat

@Transactional
class CompensazioniService {


    SessionFactory sessionFactory
    CommonService commonService
    Tr4AfcElaborazioneService tr4AfcElaborazioneService
    def dataSource

    def getListaCompensazioni(def filtri, def paging) {

        def parametri = [
                "p_anno_da": filtri.annoDa ?: 1900,
                "p_anno_a" : filtri.annoA ?: 9999,
                "p_mode_da": filtri.motivoDa.motivoCompensazione ?: 1,
                "p_mode_a" : filtri.motivoA.motivoCompensazione ?: 999,
                "p_detr_da": filtri.compensazioneDa ?: 0,
                "p_detr_a" : filtri.compensazioneA ?: Long.MAX_VALUE,
                "p_titr"   : filtri.tipoTributo]

        //Filtraggio sul codice fiscale per la situazione contribuente
        def condizioneCodFiscale = ""
        def condizionePartizioni = ""

        //Se codFiscale è valorizzato significa che la funzionalità è aperta da situazione del contribuente
        if (filtri.codFiscale) {

            parametri << ["p_cod_fiscale": filtri.codFiscale]
            condizioneCodFiscale = " and contribuenti.cod_fiscale like :p_cod_fiscale "

        } else {//Funzionalità aperta da Bonifiche e Versamenti

            //Imposto i totali sulla partizione per il raggruppamento nella lista
            condizionePartizioni = """
                                   sum(compensazioni.compensazione) over(Partition by compensazioni.anno, compensazioni.motivo_compensazione) AS totale_compensazioni,
                                   count(distinct compensazioni.cod_fiscale) over(Partition by compensazioni.anno, compensazioni.motivo_compensazione) AS totale_contribuenti,
                                   """
        }

        def query = """
                            select ${condizionePartizioni}
                                   compensazioni.id_compensazione,
                                   compensazioni.cod_fiscale,
                                   compensazioni.tipo_tributo,
                                   compensazioni.anno,
                                   compensazioni.motivo_compensazione,
                                   compensazioni.motivo_compensazione || ' - ' ||
                                   motivi_compensazione.descrizione des_motivo_compensazione,
                                   compensazioni.compensazione,
                                   compensazioni.flag_automatico,
                                   compensazioni.utente,
                                   compensazioni.data_variazione,
                                   compensazioni.note,
                                   f_descrizione_titr(compensazioni.tipo_tributo, compensazioni.anno) des_titr,
                                   translate(soggetti.cognome_nome, '/', ' ') nominativo,
                                   soggetti.ni,
                                   vers.flag_vers,
                                   SOGGETTI.DATA_NAS,
                                   AD4_COMUNI.DENOMINAZIONE || ' ' ||
                                   decode(AD4_PROVINCIE.SIGLA,
                                          NULL,
                                          '',
                                          '(' || AD4_PROVINCIE.SIGLA || ')') com_nas
                            from compensazioni,
                                   motivi_compensazione,
                                   contribuenti,
                                   soggetti,
                                   ad4_comuni,
                                   ad4_provincie,
                                   (select id_compensazione,
                                           max(decode(id_compensazione, null, to_char(null), 'S')) flag_vers
                                      from versamenti
                                     where id_compensazione is not null
                                     group by id_compensazione) vers
                            where compensazioni.motivo_compensazione =
                                   motivi_compensazione.motivo_compensazione(+)
                               and contribuenti.ni = soggetti.ni
                               and compensazioni.cod_fiscale = contribuenti.cod_fiscale
                               and ((compensazioni.anno between :p_anno_da and :p_anno_a) and
                                   (compensazioni.motivo_compensazione between :p_mode_da and
                                   :p_mode_a) and (compensazioni.compensazione between
                                   :p_detr_da / 100 and :p_detr_a / 100))
                               and compensazioni.tipo_tributo = :p_titr
                               and compensazioni.id_compensazione = vers.id_compensazione(+)
                               and (ad4_comuni.provincia_stato = ad4_provincie.provincia(+))
                               and (soggetti.cod_com_nas = ad4_comuni.comune(+))
                               and (soggetti.cod_pro_nas = ad4_comuni.provincia_stato(+))
                               ${condizioneCodFiscale}
                            order by compensazioni.anno,
                                      compensazioni.motivo_compensazione,
                                      soggetti.cognome_nome,
                                      compensazioni.cod_fiscale
                           """


        def totalCount =
                sessionFactory.currentSession.createSQLQuery("select count(*) from (${query})").with {
                    parametri.each { k, v ->
                        setParameter(k, v)
                    }
                    list()
                }[0]

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setFirstResult(paging.activePage * paging.pageSize)
            setMaxResults(paging.pageSize)

            list()
        }

        result.each {

            it.groupHeader = ""

            if (it.anno != null) {
                it.groupHeader = "Anno: ${it.anno}"
            }
            if (it.desMotivoCompensazione != null) {
                it.groupHeader += " Motivo: ${it.desMotivoCompensazione}"
            }
            if (it.totaleCompensazioni != null) {
                it.groupHeader += " Totale: ${commonService.formattaValuta(it.totaleCompensazioni)}"
            }
            if (it.totaleContribuenti != null) {
                it.groupHeader += " Contribuenti: ${it.totaleContribuenti}"
            }
            if (it.totaleElenco != null) {
                if (it.groupHeader.toString().empty) {
                    it.groupHeader += "Totale "
                } else {
                    it.groupHeader += " totale "
                }
                it.groupHeader += " ${new DecimalFormat("€ #,##0.00").format(it.totaleElenco)}"
            }

        }

        return [totalCount: totalCount, records: result]
    }

    def getCompensazione(def idCompensazione) {

        def parametri = [
                'p_id_compensazione': idCompensazione
        ]

        def query = """
                           SELECT ID_COMPENSAZIONE,
                           COD_FISCALE,
                           TIPO_TRIBUTO,
                           ANNO,
                           MOTIVO_COMPENSAZIONE,
                           COMPENSAZIONE,
                           UTENTE,
                           DATA_VARIAZIONE,
                           F_VERSATO_COMPENSAZIONE(id_compensazione,
                                                   cod_fiscale,
                                                   anno,
                                                   tipo_tributo) versamento,
                           f_descrizione_titr(TIPO_TRIBUTO, to_number(to_char(sysdate, 'yyyy'))) des_titr,
                           NOTE
                           FROM COMPENSAZIONI
                           WHERE ID_COMPENSAZIONE = :p_id_compensazione
                           """


        def queryResult = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        def result = queryResult[0]

        def compensazione = [:]
        compensazione.id = result.idCompensazione
        compensazione.compensazione = result.compensazione
        compensazione.lastUpdated = result.dataVariazione
        compensazione.codFiscale = result.codFiscale
        compensazione.note = result.note
        compensazione.utente = result.utente
        compensazione.tipoTributo = result.tipoTributo
        compensazione.anno = result.anno
        compensazione.motivoCompensazione = MotivoCompensazione.get(result.motivoCompensazione)
        compensazione.desTitr = result.desTitr

        if (result.versamento) {
            //Controlla se la stringa contiene delle cifre numeriche
            if (result.versamento.matches(".*\\d.*")) {
                result.versamento = "€ ${result.versamento.trim()}"
                result.versPresente = true
            } else {
                result.versamento = result.versamento.trim()
                result.versPresente = false
            }
        }

        compensazione.versamento = result.versamento
        compensazione.versPresente = result.versPresente

        return compensazione
    }

    def getTipiTributo() {
        return TipoTributo.list().toDTO()
    }

    def getMotivi() {

        def query = """
                           select *
                           from motivi_compensazione
                           order by 1
                           """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            list()
        }

        return result
    }

    def getAnniCalcoloCompensazioni() {

        def query = """
                    select to_number(to_char(sysdate, 'yyyy')) - 2 anno
                      from dual
                    union
                    select to_number(to_char(sysdate, 'yyyy')) - 1
                      from dual
                    union
                    select to_number(to_char(sysdate, 'yyyy'))
                      from dual
                    union
                    select to_number(to_char(sysdate, 'yyyy')) + 1
                      from dual
                    union
                    select to_number(to_char(sysdate, 'yyyy')) + 2
                      from dual
                     where to_number(to_char(sysdate, 'mm')) > 6
                     order by 1 desc
                    """

        return sessionFactory.currentSession.createSQLQuery(query).list()
    }

    def getTipiImpostaCalcoloCompensazioni() {

        def query = """
                            select 1 as codice, '1 - Imposta Calcolata' as descrizione
                              from dual
                            union
                            select 2, '2 - Imposta Arrotondata per Contribuente'
                              from dual
                            union
                            select 3, '3 - Imposta Arrotondata per Utenza'
                              from dual
                             order by 1
                          """

        return sessionFactory.currentSession.createSQLQuery(query).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            list()
        }
    }

    def calcoloCompensazioni(def dati) {

        def idCompensazione = null

        def statement = '{call CREA_COMPENSAZIONI(?,?,?,?,?,?,?,?)}'
        def params = [dati.tipoTributo,
                      dati.anno,
                      dati.codFiscale,
                      dati.limiteDiff,
                      dati.motivoCompensazione,
                      dati.user,
                      dati.tipoImposta,
                      Sql.NUMERIC]
        if (dati.codiceElaborazione?.trim()) {
            tr4AfcElaborazioneService.saveDatabaseCall(dati.codiceElaborazione, statement, params)
        }
        new Sql(dataSource).call(statement, params, { res -> idCompensazione = res })

        return idCompensazione
    }

    def generaVersamenti(def dati) {

        def numVersamenti = 0

        Sql sql = new Sql(dataSource)
        def statement = '{call CREA_VERSAMENTI_COMP(?,?,?,?,?,?,?)}'
        def params = [dati.tipoTributo,
                      dati.anno,
                      dati.codFiscale,
                      dati.fonte,
                      dati.motivo,
                      dati.user,
                      Sql.NUMERIC]
        if (dati.codiceElaborazione?.trim()) {
            tr4AfcElaborazioneService.saveDatabaseCall(dati.codiceElaborazione, statement, params)
        }
        sql.call(statement, params) {
            numVersamenti = it
        }

        return numVersamenti
    }

    def getAnniGeneraVersamento(def tipoTributo, def tipoPratica) {

        def parametri = [:]

        parametri << ['p_tipo_tributo': tipoTributo]
        parametri << ['p_tipo_pratica': tipoPratica]

        def query = """
                            select distinct anno
                            from pratiche_tributo
                            where tipo_tributo = :p_tipo_tributo
                            and tipo_pratica = :p_tipo_pratica
                            order by 1 DESC
                          """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }

            list()
        }
    }

    def getFontiGeneraVersamento() {

        def query = """
                            select fonte codice, fonte || ' - ' || descrizione descrizione
                            from fonti
                            order by 1
                          """

        return sessionFactory.currentSession.createSQLQuery(query).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            list()
        }
    }

    def controlloParametriSalvataggio(def dati) {

        def parametri1 = [
                'p_anno'        : dati.anno,
                'p_cod_fiscale' : dati.codFiscale,
                'p_tipo_tributo': dati.tipoTributo]

        def query1 = """
                            select count(*)
                            from versamenti
                            where anno in (:p_anno, :p_anno - 1)
                            and cod_fiscale = :p_cod_fiscale
                            and oggetto_imposta is not null
                            and tipo_tributo = :p_tipo_tributo
                            """

        def result1 = sessionFactory.currentSession.createSQLQuery(query1).with {
            parametri1.each { k, v ->
                setParameter(k, v)
            }
            list()
        }

        if (result1[0] != 0) {
            return "Esistono versamenti su oggetti per questo contribuente e gli anni interessati, compensazione non possibile"
        }

        def query2 = """
                            select count(*)
                            from versamenti
                            where anno = :p_anno - 1
                            and cod_fiscale = :p_cod_fiscale
                            and tipo_tributo = :p_tipo_tributo
                            """

        def result2 = sessionFactory.currentSession.createSQLQuery(query2).with {
            parametri1.each { k, v ->
                setParameter(k, v)
            }
            list()
        }

        if (result2[0] == 0) {
            return "Non esistono versamenti per questo contribuente nell'anno precedente la compensazione, compensazione non possibile"
        }

        return ""
    }

    def controlloParametriModifica(def dati) {

        def messaggio = ""
        def parametri = [
                'p_anno'        : dati.anno,
                'p_cod_fiscale' : dati.codFiscale,
                'p_tipo_tributo': dati.tipoTributo]

        def query = """
                            select count(*)
                            from versamenti
                            where anno in (:p_anno, :p_anno - 1)
                            and cod_fiscale = :p_cod_fiscale
                            and oggetto_imposta is not null
                            and tipo_tributo = :p_tipo_tributo
                            """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {
            parametri.each { k, v ->
                setParameter(k, v)
            }
            list()
        }

        if (result[0] != 0) {
            messaggio = "Esistono versamenti su oggetti per questo contribuente e gli anni interessati, compensazione non possibile"
        }


        return messaggio
    }

    def salvaCompensazione(Compensazione compensazione) {
        compensazione.save(failOnError: true, flush: true)
    }

    def eliminaCompensazione(def compensazione) {

        def messaggio = checkCompensazioneEliminabile(compensazione.id)

        // Eliminazione possibile
        if (messaggio.empty) {
            Compensazione.get(compensazione.id).delete(failOnError: true, flush: true)
        }

        return messaggio
    }

    def checkCompensazioneEliminabile(def idCompensazione) {

        def params = []

        params << idCompensazione

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call COMPENSAZIONI_PD(?)}', params)
            return ''
        } catch (Exception e) {
            return e.message.substring('ORA-20006: '.length(), e.message.indexOf('\n'))
        }
    }

    def getCountCompensazioni(def filtri) {

        def parametri = [
                "p_anno_da": filtri.annoDa ?: 1900,
                "p_anno_a" : filtri.annoA ?: 9999,
                "p_mode_da": filtri.motivoDa?.motivoCompensazione ?: 1,
                "p_mode_a" : filtri.motivoA?.motivoCompensazione ?: 999,
                "p_detr_da": filtri.compensazioneDa ?: 0,
                "p_detr_a" : filtri.compensazioneA ?: Long.MAX_VALUE,
                "p_titr"   : filtri.tipoTributo]

        def condizioneCodFiscale = ""

        if (filtri.codFiscale) {
            parametri << ["p_cod_fiscale": filtri.codFiscale]
            condizioneCodFiscale = " and contribuenti.cod_fiscale like :p_cod_fiscale "
        }

        def query = """
                select compensazioni.id_compensazione,
                       compensazioni.cod_fiscale,
                       compensazioni.tipo_tributo,
                       compensazioni.anno,
                       compensazioni.motivo_compensazione,
                       compensazioni.motivo_compensazione || ' - ' ||
                       motivi_compensazione.descrizione des_motivo_compensazione,
                       compensazioni.compensazione,
                       compensazioni.flag_automatico,
                       compensazioni.utente,
                       compensazioni.data_variazione,
                       compensazioni.note,
                       f_descrizione_titr(compensazioni.tipo_tributo, compensazioni.anno) des_titr,
                       translate(soggetti.cognome_nome, '/', ' ') nominativo,
                       soggetti.ni,
                       vers.flag_vers,
                       SOGGETTI.DATA_NAS,
                       AD4_COMUNI.DENOMINAZIONE || ' ' ||
                       decode(AD4_PROVINCIE.SIGLA,
                              NULL,
                              '',
                              '(' || AD4_PROVINCIE.SIGLA || ')') com_nas
                from compensazioni,
                       motivi_compensazione,
                       contribuenti,
                       soggetti,
                       ad4_comuni,
                       ad4_provincie,
                       (select id_compensazione,
                               max(decode(id_compensazione, null, to_char(null), 'S')) flag_vers
                          from versamenti
                         where id_compensazione is not null
                         group by id_compensazione) vers
                where compensazioni.motivo_compensazione =
                       motivi_compensazione.motivo_compensazione(+)
                   and contribuenti.ni = soggetti.ni
                   and compensazioni.cod_fiscale = contribuenti.cod_fiscale
                   and ((compensazioni.anno between :p_anno_da and :p_anno_a) and
                       (compensazioni.motivo_compensazione between :p_mode_da and
                       :p_mode_a) and (compensazioni.compensazione between
                       :p_detr_da / 100 and :p_detr_a / 100))
                   and compensazioni.tipo_tributo = :p_titr
                   and compensazioni.id_compensazione = vers.id_compensazione(+)
                   and (ad4_comuni.provincia_stato = ad4_provincie.provincia(+))
                   and (soggetti.cod_com_nas = ad4_comuni.comune(+))
                   and (soggetti.cod_pro_nas = ad4_comuni.provincia_stato(+))
                   ${condizioneCodFiscale}
                order by compensazioni.anno,
                          compensazioni.motivo_compensazione,
                          soggetti.cognome_nome,
                          compensazioni.cod_fiscale
                           """


        def totalCount =
                sessionFactory.currentSession.createSQLQuery("select count(*) from (${query})").with {
                    parametri.each { k, v ->
                        setParameter(k, v)
                    }
                    list()
                }[0]

        return totalCount
    }
}
