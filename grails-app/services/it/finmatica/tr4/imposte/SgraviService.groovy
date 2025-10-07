package it.finmatica.tr4.imposte

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.MotivoSgravio
import it.finmatica.tr4.Ruolo
import it.finmatica.tr4.RuoloContribuente
import it.finmatica.tr4.Sgravio
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.pratiche.OggettoPratica
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.hibernate.transform.AliasToEntityMapResultTransformer
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.text.DecimalFormat
import java.text.SimpleDateFormat

@Transactional
class SgraviService {

    def springSecurityService
    def dataSource
    def sessionFactory
    CommonService commonService

    //report
    JasperService jasperService
    def servletContext
    def ad4EnteService


    def calcolaSgravio(def parametri) {

        def importo
        def nota

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call CALCOLO_SGRAVIO(?, ?, ?, ?, ?, ?, ?, ?, ?)}',
                    [
                            parametri.codFiscale?.toUpperCase(),
                            parametri.ruolo,
                            parametri.sequenza,
                            parametri.motivo.id,
                            parametri.oggPratica,
                            parametri.calcoloNormalizzato,
                            Sql.NUMERIC,
                            Sql.VARCHAR,
                            parametri.tipo,
                    ],
                    {
                        def res1, def res2 ->
                            importo = res1
                            nota = res2
                    }
            )
        } catch (Exception e) {
            commonService.serviceException(e)
        }

        return [importo: importo, nota: nota]
    }


    def getRuoloContribuente(def ruolo, def codFiscale, def sequenza) {
        return RuoloContribuente.createCriteria().get {
            eq('ruolo.id', ruolo as Long)
            eq('contribuente.codFiscale', codFiscale)
            eq('sequenza', sequenza as Short)
        }
    }

    def getRuoliContribuente(def ruolo, def codFiscale) {
        return RuoloContribuente.createCriteria().list {
            eq('ruolo.id', ruolo as Long)
            eq('contribuente.codFiscale', codFiscale)
        }
    }

    def aggiornaDatiSgraviSuRuolo(def datiSgraviSuRuolo) {

        def ruoloContribuente = getRuoloContribuente(datiSgraviSuRuolo.ruolo, datiSgraviSuRuolo.codFiscale, datiSgraviSuRuolo.sequenza)

        // Aggiorno num e data cartella del contribuente
        ruoloContribuente.numeroCartella = datiSgraviSuRuolo.numeroCartella
        ruoloContribuente.dataCartella = datiSgraviSuRuolo.dataCartella

        // Aggiorno numRuolo e codConcessione di ogni sgravio relativo
        for (Sgravio sgravio : ruoloContribuente.sgravi) {
            sgravio.codConcessione = datiSgraviSuRuolo.codConcessione
            sgravio.numRuolo = datiSgraviSuRuolo.numRuolo
            sgravio.save(failOnError: true)
        }

        ruoloContribuente.save(failOnError: true)
    }

    def aggiornaDatiSgraviSuRuoloCoattivo(def datiSgraviSuRuolo) {

        def ruoliContribuente = getRuoliContribuente(datiSgraviSuRuolo.ruolo, datiSgraviSuRuolo.codFiscale)

        ruoliContribuente.each { rc ->
            rc.numeroCartella = datiSgraviSuRuolo.numeroCartella
            rc.dataCartella = datiSgraviSuRuolo.dataCartella

            rc.sgravi.each { sg ->
                sg.codConcessione = datiSgraviSuRuolo.codConcessione
                sg.numRuolo = datiSgraviSuRuolo.numRuolo
                sg.save(failOnError: true)

            }
            rc.save(failOnError: true)
        }

    }

    def eliminaSgravio(def sgravioMap) {

        def messaggio = ""
        Sgravio sgravio = Sgravio.createCriteria().get {

            eq("sequenzaSgravio", sgravioMap.sequenzaSgravio as Short)
            eq("ruoloContribuente.ruolo.id", sgravioMap.ruolo as Long)
            eq("ruoloContribuente.contribuente.codFiscale", sgravioMap.codFiscale)
            eq("ruoloContribuente.sequenza", sgravioMap.sequenza as Short)
        }

        // Verifico se è possibile effettuare l'eliminazione
        messaggio = checkEliminaSgravio(sgravio)

        // Eliminazione possibile
        if (messaggio.length() == 0) {
            sgravio.delete(failOnError: true)
        }

        return messaggio
    }

    def checkEliminaSgravio(def sgravio) {

        def params = [sgravio.ruoloContribuente.ruolo.id,
                      sgravio.ruoloContribuente.contribuente.codFiscale,
                      sgravio.sequenzaSgravio,
                      sgravio.ruoloContribuente.sequenza]

        try {
            Sql sql = new Sql(dataSource)
            sql.call("{call SGRAVI_PD(?,?,?,?)}", params)
            return ''
        } catch (Exception e) {
            return e.message.substring('ORA-20006: '.length(), e.message.indexOf('\n'))
        }
    }

    def getSgravio(def ruolo, def codFiscale, def sequenza, def sequenzaSgravio) {
        return Sgravio.createCriteria().get {

            eq("sequenzaSgravio", sequenzaSgravio as Short)
            eq("ruoloContribuente.ruolo.id", ruolo as Long)
            eq("ruoloContribuente.contribuente.codFiscale", codFiscale)
            eq("ruoloContribuente.sequenza", sequenza as Short)
        }
    }

    def salvaSgravioSuRuolo(def sgravio, def parametriRuolo = null) {

        def sgravioDB = getSgravio(sgravio.ruolo, sgravio.codFiscale,
                sgravio.sequenza, sgravio.sequenzaSgravio)

        //Nel caso di aggiunta sgravioDB sarà == null in quanto non esiste l'entità sul db, quindi verrà creato un oggetto Sgravio e popolato
        //Nel caso di modifica sgravioDB sarà != null in quanto l'entità è già presente nel db, quindi verranno aggiornati i campi modificabili di sgravioDB
        //Nel caso di clonazione come per modifica ma con sequenzaSgravio diversa
        if (sgravioDB != null) {//Esiste già lo sgravio, siamo nel caso di modifica o clonazione

            sgravioDB.semestri = sgravio.semestri
            sgravioDB.motivoSgravio = sgravio.motivoSgravio
            sgravioDB.tipoSgravio = sgravio.tipoSgravio
            sgravioDB.importo = sgravio.importo
            sgravioDB.maggiorazioneTares = sgravio.maggiorazioneTares
            sgravioDB.note = sgravio.note
            sgravioDB.sequenzaSgravio = sgravio.sequenzaSgravio
            sgravioDB.addizionalePro = sgravio.addizionalePro

            if (parametriRuolo != null) {
                sgravioDB.oggettoPratica = OggettoPratica.get(parametriRuolo.oggettoPratica)
            }

        } else {//Caso aggiunta nuovo sgravio

            sgravioDB = new Sgravio()

            //Dati sgravio
            sgravioDB.motivoSgravio = new MotivoSgravio()
            sgravioDB.motivoSgravio = sgravio.motivoSgravio
            sgravioDB.semestri = sgravio.semestri
            sgravioDB.tipoSgravio = sgravio.tipoSgravio
            sgravioDB.importo = sgravio.importo
            sgravioDB.maggiorazioneTares = sgravio.maggiorazioneTares
            sgravioDB.note = sgravio.note
            sgravioDB.sequenzaSgravio = sgravio.sequenzaSgravio
            sgravioDB.addizionalePro = sgravio.addizionalePro

            RuoloContribuente ruoloContribuente = getRuoloContribuente(parametriRuolo.ruolo, parametriRuolo.codFiscale, parametriRuolo.sequenza)

            //Dati contribuente
            sgravioDB.ruoloContribuente = ruoloContribuente
            sgravioDB.codConcessione = parametriRuolo.codConcessione
            sgravioDB.numRuolo = parametriRuolo.numRuolo
            sgravioDB.oggettoPratica = OggettoPratica.get(parametriRuolo.oggettoPratica)

            sgravioDB.sequenzaSgravio = getNextSequenzaSgravio(ruoloContribuente.ruolo.id,
                    ruoloContribuente.contribuente.codFiscale, ruoloContribuente.sequenza)

        }

        sgravioDB.save(flush: true, failOnError: true)
    }

    def getNextSequenzaSgravio(def numRuolo, def codFiscale, def sequenza) {

        Short progressivo = 1

        Sql sql = new Sql(dataSource)
        sql.call('{call SGRAVI_NR(?, ?, ?, ?)}',
                [
                        numRuolo, codFiscale, sequenza,
                        Sql.NUMERIC
                ],
                { progressivo = it }
        )

        return progressivo
    }

    def synchronized getNextProgrSgravio(def filter) {
        def parametri = [:]
        parametri << ['ruolo': filter.ruolo as Long]
        parametri << ['codFiscale': filter.codFiscale as String]
        parametri << ['pratica': filter.pratica as Long]

        def query = """
            select nvl(max(sgra.progr_sgravio),0) as max_progr_sgravio
              from ruoli_contribuente ruco,
                   sgravi sgra
             where ruco.ruolo = sgra.ruolo(+)
               and ruco.sequenza = sgra.sequenza(+)
               and ruco.cod_fiscale = sgra.cod_fiscale(+)
               and ruco.ruolo = :ruolo
               and ruco.pratica = :pratica
               and ruco.cod_fiscale = :codFiscale
        """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()[0]
        }

        return result.maxProgrSgravio + 1
    }

    def updateRuoloContribuente(def ruoloContribuenteRaw) {
        RuoloContribuente ruoloContribuente = getRuoloContribuente(
                ruoloContribuenteRaw.ruolo,
                ruoloContribuenteRaw.codFiscale,
                ruoloContribuenteRaw.sequenza)
        ruoloContribuente.importo = ruoloContribuenteRaw.importo as BigDecimal
        ruoloContribuente.save(failOnError: true, flush: true).refresh()
    }

    def updateSgravio(def sgravioRaw) {
        Sgravio sgravio = getSgravio(sgravioRaw.ruolo,
                sgravioRaw.codFiscale,
                sgravioRaw.sequenza,
                sgravioRaw.sequenzaSgravio)
        sgravio.motivoSgravio = sgravioRaw.motivoSgravio as MotivoSgravio
        sgravio.tipoSgravio = sgravioRaw.tipoSgravio
        sgravio.importo = sgravioRaw.importoSgravio as BigDecimal
        sgravio.note = sgravioRaw.note as String
        sgravio.save(failOnError: true, flush: true)
    }

    def createSgravio(def sgravioRaw) {
        Sgravio sgravio = new Sgravio()
        sgravio.ruoloContribuente = getRuoloContribuente(sgravioRaw.ruolo, sgravioRaw.codFiscale, sgravioRaw.sequenza)
        sgravio.sequenzaSgravio = getNextSequenzaSgravio(
                sgravioRaw.ruolo,
                sgravioRaw.codFiscale,
                sgravioRaw.sequenza)
        sgravio.progrSgravio = sgravioRaw.progrSgravio
        sgravio.motivoSgravio = sgravioRaw.motivoSgravio as MotivoSgravio
        sgravio.tipoSgravio = sgravioRaw.tipoSgravio
        sgravio.importo = sgravioRaw.importoSgravio as BigDecimal
        sgravio.note = sgravioRaw.note as String
        sgravio.save(failOnError: true, flush: true)
    }

    def deleteSgravio(def sgravioRaw) {
        Sgravio sgravio = getSgravio(sgravioRaw.ruolo, sgravioRaw.codFiscale, sgravioRaw.sequenza, sgravioRaw.sequenzaSgravio)
        sgravio.delete(failOnError: true, flush: true)
    }

    def getSgravioRecords(def filter) {
        def parametri = [:]

        parametri << ['pratica': filter.pratica as Long]
        parametri << ['codFiscale': filter.codFiscale as String]
        parametri << ['ruolo': filter.ruolo as Long]
        parametri << ['progrSgravio': filter.progrSgravio as Long]
        def query = """
            select ruco.ruolo,
                   ruco.cod_fiscale,
                   ruco.sequenza,
                   ruco.tributo,
                   ruco.importo,
                   sgra.sequenza_sgravio,
                   sgra.progr_sgravio,
                   sgra.importo importo_sgravio,
                   nvl((select sum(sgra1.importo)
                         from ruoli_contribuente ruco1, sgravi sgra1
                        where ruco1.ruolo = sgra1.ruolo
                          and ruco1.sequenza = sgra1.sequenza(+)
                          and ruco1.cod_fiscale = sgra1.cod_fiscale
                          and ruco1.tributo = ruco.tributo
                          and ruco1.ruolo = ruco.ruolo
                          and ruco1.cod_fiscale = ruco.cod_fiscale
                          and ruco1.pratica = ruco.pratica
                          and sgra1.progr_sgravio != nvl(:progrSgravio, -1)),
                       0) importo_sgravato
              from ruoli_contribuente ruco, sgravi sgra
             where ruco.ruolo = sgra.ruolo(+)
               and ruco.sequenza = sgra.sequenza(+)
               and ruco.cod_fiscale = sgra.cod_fiscale(+)
               and ruco.ruolo = :ruolo
               and ruco.cod_fiscale = :codFiscale
               and ruco.pratica = :pratica
               and sgra.progr_sgravio(+) = :progrSgravio
        """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        result = result.collect {
            [*  : it,
             key: "${it.ruolo}${it.codFiscale}${it.sequenza}${it.tributo}${it.sequenzaSgravio}" as String]
        }

        return result
    }

    def getSgraviSuRuoloCoattivo(def filter) {
        def parametri = [:]
        parametri << ['codFiscale': filter.codFiscale as String]
        parametri << ['ruolo': filter.ruolo as Long]
        parametri << ['pratica': filter.pratica as Long]
        def query = """
            select ruco.pratica,
                   ruco.ruolo,
                   ruco.cod_fiscale,
                   sgra.progr_sgravio,
                   sgra.motivo_sgravio,
                   sgra.numero_elenco,
                   sgra.data_elenco,
                   sgra.tipo_sgravio,
                   sgra.note,
                   mosg.descrizione motivo_sgravio_descrizione,
                   sum(sgra.importo) importo
              from ruoli_contribuente ruco, sgravi sgra, motivi_sgravio mosg
             where sgra.ruolo = ruco.ruolo
               and sgra.cod_fiscale = ruco.cod_fiscale
               and sgra.sequenza = ruco.sequenza
               and sgra.motivo_sgravio = mosg.motivo_sgravio(+)
               and sgra.ruolo = :ruolo
               and sgra.cod_fiscale = :codFiscale
               and ruco.pratica = :pratica
             group by ruco.pratica,
                      ruco.ruolo,
                      ruco.cod_fiscale,
                      sgra.progr_sgravio,
                      sgra.motivo_sgravio,
                      sgra.numero_elenco,
                      sgra.data_elenco,
                      sgra.tipo_sgravio,
                      sgra.note,
                      mosg.descrizione
             order by sgra.progr_sgravio
        """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return result
    }

    def getSgraviSuRuolo(def sgravio) {

        def parametri = [:]

        parametri << ['p_ruolo': sgravio.ruolo as Long]
        parametri << ['p_CF': sgravio.codFiscale]
        parametri << ['p_seq': sgravio.sequenza as Short]

        def query = """
                            select sgravi.ruolo,
                             sgravi.cod_fiscale,
                             sgravi.sequenza,
                             sgravi.sequenza_sgravio,
                             sgravi.motivo_sgravio,
                             sgravi.numero_elenco,
                             sgravi.data_elenco,
                             sgravi.importo,
                             sgravi.importo - nvl(sgravi.addizionale_eca, 0) -
                             nvl(sgravi.maggiorazione_eca, 0) - nvl(sgravi.addizionale_pro, 0) -
                             nvl(sgravi.iva, 0) - nvl(sgravi.maggiorazione_tares, 0) netto_sgravi,
                             sgravi.semestri,
                             sgravi.addizionale_eca,
                             sgravi.maggiorazione_eca,
                             sgravi.addizionale_pro,
                             sgravi.iva,
                             ruoli.importo_lordo,
                             sgravi_oggetto.imposta,
                             sgravi.cod_concessione,
                             sgravi.num_ruolo,
                             sgravi.mesi_sgravio,
                             sgravi.flag_automatico,
                             sgravi.giorni_sgravio,
                             sgravi.tipo_sgravio,
                             sgravi.maggiorazione_tares,
                             sgravi.ogpr_sgravio,
                             sgravi.note,
                             sgravi.utente,
                             motivi_sgravio.descrizione AS MOTIVO_SGRAVIO_DESCRIZIONE,
                             'N' modifica_add_prov,
                             to_number(decode(nvl(ruoli.tipo_calcolo, 'T'), 'T', 1, 2)) tipo_stampa
                        from SGRAVI_OGGETTO, SGRAVI, RUOLI, MOTIVI_SGRAVIO
                       where sgravi.ruolo = sgravi_oggetto.ruolo
                         and sgravi.cod_fiscale = sgravi_oggetto.cod_fiscale
                         and sgravi.sequenza = sgravi_oggetto.sequenza
                         and sgravi.sequenza_sgravio = sgravi_oggetto.sequenza_sgravio
                         and sgravi.ruolo = ruoli.ruolo
                         AND sgravi_oggetto.ruolo = :p_ruolo
                         AND sgravi_oggetto.cod_fiscale = :p_CF
                         AND sgravi_oggetto.sequenza = :p_seq
                         AND sgravi.motivo_sgravio = motivi_sgravio.motivo_sgravio (+)
                       order by sgravi.sequenza_sgravio
                           """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return result
    }

    def getRuoloCoattivo(def parametri) {

        def query = """
            SELECT max(RUOL.TIPO_RUOLO) as TIPO_RUOLO,
               max(RUOL.TIPO_TRIBUTO) as TIPO_TRIBUTO,
               max(RUOL.ANNO_RUOLO) as ANNO_RUOLO,
               max(RUOL.ANNO_EMISSIONE) as ANNO_EMISSIONE,
               max(RUOL.PROGR_EMISSIONE) as PROGR_EMISSIONE,
               max(RUOL.DATA_EMISSIONE) as DATA_EMISSIONE,
               max(RUOL.RUOLO) as ruolo,
               max(RUOL.INVIO_CONSORZIO) as INVIO_CONSORZIO,
               max(RUOL.SPECIE_RUOLO) as SPECIE_RUOLO,
               max(ruco.DATA_CARTELLA) as DATA_CARTELLA,
               max(ruco.NUMERO_CARTELLA) as NUMERO_CARTELLA,
               max(ruco.cod_fiscale) as cod_fiscale,
               max(ruco.sequenza) as sequenza,
               sum(ruco.importo) as importo,
               max(sgra.num_ruolo) num_ruolo,
               max(sgra.cod_concessione) cod_concessione
          FROM RUOLI ruol,
               RUOLI_CONTRIBUENTE ruco,
               (select max(sgr1.num_ruolo) num_ruolo,
                       max(sgr1.cod_concessione) as cod_concessione
                  from ruoli_contribuente ruc1, sgravi sgr1
                 where ruc1.ruolo = sgr1.ruolo(+)
                   and ruc1.sequenza = sgr1.sequenza(+)
                   and ruc1.cod_fiscale = sgr1.cod_fiscale(+)
                   and ruc1.ruolo = :ruolo
                   and ruc1.cod_fiscale = :codFiscale
                   and ruc1.pratica = :pratica) sgra
         WHERE ruol.ruolo = :ruolo
           and ruol.ruolo = ruco.ruolo
           AND ruco.COD_FISCALE = :codFiscale
           and exists (select 1
                  from pratiche_tributo prtr, sanzioni_pratica sapr
                 where prtr.pratica = sapr.pratica
                   and sapr.ruolo = :ruolo
                   and prtr.cod_fiscale = :codFiscale
                   and sapr.pratica = :pratica)
        """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return result[0]
    }

    def getRuolo(def ruolo, def codFiscale, def sequenza) {

        def parametri = [:]

        parametri << ['p_ruolo': ruolo]
        parametri << ['p_CF': codFiscale]
        parametri << ['p_seq': sequenza]

        def query = """
                    SELECT RUOLI.TIPO_RUOLO,
                       RUOLI.TIPO_TRIBUTO,
                       RUOLI.ANNO_RUOLO,
                       RUOLI.ANNO_EMISSIONE,
                       RUOLI.PROGR_EMISSIONE,
                       RUOLI.DATA_EMISSIONE,
                       RUOLI_OGGETTO.TRIBUTO,
                       RUOLI.INVIO_CONSORZIO,
                       RUOLI.SPECIE_RUOLO,
                       RUOLI_OGGETTO.IMPORTO,
                       CODICI_TRIBUTO.TRIBUTO || ' - ' || CODICI_TRIBUTO.DESCRIZIONE descr_tributo,
                       CATEGORIE.CATEGORIA || ' - ' || CATEGORIE.DESCRIZIONE descr_categoria,
                       RUOLI_OGGETTO.OGGETTO_PRATICA,
                       RUOLI_CONTRIBUENTE.DATA_CARTELLA,
                       RUOLI_CONTRIBUENTE.RUOLO,
                       RUOLI_CONTRIBUENTE.COD_FISCALE,
                       RUOLI_CONTRIBUENTE.SEQUENZA,
                       RUOLI_CONTRIBUENTE.NUMERO_CARTELLA,
                       RUOLI_CONTRIBUENTE.OGGETTO_IMPOSTA,
                       RUOLI.IMPORTO_LORDO,
                       RUOLI.TIPO_CALCOLO,
                       SGRA.COD_CONCESSIONE,
                       SGRA.NUM_RUOLO,
                       RUOLI.TIPO_EMISSIONE,
                       RUOLI.importo_Lordo,
                       RUOLI_OGGETTO.IMPOSTA,
                       RUOLI_OGGETTO.MAGGIORAZIONE_TARES,
                       OGCO.FLAG_PUNTO_RACCOLTA
                  FROM RUOLI,
                       RUOLI_OGGETTO,
                       CODICI_TRIBUTO,
                       CATEGORIE,
                       RUOLI_CONTRIBUENTE,
                       (select SGRAVI.RUOLO,
                               SGRAVI.COD_FISCALE,
                               SGRAVI.SEQUENZA,
                               max(SGRAVI.COD_CONCESSIONE) cod_concessione,
                               max(SGRAVI.NUM_RUOLO) num_ruolo
                          from SGRAVI
                         where SGRAVI.RUOLO = :p_ruolo
                           and SGRAVI.COD_FISCALE = :p_CF
                           and SGRAVI.SEQUENZA = :p_seq
                         group by SGRAVI.RUOLO, SGRAVI.COD_FISCALE, SGRAVI.SEQUENZA) SGRA,
                        OGGETTI_PRATICA OGPR,
                        OGGETTI_CONTRIBUENTE OGCO
                 WHERE (ruoli_oggetto.tributo = categorie.tributo(+))
                   and (ruoli_oggetto.categoria = categorie.categoria(+))
                   and (RUOLI.RUOLO = RUOLI_OGGETTO.RUOLO)
                   and (RUOLI_OGGETTO.TRIBUTO = CODICI_TRIBUTO.TRIBUTO)
                   and (RUOLI_CONTRIBUENTE.RUOLO = RUOLI_OGGETTO.RUOLO)
                   and (RUOLI_CONTRIBUENTE.COD_FISCALE = RUOLI_OGGETTO.COD_FISCALE)
                   and (RUOLI_CONTRIBUENTE.SEQUENZA = RUOLI_OGGETTO.SEQUENZA)
                   and ruoli_oggetto.oggetto_pratica = OGPR.oggetto_pratica(+)
                   and ruoli_oggetto.oggetto_pratica = ogco.oggetto_pratica(+)
                   and ruoli_oggetto.COD_FISCALE = ogco.cod_fiscale(+)
                   and (SGRA.RUOLO(+) = RUOLI_CONTRIBUENTE.RUOLO)
                   and (SGRA.COD_FISCALE(+) = RUOLI_CONTRIBUENTE.COD_FISCALE)
                   and (SGRA.SEQUENZA(+) = RUOLI_CONTRIBUENTE.SEQUENZA)
                   and ((RUOLI_OGGETTO.RUOLO = :p_ruolo) AND
                       (RUOLI_OGGETTO.COD_FISCALE = :p_CF) AND
                       (RUOLI_OGGETTO.SEQUENZA = :p_seq))
                    """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return result[0]
    }

    def generaDettaglioSgravio(def dataElenco, def motivoSgravio, def numeroElenco, def ruolo, def ordinamento) {

        def datiSgravi = []
        def sgravi = [:]
        sgravi.testata = [
                "ordinamento": ordinamento == SgraviOrdinamento.ALFABETICO ? "Alfabetico" : (ordinamento == SgraviOrdinamento.CODFISCALE ? "Codice Fiscale" : "Numero")]
        def listaDati = dettaglioSgravio(dataElenco, motivoSgravio, numeroElenco, ruolo, ordinamento)


        sgravi.dati = listaDati

        datiSgravi << sgravi

        JasperReportDef reportDef = new JasperReportDef(name: 'dettaglioSgravi.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiSgravi
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])

        return sgravi.dati == null ? null : jasperService.generateReport(reportDef)
    }

    def generaDettaglioElenco(def elenco, def numero, def data) {

        //elenco stringa nel formato ' numero - data', serve per il il titolo nella testata del report

        def datiSgravi = []
        def sgravi = [:]
        sgravi.testata = [
                "elenco": elenco]

        sgravi.dati = dettaglioElenco(numero, data)

        datiSgravi << sgravi

        JasperReportDef reportDef = new JasperReportDef(name: 'dettaglioElencoSgravi.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: datiSgravi
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])

        return sgravi.dati == null ? null : jasperService.generateReport(reportDef)
    }

    def numeraElencoProcedure(def numero, def data) {

        def params = []
        params << numero
        params << new java.sql.Date(data.getTime())

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call NUMERA_ELENCO_SGRAVI(?,?)}', params)
            return ''
        } catch (Exception e) {
            return e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
        }
    }

    def annullaElencoProcedure(def numero, def data) {

        def params = []
        params << numero
        params << new java.sql.Date(data.getTime())

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call ANNULLA_ELENCO_SGRAVI(?,?)}', params)
            return ''
        } catch (Exception e) {
            return e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
        }
    }

    def dettaglioSgravio(def dataElenco, def motivoSgravio, def numeroElenco, def ruolo, def ordinamento = SgraviOrdinamento.ALFABETICO) {

        def filtri = [:]
        def orderBy = ""
        def parametri = ""

        filtri << ['p_motivoSgravio': motivoSgravio]
        filtri << ['p_ruolo': ruolo]

        if (dataElenco != null) {
            filtri << ['p_dataElenco': dataElenco]
            parametri += " AND nvl(SGRAVI.DATA_ELENCO, to_date('01011900', 'ddmmyyyy')) = nvl(:p_dataElenco, to_date('01011900', 'ddmmyyyy')) "
        }
        if (numeroElenco != null) {
            filtri << ['p_numeroElenco': numeroElenco]
            parametri += " AND NVL(SGRAVI.NUMERO_ELENCO, -1) = nvl(:p_numeroElenco, 1) "
        }


        switch (ordinamento) {
            case SgraviOrdinamento.ALFABETICO:
                orderBy = " ORDER BY COGNOME, NOME, COD_FISCALE, NUMERO_ELENCO "
                break
            case SgraviOrdinamento.CODFISCALE:
                orderBy = " ORDER BY COD_FISCALE, COGNOME, NOME, NUMERO_ELENCO "
                break
            case SgraviOrdinamento.NUMERO:
                orderBy = " ORDER BY NUMERO_ELENCO, COGNOME, NOME, COD_FISCALE "
                break
        }

        String query = """
                    SELECT translate(soggetti.COGNOME_NOME, '/', ' ') cog_nom,
                           SOGGETTI.COGNOME cognome,
                           SOGGETTI.NOME nome,
                           RUOLI.ANNO_RUOLO,
                           RUOLI.TIPO_RUOLO,
                           RUOLI.ANNO_EMISSIONE,
                           CONTRIBUENTI.COD_FISCALE,
                           decode(CONTRIBUENTI.COD_CONTROLLO,
                                  NULL,
                                  to_char(CONTRIBUENTI.COD_CONTRIBUENTE),
                                  CONTRIBUENTI.COD_CONTRIBUENTE || '-' ||
                                  CONTRIBUENTI.COD_CONTROLLO) cod_cont,
                           RUCO.TRIBUTO,
                           OGIM.IMPOSTA + nvl(OGIM.ADDIZIONALE_ECA, 0) +
                           nvl(OGIM.MAGGIORAZIONE_ECA, 0) + nvl(OGIM.ADDIZIONALE_PRO, 0) +
                           nvl(OGIM.IVA, 0) ruco_importo,
                           decode(RUOLI.IMPORTO_LORDO,
                                  'S',
                                  SGRAVI.IMPORTO - nvl(SGRAVI.ADDIZIONALE_ECA, 0) -
                                  nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) -
                                  nvl(SGRAVI.ADDIZIONALE_PRO, 0) - nvl(SGRAVI.IVA, 0) -
                                  nvl(SGRAVI.MAGGIORAZIONE_TARES, 0),
                                  SGRAVI.IMPORTO) sgra_importo,
                           OGIM.IMPOSTA +
                           decode(RUOLI.IMPORTO_LORDO,
                                  'S',
                                  (nvl(OGIM.ADDIZIONALE_ECA, 0) + nvl(OGIM.MAGGIORAZIONE_ECA, 0) +
                                  nvl(OGIM.ADDIZIONALE_PRO, 0) + nvl(OGIM.IVA, 0) +
                                  nvl(SGRAVI.MAGGIORAZIONE_TARES, 0)),
                                  (F_CATA(CATA.anno, RUCO.tributo, OGIM.imposta, 'A') +
                                  F_CATA(CATA.anno, RUCO.tributo, OGIM.imposta, 'M') +
                                  F_CATA(CATA.anno, RUCO.tributo, OGIM.imposta, 'P') +
                                  F_CATA(CATA.anno, RUCO.tributo, OGIM.imposta, 'I'))) lordo_a_ruolo,
                           SGRAVI.IMPORTO +
                           decode(RUOLI.IMPORTO_LORDO,
                                  'S',
                                  0,
                                  F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'T')) imposta_lorda,
                           SGRAVI.IMPORTO -
                           decode(RUOLI.IMPORTO_LORDO,
                                  'S',
                                  nvl(SGRAVI.ADDIZIONALE_ECA, 0) +
                                  nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) +
                                  nvl(SGRAVI.ADDIZIONALE_PRO, 0) + nvl(SGRAVI.IVA, 0) +
                                  nvl(SGRAVI.MAGGIORAZIONE_TARES, 0),
                                  0) imposta_netta,
                           SGRAVI.MOTIVO_SGRAVIO,
                           SGRAVI.NUMERO_ELENCO,
                           decode(RUOLI.IMPORTO_LORDO,
                                  'S',
                                  nvl(SGRAVI.ADDIZIONALE_ECA, 0) +
                                  nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) + nvl(SGRAVI.IVA, 0),
                                  F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'A') +
                                  F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'M') +
                                  F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'I')) addizionale_eca,
                           round(decode(RUOLI.IMPORTO_LORDO,
                                        'S',
                                        nvl(SGRAVI.ADDIZIONALE_PRO, 0) -
                                        nvl(SGRAVI.ADDIZIONALE_PRO, 0) *
                                        nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                        F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') -
                                        F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') *
                                        nvl(CATA.COMMISSIONE_COM, 0) / 100),
                                 2) addizionale_provinciale,
                           round(decode(RUOLI.IMPORTO_LORDO,
                                        'S',
                                        nvl(SGRAVI.ADDIZIONALE_PRO, 0) -
                                        nvl(SGRAVI.ADDIZIONALE_PRO, 0) *
                                        nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                        F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') -
                                        F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') *
                                        nvl(CATA.COMMISSIONE_COM, 0) / 100) *
                                 nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                 2) commissione_comunale,
                           CATA.LIMITE,
                           CATA.COMPENSO_MINIMO,
                           CATA.COMPENSO_MASSIMO,
                           CATA.PERC_COMPENSO,
                           decode(SOGGETTI.COD_VIA,
                                  NULL,
                                  SOGGETTI.DENOMINAZIONE_VIA,
                                  ARCHIVIO_VIE.DENOM_UFF) ||
                           decode(SOGGETTI.NUM_CIV, NULL, '', ', ' || SOGGETTI.NUM_CIV) ||
                           decode(SOGGETTI.SUFFISSO, NULL, '', '/' || SOGGETTI.SUFFISSO) indirizzo_sogg,
                           AD4_COMUNI.DENOMINAZIONE || ' (' || AD4_PROVINCIE.SIGLA || ')' AS DENOM_COMUNE,
                           RUCO.NUMERO_CARTELLA
                    FROM AD4_PROVINCIE,
                         AD4_COMUNI,
                         ARCHIVIO_VIE,
                         SOGGETTI,
                         CONTRIBUENTI,
                         CARICHI_TARSU      CATA,
                         SGRAVI,
                         RUOLI_CONTRIBUENTE RUCO,
                         OGGETTI_IMPOSTA    OGIM,
                         RUOLI
                    WHERE SOGGETTI.COD_PRO_RES = AD4_COMUNI.PROVINCIA_STATO(+)
                       and SOGGETTI.COD_COM_RES = AD4_COMUNI.COMUNE(+)
                       and AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA(+)
                       and (soggetti.cod_via = archivio_vie.cod_via(+))
                       and (SOGGETTI.NI = CONTRIBUENTI.NI)
                       and (RUCO.COD_FISCALE = CONTRIBUENTI.COD_FISCALE)
                       and (CATA.ANNO = RUOLI.ANNO_RUOLO)
                       AND (RUCO.RUOLO = SGRAVI.RUOLO)
                       and (RUCO.COD_FISCALE = SGRAVI.COD_FISCALE)
                       and (RUCO.SEQUENZA = SGRAVI.SEQUENZA)
                       and (RUCO.RUOLO = RUOLI.RUOLO)
                       and (OGIM.OGGETTO_IMPOSTA = RUCO.OGGETTO_IMPOSTA)
                       and (OGIM.RUOLO = RUCO.RUOLO)
                       AND NVL(SGRAVI.MOTIVO_SGRAVIO, -1) = nvl(:p_motivoSgravio, -1)
                       AND RUOLI.RUOLO = :p_ruolo
                       ${parametri}
                    UNION ALL
                    SELECT translate(soggetti.COGNOME_NOME, '/', ' ') cog_nom,
                           SOGGETTI.COGNOME cognome,
                           SOGGETTI.NOME nome,
                           RUOLI.ANNO_RUOLO,
                           RUOLI.TIPO_RUOLO,
                           RUOLI.ANNO_EMISSIONE,
                           CONTRIBUENTI.COD_FISCALE,
                           decode(CONTRIBUENTI.COD_CONTROLLO,
                                  NULL,
                                  to_char(CONTRIBUENTI.COD_CONTRIBUENTE),
                                  CONTRIBUENTI.COD_CONTRIBUENTE || '-' ||
                                  CONTRIBUENTI.COD_CONTROLLO) cod_cont,
                           RUCO.TRIBUTO,
                           RUCO.IMPORTO ruco_importo,
                           decode(RUOLI.IMPORTO_LORDO,
                                  'S',
                                  SGRAVI.IMPORTO - nvl(SGRAVI.ADDIZIONALE_ECA, 0) -
                                  nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) -
                                  nvl(SGRAVI.ADDIZIONALE_PRO, 0) - nvl(SGRAVI.IVA, 0) -
                                  nvl(SGRAVI.MAGGIORAZIONE_TARES, 0),
                                  SGRAVI.IMPORTO) sgra_importo,
                           F_IMPORTO_VIOLAZIONE(RUCO.PRATICA, 'S') lordo_a_ruolo,
                           SGRAVI.IMPORTO +
                           decode(RUOLI.IMPORTO_LORDO,
                                  'S',
                                  0,
                                  F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'T')) imposta_lorda,
                           SGRAVI.IMPORTO -
                           decode(RUOLI.IMPORTO_LORDO,
                                  'S',
                                  nvl(SGRAVI.ADDIZIONALE_ECA, 0) +
                                  nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) +
                                  nvl(SGRAVI.ADDIZIONALE_PRO, 0) + nvl(SGRAVI.IVA, 0) +
                                  nvl(SGRAVI.MAGGIORAZIONE_TARES, 0),
                                  0) imposta_netta,
                           SGRAVI.MOTIVO_SGRAVIO,
                           SGRAVI.NUMERO_ELENCO,
                           decode(RUOLI.IMPORTO_LORDO,
                                  'S',
                                  nvl(SGRAVI.ADDIZIONALE_ECA, 0) +
                                  nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) + nvl(SGRAVI.IVA, 0),
                                  F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'A') +
                                  F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'M') +
                                  F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'I')) addizionale_eca,
                           round(decode(RUOLI.IMPORTO_LORDO,
                                        'S',
                                        nvl(SGRAVI.ADDIZIONALE_PRO, 0) -
                                        nvl(SGRAVI.ADDIZIONALE_PRO, 0) *
                                        nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                        F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') -
                                        F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') *
                                        nvl(CATA.COMMISSIONE_COM, 0) / 100),
                                 2) addizionale_provinciale,
                           round(decode(RUOLI.IMPORTO_LORDO,
                                        'S',
                                        nvl(SGRAVI.ADDIZIONALE_PRO, 0) -
                                        nvl(SGRAVI.ADDIZIONALE_PRO, 0) *
                                        nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                        F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') -
                                        F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') *
                                        nvl(CATA.COMMISSIONE_COM, 0) / 100) *
                                 nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                 2) commissione_comunale,
                           CATA.LIMITE,
                           CATA.COMPENSO_MINIMO,
                           CATA.COMPENSO_MASSIMO,
                           CATA.PERC_COMPENSO,
                           decode(SOGGETTI.COD_VIA,
                                  NULL,
                                  SOGGETTI.DENOMINAZIONE_VIA,
                                  ARCHIVIO_VIE.DENOM_UFF) ||
                           decode(SOGGETTI.NUM_CIV, NULL, '', ', ' || SOGGETTI.NUM_CIV) ||
                           decode(SOGGETTI.SUFFISSO, NULL, '', '/' || SOGGETTI.SUFFISSO) indirizzo_sogg,
                           AD4_COMUNI.DENOMINAZIONE || ' (' || AD4_PROVINCIE.SIGLA || ')',
                           RUCO.NUMERO_CARTELLA
                    FROM AD4_PROVINCIE,
                           AD4_COMUNI,
                           ARCHIVIO_VIE,
                           SOGGETTI,
                           CONTRIBUENTI,
                           CARICHI_TARSU      CATA,
                           SGRAVI,
                           RUOLI_CONTRIBUENTE RUCO,
                           PRATICHE_TRIBUTO   PRTR,
                           RUOLI
                    WHERE SOGGETTI.COD_PRO_RES = AD4_COMUNI.PROVINCIA_STATO(+)
                       and SOGGETTI.COD_COM_RES = AD4_COMUNI.COMUNE(+)
                       and AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA(+)
                       and (soggetti.cod_via = archivio_vie.cod_via(+))
                       and (SOGGETTI.NI = CONTRIBUENTI.NI)
                       and (RUCO.COD_FISCALE = CONTRIBUENTI.COD_FISCALE)
                       and (CATA.ANNO = RUOLI.ANNO_RUOLO)
                       AND (RUCO.RUOLO = SGRAVI.RUOLO)
                       and (RUCO.COD_FISCALE = SGRAVI.COD_FISCALE)
                       and (RUCO.SEQUENZA = SGRAVI.SEQUENZA)
                       and (RUCO.RUOLO = RUOLI.RUOLO)
                       and (PRTR.PRATICA = RUCO.PRATICA)
                       AND NVL(SGRAVI.MOTIVO_SGRAVIO, -1) = nvl(:p_motivoSgravio, -1)
                       AND RUOLI.RUOLO = :p_ruolo
                       ${parametri}
                   ${orderBy}
                   """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            filtri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return result
    }

    def dettaglioElenco(def numeroElenco, def dataElenco) {

        def filtri = [:]

        filtri << ['p_elenco': numeroElenco]
        filtri << ['p_data_elenco': dataElenco]

        String query = """
                        SELECT translate(soggetti.COGNOME_NOME, '/', ' ') cog_nom,
                               SOGGETTI.COGNOME cognome,
                               SOGGETTI.NOME nome,
                               RUOLI.ANNO_RUOLO,
                               RUOLI.TIPO_RUOLO,
                               RUOLI.ANNO_EMISSIONE,
                               CONTRIBUENTI.COD_CONTRIBUENTE,
                               CONTRIBUENTI.COD_FISCALE,
                               decode(sign(ANNO_EMISSIONE - 1999), -1, 0, 1),
                               decode(CONTRIBUENTI.COD_CONTROLLO,
                                      NULL,
                                      to_char(CONTRIBUENTI.COD_CONTRIBUENTE),
                                      CONTRIBUENTI.COD_CONTRIBUENTE || '-' ||
                                      CONTRIBUENTI.COD_CONTROLLO) cod_cont,
                               RUCO.TRIBUTO,
                               OGIM.IMPOSTA + nvl(OGIM.ADDIZIONALE_ECA, 0) +
                               nvl(OGIM.MAGGIORAZIONE_ECA, 0) + nvl(OGIM.ADDIZIONALE_PRO, 0) +
                               nvl(OGIM.IVA, 0) ruco_importo,
                               decode(RUOLI.IMPORTO_LORDO,
                                      'S',
                                      SGRAVI.IMPORTO - nvl(SGRAVI.ADDIZIONALE_ECA, 0) -
                                      nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) -
                                      nvl(SGRAVI.ADDIZIONALE_PRO, 0) - nvl(SGRAVI.IVA, 0) -
                                      nvl(SGRAVI.MAGGIORAZIONE_TARES, 0),
                                      SGRAVI.IMPORTO) sgra_importo,
                               OGIM.IMPOSTA +
                               decode(RUOLI.IMPORTO_LORDO,
                                      'S',
                                      (nvl(OGIM.ADDIZIONALE_ECA, 0) + nvl(OGIM.MAGGIORAZIONE_ECA, 0) +
                                      nvl(OGIM.ADDIZIONALE_PRO, 0) + nvl(OGIM.IVA, 0) +
                                      nvl(SGRAVI.MAGGIORAZIONE_TARES, 0)),
                                      (F_CATA(CATA.anno, RUCO.tributo, OGIM.imposta, 'A') +
                                      F_CATA(CATA.anno, RUCO.tributo, OGIM.imposta, 'M') +
                                      F_CATA(CATA.anno, RUCO.tributo, OGIM.imposta, 'P') +
                                      F_CATA(CATA.anno, RUCO.tributo, OGIM.imposta, 'I'))) lordo_a_ruolo,
                               SGRAVI.IMPORTO +
                               decode(RUOLI.IMPORTO_LORDO,
                                      'S',
                                      0,
                                      F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'T')) imposta_lorda,
                               SGRAVI.IMPORTO -
                               decode(RUOLI.IMPORTO_LORDO,
                                      'S',
                                      nvl(SGRAVI.ADDIZIONALE_ECA, 0) +
                                      nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) +
                                      nvl(SGRAVI.ADDIZIONALE_PRO, 0) + nvl(SGRAVI.IVA, 0) +
                                      nvl(SGRAVI.MAGGIORAZIONE_TARES, 0),
                                      0) imposta_netta,
                               SGRAVI.MOTIVO_SGRAVIO,
                               decode(RUOLI.IMPORTO_LORDO,
                                      'S',
                                      nvl(SGRAVI.ADDIZIONALE_ECA, 0) +
                                      nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) + nvl(SGRAVI.IVA, 0),
                                      F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'A') +
                                      F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'M') +
                                      F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'I')) addizionale_eca,
                               round(decode(RUOLI.IMPORTO_LORDO,
                                            'S',
                                            nvl(SGRAVI.ADDIZIONALE_PRO, 0) -
                                            nvl(SGRAVI.ADDIZIONALE_PRO, 0) *
                                            nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                            F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') -
                                            F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') *
                                            nvl(CATA.COMMISSIONE_COM, 0) / 100),
                                     2) addizionale_provinciale,
                               round(decode(RUOLI.IMPORTO_LORDO,
                                            'S',
                                            nvl(SGRAVI.ADDIZIONALE_PRO, 0) -
                                            nvl(SGRAVI.ADDIZIONALE_PRO, 0) *
                                            nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                            F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') -
                                            F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') *
                                            nvl(CATA.COMMISSIONE_COM, 0) / 100) *
                                     nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                     2) commissione_comunale,
                               CATA.LIMITE,
                               CATA.COMPENSO_MINIMO,
                               CATA.COMPENSO_MASSIMO,
                               CATA.PERC_COMPENSO,
                               decode(SOGGETTI.COD_VIA,
                                      NULL,
                                      SOGGETTI.DENOMINAZIONE_VIA,
                                      ARCHIVIO_VIE.DENOM_UFF) ||
                               decode(SOGGETTI.NUM_CIV, NULL, '', ', ' || SOGGETTI.NUM_CIV) ||
                               decode(SOGGETTI.SUFFISSO, NULL, '', '/' || SOGGETTI.SUFFISSO) indirizzo_sogg,
                               AD4_COMUNI.DENOMINAZIONE || ' (' || AD4_PROVINCIE.SIGLA || ')' AS DENOM_COMUNE,
                               RUCO.NUMERO_CARTELLA
                          FROM AD4_PROVINCIE,
                               AD4_COMUNI,
                               ARCHIVIO_VIE,
                               SOGGETTI,
                               CONTRIBUENTI,
                               CARICHI_TARSU      CATA,
                               RUOLI_CONTRIBUENTE RUCO,
                               OGGETTI_IMPOSTA    OGIM,
                               RUOLI,
                               SGRAVI
                         WHERE SOGGETTI.COD_PRO_RES = AD4_COMUNI.PROVINCIA_STATO(+)
                           and SOGGETTI.COD_COM_RES = AD4_COMUNI.COMUNE(+)
                           and AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA(+)
                           and (SOGGETTI.COD_VIA = ARCHIVIO_VIE.COD_VIA(+))
                           and (SOGGETTI.NI = CONTRIBUENTI.NI)
                           and (RUCO.COD_FISCALE = CONTRIBUENTI.COD_FISCALE)
                           and (OGIM.OGGETTO_IMPOSTA = RUCO.OGGETTO_IMPOSTA)
                           and (OGIM.RUOLO = RUCO.RUOLO)
                           and (CATA.ANNO = RUOLI.ANNO_RUOLO)
                           AND (RUCO.RUOLO = RUOLI.RUOLO)
                           AND (RUCO.RUOLO = SGRAVI.RUOLO)
                           and (RUCO.COD_FISCALE = SGRAVI.COD_FISCALE)
                           and (RUCO.SEQUENZA = SGRAVI.SEQUENZA)
                           and (SGRAVI.DATA_ELENCO = NVL(:p_data_elenco, SGRAVI.DATA_ELENCO))
                           and (SGRAVI.NUMERO_ELENCO =
                               decode(:p_elenco, -1, SGRAVI.NUMERO_ELENCO, :p_elenco))
                        UNION all
                        SELECT translate(soggetti.COGNOME_NOME, '/', ' ') cog_nom,
                               SOGGETTI.COGNOME cognome,
                               SOGGETTI.NOME nome,
                               RUOLI.ANNO_RUOLO,
                               RUOLI.TIPO_RUOLO,
                               RUOLI.ANNO_EMISSIONE,
                               CONTRIBUENTI.COD_CONTRIBUENTE,
                               CONTRIBUENTI.COD_FISCALE,
                               decode(sign(ANNO_EMISSIONE - 1999), -1, 0, 1),
                               decode(CONTRIBUENTI.COD_CONTROLLO,
                                      NULL,
                                      to_char(CONTRIBUENTI.COD_CONTRIBUENTE),
                                      CONTRIBUENTI.COD_CONTRIBUENTE || '-' ||
                                      CONTRIBUENTI.COD_CONTROLLO) cod_cont,
                               RUCO.TRIBUTO,
                               RUCO.IMPORTO ruco_importo,
                               decode(RUOLI.IMPORTO_LORDO,
                                      'S',
                                      SGRAVI.IMPORTO - nvl(SGRAVI.ADDIZIONALE_ECA, 0) -
                                      nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) -
                                      nvl(SGRAVI.ADDIZIONALE_PRO, 0) - nvl(SGRAVI.IVA, 0) -
                                      nvl(SGRAVI.MAGGIORAZIONE_TARES, 0),
                                      SGRAVI.IMPORTO) sgra_importo,
                               F_IMPORTO_VIOLAZIONE(RUCO.PRATICA, 'S') lordo_a_ruolo,
                               SGRAVI.IMPORTO +
                               decode(RUOLI.IMPORTO_LORDO,
                                      'S',
                                      0,
                                      F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'T')) imposta_lorda,
                               SGRAVI.IMPORTO -
                               decode(RUOLI.IMPORTO_LORDO,
                                      'S',
                                      nvl(SGRAVI.ADDIZIONALE_ECA, 0) +
                                      nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) +
                                      nvl(SGRAVI.ADDIZIONALE_PRO, 0) + nvl(SGRAVI.IVA, 0) +
                                      nvl(SGRAVI.MAGGIORAZIONE_TARES, 0),
                                      0) imposta_netta,
                               SGRAVI.MOTIVO_SGRAVIO,
                               decode(RUOLI.IMPORTO_LORDO,
                                      'S',
                                      nvl(SGRAVI.ADDIZIONALE_ECA, 0) +
                                      nvl(SGRAVI.MAGGIORAZIONE_ECA, 0) + nvl(SGRAVI.IVA, 0),
                                      F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'A') +
                                      F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'M') +
                                      F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'I')) addizionale_eca,
                               round(decode(RUOLI.IMPORTO_LORDO,
                                            'S',
                                            nvl(SGRAVI.ADDIZIONALE_PRO, 0) -
                                            nvl(SGRAVI.ADDIZIONALE_PRO, 0) *
                                            nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                            F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') -
                                            F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') *
                                            nvl(CATA.COMMISSIONE_COM, 0) / 100),
                                     2) addizionale_provinciale,
                               round(decode(RUOLI.IMPORTO_LORDO,
                                            'S',
                                            nvl(SGRAVI.ADDIZIONALE_PRO, 0) -
                                            nvl(SGRAVI.ADDIZIONALE_PRO, 0) *
                                            nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                            F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') -
                                            F_CATA(CATA.anno, RUCO.tributo, SGRAVI.importo, 'P') *
                                            nvl(CATA.COMMISSIONE_COM, 0) / 100) *
                                     nvl(CATA.COMMISSIONE_COM, 0) / 100,
                                     2) commissione_comunale,
                               CATA.LIMITE,
                               CATA.COMPENSO_MINIMO,
                               CATA.COMPENSO_MASSIMO,
                               CATA.PERC_COMPENSO,
                               decode(SOGGETTI.COD_VIA,
                                      NULL,
                                      SOGGETTI.DENOMINAZIONE_VIA,
                                      ARCHIVIO_VIE.DENOM_UFF) ||
                               decode(SOGGETTI.NUM_CIV, NULL, '', ', ' || SOGGETTI.NUM_CIV) ||
                               decode(SOGGETTI.SUFFISSO, NULL, '', '/' || SOGGETTI.SUFFISSO) indirizzo_sogg,
                               AD4_COMUNI.DENOMINAZIONE || ' (' || AD4_PROVINCIE.SIGLA || ')',
                               RUCO.NUMERO_CARTELLA
                          FROM AD4_PROVINCIE,
                               AD4_COMUNI,
                               ARCHIVIO_VIE,
                               SOGGETTI,
                               CONTRIBUENTI,
                               CARICHI_TARSU      CATA,
                               SGRAVI,
                               RUOLI_CONTRIBUENTE RUCO,
                               PRATICHE_TRIBUTO   PRTR,
                               RUOLI
                         WHERE SOGGETTI.COD_PRO_RES = AD4_COMUNI.PROVINCIA_STATO(+)
                           and SOGGETTI.COD_COM_RES = AD4_COMUNI.COMUNE(+)
                           and AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA(+)
                           and (soggetti.cod_via = archivio_vie.cod_via(+))
                           and (SOGGETTI.NI = CONTRIBUENTI.NI)
                           and (RUCO.COD_FISCALE = CONTRIBUENTI.COD_FISCALE)
                           and (CATA.ANNO = RUOLI.ANNO_RUOLO)
                           AND (RUCO.RUOLO = SGRAVI.RUOLO)
                           and (RUCO.COD_FISCALE = SGRAVI.COD_FISCALE)
                           and (RUCO.SEQUENZA = SGRAVI.SEQUENZA)
                           and (RUCO.RUOLO = RUOLI.RUOLO)
                           and (PRTR.PRATICA = RUCO.PRATICA)
                           and (SGRAVI.DATA_ELENCO = NVL(:p_data_elenco, SGRAVI.DATA_ELENCO))
                           and (SGRAVI.NUMERO_ELENCO =
                               decode(:p_elenco, -1, SGRAVI.NUMERO_ELENCO, :p_elenco))
                         order by 9, 1, 7, 8
                       """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            filtri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return result
    }

    def getNumeroElencoFunzioni() {

        def lista = []

        String query = """
                SELECT DISTINCT numero_elenco, lPad(numero_elenco, 4)||' - '||to_char(data_elenco, 'dd/mm/yyyy') AS descrizione
                FROM sgravi
                WHERE (numero_elenco is not null)
                AND (data_elenco is not null)
                ORDER BY 1
               """

        def result = sessionFactory.currentSession.createSQLQuery(query)
                .with {
                    resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
                    list()
                }
                .sort { it.NUMERO_ELENCO }
                .each { lista << it.DESCRIZIONE }

        return lista
    }

    def getListaSgraviFiltrati(def parametriRicerca, def pageSize = Integer.MAX_VALUE, def activePage = 0) {

        def filtri = [:]

        def numeroDa = parametriRicerca?.numeroDa ?: 0
        def numeroA = parametriRicerca?.numeroA ?: 9999
        def motivo = parametriRicerca?.motivo
        def dataElencoDa = parametriRicerca?.dataElencoDa ?: new SimpleDateFormat("yyyyMMdd").parse("18000101")
        def dataElencoA = parametriRicerca?.dataElencoA ?: new SimpleDateFormat("yyyyMMdd").parse("99991231")
        def tipo = parametriRicerca?.tipo?.key == 'X' ? null : parametriRicerca?.tipo
        def importoDa = parametriRicerca?.importoDa ?: 0
        def importoA = parametriRicerca?.importoA ?: Integer.MAX_VALUE

        String extraFilter = ""
        String amountFilter = ""

        filtri << ['numeroDa': numeroDa]
        filtri << ['numeroA': numeroA]
        extraFilter += " AND (nvl(SGRAVI.NUMERO_ELENCO, 0) between :numeroDa and :numeroA)"

        filtri << ['dataElencoDa': dataElencoDa]
        filtri << ['dataElencoA': dataElencoA]
        extraFilter += " AND ((SGRAVI.DATA_ELENCO between :dataElencoDa and :dataElencoA) OR (SGRAVI.DATA_ELENCO is null)) "

        filtri << ['importoDa': importoDa]
        filtri << ['importoA': importoA]
        amountFilter = " HAVING(SUM(SGRAVI.IMPORTO) between :importoDa and :importoA) "

        if (motivo != null) {
            filtri << ['motivo': motivo.id]
            extraFilter += " AND SGRAVI.MOTIVO_SGRAVIO = :motivo "
        }

        if (tipo != null) {
            filtri << ['tipo': tipo.key]
            extraFilter += " AND SGRAVI.TIPO_SGRAVIO = :tipo "
        }

        filtri << ['p_utente': springSecurityService.currentUser.id]


        String query = """
                        select sgravi.*, sum(sgravi.importo) over (partition by sgravi.numero_elenco) totale_elenco
                      from (
                            SELECT SGRAVI.NUMERO_ELENCO,
                           SGRAVI.DATA_ELENCO,
                           RUOLI.TIPO_RUOLO,
                           RUOLI.ANNO_RUOLO,
                           RUOLI.ANNO_EMISSIONE,
                           RUOLI.PROGR_EMISSIONE,
                           RUOLI.INVIO_CONSORZIO,
                           RUOLI.IMPORTO_LORDO,
                           SUM(SGRAVI.IMPORTO) IMPORTO,
                           SGRAVI.RUOLO,
                           case nvl(SGRAVI.MOTIVO_SGRAVIO, -1)
                             when -1 then
                              ''
                             else
                              SGRAVI.MOTIVO_SGRAVIO || ' - ' || MOTIVI_SGRAVIO.DESCRIZIONE
                           end as MOTIVO_SGRAVIO_CAT,
                           SGRAVI.TIPO_SGRAVIO,
                           decode(SGRAVI.TIPO_SGRAVIO, 'D', 'Discarico',
                                                       'R', 'Rimborso',
                                                       'S', 'Sgravio',
                                                       '') tipo_sgravio_desc,
                           ruoli.tipo_tributo
                          FROM SGRAVI, RUOLI, MOTIVI_SGRAVIO
                          WHERE SGRAVI.RUOLO = RUOLI.RUOLO
                          AND SGRAVI.MOTIVO_SGRAVIO = MOTIVI_SGRAVIO.MOTIVO_SGRAVIO(+)
                          AND ruoli.tipo_tributo in
                           (SELECT comp.oggetto oggetto
                              FROM si4_competenze comp, dati_generali dage
                             WHERE upper(comp.Utente) = upper(trim(:p_utente))
                               AND comp.id_abilitazione in (6, 7)
                               AND sysdate between
                                   nvl(comp.dal, to_date('01/01/1900', 'dd/mm/yyyy')) AND
                                   nvl(comp.al, to_date('31/12/2900', 'dd/mm/yyyy'))
                               AND upper(dage.flag_competenze) = 'S'
                            UNION
                            SELECT titr.tipo_tributo oggetto
                              FROM tipi_tributo titr, dati_generali dage
                             WHERE dage.flag_competenze is NULL)
                          ${extraFilter}
                          GROUP BY SGRAVI.NUMERO_ELENCO,
                              SGRAVI.DATA_ELENCO,
                              SGRAVI.RUOLO,
                              SGRAVI.MOTIVO_SGRAVIO,
                              RUOLI.TIPO_RUOLO,
                              RUOLI.ANNO_RUOLO,
                              RUOLI.ANNO_EMISSIONE,
                              RUOLI.PROGR_EMISSIONE,
                              RUOLI.INVIO_CONSORZIO,
                              RUOLI.IMPORTO_LORDO,
                              SGRAVI.TIPO_SGRAVIO,
                              ruoli.tipo_tributo,
                              SGRAVI.MOTIVO_SGRAVIO,
                              MOTIVI_SGRAVIO.DESCRIZIONE
                          ${amountFilter}) sgravi
                              ORDER BY nvl(NUMERO_ELENCO, 0)
                        """

        int pageCount = 0

        def totalCount =
                sessionFactory.currentSession.createSQLQuery("select count(*) from (${query})").with {
                    filtri.each { k, v ->
                        setParameter(k, v)
                    }
                    list()
                }[0]


        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            filtri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setFirstResult(activePage * pageSize)
            setMaxResults(pageSize)

            list()

        }

        result.each {

            it.groupHeader = ""

            if (it.numeroElenco != null) {
                it.groupHeader = "Numero ${it.numeroElenco}"
            }
            if (it.dataElenco != null) {
                it.groupHeader += " del ${it.dataElenco.format('dd/MM/yyyy')}"
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

    def getMotiviSgravio() {
        return MotivoSgravio.findAll()
                .sort { it.id }
    }

    def calcolaImportiSgravio(def netto, def maggTares, def idRuolo) {

        def query = """
            select cata.addizionale_eca,
               cata.maggiorazione_eca,
               cata.addizionale_pro,
               cata.aliquota,
               ruol.importo_lordo
                  from carichi_tarsu cata, ruoli ruol
                 where cata.anno = ruol.anno_ruolo
                   and ruol.ruolo = :pRuolo

        """

        def ruolo = Ruolo.get(idRuolo)

        def result = sessionFactory.currentSession.createSQLQuery(query).with {


            setParameter("pRuolo", idRuolo)

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        def res = result[0]
        def importi = [:]

        if (ruolo.importoLordo) {
            importi.addEca = ((netto * (res.addizionaleEca ?: 0.00) / 100) as Double).round(2)
            importi.maggEca = ((netto * (res.maggiorazioneEca ?: 0.00) / 100) as Double).round(2)
            importi.addPro = ((netto * (res.addizionalePro ?: 0.00) / 100) as Double).round(2)
            importi.iva = ((netto * (res.aliquota ?: 0.00) / 100) as Double).round(2)
            importi.lordo = ((netto +
                    importi.addEca +
                    importi.maggEca +
                    importi.addPro +
                    importi.iva +
                    ((maggTares ?: 0) as Double).round(2).round(2)) as Double).round(2)
        } else {
            importi.addEca = 0
            importi.maggEca = 0
            importi.addPro = 0
            importi.iva = 0
            importi.lordo = netto
        }

        return importi

    }

}
