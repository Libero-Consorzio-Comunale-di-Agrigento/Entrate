package it.finmatica.tr4.datiesterni

import grails.transaction.NotTransactional
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.Application20999Error
import it.finmatica.tr4.ParametriExport
import it.finmatica.tr4.TipiExport
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.dto.TipiExportDTO
import it.finmatica.tr4.jobs.ExportDatiJob
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.sql.Date
import java.text.SimpleDateFormat

@Transactional
class ExportDatiService {

    // Logger
    private static final Log log = LogFactory.getLog(this)

    def sessionFactory
    def springSecurityService

    // Servizi
    CommonService commonService
    DatiGeneraliService datiGeneraliService
    def dataSource

    @NotTransactional
    def listaTipiExport() {

        def sql = """select ord.tipo_export, ord.descrizione
                              from (select tiex.tipo_export, tiex.descrizione, tiex.ordinamento
                                      from tipi_export tiex, dati_generali dage
                                     where tiex.flag_standard = 'S'
                                       and nvl(dage.flag_competenze, 'N') = 'N'
                                    union
                                    select tiex.tipo_export, tiex.descrizione, tiex.ordinamento
                                      from tipi_export           tiex,
                                           dati_generali         dage,
                                           export_personalizzati expe
                                     where tiex.tipo_export = expe.tipo_export
                                       and expe.codice_istat = lpad(dage.pro_cliente, 3, '0') ||
                                           lpad(dage.com_cliente, 3, '0')
                                       and nvl(dage.flag_competenze, 'N') = 'N'
                                    union
                                    select tiex.tipo_export, tiex.descrizione, tiex.ordinamento
                                      from tipi_export           tiex,
                                           dati_generali         dage,
                                           si4_competenze        comp,
                                           si4_abilitazioni      abil,
                                           si4_tipi_abilitazione tiab
                                     where tiex.flag_standard = 'S'
                                       and nvl(dage.flag_competenze, 'N') = 'S'
                                       and comp.id_abilitazione = abil.id_abilitazione
                                       and abil.id_tipo_abilitazione = tiab.id_tipo_abilitazione
                                       and comp.utente = :pUser
                                       and comp.oggetto = tiex.tipo_tributo
                                       and sysdate between
                                           nvl(comp.dal, to_date('01/01/1900', 'dd/mm/yyyy')) and
                                           nvl(comp.al, to_date('31/12/2900', 'dd/mm/yyyy'))
                                       and tiab.tipo_abilitazione = 'A'
                                    union
                                    select tiex.tipo_export, tiex.descrizione, tiex.ordinamento
                                      from tipi_export           tiex,
                                           dati_generali         dage,
                                           si4_competenze        comp,
                                           si4_abilitazioni      abil,
                                           si4_tipi_abilitazione tiab,
                                           export_personalizzati expe
                                     where tiex.tipo_export = expe.tipo_export
                                       and expe.codice_istat = lpad(dage.pro_cliente, 3, '0') ||
                                           lpad(dage.com_cliente, 3, '0')
                                       and nvl(dage.flag_competenze, 'N') = 'S'
                                       and comp.id_abilitazione = abil.id_abilitazione
                                       and abil.id_tipo_abilitazione = tiab.id_tipo_abilitazione
                                       and comp.utente = :pUser
                                       and comp.oggetto = tiex.tipo_tributo
                                       and sysdate between
                                           nvl(comp.dal, to_date('01/01/1900', 'dd/mm/yyyy')) and
                                           nvl(comp.al, to_date('31/12/2900', 'dd/mm/yyyy'))
                                       and tiab.tipo_abilitazione = 'A') ord
                             order by ord.ordinamento, ord.tipo_export
                        """

        def tipiExportId = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setString('pUser', springSecurityService.currentUser.id)


            list()
        }.collect { it.tipoExport as Long }

        return TipiExport.createCriteria().list {

            'in'("id", tipiExportId)

            order("ordinamento")
            order("id")
        }.toDTO()

    }

    def listaParametriExport(TipiExportDTO tipoExport) {
        ParametriExport.findAllByTipoExport(tipoExport.toDomain()).sort { it.parametroExport }
    }

    def listaValoriParametro(ParametriExport parametroExport) {

        if ((parametroExport.querySelezione ?: '').empty) {
            return null
        }

        def valori = sessionFactory.currentSession.createSQLQuery(parametroExport.querySelezione).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            list()
        }

        valori.each { it.key = (it.key as String) }

        return valori


    }

    def eseguiExport(
            String nomeProcedura,
            def tipoExport,
            def paramsIn,
            def listaParametriExport
    ) {

        sessionFactory.currentSession.createSQLQuery("truncate table ${tipoExport.tabellaTemporanea}").executeUpdate()

        def pIn = paramsIn.collect { k, v -> [(k.id): v] }.collectEntries()

        // Validazione
        listaParametriExport.findAll {
            it.tipoParametro == 'I'
        }.each {
            validaParametro(it, pIn[tipoExport.id][it.parametroExport]?.toString())
        }

        def params = "{call ${nomeProcedura}("
        def values = []

        listaParametriExport.each {
            params += "?,"
        }

        params = params.substring(0, params.length() - 1)

        if (!listaParametriExport.empty) {
            params += ")}"
        } else {
            params += "}"
        }


        listaParametriExport.sort { it.parametroExport }.each {
            if (it.tipoParametro == "U") {
                switch (it.formatoParametro) {
                    case "date":
                        values << Sql.DATE
                        break
                    case "number":
                        values << Sql.NUMERIC
                        break
                    case "varchar2":
                        values << Sql.VARCHAR
                        break
                }
            } else {
                values << assegnaValore(pIn[tipoExport.id][it.parametroExport] ?: "", it)
            }
        }

        log.info "Procedure: $params"
        log.info "Parametri: $values"

        Sql sql = new Sql(dataSource)

        try {
            def result = null
            def exportText = ""
            def execTime = commonService.timeMe {
                sql.call(params, values, { ... args ->
                    args.each { log.info it }
                    result = args
                })

                exportText = creaDatiFile(tipoExport)
            }

            log.info "Esportazione eseguita in ${execTime}"


            return [output: result, data: exportText, nomeFile: creaNomeFile(tipoExport), time: execTime]
        } catch (Exception e) {
            commonService.serviceException(e)
        } finally {
            sessionFactory.currentSession.createSQLQuery("truncate table ${tipoExport.tabellaTemporanea}").executeUpdate()
        }
    }

    private String validaParametro(def parametro, def valore) {

        if ((parametro.flagObbligatorio ?: 'N') != 'S' && (valore == null || valore.empty)) {
            return ""
        }

        if (parametro.flagObbligatorio == 'S' && (valore == null || valore.empty)) {
            throw new Application20999Error("Specificare un valore per [${parametro.nomeParametro}].")
        }

        switch (parametro.formatoParametro) {
            case "number":
                if (!valore.isNumber()) {
                    throw new Application20999Error("Valore [${valore}] non valido per il parametro [${parametro.nomeParametro}].")
                }
                return ""
            case "date":
                try {
                    java.util.Date.parse('dd/MM/yyyy', valore)
                } catch (Exception e) {
                    throw new Application20999Error("Valore [${valore}] non valido per il parametro [${parametro.nomeParametro}].")
                }
                return ""

            case "varchar2":
                return ""
                break

            default:
                throw new Application20999Error("Formato parametro non [${parametro.formatoParametro}] valido.")
        }
    }

    private assegnaValore(def valore, def parametroExport) {
        if (parametroExport.tipoParametro == "U") {
            switch (parametroExport.formatoParametro) {
                case "date":
                    return Sql.DATE
                    break
                case "number":
                    return Sql.NUMERIC
                    break
                case "varchar2":
                    return Sql.VARCHAR
                    break
            }
        } else {

            def valorePredefinito = ""
            switch (parametroExport.valorePredefinito) {
                case "SYSDATE":
                    valorePredefinito = valore.toString().empty ? new java.util.Date().format("dd/MM/yyyy") : valore
                    break
                default:
                    valorePredefinito = valore.toString().empty ? (parametroExport.valorePredefinito ?: "") : valore
            }

            // Salvataggio dei valori assegnati
            parametroExport.ultimoValore = valore.toString()
            parametroExport.save(failOnError: true, flush: true)

            switch (parametroExport.formatoParametro) {
                case "date":
                    return valorePredefinito.toString().empty ?
                            null :
                            (new Date(new SimpleDateFormat("dd/MM/yyyy")
                                    .parse(valorePredefinito.toString()).time))
                    break
                case "number":
                    return (valorePredefinito.toString().empty ?
                            null :
                            (valorePredefinito.toString() as BigDecimal))
                    break
                case "varchar2":
                    return (valorePredefinito.toString().empty ?
                            null :
                            valorePredefinito.toString())
                    break
            }
        }
    }

    private creaDatiFile(def tipoExport) {
        def queryWrkTrasAnci = "select dati from wrk_tras_anci order by progressivo"
        def queryWrkTrasmissioni = "select dati, dati2, dati3, dati4, dati5, dati6, dati7, dati8 from wrk_trasmissioni order by numero"
        def queryWrkTrasmissioniFlagClob = "select dati_clob from wrk_trasmissioni"
        def query = ""
        def dati = """"""

        switch (tipoExport.tabellaTemporanea) {
            case "wrk_tras_anci":
                query = queryWrkTrasAnci
                break
            case "wrk_trasmissioni":
                switch (tipoExport.flagClob) {
                    case "S":
                        query = queryWrkTrasmissioniFlagClob
                        break
                    default:
                        query = queryWrkTrasmissioni
                }
                break
            default:
                throw new Application20999Error("Tabella temporanea [${tipoExport.tabellaTemporanea}] non riconosciuta.")
        }

        return sessionFactory.currentSession.createSQLQuery(query).list().collect { row ->
            if (tipoExport.tabellaTemporanea == "wrk_trasmissioni" && tipoExport.flagClob != 'S') {
                row.collect { c ->
                    c ?: ''
                }.join('') + "\r\n"
            } else {
                if (tipoExport.flagClob == "S") {
                    row.getSubString(1, (int) row.length())
                } else {
                    "${row}\r\n"
                }
            }
        }.join('')
    }

    def creaNomeFile(def tipoExport) {
        def nomeFile = tipoExport.nomeFile
        def estensione = tipoExport.estensioneNomeFile ?: ""
        def suffisso = ""
        def prefisso = ""

        if (!(tipoExport.prefissoNomeFile ?: "").empty) {
            prefisso = fPrefNomeFile(tipoExport.prefissoNomeFile, tipoExport.id)
        }

        if (!(tipoExport.suffissoNomeFile ?: "").empty) {
            suffisso = fPrefNomeFile(tipoExport.suffissoNomeFile, tipoExport.id)
        }

        return prefisso + nomeFile + suffisso + estensione
    }

    private def fPrefNomeFile(def prefisso, def tipoExport) {
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        String str
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_pref_nome_file(?, ?)}'
                , [Sql.VARCHAR
                   , prefisso
                   , tipoExport
        ]) { str = it }
        sql.close()
        return str
    }
}
