package it.finmatica.tr4.soggetti

import grails.orm.PagedResultList
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.ad4.dizionari.Ad4ComuneTr4
import it.finmatica.datigenerali.DatiGeneraliService
import it.finmatica.tr4.*
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.contribuenti.StatoContribuenteService
import it.finmatica.tr4.depag.IntegrazioneDePagService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.elaborazioni.DettaglioElaborazione
import it.finmatica.tr4.pratiche.PraticaTributo
import it.finmatica.tr4.pratiche.RapportoTributo
import org.codehaus.groovy.grails.plugins.jasper.JasperExportFormat
import org.codehaus.groovy.grails.plugins.jasper.JasperReportDef
import org.codehaus.groovy.grails.plugins.jasper.JasperService
import org.codehaus.groovy.runtime.InvokerHelper
import org.hibernate.criterion.*
import org.hibernate.transform.AliasToEntityMapResultTransformer
import org.hibernate.type.StandardBasicTypes
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.sql.Timestamp

@Transactional(rollbackFor = [RuntimeException.class, Application20999Error.class])
class SoggettiService {

    final static def STATO_SOGGETTO_DECEDUTO = 50L

    static transactional = false

    def springSecurityService
    def sessionFactory
    def dataSource
    def servletContext
    JasperService jasperService
    def ad4EnteService

    DatiGeneraliService datiGeneraliService
    CompetenzeService competenzeService
    StatoContribuenteService statoContribuenteService
    IntegrazioneDePagService integrazioneDePagService

    def listaSoggettiSQL(def parametriRicerca, int pageSize, int activePage, def sortBy = null) {

        String sql = ""
        String sqlTotali = ""
        String sqlFiltri = ""

        String sqlCampiExtra = ""
        String sqlTabelleExtra = ""
        String sqlJoinExtra = ""

        Boolean flagContribuenti = false

        Boolean flagPresso = false
        Boolean flagRappresentante = false
        Boolean flagEredi = false
        Boolean flagRecapiti = false
        Boolean flagFamiliari = false
        Boolean flagDeleghe = false

        Boolean flagTipoTributo = false
        Boolean flagTipoPratica = false
        Boolean flagTipoPraticaL = false

        Boolean flagContatti = false
        Boolean flagDocumenti = false
        Boolean flagPratiche = false
        Boolean flagVersamenti = false
        Boolean flagVersamentiICI = false
        Boolean flagVersamentiTAR = false

        Boolean flagTabPratiche = false
        Boolean flagTabVersamenti = false

        String tempString

        boolean integrazioneGSD = datiGeneraliService.integrazioneGSDAbilitata()

        Short annoCorrente = Calendar.getInstance().get(Calendar.YEAR)

        def tipiPratica = parametriRicerca.tipiPratica ?: []
        def tipiTributo = parametriRicerca.tipiTributo?.clone() ?: []

        if (tipiTributo.find { it == 'CUNI' }) {
            tipiTributo << 'ICP'
            tipiTributo << 'TOSAP'
        }

        def filtri = [:]

        if (parametriRicerca.soloContribuenti) {
            sqlTabelleExtra += ", CONTRIBUENTI CONTR"
            sqlJoinExtra += "AND SOGG.NI = CONTR.NI "
            flagContribuenti = true
        } else {
            if (parametriRicerca.contribuente || parametriRicerca.ricercaSoggCont) {
                sqlTabelleExtra += ", CONTRIBUENTI CONTR"
                sqlJoinExtra += "AND SOGG.NI = CONTR.NI (+)"
                flagContribuenti = true
            }
        }

        if (parametriRicerca.id) {
            filtri << ['idSoggetto': parametriRicerca.id]
            sqlFiltri += "AND NVL(SOGG.NI,0) = :idSoggetto "
        }
        if (parametriRicerca.idEscluso) {
            filtri << ['idEscluso': parametriRicerca.idEscluso]
            sqlFiltri += "AND NVL(SOGG.NI,0) <> :idEscluso "
        }

        if (parametriRicerca.cognomeNome) {
            tempString = parametriRicerca.cognomeNome.trim().toUpperCase()
            filtri << ['cognomeNome': tempString]
            sqlFiltri += "AND UPPER(SOGG.COGNOME_NOME) LIKE(:cognomeNome) "
        }
        if (parametriRicerca.cognome) {
            tempString = parametriRicerca.cognome.trim().toUpperCase()
            filtri << ['cognome': tempString]
            sqlFiltri += "AND UPPER(SOGG.COGNOME) LIKE(:cognome) "
        }
        if (parametriRicerca.nome) {
            tempString = parametriRicerca.nome.trim().toUpperCase()
            filtri << ['nome': tempString]
            sqlFiltri += "AND UPPER(SOGG.NOME) LIKE(:nome) "
        }
        if (parametriRicerca.fonte && parametriRicerca.fonte instanceof FonteDTO) {
            filtri << ['fonte': parametriRicerca.fonte.fonte]
            sqlFiltri += "AND SOGG.FONTE = :fonte "
        }

        if (parametriRicerca.codFiscale) {

            tempString = parametriRicerca.codFiscale.trim().toUpperCase()
            filtri << ['codFiscale': tempString]

            if (!parametriRicerca.ricercaSoggCont) {
                if (parametriRicerca.contribuente) {
                    sqlFiltri += "AND UPPER(CONTR.COD_FISCALE) LIKE(:codFiscale) "
                } else {
                    sqlFiltri += "AND (UPPER(SOGG.COD_FISCALE) LIKE(:codFiscale) " +
                            "OR UPPER(SOGG.PARTITA_IVA) LIKE(:codFiscale)) "
                }
            } else {
                sqlFiltri += "AND (UPPER(CONTR.COD_FISCALE) LIKE(:codFiscale) " +
                        "OR UPPER(SOGG.COD_FISCALE) LIKE(:codFiscale) " +
                        "OR UPPER(SOGG.PARTITA_IVA) LIKE(:codFiscale)) "
            }
        }
        if (parametriRicerca.codFiscaleEscluso) {

            tempString = parametriRicerca.codFiscaleEscluso.trim().toUpperCase()
            filtri << ['codFiscaleEscluso': tempString]

            if (parametriRicerca.contribuente == "s") {
                sqlFiltri += "AND UPPER(CONTR.COD_FISCALE) <> :codFiscale "
            } else {
                sqlFiltri += "AND UPPER(SOGG.COD_FISCALE) <> :codFiscale "
            }
        }
        if (parametriRicerca.indirizzo) {
            tempString = parametriRicerca.indirizzo.trim().toUpperCase()
            filtri << ['indirizzo': tempString + "%"]
            sqlFiltri += "AND UPPER((DECODE(SOGG.COD_VIA,NULL,SOGG.DENOMINAZIONE_VIA,AVIE.DENOM_UFF) || " +
                    "DECODE(SOGG.NUM_CIV, NULL, '', ', ' || SOGG.NUM_CIV) || " +
                    "DECODE(SOGG.SUFFISSO, NULL,'', '/' || SOGG.SUFFISSO))) LIKE(:indirizzo) "
        }
        if (parametriRicerca.comuneResidenza) {
            tempString = parametriRicerca.comuneResidenza.trim().toUpperCase()
            filtri << ['comuneResidenza': tempString]
            sqlFiltri += "AND COMRES.DENOMINAZIONE = :comuneResidenza "
        }

        if (parametriRicerca.residente == "s") {
            sqlFiltri += "AND (SOGG.TIPO_RESIDENTE = 0 AND SOGG.FASCIA = 1) "
        }
        if (parametriRicerca.residente == "n") {
            sqlFiltri += "AND (SOGG.TIPO_RESIDENTE <> 0 OR SOGG.FASCIA <> 1) "
        }
        if (parametriRicerca.gsd == "s") {
            sqlFiltri += "AND SOGG.TIPO_RESIDENTE = 0 "
        }
        if (parametriRicerca.gsd == "n") {
            sqlFiltri += "AND SOGG.TIPO_RESIDENTE <> 0 "
        }
        if (parametriRicerca.contribuente == "n") {
            sqlFiltri += "AND CONTR.NI IS NULL "
        }

        if (parametriRicerca.statoContribuenteFilter?.isActive()) {
            def statoContribuenteSubQuery = getStatoContribuenteSubquery(parametriRicerca)
            def criteria = statoContribuenteSubQuery.getExecutableCriteria(sessionFactory.currentSession)
            def codFiscaleList = criteria.list().codFiscale.unique()

            if (codFiscaleList.isEmpty()) {
                sqlFiltri += "AND 1=0 "
            } else {
                filtri << ['cod_fiscale_list': codFiscaleList]
                sqlFiltri += "AND CONTR.COD_FISCALE IN (:cod_fiscale_list)"
            }
        }

        def tipiPersona = []

        if (parametriRicerca.personaFisica) tipiPersona << '0'
        if (parametriRicerca.personaGiuridica) tipiPersona << '1'
        if (parametriRicerca.personaParticolare) tipiPersona << '2'

        if (tipiPersona.size() > 0) {
            tempString = "'" + tipiPersona.join("','") + "'"
            sqlFiltri += "AND SOGG.TIPO IN (${tempString}) "
        }

        if ((parametriRicerca.pressoCognome) || (parametriRicerca.pressoNome) ||
                (parametriRicerca.pressoCodFiscale) || (parametriRicerca.pressoIndirizzo) || (parametriRicerca.pressoComune) ||
                (parametriRicerca.pressoNi) || (parametriRicerca.pressoFonte) || (parametriRicerca.pressoNote)) {

            sqlTabelleExtra += ", SOGGETTI SOPR "
            sqlJoinExtra += "AND SOGG.NI_PRESSO = SOPR.NI (+) "
            sqlTabelleExtra += ", ARCHIVIO_VIE SOPRVE "
            sqlJoinExtra += "AND SOPR.COD_VIA = SOPRVE.COD_VIA (+) "
            sqlTabelleExtra += ", AD4_COMUNI COMPRS, AD4_PROVINCIE PROPRS "
            sqlJoinExtra += "AND SOPR.COD_PRO_RES = COMPRS.PROVINCIA_STATO (+) " +
                    "AND SOPR.COD_COM_RES = COMPRS.COMUNE (+) " +
                    "AND COMPRS.PROVINCIA_STATO = PROPRS.PROVINCIA (+) "

            sqlCampiExtra += ",SOPR.FONTE AS PRESSO_FONTE"
            sqlCampiExtra += ",SOPR.COGNOME_NOME AS PRESSO_COGN_NOME"
            sqlCampiExtra += ",SOPR.COD_FISCALE AS PRESSO_COD_FIS"
            sqlCampiExtra += ",DECODE(SOPR.COD_VIA,NULL,SOPR.DENOMINAZIONE_VIA,SOPRVE.DENOM_UFF) || " +
                    "DECODE(SOPR.NUM_CIV,NULL,'', ', ' || SOPR.NUM_CIV) || " +
                    "DECODE(SOPR.SUFFISSO,NULL,'', '/' || SOPR.SUFFISSO) PRESSO_INDIRIZZO"
            sqlCampiExtra += ",DECODE(COMPRS.DENOMINAZIONE,NULL,'',COMPRS.DENOMINAZIONE || " +
                    "DECODE(PROPRS.SIGLA,NULL,'',' (' || PROPRS.SIGLA|| ')')) AS PRESSO_COMUNE"
            sqlCampiExtra += ",SOPR.NOTE AS PRESSO_NOTE"

            if (parametriRicerca.pressoCognome) {
                tempString = parametriRicerca.pressoCognome.trim().toUpperCase()
                filtri << ['pressoCognome': tempString]
                sqlFiltri += "AND UPPER(SOPR.COGNOME_RIC) like(:pressoCognome) "
            }
            if (parametriRicerca.pressoNome) {
                tempString = parametriRicerca.pressoNome.trim().toUpperCase()
                filtri << ['pressoNome': tempString]
                sqlFiltri += "AND UPPER(SOPR.NOME_RIC) like(:pressoNome) "
            }
            if (parametriRicerca.pressoCodFiscale) {
                tempString = parametriRicerca.pressoCodFiscale.trim().toUpperCase()
                filtri << ['pressoCodFiscale': tempString]
                sqlFiltri += "AND UPPER(SOPR.COD_FISCALE) like(:pressoCodFiscale) "
            }
            if (parametriRicerca.pressoIndirizzo) {
                tempString = parametriRicerca.pressoIndirizzo.trim().toUpperCase()
                filtri << ['pressoIndirizzo': tempString]
                sqlFiltri += "AND UPPER(SOPR.DENOMINAZIONE_VIA) like(:pressoIndirizzo) "
            }
            if (parametriRicerca.pressoComune) {
                filtri << ['pressoCodPro': parametriRicerca.pressoComune.provinciaStato]
                filtri << ['pressoCodCom': parametriRicerca.pressoComune.comune]
                sqlFiltri += "AND SOPR.COD_PRO_RES = :pressoCodPro AND SOPR.COD_COM_RES = :pressoCodCom "
            }
            if (parametriRicerca.pressoNi) {
                filtri << ['pressoNi': parametriRicerca.pressoNi]
                sqlFiltri += "AND SOPR.NI = :pressoNi "
            }
            if (parametriRicerca.pressoFonte != null) {
                if (parametriRicerca.pressoFonte == -1) {
                    sqlFiltri += "AND SOPR.FONTE IS NOT NULL "
                } else {
                    filtri << ['pressoFonte': parametriRicerca.pressoFonte]
                    sqlFiltri += "AND NVL(SOPR.FONTE,'') = :pressoFonte "
                }
            }
            if (parametriRicerca.pressoNote) {
                tempString = parametriRicerca.pressoNote.trim().toUpperCase()
                filtri << ['pressoNote': tempString]
                sqlFiltri += "AND UPPER(SOPR.NOTE) like(:pressoNote) "
            }

            flagPresso = true
        }

        if ((parametriRicerca.rappCognNome) || (parametriRicerca.rappCodFis) ||
                (parametriRicerca.rappTipoCarica != null) || (parametriRicerca.rappIndirizzo) ||
                (parametriRicerca.rappComune != null)) {

            sqlTabelleExtra += ", TIPI_CARICA TICA "
            sqlJoinExtra += "AND SOGG.TIPO_CARICA = TICA.TIPO_CARICA (+) "
            sqlTabelleExtra += ", AD4_COMUNI COMRAP, AD4_PROVINCIE PRORAP "
            sqlJoinExtra += "AND SOGG.COD_PRO_RAP = COMRAP.PROVINCIA_STATO (+) " +
                    "AND SOGG.COD_COM_RAP = COMRAP.COMUNE (+) " +
                    "AND COMRAP.PROVINCIA_STATO = PRORAP.PROVINCIA (+) "

            sqlCampiExtra += ",SOGG.RAPPRESENTANTE AS RAPP_COGN_NOME"
            sqlCampiExtra += ",SOGG.COD_FISCALE_RAP AS RAPP_COD_FIS"
            sqlCampiExtra += ",TICA.DESCRIZIONE AS RAPP_TIPO_CARICA"
            sqlCampiExtra += ",SOGG.INDIRIZZO_RAP AS RAPP_INDIRIZZO"
            sqlCampiExtra += ",DECODE(COMRAP.DENOMINAZIONE,NULL,'',COMRAP.DENOMINAZIONE || " +
                    "DECODE(PRORAP.SIGLA,NULL,'',' (' || PRORAP.SIGLA|| ')')) AS RAPP_COMUNE"

            if (parametriRicerca.rappCognNome) {
                tempString = parametriRicerca.rappCognNome.trim().toUpperCase()
                filtri << ['rappCognNome': tempString]
                sqlFiltri += "AND UPPER(SOGG.RAPPRESENTANTE) like(:rappCognNome) "
            }
            if (parametriRicerca.rappCodFis) {
                tempString = parametriRicerca.rappCodFis.trim().toUpperCase()
                filtri << ['rappCodFis': tempString]
                sqlFiltri += "AND UPPER(SOGG.COD_FISCALE_RAP) like(:rappCodFis) "
            }
            if (parametriRicerca.rappTipoCarica != null) {
                if (parametriRicerca.rappTipoCarica != -1) {
                    filtri << ['rappTipoCarica': parametriRicerca.rappTipoCarica]
                    sqlFiltri += "AND SOGG.TIPO_CARICA = :rappTipoCarica "
                } else {
                    sqlFiltri += "AND SOGG.TIPO_CARICA IS NOT NULL "
                }
            }
            if (parametriRicerca.rappIndirizzo) {
                tempString = parametriRicerca.rappIndirizzo.trim().toUpperCase()
                filtri << ['rappIndirizzo': tempString]
                sqlFiltri += "AND UPPER(SOGG.INDIRIZZO_RAP) like(:rappIndirizzo) "
            }
            if (parametriRicerca.rappComune != null) {
                filtri << ['rappCodPro': parametriRicerca.rappComune.provinciaStato]
                filtri << ['rappCodCom': parametriRicerca.rappComune.comune]
                sqlFiltri += "AND SOGG.COD_PRO_RAP = :rappCodPro AND SOGG.COD_COM_RAP = :rappCodCom "
            }
            flagRappresentante = true
        }

        if ((parametriRicerca.erediCognome) || (parametriRicerca.erediNome) ||
                (parametriRicerca.erediCodFiscale) || (parametriRicerca.erediIndirizzo) ||
                (parametriRicerca.erediId != null) || (parametriRicerca.erediFonte != null) || (parametriRicerca.erediNote)) {

            sqlTabelleExtra += ", EREDI_SOGGETTO ERSO "
            sqlJoinExtra += "AND SOGG.NI = ERSO.NI (+) "
            sqlTabelleExtra += ", SOGGETTI ERSOSO "
            sqlJoinExtra += "AND ERSO.NI_EREDE = ERSOSO.NI (+) "
            sqlTabelleExtra += ", ARCHIVIO_VIE ERSOVE "
            sqlJoinExtra += "AND ERSOSO.COD_VIA = ERSOVE.COD_VIA (+) "
            sqlTabelleExtra += ", AD4_COMUNI COMERD, AD4_PROVINCIE PROERD "
            sqlJoinExtra += "AND ERSOSO.COD_PRO_RES = COMERD.PROVINCIA_STATO (+) " +
                    "AND ERSOSO.COD_COM_RES = COMERD.COMUNE (+) " +
                    "AND COMERD.PROVINCIA_STATO = PROERD.PROVINCIA (+) "

            sqlCampiExtra += ",ERSOSO.FONTE AS ERED_FONTE"
            sqlCampiExtra += ",ERSOSO.COGNOME_NOME AS ERED_COGN_NOME"
            sqlCampiExtra += ",ERSOSO.COD_FISCALE AS ERED_COD_FIS"
            sqlCampiExtra += ",DECODE(ERSOSO.COD_VIA,NULL,ERSOSO.DENOMINAZIONE_VIA,ERSOVE.DENOM_UFF) || " +
                    "DECODE(ERSOSO.NUM_CIV,NULL,'', ', ' || ERSOSO.NUM_CIV) || " +
                    "DECODE(ERSOSO.SUFFISSO,NULL,'', '/' || ERSOSO.SUFFISSO) ERED_INDIRIZZO"
            sqlCampiExtra += ",DECODE(COMERD.DENOMINAZIONE,NULL,'',COMERD.DENOMINAZIONE || " +
                    "DECODE(PROERD.SIGLA,NULL,'',' (' || PROERD.SIGLA|| ')')) AS ERED_COMUNE"

            sqlCampiExtra += ",ERSO.NOTE AS ERED_NOTE"

            if (parametriRicerca.erediCognome) {
                tempString = parametriRicerca.erediCognome.trim().toUpperCase()
                filtri << ['cognomeEredi': tempString]
                sqlFiltri += "AND UPPER(ERSOSO.COGNOME_RIC) like(:cognomeEredi) "
            }
            if (parametriRicerca.erediNome) {
                tempString = parametriRicerca.erediNome.trim().toUpperCase()
                filtri << ['nomeEredi': tempString]
                sqlFiltri += "AND UPPER(ERSOSO.NOME_RIC) like(:nomeEredi) "
            }
            if (parametriRicerca.erediCodFiscale) {
                tempString = parametriRicerca.erediCodFiscale.trim().toUpperCase()
                filtri << ['codFiscaleEredi': tempString]
                sqlFiltri += "AND UPPER(ERSOSO.COD_FISCALE) like(:codFiscaleEredi) "
            }
            if (parametriRicerca.erediIndirizzo) {
                tempString = parametriRicerca.erediIndirizzo.trim().toUpperCase()
                filtri << ['indirizzoEredi': tempString]
                sqlFiltri += "AND UPPER(ERSOSO.DENOMINAZIONE_VIA) like(:indirizzoEredi) "
            }
            if (parametriRicerca.erediId != null) {
                filtri << ['idErede': parametriRicerca.erediId]
                sqlFiltri += "AND ERSOSO.NI = :idErede "
            }
            if (parametriRicerca.erediFonte != null) {
                if (parametriRicerca.erediFonte == -1) {
                    sqlFiltri += "AND ERSOSO.FONTE IS NOT NULL "
                } else {
                    filtri << ['erediFonte': parametriRicerca.erediFonte]
                    sqlFiltri += "AND NVL(ERSOSO.FONTE,'') = :erediFonte "
                }
            }
            if (parametriRicerca.erediNote) {
                tempString = parametriRicerca.erediNote.trim().toUpperCase()
                filtri << ['erediNote': tempString]
                sqlFiltri += "AND UPPER(ERSO.NOTE) like(:erediNote) "
            }
            flagEredi = true
        }

        def recapTipiTributo = parametriRicerca.recapTipiTributo ?: []
        def recapTipiRecapito = parametriRicerca.recapTipiRecapito ?: []

        if ((recapTipiTributo.size() > 0) || (recapTipiRecapito.size() > 0) ||
                (parametriRicerca.recapIndirizzo) || (parametriRicerca.recapDescr) ||
                (parametriRicerca.recapPresso) || (parametriRicerca.recapNote) ||
                (parametriRicerca.recapDal) || (parametriRicerca.recapAl)) {

            sqlTabelleExtra += ", RECAPITI_SOGGETTO RESO "
            sqlJoinExtra += "AND SOGG.NI = RESO.NI (+) "
            sqlTabelleExtra += ", TIPI_RECAPITO TIRE "
            sqlJoinExtra += "AND RESO.TIPO_RECAPITO = TIRE.TIPO_RECAPITO (+) "
            sqlTabelleExtra += ", ARCHIVIO_VIE REVI "
            sqlJoinExtra += "AND RESO.COD_VIA = REVI.COD_VIA (+) "
            sqlTabelleExtra += ", AD4_COMUNI COMREC, AD4_PROVINCIE PROREC "
            sqlJoinExtra += "AND RESO.COD_PRO = COMREC.PROVINCIA_STATO (+) " +
                    "AND RESO.COD_COM = COMREC.COMUNE (+) " +
                    "AND COMREC.PROVINCIA_STATO = PROREC.PROVINCIA (+) "

            sqlCampiExtra += ",RESO.TIPO_TRIBUTO AS RECA_TIPO_TRIBUTO"
            sqlCampiExtra += ",RESO.TIPO_RECAPITO|| ' - ' || TIRE.DESCRIZIONE AS RECA_TIPO_RECAPITO"
            sqlCampiExtra += ",RESO.DESCRIZIONE AS RECA_DESCRIZIONE"
            sqlCampiExtra += ",DECODE(RESO.COD_VIA,NULL,'',REVI.DENOM_UFF) || " +
                    "DECODE(RESO.NUM_CIV,NULL,'', ', ' || RESO.NUM_CIV) || " +
                    "DECODE(RESO.SUFFISSO,NULL,'', '/' || RESO.SUFFISSO) AS RECA_INDIRIZZO"
            sqlCampiExtra += ",DECODE(COMREC.DENOMINAZIONE,NULL,'',COMREC.DENOMINAZIONE || " +
                    "DECODE(PROREC.SIGLA,NULL,'',' (' || PROREC.SIGLA|| ')')) AS RECA_COMUNE"

            sqlCampiExtra += ",RESO.PRESSO AS RECA_PRESSO"
            sqlCampiExtra += ",RESO.NOTE AS RECA_NOTE"
            sqlCampiExtra += ",DECODE(RESO.DAL,NULL,'',TO_CHAR(RESO.DAL,'dd/mm/yyyy')) AS RECA_DAL"
            sqlCampiExtra += ",DECODE(RESO.AL,NULL,'',TO_CHAR(RESO.AL,'dd/mm/yyyy'))  AS RECA_AL"

            if (recapTipiTributo.size() > 0) {
                tempString = "'" + recapTipiTributo.join("','") + "'"
                sqlFiltri += "AND RESO.TIPO_TRIBUTO IN (${tempString}) "
            }
            if (recapTipiRecapito.size() > 0) {
                tempString = recapTipiRecapito.join(",")
                sqlFiltri += "AND RESO.TIPO_RECAPITO IN (${tempString}) "
            }
            if (parametriRicerca.recapIndirizzo) {
                tempString = parametriRicerca.recapIndirizzo.trim().toUpperCase()
                filtri << ['indirizzoRecapito': tempString]
                sqlFiltri += "AND UPPER((DECODE(RESO.COD_VIA,NULL,RESO.DESCRIZIONE,REVI.DENOM_UFF) || " +
                        "DECODE(RESO.NUM_CIV, NULL,'', ', ' || RESO.NUM_CIV) || " +
                        "DECODE(RESO.SUFFISSO, NULL,'', '/' || RESO.SUFFISSO))) LIKE(:indirizzoRecapito) "
            }
            if (parametriRicerca.recapDescr) {
                tempString = parametriRicerca.recapDescr.trim().toUpperCase()
                filtri << ['descrDecapito': tempString]
                sqlFiltri += "AND UPPER(RESO.DESCRIZIONE) like(:descrDecapito) "
            }
            if (parametriRicerca.recapPresso) {
                tempString = parametriRicerca.recapPresso.trim().toUpperCase()
                filtri << ['pressoRecapito': tempString]
                sqlFiltri += "AND UPPER(RESO.PRESSO) like(:pressoRecapito) "
            }
            if (parametriRicerca.recapNote) {
                tempString = parametriRicerca.recapNote.trim().toUpperCase()
                filtri << ['noteRecapito': tempString]
                sqlFiltri += "AND UPPER(RESO.NOTE) like(:noteRecapito) "
            }
            if (parametriRicerca.recapDal != null) {
                filtri << ['validoDaRecapito': parametriRicerca.recapDal]
                sqlFiltri += "AND RESO.DAL >= :validoDaRecapito "
            }
            if (parametriRicerca.recapAl != null) {
                filtri << ['validoARecapito': parametriRicerca.recapAl]
                sqlFiltri += "AND RESO.AL <= :validoARecapito "
            }
            flagRecapiti = true
        }

        if ((parametriRicerca.familAnno != null) || (parametriRicerca.familNote) ||
                (parametriRicerca.familDal != null) || (parametriRicerca.familAl != null) ||
                (parametriRicerca.familNumeroDa != null) || (parametriRicerca.familNumeroA != null)) {

            sqlTabelleExtra += ", FAMILIARI_SOGGETTO FASO "
            sqlJoinExtra += "AND SOGG.NI = FASO.NI (+) "

            sqlCampiExtra += ",FASO.ANNO AS FAMIL_ANNO"
            sqlCampiExtra += ",FASO.DAL AS FAMIL_DAL"
            sqlCampiExtra += ",FASO.AL AS FAMIL_AL"
            sqlCampiExtra += ",FASO.NUMERO_FAMILIARI AS FAMIL_NUMERO"
            sqlCampiExtra += ",FASO.NOTE AS FAMIL_NOTE"

            if (parametriRicerca.familAnno != null) {
                filtri << ['familAnno': parametriRicerca.familAnno]
                sqlFiltri += "AND FASO.ANNO = :familAnno "
            }
            if (parametriRicerca.familDal != null) {
                filtri << ['familDal': parametriRicerca.familDal]
                sqlFiltri += "AND FASO.DAL >= :familDal AND FASO.AL > :familDal "
            }
            if (parametriRicerca.familAl != null) {
                filtri << ['familAl': parametriRicerca.familAl]
                sqlFiltri += "AND FASO.DAL < :familAl AND FASO.AL <= :familAl "
            }
            if (parametriRicerca.familNumeroDa != null) {
                filtri << ['familNumeroDa': parametriRicerca.familNumeroDa]
                sqlFiltri += "AND FASO.NUMERO_FAMILIARI >= :familNumeroDa "
            }
            if (parametriRicerca.familNumeroA != null) {
                filtri << ['familNumeroA': parametriRicerca.familNumeroA]
                sqlFiltri += "AND FASO.NUMERO_FAMILIARI >= :familNumeroA "
            }
            if (parametriRicerca.familNote) {
                tempString = parametriRicerca.familNote.trim().toUpperCase()
                filtri << ['familNote': tempString]
                sqlFiltri += "AND UPPER(FASO.NOTE) like(:familNote) "
            }
            flagFamiliari = true
        }

        def delegTipiTributo = parametriRicerca.delegTipiTributo ?: []

        if ((delegTipiTributo.size() > 0) ||
                (parametriRicerca.delegIBAN) || (parametriRicerca.delegDescr) ||
                (parametriRicerca.delegCodFisInt) || (parametriRicerca.delegCognNomeInt) ||
                (parametriRicerca.delegCessata != null) || (parametriRicerca.delegRitiroDal != null) ||
                (parametriRicerca.delegRitiroAl != null) || (parametriRicerca.delegRataUnica != null) || (parametriRicerca.delegNote)) {

            if (flagContribuenti == false) {
                sqlTabelleExtra += ", CONTRIBUENTI CONTR"
                sqlJoinExtra += "AND SOGG.NI = CONTR.NI (+) "
                flagContribuenti = true
            }

            sqlTabelleExtra += """,( 
				SELECT
					DEBA.COD_FISCALE,
					DEBA.TIPO_TRIBUTO,
					DEBA.COD_ABI,
					DEBA.COD_CAB,
					NVL(A4BN.DENOMINAZIONE, 'BANCA ASSENTE') || ' - ' || NVL (A4SP.DESCRIZIONE, 'SPORTELLO ASSENTE') AS DESCRIZIONE,
					DEBA.CONTO_CORRENTE,
					DEBA.COD_CONTROLLO_CC,
					DEBA.UTENTE,
					DEBA.DATA_VARIAZIONE,
					DEBA.NOTE,
					DEBA.CODICE_FISCALE_INT,
					DEBA.COGNOME_NOME_INT,
					DEBA.FLAG_DELEGA_CESSATA,
					DEBA.DATA_RITIRO_DELEGA,
					DEBA.FLAG_RATA_UNICA,
					DEBA.CIN_BANCARIO,
					DEBA.IBAN_PAESE,
					DEBA.IBAN_CIN_EUROPA,
					DEBA.IBAN_PAESE || LPAD (DEBA.IBAN_CIN_EUROPA, 2, '0') || DEBA.CIN_BANCARIO || LPAD (DEBA.COD_ABI, 5, '0') || LPAD (DEBA.COD_CAB, 5, '0')
																						|| SUBSTR(LPAD(DEBA.conto_corrente || DEBA.cod_controllo_cc,13,'0'),-12) AS IBAN
                  FROM DELEGHE_BANCARIE DEBA,
                       AD4_SPORTELLI A4SP,
                       AD4_BANCHE A4BN,
                       DATI_GENERALI DAGE
                 WHERE
					(LPAD (TO_CHAR (DEBA.COD_ABI), 5, '0') = A4SP.ABI(+))
					AND (LPAD (TO_CHAR (DEBA.COD_CAB), 5, '0') = A4SP.CAB(+))
					AND (LPAD (TO_CHAR (DEBA.COD_ABI), 5, '0') = A4BN.ABI(+))
					AND DAGE.FLAG_COMPETENZE IS NULL
                UNION
                SELECT
					DEBA.COD_FISCALE,
					DEBA.TIPO_TRIBUTO,
					DEBA.COD_ABI,
					DEBA.COD_CAB,
					NVL (A4BN.DENOMINAZIONE, 'BANCA ASSENTE') || ' - ' || NVL (A4SP.DESCRIZIONE, 'SPORTELLO ASSENTE') AS DESCRIZIONE,
					DEBA.CONTO_CORRENTE,
					DEBA.COD_CONTROLLO_CC,
					DEBA.UTENTE,
					DEBA.DATA_VARIAZIONE,
					DEBA.NOTE,
					DEBA.CODICE_FISCALE_INT,
					DEBA.COGNOME_NOME_INT,
					DEBA.FLAG_DELEGA_CESSATA,
					DEBA.DATA_RITIRO_DELEGA,
					DEBA.FLAG_RATA_UNICA,
					DEBA.CIN_BANCARIO,
					DEBA.IBAN_PAESE,
					DEBA.IBAN_CIN_EUROPA,
					DEBA.IBAN_PAESE || LPAD (DEBA.IBAN_CIN_EUROPA, 2, '0') || DEBA.CIN_BANCARIO || LPAD (DEBA.COD_ABI, 5, '0') || LPAD (DEBA.COD_CAB, 5, '0')
																							|| SUBSTR(LPAD(DEBA.CONTO_CORRENTE || DEBA.COD_CONTROLLO_CC,13,'0'),-12) AS IBAN
				FROM
					DELEGHE_BANCARIE DEBA,
					AD4_SPORTELLI A4SP,
					AD4_BANCHE A4BN,
					DATI_GENERALI DAGE,
					SI4_COMPETENZE COMP
				WHERE 
					(LPAD (TO_CHAR (DEBA.COD_ABI), 5, '0') = A4SP.ABI(+))
					AND (LPAD (TO_CHAR (DEBA.COD_CAB), 5, '0') = A4SP.CAB(+))
					AND (LPAD (TO_CHAR (DEBA.COD_ABI), 5, '0') = A4BN.ABI(+))
					AND DEBA.TIPO_TRIBUTO = COMP.OGGETTO
					AND COMP.Utente = :p_utente
					AND COMP.ID_ABILITAZIONE IN (6, 7)
					AND DAGE.FLAG_COMPETENZE = 'S'
                ORDER BY 1, 2
			) DEBA"""
            filtri << ['p_utente': springSecurityService.currentUser?.id]

            sqlJoinExtra += "AND CONTR.COD_FISCALE = DEBA.COD_FISCALE (+) "

            sqlCampiExtra += ",DEBA.TIPO_TRIBUTO AS DELEG_TIPO_TRIBUTO"
            sqlCampiExtra += ",DEBA.DESCRIZIONE AS DELEG_DESCRIZIONE"
            sqlCampiExtra += ",DEBA.CONTO_CORRENTE AS DELEG_CONTO_CORRENTE"
            sqlCampiExtra += ",DEBA.CODICE_FISCALE_INT AS DELEG_COD_FIS_INT"
            sqlCampiExtra += ",DEBA.COGNOME_NOME_INT AS DELEG_COGN_NOME_INT"
            sqlCampiExtra += ",DECODE(DEBA.FLAG_DELEGA_CESSATA,NULL,'-','Si') AS DELEG_CESSATA"
            sqlCampiExtra += ",DEBA.DATA_RITIRO_DELEGA AS DELEG_DATA_RITIRO"
            sqlCampiExtra += ",DECODE(DEBA.FLAG_RATA_UNICA,NULL,'-','Si') AS DELEG_RATA_UNICA"
            sqlCampiExtra += ",DEBA.IBAN AS DELEG_IBAN"
            sqlCampiExtra += ",DEBA.NOTE AS DELEG_NOTE"

            if (delegTipiTributo.size() > 0) {
                tempString = "'" + delegTipiTributo.join("','") + "'"
                sqlFiltri += "AND DEBA.TIPO_TRIBUTO IN (${tempString}) "
            }
            if (parametriRicerca.delegIBAN) {
                tempString = parametriRicerca.delegIBAN.trim().toUpperCase()
                filtri << ['delegIBAN': tempString]
                sqlFiltri += "AND UPPER(DEBA.CONTO_CORRENTE) like(:delegIBAN) "
            }
            if (parametriRicerca.delegDescr) {
                tempString = parametriRicerca.delegDescr.trim().toUpperCase()
                filtri << ['delegDescr': tempString]
                sqlFiltri += "AND UPPER(DEBA.DESCRIZIONE) like(:delegDescr) "
            }
            if (parametriRicerca.delegCodFisInt) {
                tempString = parametriRicerca.delegCodFisInt.trim().toUpperCase()
                filtri << ['delegCodFisInt': tempString]
                sqlFiltri += "AND UPPER(DEBA.CODICE_FISCALE_INT) like(:delegCodFisInt) "
            }
            if (parametriRicerca.delegCognNomeInt) {
                tempString = parametriRicerca.delegCognNomeInt.trim().toUpperCase()
                filtri << ['delegCognNomeInt': tempString]
                sqlFiltri += "AND UPPER(DEBA.COGNOME_NOME_INT) like(:delegCognNomeInt) "
            }
            if (parametriRicerca.delegCessata != null) {
                if (parametriRicerca.delegCessata == true) {
                    sqlFiltri += "AND DEBA.FLAG_DELEGA_CESSATA = 'S' "
                }
                if (parametriRicerca.delegCessata == false) {
                    sqlFiltri += "AND DEBA.FLAG_DELEGA_CESSATA IS NULL "
                }
            }
            if (parametriRicerca.delegRitiroDal != null) {
                filtri << ['delegRitiroDal': parametriRicerca.delegRitiroDal]
                sqlFiltri += "AND DEBA.DATA_RITIRO_DELEGA >= :delegRitiroDal "
            }
            if (parametriRicerca.delegRitiroAl != null) {
                filtri << ['delegRitiroAl': parametriRicerca.delegRitiroAl]
                sqlFiltri += "AND DEBA.DATA_RITIRO_DELEGA >= :delegRitiroAl "
            }
            if (parametriRicerca.delegRataUnica != null) {
                if (parametriRicerca.delegRataUnica == true) {
                    sqlFiltri += "AND DEBA.FLAG_RATA_UNICA = 'S' "
                }
                if (parametriRicerca.delegRataUnica == false) {
                    sqlFiltri += "AND DEBA.FLAG_RATA_UNICA IS NULL "
                }
            }
            if (parametriRicerca.delegNote) {
                tempString = parametriRicerca.delegNote.trim().toUpperCase()
                filtri << ['delegNote': tempString]
                sqlFiltri += "AND UPPER(DEBA.NOTE) like(:delegNote) "
            }
            flagDeleghe = true
        }

        if (((parametriRicerca.statoAttivi) || (parametriRicerca.statoCessati)) && (parametriRicerca.statoAttivi != parametriRicerca.statoCessati)) {

            String filtroStato
            String filtroJoin

            if (parametriRicerca.statoAttivi) {
                filtroStato = "SI"
                filtroJoin = " OR "
            } else {
                filtroStato = "NO"
                filtroJoin = " AND "
            }

            tempString = ""

            if (parametriRicerca.annoStato) {

                def annoStato = parametriRicerca.annoStato

                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'ICI' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO_ANNO('ICI',CONTR.COD_FISCALE,${annoStato}) = '${filtroStato}'"""
                }
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TASI' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO_ANNO('TASI',CONTR.COD_FISCALE,${annoStato}) = '${filtroStato}'"""
                }
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TARSU' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO_ANNO('TARSU',CONTR.COD_FISCALE,${annoStato}) = '${filtroStato}'"""
                }
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'ICIAP' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO_ANNO('ICIAP',CONTR.COD_FISCALE,${annoStato}) = '${filtroStato}'"""
                }
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'ICP' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO_ANNO('ICP',CONTR.COD_FISCALE,${annoStato}) = '${filtroStato}'"""
                }
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TOSAP' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO_ANNO('TOSAP',CONTR.COD_FISCALE,${annoStato}) = '${filtroStato}'"""
                }
            } else {
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'ICI' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO('ICI',CONTR.COD_FISCALE) = '${filtroStato}'"""
                }
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TASI' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO('TASI',CONTR.COD_FISCALE) = '${filtroStato}'"""
                }
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TARSU' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO('TARSU',CONTR.COD_FISCALE) = '${filtroStato}'"""
                }
                if (tipiTributo.find { it == 'ICIAP' }) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO('ICIAP',CONTR.COD_FISCALE) = '${filtroStato}'"""
                }
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'ICP' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO('ICP',CONTR.COD_FISCALE) = '${filtroStato}'"""
                }
                if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TOSAP' })) {
                    if (!(tempString.isEmpty())) tempString += filtroJoin
                    tempString += """F_CONT_ATTIVO('TOSAP',CONTR.COD_FISCALE) = '${filtroStato}'"""
                }
            }
            sqlFiltri += "AND (" + tempString + ") "
        }

        if (tipiTributo.size() > 0) {

            sqlTabelleExtra += ", PRATICHE_TRIBUTO PRTR"
            sqlJoinExtra += "AND CONTR.COD_FISCALE = PRTR.COD_FISCALE (+) "
            flagTabPratiche = true
            sqlTabelleExtra += ", VERSAMENTI VERS"
            sqlJoinExtra += "AND CONTR.COD_FISCALE = VERS.COD_FISCALE (+) "
            flagTabVersamenti = true

            tempString = "'" + tipiTributo.join("','") + "'"
            sqlFiltri += "AND (NVL(PRTR.TIPO_TRIBUTO,'') IN (${tempString}) OR NVL(VERS.TIPO_TRIBUTO,'') IN (${tempString})) "
        }

        if ((tipiPratica.size() > 0) || (tipiTributo.size() > 0)) {

            flagPratiche = true
        }

        if ((parametriRicerca.fonteVersamento != null) || (parametriRicerca.ordinarioVersamento == true) ||
                (parametriRicerca.tipoVersamento != null) || (parametriRicerca.rataVersamento != null) ||
                (parametriRicerca.tipoPraticaVersamento != null) || (parametriRicerca.statoPraticaVersamento != null) ||
                (parametriRicerca.ruoloVersamento != null) || (parametriRicerca.progrDocVersamento != null) ||
                (parametriRicerca.annoDaVersamento != null) || (parametriRicerca.annoAVersamento != null) ||
                (parametriRicerca.pagamentoDaVersamento != null) || (parametriRicerca.pagamentoAVersamento != null) ||
                (parametriRicerca.registrazioneDaVersamento != null) || (parametriRicerca.registrazioneAVersamento != null) ||
                (parametriRicerca.importoDaVersamento != null) || (parametriRicerca.importoAVersamento != null) ||
                (parametriRicerca.soloConVersamenti == true)) {

            flagVersamenti = true
        }

        if (flagPratiche != false) {

            if (flagTabPratiche == false) {
                sqlTabelleExtra += ", PRATICHE_TRIBUTO PRTR"
                sqlJoinExtra += "AND CONTR.COD_FISCALE = PRTR.COD_FISCALE (+) "
                flagTabPratiche = true
            }

            if (tipiPratica.size() > 0) {
                tempString = "'" + tipiPratica.join("','") + "'"
                sqlFiltri += "AND NVL(PRTR.TIPO_PRATICA,'') IN (${tempString}) "
                sqlCampiExtra += ",PRTR.TIPO_TRIBUTO AS TIPO_TRIBUTO"
                flagTipoTributo = true
                sqlCampiExtra += ",PRTR.TIPO_PRATICA AS TIPO_PRATICA"
                flagTipoPratica = true

                if (tipiPratica.find { it == 'L' }) {

                    sqlTabelleExtra += ", TIPI_ATTO PRTRTA"
                    sqlJoinExtra += "AND PRTR.TIPO_ATTO = PRTRTA.TIPO_ATTO (+) "
                    sqlCampiExtra += ",PRTRTA.DESCRIZIONE AS PRAT_TIPO_ATTO"
                    sqlCampiExtra += ",PRTR.IMPORTO_TOTALE AS PRAT_IMP_TOTALE"
                    sqlCampiExtra += ",PRTR.IMPORTO_RIDOTTO AS PRAT_IMP_RIDOTTO"
                    flagTipoPraticaL = true
                }
            }
        }

        if ((parametriRicerca.tipoContatto != null) || (parametriRicerca.annoContatto != null)) {

            sqlTabelleExtra += ", CONTATTI_CONTRIBUENTE COCO"
            sqlJoinExtra += "AND CONTR.COD_FISCALE = COCO.COD_FISCALE (+) "
            sqlTabelleExtra += ", TIPI_CONTATTO TICO"
            sqlJoinExtra += "AND COCO.TIPO_CONTATTO = TICO.TIPO_CONTATTO (+) "
            sqlTabelleExtra += ", TIPI_RICHIEDENTE TIRI"
            sqlJoinExtra += "AND COCO.TIPO_RICHIEDENTE = TIRI.TIPO_RICHIEDENTE (+) "

            sqlCampiExtra += ",COCO.TIPO_CONTATTO|| ' - ' || TICO.DESCRIZIONE AS TIPO_CONTATTO"
            sqlCampiExtra += ",COCO.ANNO AS ANNO_CONTATTO"
            sqlCampiExtra += ",COCO.DATA AS DATA_CONTATTO"
            sqlCampiExtra += ",COCO.TIPO_TRIBUTO AS TIPO_TRIBUTO_CONTATTO"
            sqlCampiExtra += ",TIRI.DESCRIZIONE AS TIPO_RICHIEDENTE"
            flagContatti = true

            if (parametriRicerca.tipoContatto != null) {
                if (parametriRicerca.tipoContatto != -1) {
                    filtri << ['tipoContatto': parametriRicerca.tipoContatto]
                    sqlFiltri += "AND (COCO.TIPO_CONTATTO + 0) = :tipoContatto "
                } else {
                    sqlFiltri += "AND COCO.TIPO_CONTATTO IS NOT NULL "
                }
            }
            if (parametriRicerca.annoContatto != null) {
                filtri << ['annoContatto': parametriRicerca.annoContatto]
                sqlFiltri += "AND COCO.ANNO = :annoContatto "
            }
            if (tipiTributo.size() > 0) {
                tempString = "'" + tipiTributo.join("','") + "'"
                sqlFiltri += "AND COCO.TIPO_TRIBUTO||'' IN (${tempString}) "
            }
        }
        if ((parametriRicerca.titoloDocumento) || (parametriRicerca.nomeFileDocumento) ||
                (parametriRicerca.validoDaDocumento != null) || (parametriRicerca.validoADocumento != null)) {

            sqlTabelleExtra += ", DOCUMENTI_CONTRIBUENTE DOCO"
            sqlJoinExtra += "AND CONTR.COD_FISCALE = DOCO.COD_FISCALE (+) "

            sqlCampiExtra += ",DOCO.TITOLO AS DOC_TITOLO"
            sqlCampiExtra += ",DECODE(DOCO.DATA_INSERIMENTO,NULL,'',TO_CHAR(DOCO.DATA_INSERIMENTO,'dd/mm/yyyy')) AS DOC_DATA_INSERIMENTO"
            sqlCampiExtra += ",DECODE(DOCO.VALIDITA_DAL,NULL,'',TO_CHAR(DOCO.VALIDITA_DAL,'dd/mm/yyyy')) AS DOC_VALIDITA_DAL"
            sqlCampiExtra += ",DECODE(DOCO.VALIDITA_AL,NULL,'',TO_CHAR(DOCO.VALIDITA_AL,'dd/mm/yyyy'))  AS DOC_VALIDITA_AL"
            sqlCampiExtra += ",DOCO.INFORMAZIONI AS DOC_INFORMAZIONI"
            sqlCampiExtra += ",DOCO.NOTE AS DOC_NOTE"
            sqlCampiExtra += ",DOCO.NOME_FILE AS DOC_NOME_FILE"
            flagDocumenti = true

            if (parametriRicerca.titoloDocumento) {
                tempString = parametriRicerca.titoloDocumento.trim().toUpperCase()
                filtri << ['titoloDocumento': tempString]
                sqlFiltri += "AND UPPER(DOCO.TITOLO) like(:titoloDocumento) "
            }
            if (parametriRicerca.nomeFileDocumento) {
                tempString = parametriRicerca.nomeFileDocumento.trim().toUpperCase()
                filtri << ['nomeFileDocumento': tempString]
                sqlFiltri += "AND UPPER(DOCO.NOME_FILE) like(:nomeFileDocumento) "
            }
            if (parametriRicerca.validoDaDocumento) {
                filtri << ['validoDaDocumento': parametriRicerca.validoDaDocumento]
                sqlFiltri += "AND DOCO.VALIDITA_DAL >= :validoDaDocumento "
            }
            if (parametriRicerca.validoADocumento) {
                filtri << ['validoADocumento': parametriRicerca.validoADocumento]
                sqlFiltri += "AND DOCO.VALIDITA_AL <= :validoADocumento "
            }
        }

        if (flagVersamenti != false) {

            if (flagTabVersamenti == false) {
                sqlTabelleExtra += ", VERSAMENTI VERS"
                sqlJoinExtra += "AND CONTR.COD_FISCALE = VERS.COD_FISCALE (+) "
                flagTabVersamenti = true
            }

            sqlTabelleExtra += ", PRATICHE_TRIBUTO VEPR"
            sqlJoinExtra += "AND VERS.PRATICA = VEPR.PRATICA (+) "
            sqlTabelleExtra += ", TIPI_STATO VEPRTS"
            sqlJoinExtra += "AND VEPR.STATO_ACCERTAMENTO = VEPRTS.TIPO_STATO (+) "
            sqlTabelleExtra += ", CARICHI_TARSU VECATA"
            sqlJoinExtra += "AND VERS.ANNO = VECATA.ANNO (+) "

            sqlCampiExtra += ",VERS.SEQUENZA AS VERS_SEQUENZA"

            sqlCampiExtra += ",VERS.TIPO_TRIBUTO AS VERS_TIPO_TRIBUTO"
            sqlCampiExtra += ",VEPR.TIPO_PRATICA AS VERS_TIPO_PRATICA"
            sqlCampiExtra += ",VEPRTS.DESCRIZIONE AS VERS_STATO_PRATICA"
            sqlCampiExtra += ",VERS.ANNO AS VERS_ANNO"
            sqlCampiExtra += ",VERS.RATA AS VERS_RATA"
            sqlCampiExtra += ",VERS.TIPO_VERSAMENTO AS VERS_TIPO"
            sqlCampiExtra += ",VERS.IMPORTO_VERSATO AS VERS_IMP_VERSATO"
            sqlCampiExtra += ",DECODE(VERS.DATA_PAGAMENTO,NULL,'',TO_CHAR(VERS.DATA_PAGAMENTO,'dd/mm/yyyy')) AS VERS_DATA_PAG"
            sqlCampiExtra += ",DECODE(VERS.DATA_REG,NULL,'',TO_CHAR(VERS.DATA_REG,'dd/mm/yyyy')) AS VERS_DATA_REG"
            sqlCampiExtra += ",VERS.FONTE AS VERS_FONTE"
            sqlCampiExtra += ",VERS.DOCUMENTO_ID AS VERS_PROG_DOC"

            if (tipiTributo.find { it in ['ICI', 'TASI', 'ICIAP'] }) {

                sqlCampiExtra += ",VERS.FABBRICATI AS VERS_NUM_FAB"

                sqlCampiExtra += ",VERS.NUM_FABBRICATI_AB AS VERS_NUM_FAB_AB"
                sqlCampiExtra += ",VERS.AB_PRINCIPALE AS VERS_AB"

                sqlCampiExtra += ",VERS.NUM_FABBRICATI_TERRENI AS VERS_NUM_FAB_TE"
                sqlCampiExtra += ",VERS.TERRENI_ERARIALE AS VERS_TER"
                sqlCampiExtra += ",VERS.TERRENI_AGRICOLI AS VERS_TER_ER"
                sqlCampiExtra += ",VERS.TERRENI_COMUNE AS VERS_TER_CM"

                sqlCampiExtra += ",VERS.NUM_FABBRICATI_AREE AS VERS_NUM_FAB_AF"
                sqlCampiExtra += ",VERS.AREE_FABBRICABILI AS VERS_AF"
                sqlCampiExtra += ",VERS.AREE_ERARIALE AS VERS_AF_ER"
                sqlCampiExtra += ",VERS.AREE_COMUNE AS VERS_AF_CM"

                sqlCampiExtra += ",VERS.NUM_FABBRICATI_ALTRI AS VERS_NUM_FAB_AL"
                sqlCampiExtra += ",VERS.ALTRI_FABBRICATI AS VERS_FAB_AL"
                sqlCampiExtra += ",VERS.ALTRI_ERARIALE AS VERS_FAB_AL_ER"
                sqlCampiExtra += ",VERS.ALTRI_COMUNE AS VERS_FAB_AL_CM"

                sqlCampiExtra += ",VERS.NUM_FABBRICATI_RURALI AS VERS_NUM_FAB_RU"
                sqlCampiExtra += ",VERS.RURALI AS VERS_RUR"
                sqlCampiExtra += ",VERS.RURALI_ERARIALE AS VERS_RUR_ER"
                sqlCampiExtra += ",VERS.RURALI_COMUNE AS VERS_RUR_CM"

                sqlCampiExtra += ",VERS.NUM_FABBRICATI_D AS VERS_NUM_FAB_D"
                sqlCampiExtra += ",VERS.FABBRICATI_D AS VERS_FAB_D"
                sqlCampiExtra += ",VERS.FABBRICATI_D_ERARIALE AS VERS_FAB_D_ER"
                sqlCampiExtra += ",VERS.FABBRICATI_D_COMUNE AS VERS_FAB_D_CM"

                sqlCampiExtra += ",VERS.NUM_FABBRICATI_MERCE AS VERS_NUM_FAB_ME"
                sqlCampiExtra += ",VERS.FABBRICATI_MERCE AS VERS_FAB_ME"
                sqlCampiExtra += ",VERS.DETRAZIONE AS VERS_DETRAZIONE"
                flagVersamentiICI = true
            }

            if (tipiTributo.find { it == 'TARSU' }) {

                sqlCampiExtra += ",VERS.SPESE_SPEDIZIONE AS VERS_SPE_SPED"
                sqlCampiExtra += ",VERS.SPESE_MORA AS VERS_SPE_MORA"

                sqlCampiExtra += """,DECODE(VERS.PRATICA,NULL,
										F_IMPORTI_ANNO_TARSU(VERS.COD_FISCALE,VERS.ANNO,VERS.TIPO_TRIBUTO,VERS.SEQUENZA,VERS.RUOLO,VERS.RATA,'IMPOSTA'),
																								F_IMPORTI_ACC(VERS.PRATICA,'N','LORDO')) AS VERS_IMP_DOV"""
                sqlCampiExtra += """,DECODE(VERS.PRATICA,NULL,
										F_IMPORTI_ANNO_TARSU(VERS.COD_FISCALE,VERS.ANNO,VERS.TIPO_TRIBUTO,VERS.SEQUENZA,VERS.RUOLO,VERS.RATA,'NETTO'),
																								F_IMPORTI_ACC(VERS.PRATICA,'N','NETTO')) AS VERS_IMPOSTA"""
                sqlCampiExtra += """,DECODE(VERS.PRATICA,NULL,
										F_IMPORTI_ANNO_TARSU(VERS.COD_FISCALE,VERS.ANNO,VERS.TIPO_TRIBUTO,VERS.SEQUENZA,VERS.RUOLO,VERS.RATA,'ECA'),
													F_IMPORTI_ACC(VERS.PRATICA,'N','ADD_ECA') + F_IMPORTI_ACC(VERS.PRATICA,'N','MAG_ECA')) AS VERS_ADD_ECA"""
                sqlCampiExtra += """,DECODE(VERS.PRATICA,NULL,
										F_IMPORTI_ANNO_TARSU(VERS.COD_FISCALE,VERS.ANNO,VERS.TIPO_TRIBUTO,VERS.SEQUENZA,VERS.RUOLO,VERS.RATA,'ADD_PRO'),
																								F_IMPORTI_ACC(VERS.PRATICA,'N','ADD_PRO')) AS VERS_ADD_PRO"""
                sqlCampiExtra += """,DECODE(NVL(VECATA.MAGGIORAZIONE_TARES,0),0,TO_NUMBER(NULL),DECODE(VERS.PRATICA,NULL,
										F_IMPORTI_ANNO_TARSU(VERS.COD_FISCALE,VERS.ANNO,VERS.TIPO_TRIBUTO,VERS.SEQUENZA,VERS.RUOLO,VERS.RATA,'MAG_TAR'),
																								F_IMPORTI_ACC(VERS.PRATICA,'N','MAGGIORAZIONE'))) AS VERS_MAG_TAR"""

                sqlCampiExtra += ",DECODE(VERS.PRATICA,NULL,TO_NUMBER(NULL),F_IMPORTI_ACC(VERS.PRATICA,'S','LORDO')) AS VERS_IMPORTO_RID"
                sqlCampiExtra += ",DECODE(VERS.PRATICA,NULL,TO_NUMBER(NULL),F_IMPORTI_ACC(VERS.PRATICA,'S','NETTO')) AS VERS_IMPOSTA_RID"
                sqlCampiExtra += ",DECODE(VERS.PRATICA,NULL,TO_NUMBER(NULL),F_IMPORTI_ACC(VERS.PRATICA,'N','INTERESSI')) AS VERS_IMP_INTERESSI"
                sqlCampiExtra += ",DECODE(VERS.PRATICA,NULL,TO_NUMBER(NULL),F_IMPORTI_ACC(VERS.PRATICA,'N','SANZIONI')) AS VERS_IMP_SANZIONI"
                sqlCampiExtra += ",DECODE(VERS.PRATICA,NULL,TO_NUMBER(NULL),F_IMPORTI_ACC(VERS.PRATICA,'S','SANZIONI')) AS VERS_IMP_SANZIONI_RID"
                sqlCampiExtra += ",DECODE(VERS.PRATICA,NULL,TO_NUMBER(NULL),F_IMPORTI_ACC(VERS.PRATICA,'S','SPESE')) AS VERS_IMP_SPESE"
                sqlCampiExtra += ",DECODE(NVL(VECATA.MAGGIORAZIONE_TARES,0),0,TO_NUMBER(NULL),VERS.MAGGIORAZIONE_TARES) AS VERS_IMP_MAG_TAR"

                sqlCampiExtra += ",DECODE(VERS.ID_COMPENSAZIONE,NULL,'-','Si') AS VERS_COMP"
                flagVersamentiTAR = true
            }

            if (tipiTributo.size() > 0) {
                tempString = "'" + tipiTributo.join("','") + "'"
                sqlFiltri += "AND NVL(VERS.TIPO_TRIBUTO,'') IN (${tempString}) "
            }

            if (parametriRicerca.fonteVersamento != null) {
                if (parametriRicerca.fonteVersamento == -1) {
                    sqlFiltri += "AND VERS.FONTE IS NOT NULL "
                } else {
                    filtri << ['fonteVersamento': parametriRicerca.fonteVersamento]
                    sqlFiltri += "AND NVL(VERS.FONTE,'') = :fonteVersamento "
                }
            }
            if ((tipiTributo.size() > 0) && (tipiTributo.find { it in ['ICI', 'TASI', 'CUNI'] })) {
                if (parametriRicerca.tipoVersamento != null) {
                    if (parametriRicerca.tipoVersamento == 'T') {
                        sqlFiltri += "AND VERS.TIPO_VERSAMENTO IS NOT NULL "
                    } else {
                        filtri << ['tipoVersamento': parametriRicerca.tipoVersamento]
                        sqlFiltri += "AND NVL(VERS.TIPO_VERSAMENTO,'') = :tipoVersamento "
                    }
                }
                if (parametriRicerca.rataVersamento != null) {
                    if (parametriRicerca.rataVersamento == 'T') {
                        sqlFiltri += "AND VERS.RATA IS NOT NULL "
                    } else {
                        filtri << ['rataVersamento': parametriRicerca.rataVersamento]
                        sqlFiltri += "AND NVL(VERS.RATA,'') = :rataVersamento "
                    }
                }
            }
            if (parametriRicerca.ordinarioVersamento == true) {
                sqlFiltri += "AND VERS.PRATICA IS NULL "
            } else {
                if (parametriRicerca.tipoPraticaVersamento != null) {
                    if (parametriRicerca.tipoPraticaVersamento == 'T') {
                        sqlFiltri += "AND VEPR.TIPO_PRATICA IS NOT NULL "
                    } else {
                        filtri << ['tipoPraticaVersamento': parametriRicerca.tipoPraticaVersamento]
                        sqlFiltri += "AND NVL(VEPR.TIPO_PRATICA,'') = :tipoPraticaVersamento "
                    }
                }
                if (parametriRicerca.statoPraticaVersamento != null) {
                    if (parametriRicerca.statoPraticaVersamento == '-') {
                        sqlFiltri += "AND VEPR.STATO_ACCERTAMENTO IS NOT NULL "
                    } else {
                        filtri << ['statoPraticaVersamento': parametriRicerca.statoPraticaVersamento]
                        sqlFiltri += "AND NVL(VEPR.STATO_ACCERTAMENTO,'') = :statoPraticaVersamento "
                    }
                }
            }
            if (parametriRicerca.ruoloVersamento != null) {
                filtri << ['ruoloVersamento': parametriRicerca.ruoloVersamento]
                sqlFiltri += "AND VERS.RUOLO = :ruoloVersamento "
            }
            if (parametriRicerca.progrDocVersamento != null) {
                if (parametriRicerca.progrDocVersamento == -1) {
                    sqlFiltri += "AND VERS.DOCUMENTO_ID IS NOT NULL "
                } else {
                    filtri << ['progrDocVersamento': parametriRicerca.progrDocVersamento]
                    sqlFiltri += "AND VERS.DOCUMENTO_ID = :progrDocVersamento "
                }
            }
            if (parametriRicerca.annoDaVersamento != null) {
                filtri << ['annoDaVersamento': parametriRicerca.annoDaVersamento]
                sqlFiltri += "AND VERS.ANNO >= :annoDaVersamento "
            }
            if (parametriRicerca.annoAVersamento != null) {
                filtri << ['annoAVersamento': parametriRicerca.annoAVersamento]
                sqlFiltri += "AND VERS.ANNO <= :annoAVersamento "
            }
            if (parametriRicerca.pagamentoDaVersamento != null) {
                filtri << ['pagamentoDaVersamento': parametriRicerca.pagamentoDaVersamento]
                sqlFiltri += "AND VERS.DATA_PAGAMENTO >= :pagamentoDaVersamento "
            }
            if (parametriRicerca.pagamentoAVersamento != null) {
                filtri << ['pagamentoAVersamento': parametriRicerca.pagamentoAVersamento]
                sqlFiltri += "AND VERS.DATA_PAGAMENTO <= :pagamentoAVersamento "
            }
            if (parametriRicerca.registrazioneDaVersamento != null) {
                filtri << ['registrazioneDaVersamento': parametriRicerca.registrazioneDaVersamento]
                sqlFiltri += "AND VERS.DATA_REG >= :registrazioneDaVersamento "
            }
            if (parametriRicerca.registrazioneAVersamento != null) {
                filtri << ['registrazioneAVersamento': parametriRicerca.registrazioneAVersamento]
                sqlFiltri += "AND VERS.DATA_REG <= :registrazioneAVersamento "
            }
            if (parametriRicerca.importoDaVersamento != null) {
                filtri << ['importoDaVersamento': parametriRicerca.importoDaVersamento]
                sqlFiltri += "AND VERS.IMPORTO_VERSATO >= :importoDaVersamento "
            }
            if (parametriRicerca.importoAVersamento != null) {
                filtri << ['importoAVersamento': parametriRicerca.importoAVersamento]
                sqlFiltri += "AND VERS.IMPORTO_VERSATO <= :importoAVersamento "
            }
            if (parametriRicerca.soloConVersamenti) {
                sqlFiltri += """ AND (VERS.PRATICA IS NULL)
                                 AND not exists
                                 (select 'x'
                                          from pratiche_tributo
                                         where pratiche_tributo.cod_fiscale = CONTR.COD_FISCALE)
                                   AND not exists
                                 (select 'x'
                                          from rapporti_tributo
                                         where rapporti_tributo.cod_fiscale = CONTR.COD_FISCALE) 
                            """
            }
        }

        if (parametriRicerca.campiExtra != true) {
            sqlCampiExtra = ""
        }


        if (flagContribuenti) {
            sqlCampiExtra += ",nvl(CONTR.COD_FISCALE, SOGG.COD_FISCALE) AS COD_FISCALE_CONT "
            sqlCampiExtra += ",CONTR.NI AS NI_CONT "
        }

        sql = """
				SELECT DISTINCT
					SOGG.NI,
					SOGG.TIPO_RESIDENTE AS TIPO_RESIDENTE,
					SOGG.FASCIA AS FASCIA_RESIDENTE,
					SOGG.COGNOME_NOME,
					SOGG.COD_FISCALE AS COD_FISCALE,
					SOGG.PARTITA_IVA,
					SOGG.DATA_NAS,
					DECODE(SOGG.COD_VIA,NULL,SOGG.DENOMINAZIONE_VIA,AVIE.DENOM_UFF) ||
									DECODE(SOGG.NUM_CIV, NULL, '', ', ' || SOGG.NUM_CIV) ||
											DECODE(SOGG.SUFFISSO, NULL, '', '/' || SOGG.SUFFISSO) INDIRIZZO,
					COMRES.DENOMINAZIONE AS COMUNE_RESIDENZA,
					TRANSLATE(SOGG.COGNOME_NOME, '/',' ') COG_NOM,
					UPPER(REPLACE(SOGG.COGNOME,' ','')) COGNOME,
					UPPER(REPLACE(SOGG.NOME,' ','')) NOME,
					ANDV.DESCRIZIONE AS STATO_EVENTO,
					SOGG.DATA_ULT_EVE AS DATA_ULT_EVE,
					DECODE(COMEVE.DENOMINAZIONE,NULL,'',COMEVE.DENOMINAZIONE || 
									DECODE(PROEVE.SIGLA,NULL,'',' (' || PROEVE.SIGLA|| ')')) AS COMUNE_EVENTO
					${sqlCampiExtra}
				FROM
					SOGGETTI SOGG,
					ARCHIVIO_VIE AVIE,
					AD4_COMUNI COMRES,
					AD4_PROVINCIE PRORES,
					WEB_ANADEV ANDV, 
					AD4_COMUNI COMEVE,
					AD4_PROVINCIE PROEVE
					${sqlTabelleExtra}
				WHERE
					SOGG.COD_VIA = AVIE.COD_VIA (+) AND
					SOGG.COD_PRO_RES = COMRES.PROVINCIA_STATO (+) AND
					SOGG.COD_COM_RES = COMRES.COMUNE (+) AND
					COMRES.PROVINCIA_STATO = PRORES.PROVINCIA (+) AND
					SOGG.STATO = ANDV.COD_EV (+) AND
					SOGG.COD_PRO_EVE = COMEVE.PROVINCIA_STATO (+) AND
					SOGG.COD_COM_EVE = COMEVE.COMUNE (+) AND
					COMEVE.PROVINCIA_STATO = PROEVE.PROVINCIA (+)
					${sqlJoinExtra}
					${sqlFiltri}
		"""

        if (!sortBy) {
            sql += """
				ORDER BY
					SOGG.COGNOME_NOME ASC,
					2 ASC, 3 ASC, 4 ASC, 1 ASC
			"""
        }

        sqlTotali = """
				SELECT
					COUNT(*) AS TOT_COUNT
				FROM ($sql)
		"""

        int totalCount = 0

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def totali = eseguiQuery("${sqlTotali}", filtri, params, true)[0]

        def totals = [
                totalCount: totali.TOT_COUNT,
        ]

        def results = eseguiQuery("${sql}", filtri, params)

        def records = []

        results.each {

            def record = [:]

            record.id = it['NI']

            def niContribuente = it['NI_CONT'] as BigDecimal
            record.contribuente = ((niContribuente ?: 0) > 0) ? 'Si' : '-'

            def tipoResidente = it['TIPO_RESIDENTE'] as Short
            def fasciaResidente = it['FASCIA_RESIDENTE'] as Short

            if (integrazioneGSD) {
                record.gsd = (tipoResidente != 0) ? '-' : 'Si'

                if (tipoResidente == 0) {
                    switch (fasciaResidente) {
                        default:
                            record.residente = '-'
                            break
                        case 1:
                            record.residente = 'Si'
                            break
                        case 3:
                            record.residente = 'NI'
                            break
                    }
                } else {
                    record.residente = '-'
                }
            } else {
                record.gsd = '-'
                record.residente = (tipoResidente != 0) ? '-' : 'Si'
            }

            record.cognomeNome = it['COGNOME_NOME']
            record.codFiscale = it['COD_FISCALE']
            record.partitaIva = it['PARTITA_IVA']
            record.dataNas = it['DATA_NAS']
            record.codFiscaleCont = it['COD_FISCALE_CONT']
            record.indirizzo = it['INDIRIZZO']
            record.comuneResidenza = it['COMUNE_RESIDENZA']

            record.statoEvento = it['STATO_EVENTO']
            record.dataUltEve = it['DATA_ULT_EVE']
            record.comuneEvento = it['COMUNE_EVENTO']

            if (flagPresso != false) {
                record.pressoFonte = it['PRESSO_FONTE']
                record.pressoCognNome = it['PRESSO_COGN_NOME']
                record.pressoCodFis = it['PRESSO_COD_FIS']
                record.pressoIndirizzo = it['PRESSO_INDIRIZZO']
                record.pressoComune = it['PRESSO_COMUNE']
                record.pressoNote = it['PRESSO_NOTE']
            }

            if (flagRappresentante != false) {
                record.rappCognNome = it['RAPP_COGN_NOME']
                record.rappCodFis = it['RAPP_COD_FIS']
                record.rappTipoCarica = it['RAPP_TIPO_CARICA']
                record.rappIndirizzo = it['RAPP_INDIRIZZO']
                record.rappComune = it['RAPP_COMUNE']
            }

            if (flagEredi != false) {
                record.eredFonte = it['ERED_FONTE']
                record.eredCognNome = it['ERED_COGN_NOME']
                record.eredCodFis = it['ERED_COD_FIS']
                record.eredIndirizzo = it['ERED_INDIRIZZO']
                record.eredComune = it['ERED_COMUNE']
                record.eredNote = it['ERED_NOTE']
            }

            if (flagRecapiti != false) {
                record.recaTipoTributo = it['RECA_TIPO_TRIBUTO']
                record.recaTipoRecapito = it['RECA_TIPO_RECAPITO']
                record.recaDescrizione = it['RECA_DESCRIZIONE']
                record.recaIndirizzo = it['RECA_INDIRIZZO']
                record.recaComune = it['RECA_COMUNE']
                record.recaPresso = it['RECA_PRESSO']
                record.recaNote = it['RECA_NOTE']
                record.recaDal = it['RECA_DAL']
                record.recaAl = it['RECA_AL']
            }

            if (flagFamiliari != false) {
                record.familAnno = it['FAMIL_ANNO']
                record.familDal = it['FAMIL_DAL']
                record.familAl = it['FAMIL_AL']
                record.familNumero = it['FAMIL_NUMERO']
                record.familNote = it['FAMIL_NOTE']
            }

            if (flagDeleghe != false) {
                record.delegTipoTributo = it['DELEG_TIPO_TRIBUTO']
                record.delegIBAN = it['DELEG_IBAN']
                record.delegDescr = it['DELEG_DESCRIZIONE']
                record.delegCodFisInt = it['DELEG_COD_FIS_INT']
                record.delegCognNomeInt = it['DELEG_COGN_NOME_INT']
                record.delegCessata = it['DELEG_CESSATA']
                record.delegDataRitiro = it['DELEG_DATA_RITIRO']
                record.delegRataUnica = it['DELEG_RATA_UNICA']
                record.delegNote = it['DELEG_NOTE']
                record.delegCC = it['DELEG_CONTO_CORRENTE']
            }

            if (flagTipoTributo != false) {
                record.tipoTributo = it['TIPO_TRIBUTO']
            }
            if (flagTipoPratica != false) {
                record.tipoPratica = it['TIPO_PRATICA']
            }
            if (flagTipoPraticaL != false) {
                record.pratTipoAtto = it['PRAT_TIPO_ATTO']
                record.pratImpTotale = it['PRAT_IMP_TOTALE']
                record.pratImpRidotto = it['PRAT_IMP_RIDOTTO']
            }

            if (flagContatti != false) {
                record.tipoContatto = it['TIPO_CONTATTO']
                record.annoContatto = it['ANNO_CONTATTO']
                record.dataContatto = it['DATA_CONTATTO']
                record.tipoTributoContatto = it['TIPO_TRIBUTO_CONTATTO']
                record.tipoRichiedente = it['TIPO_RICHIEDENTE']
            }

            if (flagDocumenti != false) {
                record.docTitolo = it['DOC_TITOLO']
                record.docDataInserimento = it['DOC_DATA_INSERIMENTO']
                record.docValiditaDal = it['DOC_VALIDITA_DAL']
                record.docValiditaAl = it['DOC_VALIDITA_AL']
                record.docInformazioni = it['DOC_INFORMAZIONI']
                record.docNote = it['DOC_NOTE']
                record.docNomeFile = it['DOC_NOME_FILE']
            }

            if (flagVersamenti != false) {
                record.versTipoTributo = it['VERS_TIPO_TRIBUTO']
                record.versTipoPratica = it['VERS_TIPO_PRATICA']
                record.versStatoPratica = it['VERS_STATO_PRATICA']
                record.versAnno = it['VERS_ANNO']
                record.versRata = it['VERS_RATA']
                record.versTipo = it['VERS_TIPO']
                record.versImpVersato = it['VERS_IMP_VERSATO']
                record.versDataPag = it['VERS_DATA_PAG']
                record.versDataReg = it['VERS_DATA_REG']
                record.versFonte = it['VERS_FONTE']
                record.versProgDoc = it['VERS_PROG_DOC']

                if (flagVersamentiICI != false) {

                    record.versNumFab = it['VERS_NUM_FAB']

                    record.versNumFabAb = it['VERS_NUM_FAB_AB']
                    record.versAb = it['VERS_AB']

                    record.versNumFabTe = it['VERS_NUM_FAB_TE']
                    record.versTer = it['VERS_TER']
                    record.versTerEr = it['VERS_TER_ER']
                    record.versTerCm = it['VERS_TER_CM']

                    record.versNumFabAF = it['VERS_NUM_FAB_AF']
                    record.versAF = it['VERS_AF']
                    record.versAfEr = it['VERS_AF_ER']
                    record.versAFCm = it['VERS_AF_CM']

                    record.versNumFabAl = it['VERS_NUM_FAB_AL']
                    record.versFabAl = it['VERS_FAB_AL']
                    record.versFabAlEr = it['VERS_FAB_AL_ER']
                    record.versFabAlCm = it['VERS_FAB_AL_CM']

                    record.versNumFabRu = it['VERS_NUM_FAB_RU']
                    record.versRur = it['VERS_RUR']
                    record.versRurEr = it['VERS_RUR_ER']
                    record.versRurCm = it['VERS_RUR_CM']

                    record.versNumFabD = it['VERS_NUM_FAB_D']
                    record.versFabD = it['VERS_FAB_D']
                    record.versFabDEr = it['VERS_FAB_D_ER']
                    record.versFabDCm = it['VERS_FAB_D_CM']

                    record.versNumFabMe = it['VERS_NUM_FAB_ME']
                    record.versFabMe = it['VERS_FAB_ME']
                    record.versDet = it['VERS_DETRAZIONE']
                }

                if (flagVersamentiTAR != false) {

                    record.versSpeSped = it['VERS_SPE_SPED']
                    record.versSpeMora = it['VERS_SPE_MORA']

                    record.versImpDov = it['VERS_IMP_DOV']
                    record.versImposta = it['VERS_IMPOSTA']
                    record.versAddECA = it['VERS_ADD_ECA']
                    record.versAddPro = it['VERS_ADD_PRO']
                    record.versMagTAR = it['VERS_MAG_TAR']

                    record.versImpDovRid = it['VERS_IMPORTO_RID']
                    record.versImpostaRid = it['VERS_IMPOSTA_RID']
                    record.versInteressi = it['VERS_IMP_INTERESSI']
                    record.versSanz = it['VERS_IMP_SANZIONI']
                    record.versSanzRid = it['VERS_IMP_SANZIONI_RID']
                    record.versImpSpese = it['VERS_IMP_SPESE']
                    record.versImpMagTAR = it['VERS_IMP_MAG_TAR']

                    record.versComp = it['VERS_COMP']
                }
            }

            records << record
        }

        return [lista: records, totale: totals.totalCount]
    }

    /**
     *
     * Stessi parametri di listaSoggetti,
     * tuttavia incorpora alcune funzioni estese per la generazione di report XLS
     * campiExtra : boolean	-> Crea elenco con campi aggiuntivi.
     * Se <> True riporta solo i dati dei soggetti / contribuenti
     * Se = Ture aggiunge i campi in base alle logiche specificate con i filtri
     *
     * @param filtri una mappa così strutturata
     def filtri = [  personaFisica: 		true
     , personaGiuridica: 	true
     , personaParticolare:	true
     , residente:			true
     , contribuente:		true
     , gsd:				true
     , codFiscale:			""
     , indirizzo:			""
     , comune:				""
     , provincia:			""
     , id:					""]
     * @param pageSize
     * @param activePage
     * @param listaFetch un array di proprietà da mettere in join per il fetch dei dati
     * @return
     */
    def listaSoggetti(def filtri, int pageSize, int activePage, def listaFetch, def sortBy = null) {

        String tempString

        /*
            Questo e' il nome dell'alias per la tabella Contribuenti utilizzato da Hibernate
            Se si tolgono o aggiungono Alias alla Soggetto.createCriteria() verificare attentamente il suo valore
         */
        String contrAlias

        Boolean flagContribuenti = false

        def tipiPratica = filtri.tipiPratica ?: []
        def tipiTributo = filtri.tipiTributo?.clone() ?: []

        if (tipiTributo.find { it == 'CUNI' }) {
            tipiTributo << 'ICP'
            tipiTributo << 'TOSAP'
        }

        PagedResultList elencoSoggetti = Soggetto.createCriteria().list(max: pageSize, offset: pageSize * activePage) {
            createAlias("comuneResidenza", "comRes", CriteriaSpecification.LEFT_JOIN)
            createAlias("comRes.ad4Comune", "comu", CriteriaSpecification.LEFT_JOIN)
            createAlias("archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)
            createAlias("comuneEvento", "comEve", CriteriaSpecification.LEFT_JOIN)
            createAlias("comEve.ad4Comune", "comuev", CriteriaSpecification.LEFT_JOIN)
            createAlias("comuev.provincia", "provev", CriteriaSpecification.LEFT_JOIN)
            createAlias("soggettoPresso", "sopr", CriteriaSpecification.LEFT_JOIN)
            createAlias("sopr.comuneResidenza", "socr", CriteriaSpecification.LEFT_JOIN)

            // ################################################################################################################################
            // Attenzione : più avanti si fa riferimento all'alias contr, che in base allo stato di
            //				 fatto è il nono alias nell'elenco, quindi diventa contr9_.
            //				 Se si aggiungono o tolgono Alias ricordarsi di ricontrollare tutti i riferimento a tale Alias.
            // ################################################################################################################################
            contrAlias = "contr9_"

            if (filtri.soloContribuenti) {
                createAlias("contribuenti", "contr", CriteriaSpecification.INNER_JOIN)
                flagContribuenti = true
            } else {
                if (filtri.contribuente || filtri.ricercaSoggCont) {
                    createAlias("contribuenti", "contr", CriteriaSpecification.LEFT_JOIN)
                    flagContribuenti = true
                }
            }

            if (filtri.id) {
                eq("id", Long.valueOf(filtri.id))
            }
            if (filtri.idEscluso) {
                ne("id", Long.valueOf(filtri.idEscluso))
            }

            if (filtri.cognome) {
                ilike("cognome", filtri.cognome.toLowerCase())
            }
            if (filtri.nome) {
                ilike("nome", filtri.nome.toLowerCase())
            }

            if (filtri.fonte && filtri.fonte instanceof FonteDTO) {
                eq("fonte.fonte", filtri.fonte.fonte)
            }

            if (filtri.codFiscale) {
                if (!filtri.ricercaSoggCont) {
                    // se sto cercando i contribuenti devo filtrare sulla proprietà
                    // codice fiscale della domain contribuente
                    if (filtri.contribuente) {
                        or {
                            ilike("contr.codFiscale", filtri.codFiscale.toLowerCase())
                            ilike("codFiscale", filtri.codFiscale.toLowerCase())
                            ilike("partitaIva", filtri.codFiscale.toLowerCase())

                            String sql = """
                            select coso.cod_fiscale
                                from contribuenti_cc_soggetti coso, cc_soggetti sogg
                                    where sogg.id_soggetto = coso.id_soggetto
                                    and lower(sogg.cod_fiscale_ric) like :codFiscale
                            """

                            def listaCfAssociati = sessionFactory.currentSession.createSQLQuery(sql).with {
                                setString('codFiscale', filtri.codFiscale.toLowerCase())
                                list()
                            }

                            if (!listaCfAssociati.empty) {
                                'in'("contr.codFiscale", listaCfAssociati)
                            }
                        }
                    } else {
                        or {
                            ilike("codFiscale", filtri.codFiscale.toLowerCase())
                            ilike("partitaIva", filtri.codFiscale.toLowerCase())
                        }
                    }
                } else {
                    // Si ricerca per CF su Contribuenti e Soggetti
                    or {
                        ilike("contr.codFiscale", filtri.codFiscale.toLowerCase())
                        ilike("codFiscale", filtri.codFiscale.toLowerCase())
                        ilike("partitaIva", filtri.codFiscale.toLowerCase())
                    }
                }
            }
            if (filtri.codContribuente) {
                eq("contr.codContribuente", filtri.codContribuente)
            }
            if (filtri.codFiscaleEscluso) {
                if (filtri.contribuente == "s") {
                    ne("contr.codFiscale", filtri.codFiscaleEscluso)
                } else {
                    ne("codFiscale", filtri.codFiscaleEscluso)
                }
            }
            if (filtri.indirizzo) {
                ilike("denominazioneVia", filtri.indirizzo)
            }
            if (filtri.comuneResidenza) {
                comuneResidenza {
                    ad4Comune {
                        eq("denominazione".filtri.comune)
                    }
                }
            }

            if (filtri.residente == "s") {
                and {
                    eq("tipoResidente", false)
                    eq("fascia", Integer.valueOf(1))
                }
            }
            if (filtri.residente == "n") {
                or {
                    eq("tipoResidente", true)
                    ne("fascia", Integer.valueOf(1))
                }
            }
            if (filtri.gsd == "s") {
                eq("tipoResidente", false)
            }
            if (filtri.gsd == "n") {
                eq("tipoResidente", true)
            }

            if (filtri.contribuente == "n") {
                DetachedCriteria subQuery = DetachedCriteria.forClass(Contribuente, "cont").setProjection(Projections.property("codFiscale"))
                subQuery.with {
                    add(Restrictions.eqProperty("cont.soggetto.id", "this.id"))
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("not exists", subQuery)
                add(exists)
            }

            if (filtri.statoContribuenteFilter?.isActive()) {
                def statoContribuenteSubQuery = getStatoContribuenteSubquery(filtri, "contr.codFiscale")
                add Subqueries.exists(statoContribuenteSubQuery)
            }


            if (filtri.personaFisica || filtri.personaGiuridica || filtri.personaParticolare) {
                or {
                    if (filtri.personaFisica) {
                        eq("tipo", "0")
                    }
                    if (filtri.personaGiuridica) {
                        eq("tipo", "1")
                    }
                    if (filtri.personaParticolare) {
                        eq("tipo", "2")
                    }
                }
            }

            if (filtri.pressoCognome) {
                ilike("sopr.cognome", filtri.pressoCognome)
            }
            if (filtri.pressoNome) {
                ilike("sopr.nome", filtri.pressoNome)
            }
            if (filtri.pressoCodFiscale) {
                ilike("sopr.codFiscale", filtri.pressoCodFiscale)
            }
            if (filtri.pressoIndirizzo) {
                ilike("sopr.denominazioneVia", filtri.pressoIndirizzo)
            }
            if (filtri.pressoComune) {
                and {
                    eq("socr.comune", filtri.pressoComune.comune)
                    eq("socr.provinciaStato", filtri.pressoComune.provinciaStato)
                }
            }
            if (filtri.pressoNi) {
                eq("sopr.id", filtri.pressoNi as Long)
            }
            if (filtri.pressoFonte != null) {
                if (filtri.pressoFonte == -1) {
                    isNotNull("sopr.fonte")
                } else {
                    eq("sopr.fonte.id", filtri.pressoFonte as Long)
                }
            }
            if (filtri.pressoNote) {
                ilike("sopr.note", filtri.pressoNote)
            }

            if (filtri.rappCognNome) {
                ilike("rappresentante", filtri.rappCognNome)
            }
            if (filtri.rappCodFis) {
                ilike("codFiscaleRap", filtri.rappCodFis)
            }
            if (filtri.rappTipoCarica != null) {
                if (filtri.rappTipoCarica != -1) {
                    eq("tipoCarica.id", filtri.rappTipoCarica as Long)
                } else {
                    isNotNull("tipoCarica.id")
                }
            }
            if (filtri.rappIndirizzo) {
                ilike("indirizzoRap", filtri.rappIndirizzo)
            }
            if (filtri.rappComune != null) {
                and {
                    eq("comuneRap.comune", filtri.rappComune.comune)
                    eq("comuneRap.provinciaStato", filtri.rappComune.provinciaStato)
                }
            }

            if ((filtri.erediCognome) || (filtri.erediNome) ||
                    (filtri.erediCodFiscale) || (filtri.erediIndirizzo) ||
                    (filtri.erediFonte != null) ||
                    (filtri.erediId != null) || (filtri.erediNote)) {

                DetachedCriteria subQuery = DetachedCriteria.forClass(EredeSoggetto, "erso").setProjection(Projections.property("id"))
                subQuery.with {
                    add(Restrictions.eqProperty("erso.soggetto", "this.id"))
                    createAlias("erso.soggettoEredeId", "ersoso", CriteriaSpecification.LEFT_JOIN)
                    if (filtri.erediCognome) {
                        add(Restrictions.ilike("ersoso.cognome", filtri.erediCognome))
                    }
                    if (filtri.erediNome) {
                        add(Restrictions.ilike("ersoso.nome", filtri.erediNome))
                    }
                    if (filtri.erediCodFiscale) {
                        add(Restrictions.ilike("ersoso.codFiscale", filtri.erediCodFiscale))
                    }
                    if (filtri.erediIndirizzo) {
                        add(Restrictions.ilike("ersoso.denominazioneVia", filtri.erediIndirizzo))
                    }
                    if (filtri.erediId != null) {
                        add(Restrictions.eq("ersoso.id", filtri.erediId as Long))
                    }
                    if (filtri.erediFonte != null) {
                        if (filtri.erediFonte == -1) {
                            add(Restrictions.isNotNull("ersoso.fonte"))
                        } else {
                            add(Restrictions.eq("ersoso.fonte.id", filtri.erediFonte as Long))
                        }
                    }
                    if (filtri.erediNote) {
                        add(Restrictions.ilike("erso.note", filtri.erediNote))
                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)
            }

            def recapTipiTributo = filtri.recapTipiTributo ?: []
            def recapTipiRecapito = filtri.recapTipiRecapito ?: []

            if ((recapTipiTributo.size() > 0) || (recapTipiRecapito.size() > 0) ||
                    (filtri.recapIndirizzo) || (filtri.recapDescr) ||
                    (filtri.recapPresso) || (filtri.recapNote) ||
                    (filtri.recapDal) || (filtri.recapAl)) {

                DetachedCriteria subQuery = DetachedCriteria.forClass(RecapitoSoggetto, "reso").setProjection(Projections.property("id"))
                subQuery.with {
                    add(Restrictions.eqProperty("reso.soggetto", "this.id"))
                    if (recapTipiTributo.size() > 0) {
                        add(Restrictions.'in'("reso.tipoTributo.id", recapTipiTributo))
                    }
                    if (recapTipiRecapito.size() > 0) {
                        add(Restrictions.'in'("reso.tipoRecapito.id", recapTipiRecapito))
                    }
                    if (filtri.recapIndirizzo) {
                        createAlias("reso.archivioVie", "revi", LEFT_JOIN)
                        add(Restrictions.ilike("revi.denomUff", filtri.recapIndirizzo))
                    }
                    if (filtri.recapDescr) {
                        add(Restrictions.ilike("reso.descrizione", filtri.recapDescr))
                    }
                    if (filtri.recapPresso) {
                        add(Restrictions.ilike("reso.presso", filtri.recapPresso))
                    }
                    if (filtri.recapNote) {
                        add(Restrictions.ilike("reso.note", filtri.recapNote))
                    }
                    if (filtri.recapDal != null) {
                        add(Restrictions.ge("reso.dal", filtri.recapDal))
                    }
                    if (filtri.recapAl != null) {
                        add(Restrictions.le("reso.al", filtri.recapAl))
                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)
            }

            if ((filtri.familAnno != null) || (filtri.familNote) ||
                    (filtri.familDal != null) || (filtri.familAl != null) ||
                    (filtri.familNumeroDa != null) || (filtri.familNumeroA != null)) {

                DetachedCriteria subQuery = DetachedCriteria.forClass(FamiliareSoggetto, "faso").setProjection(Projections.property("id"))
                subQuery.with {
                    add(Restrictions.eqProperty("faso.soggetto", "this.id"))
                    if (filtri.familAnno != null) {
                        add(Restrictions.eq("faso.anno", filtri.familAnno as Short))
                    }
                    if (filtri.familDal != null) {
                        add(Restrictions.ge("faso.dal", filtri.familDal))
                        add(Restrictions.gt("faso.al", filtri.familDal))
                    }
                    if (filtri.familAl != null) {
                        add(Restrictions.lt("faso.dal", filtri.familAl))
                        add(Restrictions.le("faso.al", filtri.familAl))
                    }
                    if (filtri.familNumeroDa != null) {
                        add(Restrictions.ge("faso.numeroFamiliari", filtri.familNumeroDa as Short))
                    }
                    if (filtri.familNumeroA != null) {
                        add(Restrictions.le("faso.numeroFamiliari", filtri.familNumeroA as Short))
                    }
                    if (filtri.familNote) {
                        add(Restrictions.ilike("faso.note", filtri.familNote))
                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)
            }

            def delegTipiTributo = filtri.delegTipiTributo ?: []

            if ((delegTipiTributo.size() > 0) ||
                    (filtri.delegIBAN) || (filtri.delegDescr) ||
                    (filtri.delegCodFisInt) || (filtri.delegCognNomeInt) ||
                    (filtri.delegCessata != null) || (filtri.delegRitiroDal != null) ||
                    (filtri.delegRitiroAl != null) || (filtri.delegRataUnica != null) || (filtri.delegNote)) {

                if (flagContribuenti == false) {
                    // Per le deleghe ci serve la join su contribuenti, non sempre presente
                    createAlias("contribuenti", "contr", CriteriaSpecification.LEFT_JOIN)
                    flagContribuenti = true
                }

                DetachedCriteria subQuery = DetachedCriteria.forClass(DelegheBancarie, "deba").setProjection(Projections.property("id"))
                subQuery.with {
                    add(Restrictions.eqProperty("deba.codFiscale", "contr.codFiscale"))
                    if (delegTipiTributo.size() > 0) {
                        add(Restrictions.'in'("deba.tipoTributo", delegTipiTributo))
                    }
                    if (filtri.delegIBAN) {
                        add(Restrictions.ilike("deba.contoCorrente", filtri.delegIBAN))
                    }
                    if (filtri.delegDescr) {

                    }
                    if (filtri.delegCodFisInt) {
                        add(Restrictions.ilike("deba.codiceFiscaleInt", filtri.delegCodFisInt))
                    }
                    if (filtri.delegCognNomeInt) {
                        add(Restrictions.ilike("deba.cognomeNomeInt", filtri.delegCognNomeInt))
                    }
                    if (filtri.delegCessata != null) {
                        if (filtri.delegCessata == true) {
                            add(Restrictions.eq("deba.flagDelegaCessata", filtri.delegCessata))
                        }
                        if (filtri.delegCessata == false) {
                            add(Restrictions.isNull("deba.flagDelegaCessata"))
                        }
                    }
                    if (filtri.delegRitiroDal != null) {
                        add(Restrictions.ge("deba.dataRitiroDelega", filtri.delegRitiroDal))
                    }
                    if (filtri.delegRitiroAl != null) {
                        add(Restrictions.le("deba.dataRitiroDelega", filtri.delegRitiroAl))
                    }
                    if (filtri.delegRataUnica != null) {
                        if (filtri.delegRataUnica == true) {
                            add(Restrictions.eq("deba.flagRataUnica", filtri.delegRataUnica))
                        }
                        if (filtri.delegRataUnica == false) {
                            add(Restrictions.isNull("deba.flagRataUnica"))
                        }
                    }
                    if (filtri.delegNote) {
                        add(Restrictions.ilike("deba.note", filtri.delegNote))
                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)
            }

            if (((filtri.statoAttivi) || (filtri.statoCessati)) && (filtri.statoAttivi != filtri.statoCessati)) {

                String filtroStato
                String filtroJoin

                if (filtri.statoAttivi) {
                    filtroStato = "SI"
                    filtroJoin = " OR "
                } else {
                    filtroStato = "NO"
                    filtroJoin = " AND "
                }

                tempString = ""

                if (filtri.annoStato) {

                    def annoStato = filtri.annoStato

                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'ICI' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO_ANNO('ICI',${contrAlias}.cod_fiscale,${annoStato}) = '${filtroStato}'"""
                    }
                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TASI' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO_ANNO('TASI',${contrAlias}.cod_fiscale,${annoStato}) = '${filtroStato}'"""
                    }
                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TARSU' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO_ANNO('TARSU',${contrAlias}.cod_fiscale,${annoStato}) = '${filtroStato}'"""
                    }
                    if (tipiTributo.find { it == 'ICIAP' }) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO_ANNO('ICIAP',${contrAlias}.cod_fiscale,${annoStato}) = '${filtroStato}'"""
                    }
                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'ICP' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO_ANNO('ICP',${contrAlias}.cod_fiscale,${annoStato}) = '${filtroStato}'"""
                    }
                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TOSAP' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO_ANNO('TOSAP',${contrAlias}.cod_fiscale,${annoStato}) = '${filtroStato}'"""
                    }
                } else {
                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'ICI' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO('ICI',${contrAlias}.cod_fiscale) = '${filtroStato}'"""
                    }
                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TASI' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO('TASI',${contrAlias}.cod_fiscale) = '${filtroStato}'"""
                    }
                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TARSU' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO('TARSU',${contrAlias}.cod_fiscale) = '${filtroStato}'"""
                    }
                    if (tipiTributo.find { it == 'ICIAP' }) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO('ICIAP',${contrAlias}.cod_fiscale) = '${filtroStato}'"""
                    }
                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'ICP' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO('ICP',${contrAlias}.cod_fiscale) = '${filtroStato}'"""
                    }
                    if ((tipiTributo.size() == 0) || (tipiTributo.find { it == 'TOSAP' })) {
                        if (!(tempString.isEmpty())) tempString += filtroJoin
                        tempString += """F_CONT_ATTIVO('TOSAP',${contrAlias}.cod_fiscale) = '${filtroStato}'"""
                    }
                }
                tempString = "(" + tempString + ")"
                sqlRestriction(tempString)
            }

            if (!tipiTributo.empty) {
                tempString = "'" + tipiTributo.join("','") + "'"
                sqlRestriction("""
					exists (
						select	distinct 
								prtr1.cod_fiscale
						from	pratiche_tributo prtr1
						where	prtr1.cod_fiscale = ${contrAlias}.cod_fiscale and
								prtr1.tipo_tributo in (${tempString})
					union
						select	distinct
								vers1.cod_fiscale
						from	versamenti vers1
						where	vers1.cod_fiscale = ${contrAlias}.cod_fiscale and
								vers1.tipo_tributo in (${tempString})
                    union
                        select distinct
                                stco.cod_fiscale
                        from stati_contribuente stco
                        where stco.cod_fiscale = ${contrAlias}.cod_fiscale
                        and stco.tipo_tributo in (${tempString})
                    union
                        select distinct
                                coco.cod_fiscale
                        from contatti_contribuente coco 
                        where coco.cod_fiscale = ${contrAlias}.cod_fiscale
                        and (coco.tipo_tributo in (${tempString}) or coco.tipo_tributo is null)
					)
				""")
            }

            if (tipiPratica.size() > 0) {
                DetachedCriteria subQuery = DetachedCriteria.forClass(PraticaTributo, "prtr").setProjection(Projections.property("id"))
                subQuery.with {
                    add(Restrictions.eqProperty("prtr.contribuente", "contr.id"))
                    if (tipiTributo.size() > 0) {
                        add(Restrictions.'in'("prtr.tipoTributo.tipoTributo", tipiTributo))
                    }
                    if (tipiPratica.size() > 0) {
                        add(Restrictions.'in'("prtr.tipoPratica", tipiPratica))
                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)
            }

            if ((filtri.tipoContatto != null) || (filtri.annoContatto != null)) {
                DetachedCriteria subQuery = DetachedCriteria.forClass(ContattoContribuente, "coco").setProjection(Projections.property("id"))
                subQuery.with {
                    add(Restrictions.eqProperty("coco.contribuente", "contr.id"))
                    if (filtri.annoContatto != null) {
                        add(Restrictions.disjunction()
                                .add(Restrictions.eq("coco.anno", filtri.annoContatto as Short))
                                .add(Restrictions.isNull("coco.anno")))
                    }
                    if ((filtri.tipoContatto != null) && (filtri.tipoContatto != -1)) {
                        add(Restrictions.sqlRestriction("coco_.tipo_contatto + 0 = ${filtri.tipoContatto}"))
                    }
                    if (tipiTributo.size() > 0) {
                        tempString = "'" + tipiTributo.join("','") + "'"
                        add(Restrictions.sqlRestriction("(coco_.tipo_tributo || '' in ($tempString) or coco_.tipo_tributo is null)"))
                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)
            }

            if ((filtri.titoloDocumento) || (filtri.nomeFileDocumento) ||
                    (filtri.validoDaDocumento != null) || (filtri.validoADocumento != null)) {
                DetachedCriteria subQuery = DetachedCriteria.forClass(DocumentoContribuente, "doco").setProjection(Projections.property("id"))
                subQuery.with {
                    add(Restrictions.eqProperty("doco.contribuente", "contr.id"))
                    if (filtri.titoloDocumento) {
                        add(Restrictions.ilike("doco.titolo", filtri.titoloDocumento))
                    }
                    if (filtri.nomeFileDocumento) {
                        add(Restrictions.ilike("doco.nomeFile", filtri.nomeFileDocumento))
                    }
                    if (filtri.validoDaDocumento != null) {
                        add(Restrictions.ge("doco.validitaDal", filtri.validoDaDocumento))
                    }
                    if (filtri.validoADocumento != null) {
                        add(Restrictions.le("doco.validitaAl", filtri.validoADocumento))
                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)
            }

            if ((filtri.fonteVersamento != null) || (filtri.ordinarioVersamento == true) ||
                    (filtri.tipoVersamento != null) || (filtri.rataVersamento != null) ||
                    (filtri.tipoPraticaVersamento != null) || (filtri.statoPraticaVersamento != null) ||
                    (filtri.ruoloVersamento != null) || (filtri.progrDocVersamento != null) ||
                    (filtri.annoDaVersamento != null) || (filtri.annoAVersamento != null) ||
                    (filtri.pagamentoDaVersamento != null) || (filtri.pagamentoAVersamento != null) ||
                    (filtri.registrazioneDaVersamento != null) || (filtri.registrazioneAVersamento != null) ||
                    (filtri.importoDaVersamento != null) || (filtri.importoAVersamento != null) ||
                    (filtri.soloConVersamenti == true)) {

                DetachedCriteria subQuery = DetachedCriteria.forClass(Versamento, "vers").setProjection(Projections.property("id"))
                subQuery.with {
                    add(Restrictions.eqProperty("vers.contribuente", "contr.id"))
                    if (tipiTributo.size() > 0) {
                        add(Restrictions.'in'("vers.tipoTributo.tipoTributo", tipiTributo))
                    }
                    if (filtri.fonteVersamento != null) {
                        if (filtri.fonteVersamento == -1) {
                            add(Restrictions.isNotNull("vers.fonte"))
                        } else {
                            add(Restrictions.eq("vers.fonte.id", filtri.fonteVersamento as Long))
                        }
                    }
                    if (filtri.ordinarioVersamento == true) {
                        add(Restrictions.isNull("vers.pratica"))
                    } else {
                        if ((filtri.tipoPraticaVersamento != null) || (filtri.statoPraticaVersamento != null)) {
                            createAlias("vers.pratica", "vrpr")
                            add(Restrictions.isNotNull("vers.pratica"))
                        }
                        if (filtri.tipoPraticaVersamento != null) {
                            if (filtri.tipoPraticaVersamento == 'T') {
                                add(Restrictions.isNotNull("vrpr.tipoPratica"))
                            } else {
                                add(Restrictions.eq("vrpr.tipoPratica", filtri.tipoPraticaVersamento))
                            }
                        }
                        if (filtri.statoPraticaVersamento != null) {
                            if (filtri.statoPraticaVersamento == '-') {
                                add(Restrictions.isNotNull("vrpr.tipoStato"))
                            } else {
                                createAlias("vrpr.tipoStato", "vrprts")
                                add(Restrictions.eq("vrprts.tipoStato", filtri.statoPraticaVersamento))
                            }
                        }
                    }
                    if ((tipiTributo.size() > 0) && (tipiTributo.find { it in ['ICI', 'TASI', 'CUNI'] })) {
                        if (filtri.tipoVersamento != null) {
                            if (filtri.tipoVersamento == 'T') {
                                add(Restrictions.isNotNull("vers.tipoVersamento"))
                            } else {
                                add(Restrictions.eq("vers.tipoVersamento", filtri.tipoVersamento))
                            }
                        }
                        if (filtri.rataVersamento != null) {
                            if (filtri.rataVersamento == 'T') {
                                add(Restrictions.isNotNull("vers.rata"))
                            } else {
                                add(Restrictions.eq("vers.rata", filtri.rataVersamento as Short))
                            }
                        }
                    }
                    if (filtri.ruoloVersamento != null) {
                        add(Restrictions.eq("vers.ruolo.id", filtri.ruoloVersamento as Long))
                    }
                    if (filtri.progrDocVersamento != null) {
                        add(Restrictions.eq("vers.documentoId", filtri.progrDocVersamento as Long))
                    }
                    if (filtri.annoDaVersamento != null) {
                        add(Restrictions.ge("vers.anno", filtri.annoDaVersamento as Short))
                    }
                    if (filtri.annoAVersamento != null) {
                        add(Restrictions.le("vers.anno", filtri.annoAVersamento as Short))
                    }
                    if (filtri.pagamentoDaVersamento != null) {
                        add(Restrictions.ge("vers.dataPagamento", filtri.pagamentoDaVersamento))
                    }
                    if (filtri.pagamentoAVersamento != null) {
                        add(Restrictions.le("vers.dataPagamento", filtri.pagamentoAVersamento))
                    }
                    if (filtri.registrazioneDaVersamento != null) {
                        add(Restrictions.ge("vers.dataReg", filtri.registrazioneDaVersamento))
                    }
                    if (filtri.registrazioneAVersamento != null) {
                        add(Restrictions.le("vers.dataReg", filtri.registrazioneAVersamento))
                    }
                    if (filtri.importoDaVersamento != null) {
                        add(Restrictions.ge("vers.importoVersato", filtri.importoDaVersamento))
                    }
                    if (filtri.importoAVersamento != null) {
                        add(Restrictions.le("vers.importoVersato", filtri.importoAVersamento))
                    }
                    if (filtri.soloConVersamenti) {

                        add(Restrictions.isNull("vers.pratica"))

                        DetachedCriteria subQuery2 = DetachedCriteria.forClass(PraticaTributo, "prtr").setProjection(Projections.property("id"))
                        subQuery2.with {
                            add(Restrictions.eqProperty("prtr.contribuente.codFiscale", "contr.codFiscale"))
                            delegate
                        }

                        ExistsSubqueryExpression notExists = new ExistsSubqueryExpression("not exists", subQuery2)
                        add(notExists)

                        DetachedCriteria subQuery3 = DetachedCriteria.forClass(RapportoTributo, "rptr").setProjection(Projections.property("id"))
                        subQuery3.with {
                            add(Restrictions.eqProperty("rptr.contribuente.codFiscale", "contr.codFiscale"))
                            delegate
                        }

                        ExistsSubqueryExpression notExists2 = new ExistsSubqueryExpression("not exists", subQuery3)
                        add(notExists2)

                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists", subQuery)
                add(exists)
            }

            if (!sortBy) {
                order("cognomeNome", "asc")
            } else {
                order(sortBy.property, sortBy.direction)
            }
        }

        return [lista: elencoSoggetti.list.toDTO(listaFetch), totale: elencoSoggetti.totalCount]
    }

    private getStatoContribuenteSubquery(def filter, def codFiscaleProperty = null) {
        def filtriStati = filter.statoContribuenteFilter

        DetachedCriteria.forClass(StatoContribuente, "stco")
                .with {
                    setProjection(Projections.property("stco.contribuente"))

                    def restrictionConjuction = Restrictions.conjunction()

                    // Filtro opzionale su codFiscaleProperty (es: se viene da alias esterno)
                    if (codFiscaleProperty) {
                        restrictionConjuction.add(Restrictions.eqProperty("stco.contribuente.codFiscale", codFiscaleProperty))
                    }

                    if (filter.tipiTributo) {
                        restrictionConjuction.add(Restrictions.in("stco.tipoTributo.tipoTributo", filter.tipiTributo))
                    }
                    if (filtriStati.tipoStatoContribuente) {
                        restrictionConjuction.add(Restrictions.eq("stco.stato.id", filtriStati.tipoStatoContribuente.id))
                    }
                    if (filtriStati.dataDa) {
                        restrictionConjuction.add(Restrictions.ge("stco.dataStato", filtriStati.dataDa))
                    }
                    if (filtriStati.dataA) {
                        restrictionConjuction.add(Restrictions.le("stco.dataStato", filtriStati.dataA))
                    }
                    if (filtriStati.annoDa) {
                        restrictionConjuction.add(Restrictions.ge("stco.anno", filtriStati.annoDa as Short))
                    }
                    if (filtriStati.annoA) {
                        restrictionConjuction.add(Restrictions.le("stco.anno", filtriStati.annoA as Short))
                    }

                    // Subquery correlata per prendere SOLO l'ultimo stato per contribuente+tributo
                    def alias = "stco2"
                    def existsSubquery = DetachedCriteria.forClass(StatoContribuente, alias)
                            .add(Restrictions.eqProperty("${alias}.contribuente", "stco.contribuente"))
                            .add(Restrictions.eqProperty("${alias}.tipoTributo", "stco.tipoTributo"))
                            .add(
                                    Restrictions.or(
                                            Restrictions.gtProperty("${alias}.dataStato", "stco.dataStato"),
                                            Restrictions.and(
                                                    Restrictions.eqProperty("${alias}.dataStato", "stco.dataStato"),
                                                    Restrictions.gtProperty("${alias}.id", "stco.id")
                    )
                                    )
                            )
                            .setProjection(Projections.property("${alias}.id")) // projection necessaria per exists

                    restrictionConjuction.add(
                            Subqueries.notExists(existsSubquery)
                    )

                    add(restrictionConjuction)
                }

    }

    def listaSoggettiContribuenti(def filtri, int pageSize, int activePage, def listaFetch, def sortBy = null) {

        PagedResultList elencoSoggetti = Soggetto.createCriteria().list(max: pageSize, offset: pageSize * activePage) {
            createAlias("comuneResidenza", "comRes", CriteriaSpecification.LEFT_JOIN)
            createAlias("comRes.ad4Comune", "comu", CriteriaSpecification.LEFT_JOIN)
            createAlias("archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)

            if (filtri.contribuente == 'c') {
                createAlias("contribuenti", "contr", CriteriaSpecification.INNER_JOIN)
            } else if (filtri.contribuente == 'e') {
                createAlias("contribuenti", "contr", CriteriaSpecification.LEFT_JOIN)
            }

            if (filtri.codFiscale) {
                // se sto cercando i contribuenti devo filtrare sulla proprietà
                // codice fiscale della domain contribuente
                if (filtri.contribuente == "c") {
                    ilike("contr.codFiscale", filtri.codFiscale)
                } else if (filtri.contribuente == "s") {
                    or {
                        ilike("codFiscale", filtri.codFiscale)
                        ilike("partitaIva", filtri.codFiscale)
                    }
                } else if (filtri.contribuente == "e") {
                    or {
                        ilike("codFiscale", filtri.codFiscale)
                        ilike("partitaIva", filtri.codFiscale)
                        ilike("contr.codFiscale", filtri.codFiscale)
                    }
                }
            }

            if (filtri.cognome) {
                ilike("cognome", filtri.cognome.toLowerCase())
            }
            if (filtri.nome) {
                ilike("nome", filtri.nome.toLowerCase())
            }

            if (!sortBy) {
                order("cognomeNome", "asc")
            } else {
                order(sortBy.property, sortBy.direction)
            }
        }

        return [lista: elencoSoggetti.list.toDTO(listaFetch), totale: elencoSoggetti.totalCount]
    }

    def soggetto(long niSoggetto) {

        return Soggetto.createCriteria().get() {
            eq("id", niSoggetto)
            contribuenti {}
        }.toDTO()
    }

    def listaSoggettiBandbox(def filtri, int pageSize, int activePage, def listaFetch) {

        listaFetch = listaFetch ?: []
        PagedResultList elencoSoggetti = Soggetto.createCriteria().list(max: pageSize, offset: pageSize * activePage) {
            if (filtri?.cognomeNome) {
                ilike("cognomeNome", filtri.cognomeNome + "%")
            }
            if (filtri?.codFiscale) {
                or {
                    ilike("codFiscale", filtri.codFiscale + "%")
                    ilike("partitaIva", filtri.codFiscale + "%")
                }
            }
            if (filtri?.contribuente) {
                contribuenti {}
            }
            order("cognomeNome", "asc")

        }
        return [lista: elencoSoggetti.list.toDTO(listaFetch), totale: elencoSoggetti.totalCount]
    }

    @Transactional
    def salvaSoggetto(SoggettoDTO soggettoDTO
                      , List<EredeSoggettoDTO> listaEredi
                      , List<RecapitoSoggettoDTO> listaRecapiti
                      , List<FamiliareSoggettoDTO> listaFamiliari
                      , SoggettoDTO soggettoPresso
                      , def listaFetch) {

        Soggetto soggetto = Soggetto.get(soggettoDTO.id) ?: new Soggetto()
        soggetto.archivioVie = soggettoDTO.archivioVie?.getDomainObject()
        soggetto.fonte = soggettoDTO.fonte?.getDomainObject()
        soggetto.tipoCarica = soggettoDTO.tipoCarica?.getDomainObject()
        soggetto.soggettoPresso = soggettoPresso?.getDomainObject()

        soggetto.matricola = soggettoDTO.matricola
        soggetto.codFiscale = soggettoDTO.codFiscale?.toUpperCase()
        soggetto.fascia = soggettoDTO.fascia
        soggetto.stato = soggettoDTO.stato?.getDomainObject()
        soggetto.dataUltEve = soggettoDTO.dataUltEve
        soggetto.sesso = soggettoDTO.sesso
        soggetto.codFam = soggettoDTO.codFam
        soggetto.comuneResidenza = soggettoDTO.comuneResidenza?.getDomainObject()
        soggetto.comuneNascita = soggettoDTO.comuneNascita?.getDomainObject()
        soggetto.comuneEvento = soggettoDTO.comuneEvento?.getDomainObject()
        soggetto.comuneRap = soggettoDTO.comuneRap?.getDomainObject()
        soggetto.dataNas = soggettoDTO.dataNas
        soggetto.rapportoPar = soggettoDTO.rapportoPar
        soggetto.sequenzaPar = soggettoDTO.sequenzaPar
        soggetto.cap = soggettoDTO.cap
        soggetto.codProf = soggettoDTO.codProf
        soggetto.pensionato = soggettoDTO.pensionato
        soggetto.denominazioneVia = soggettoDTO.denominazioneVia
        soggetto.numCiv = soggettoDTO.numCiv
        soggetto.suffisso = soggettoDTO.suffisso
        soggetto.scala = soggettoDTO.scala
        soggetto.piano = soggettoDTO.piano
        soggetto.interno = soggettoDTO.interno
        soggetto.partitaIva = soggettoDTO.partitaIva
        soggetto.rappresentante = soggettoDTO.rappresentante
        soggetto.indirizzoRap = soggettoDTO.indirizzoRap
        soggetto.codFiscaleRap = soggettoDTO.codFiscaleRap
        soggetto.tipo = soggettoDTO.tipo
        soggetto.gruppoUtente = soggettoDTO.gruppoUtente
        soggetto.cognome = soggettoDTO.cognome.toUpperCase()
        soggetto.nome = soggettoDTO.nome?.toUpperCase()
        soggetto.note = soggettoDTO.note
        soggetto.intestatarioFam = soggettoDTO.intestatarioFam
        soggetto.zipcode = soggettoDTO.zipcode
        soggetto.flagCfCalcolato = soggettoDTO.flagCfCalcolato
        soggetto.flagEsenzione = soggettoDTO.flagEsenzione
        soggetto.tipoResidente = soggettoDTO.tipoResidente

        soggetto.erediSoggetto.findAll {
            !("${it.soggettoId}-${it.soggettoEredeIdId}" in listaEredi.collect {
                "${it.soggetto.id}-${it.soggettoErede.id}"
            })
        }.each {
            soggetto.erediSoggetto.remove(it)
            it.delete(failOnError: true, flush: true)
        }

        for (EredeSoggettoDTO eredeDTO in listaEredi) {
            EredeSoggetto erede = eredeDTO.getDomainObject() ?: new EredeSoggetto()
            erede.numeroOrdine = eredeDTO.numeroOrdine
            erede.soggettoErede = eredeDTO.soggettoErede.getDomainObject()
            erede.note = eredeDTO.note
            erede.soggettoEredeId = soggetto
            soggetto.addToErediSoggetto(erede)
        }

        soggetto.save(failOnError: true, flush: true)

        def familiariDaRimuovere = []
        soggetto.familiariSoggetto?.each { fam ->
            def eliminato = !listaFamiliari.find { it.anno == fam.anno && it.dal == fam.dal }
            if (eliminato) {
                familiariDaRimuovere << fam
            }
        }
        familiariDaRimuovere.each {
            soggetto.familiariSoggetto?.remove(it)
            it.delete(flush: true)
        }

        for (FamiliareSoggettoDTO familiareDTO in listaFamiliari) {
            FamiliareSoggetto familiare = familiareDTO.getDomainObject() ?: new FamiliareSoggetto()
            familiare.anno = familiareDTO.anno
            familiare.dal = familiareDTO.dal
            familiare.al = familiareDTO.al
            familiare.numeroFamiliari = familiareDTO.numeroFamiliari
            familiare.lastUpdated = familiareDTO.lastUpdated
            familiare.note = familiareDTO.note
            soggetto.addToFamiliariSoggetto(familiare)
            familiare.save(failOnError: true, flush: true)
        }

        soggetto.save(failOnError: true, flush: true)
        return soggetto.refresh().toDTO(listaFetch)
    }

    @Transactional
    def salvaDelegaBancaria(DelegheBancarieDTO delegheBancarieDTO) {
        DelegheBancarie delegheBancarie = DelegheBancarie.get(delegheBancarieDTO.id) ?: new DelegheBancarie()
        delegheBancarie.codFiscale = delegheBancarieDTO.codFiscale
        delegheBancarie.tipoTributo = delegheBancarieDTO.tipoTributo
        delegheBancarie.codAbi = delegheBancarieDTO.codAbi
        delegheBancarie.codCab = delegheBancarieDTO.codCab
        delegheBancarie.contoCorrente = delegheBancarieDTO.contoCorrente
        delegheBancarie.codControlloCc = delegheBancarieDTO.codControlloCc
        delegheBancarie.lastUpdated = delegheBancarieDTO.lastUpdated
        delegheBancarie.note = delegheBancarieDTO.note
        delegheBancarie.codiceFiscaleInt = delegheBancarieDTO.codiceFiscaleInt
        delegheBancarie.cognomeNomeInt = delegheBancarieDTO.cognomeNomeInt
        delegheBancarie.flagDelegaCessata = delegheBancarieDTO.flagDelegaCessata
        delegheBancarie.dataRitiroDelega = delegheBancarieDTO.dataRitiroDelega
        delegheBancarie.flagRataUnica = delegheBancarieDTO.flagRataUnica
        delegheBancarie.cinBancario = delegheBancarieDTO.cinBancario
        delegheBancarie.ibanPaese = delegheBancarieDTO.ibanPaese
        delegheBancarie.ibanCinEuropa = delegheBancarieDTO.ibanCinEuropa

        delegheBancarie.save(failOnError: true, flush: true)
        return delegheBancarie.toDTO()
    }

    @Transactional
    def salvaRecapitoSoggetto(RecapitoSoggettoDTO recapitoSoggettoDTO) {
        RecapitoSoggetto recapitoSoggetto = recapitoSoggettoDTO.getDomainObject() ?: new RecapitoSoggetto()
        recapitoSoggetto.soggetto = recapitoSoggettoDTO.soggetto?.getDomainObject()
        recapitoSoggetto.tipoTributo = recapitoSoggettoDTO.tipoTributo?.getDomainObject()
        recapitoSoggetto.tipoRecapito = recapitoSoggettoDTO.tipoRecapito?.getDomainObject()
        recapitoSoggetto.descrizione = recapitoSoggettoDTO.descrizione
        recapitoSoggetto.archivioVie = recapitoSoggettoDTO.archivioVie?.getDomainObject()
        recapitoSoggetto.numCiv = recapitoSoggettoDTO.numCiv
        recapitoSoggetto.suffisso = recapitoSoggettoDTO.suffisso
        recapitoSoggetto.scala = recapitoSoggettoDTO.scala
        recapitoSoggetto.piano = recapitoSoggettoDTO.piano
        recapitoSoggetto.interno = recapitoSoggettoDTO.interno
        recapitoSoggetto.dal = recapitoSoggettoDTO.dal
        recapitoSoggetto.al = recapitoSoggettoDTO.al
        recapitoSoggetto.piano = recapitoSoggettoDTO.piano
        recapitoSoggetto.utente = recapitoSoggettoDTO.utente?.getDomainObject()
        recapitoSoggetto.lastUpdated = recapitoSoggettoDTO.lastUpdated
        recapitoSoggetto.note = recapitoSoggettoDTO.note
        recapitoSoggetto.comuneRecapito = Ad4ComuneTr4.get(recapitoSoggettoDTO?.comuneRecapito?.getDomainObject())
        recapitoSoggetto.cap = recapitoSoggettoDTO.cap
        recapitoSoggetto.zipcode = recapitoSoggettoDTO.zipcode
        recapitoSoggetto.presso = recapitoSoggettoDTO.presso
        recapitoSoggetto.save(failOnError: true, flush: true)

        return recapitoSoggetto.toDTO()
    }

    def checkIntersezioniDateRecapito(def recapito) {

        def parametri = [:]
        parametri << ['p_ni': recapito.soggetto.id]
        parametri << ['p_tipo_recapito': recapito.tipoRecapito.id]

        def query = """
                    select count(*) as count
                    from recapiti_soggetto reso
                    where reso.ni = :p_ni
                    and nvl(reso.tipo_tributo,' ') = nvl(:p_titr,' ')
                    and reso.tipo_recapito = :p_tipo_recapito
                    and id_recapito != nvl(:p_id,-1)
                    and (nvl(reso.dal,to_date('01/01/1900','dd/mm/yyyy')) between nvl(:p_dal,to_date('01/01/1900','dd/mm/yyyy'))
                    and nvl(:p_al,to_date('31/12/3000','dd/mm/yyyy'))
                    or nvl(reso.al,to_date('31/12/3000','dd/mm/yyyy')) between nvl(:p_dal,to_date('01/01/1900','dd/mm/yyyy'))
                    and nvl(:p_al,to_date('31/12/3000','dd/mm/yyyy')))
                    """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            // Per parametri che possono essere valorizzati a null
            setParameter("p_dal", recapito.dal, StandardBasicTypes.DATE)
            setParameter("p_al", recapito.al, StandardBasicTypes.DATE)
            setParameter("p_titr", recapito.tipoTributo?.tipoTributo, StandardBasicTypes.STRING)
            setParameter("p_id", recapito.id, StandardBasicTypes.LONG)

            parametri.each { k, v ->
                setParameter(k, v)
            }
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()

        }[0].count

    }

    @Transactional
    def duplicaRecapitoSoggetto(RecapitoSoggettoDTO recapitoSoggettoDTO) {

        RecapitoSoggettoDTO recapitoDuplicato = new RecapitoSoggettoDTO()
        InvokerHelper.setProperties(recapitoDuplicato, recapitoSoggettoDTO.properties)
        recapitoDuplicato.id = null

        return recapitoDuplicato
    }

    @Transactional
    def salvaCaricoTarsu(CaricoTarsuDTO ct, def modalita) {
        CaricoTarsu caricoTarsu = CaricoTarsu.findByAnno(ct.anno) ?: new CaricoTarsu()
        caricoTarsu.modalitaFamiliari = modalita
        caricoTarsu.save(failOnError: true, flush: true)
    }

    def fasciaPerData(def ni, Date dataRif) {
        Soggetto sogg = Soggetto.get(ni)
        if (!sogg) return -1
        if (DatoGenerale.get(1).flagIntegrazioneGsd ?: "N".equals("S")) {
            def matricola = sogg.matricola
            def retFascia = Anaana.findByIdAndStatoNotEqual(sogg.matricola, 17)?.fascia ?: 0
            Anamov anaMovimento = Anamov.createCriteria().get() {
                eq("matricola", sogg.matricola)
                gt("dataReg", dataRif)
                'in'("codMov", [1, 2, 3, 4])
                not { 'in'("codEve", [17, 62]) }

                order("dataReg", "asc")
                order("dataEve", "asc")

                maxResults(1)
            }

            switch (anaMovimento?.codMov ?: 0) {
                case 1:
                    if (anaMovimento.codEve == 4) {
                        retFascia = 3
                    } else {
                        retFascia = 0
                    }
                    break
                case 2:
                    retFascia = 0
                    break
                case 3:
                    if (anaMovimento.codEve == 52) {
                        retFascia = 1
                    } else {
                        retFascia = 0
                    }
                    break
                case 4:
                    retFascia = 3
                    break
            }

            return retFascia
        } else {
            return sogg.fascia ?: -1
        }
    }


    def sostituisciContribuenteCheck(Long idOriginale, String cfOriginale, Long idDestinazione, String cfDestinazione) {

        String messaggio = ""
        Long result

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{? = call f_check_sostituzione_contr(?, ?, ?, ?, ?)}',
                    [
                            Sql.INTEGER,
                            cfOriginale,
                            cfDestinazione,
                            idOriginale,
                            idDestinazione,
                            Sql.VARCHAR
                    ]
            )
                    {
                        resCode, resMsg ->
                            result = resCode
                            messaggio = resMsg
                    }
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                messaggio = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                result = 3
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                messaggio = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                result = 3
            } else {
                throw e
            }
        }

        return [result: result, messaggio: messaggio]
    }

    private sostituisciContribuente(Long idOriginale, String cfOriginale, Long idDestinazione, String cfDestinazione) {

        String messaggio = ""
        Long result = 1

        try {
            Sql sql = new Sql(dataSource)

            sql.call('{call SOSTITUZIONE_CONTRIBUENTE(?, ?, ?, ?, ?)}',
                    [
                            cfOriginale,
                            cfDestinazione,
                            idOriginale,
                            idDestinazione,
                            Sql.VARCHAR
                    ]
            )
                    {
                        resMsg -> messaggio = resMsg
                    }

            if (messaggio == null) {

                if (integrazioneDePagService.dePagAbilitato()) {

                    messaggio = ""

                    def report = integrazioneDePagService.eliminaDovutiAnnullatiSoggetto(cfOriginale, null, cfDestinazione)
                    if (report.result > 0) {
                        messaggio += report.message
                        result = report.result
                    }
                    report = integrazioneDePagService.aggiornaDovutiSoggetto(cfDestinazione)
                    if (report.result > 0) {
                        if (!messaggio.isEmpty()) {
                            messaggio += "\n"
                        }
                        messaggio += report.message
                        result = report.result
                    }
                    if (!messaggio.isEmpty()) {
                        messaggio = "DEPAG – Sostituzione Contribuente:\n" + messaggio
                    }
                }
            }

        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                messaggio = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                result = 3
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                messaggio = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                result = 3
            } else {
                //throw e
                messaggio = "Errore: " + e?.message
                result = 3
            }
        }

        if ((messaggio == null) || (messaggio.empty)) {
            result = 0
        }

        return [result: result, messaggio: messaggio]
    }

    def getListaTributi(Short anno) {

        String sql = """SELECT
							TITR.TIPO_TRIBUTO,
							TITR.DESCRIZIONE,
							F_DESCRIZIONE_TITR(TITR.TIPO_TRIBUTO,:anno,NULL) AS NOME
						FROM
							TIPI_TRIBUTO TITR
						ORDER BY
							TIPO_TRIBUTO
		"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setShort('anno', anno)
            list()
        }

        def records = []

        results.each {
            def record = [:]
            if (competenzeService.tipoAbilitazioneUtente(it['TIPO_TRIBUTO'])) {
                record.codice = it['TIPO_TRIBUTO']
                record.descrizione = it['DESCRIZIONE']
                record.nome = it['NOME']
                records << record
            }

        }
        return records
    }

    // Riporta lista Progressivi documenti di tributi per combo
    def getListaProgrDocPerTributi(def elencoTributi) {

        String tipiTributo = ""

        String sqlFiltri = ""
        String sql

        def filtri = [:]

        if (elencoTributi.size() > 0) {

            tipiTributo = "'" + elencoTributi.join("','") + "'"
            sqlFiltri += "AND VERS.TIPO_TRIBUTO IN (${tipiTributo}) "
        }

        sql = """
				SELECT
				 	DOCUMENTO_ID,
				 	DOCUMENTO_ID || ' - ' || NOME_DOCUMENTO || ' del ' || TO_CHAR(DATA_VARIAZIONE,'dd/mm/yyyy') as DESCRIZIONE
				FROM
					DOCUMENTI_CARICATI DOCA
				WHERE
					DOCA.TITOLO_DOCUMENTO = 21 AND
					DOCA.STATO = 2 AND 
					EXISTS
					(SELECT 'x'
							FROM VERSAMENTI VERS
							WHERE
								VERS.DOCUMENTO_ID = DOCA.DOCUMENTO_ID
								${sqlFiltri}
					)
				ORDER BY 1 DESC
		"""

        def results = eseguiQuery("${sql}", filtri, null, true)

        def records = []

        results.each {

            def record = [:]

            record.codice = it['DOCUMENTO_ID']
            record.descrizione = it['DESCRIZIONE']

            records << record
        }

        return records
    }

    private calcolaNumeroFamiliari(def soggetto, Long anno, Date data, def scadenzaParziale, def raggruppa, Long modalita) {

        String messaggio = ""
        Long result = 2

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call INSERIMENTO_FASO_CONT(?, ?, ?, ?, ?, ?, ?)}',
                    [
                            soggetto,
                            anno,
                            new java.sql.Timestamp(data.getTime()),
                            scadenzaParziale,
                            raggruppa,
                            modalita,
                            Sql.VARCHAR
                    ]
            )
                    {
                        resMsg -> messaggio = resMsg
                    }
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                messaggio = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                result = 3
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                messaggio = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                result = 3
            } else {
                throw e
            }
        }

        if ((messaggio == null) || (messaggio.length() == 0)) result = 0

        if ((messaggio) && (messaggio.equals("NO_TRATTATI"))) result = 1

        return [result: result, messaggio: messaggio]
    }

    def generaReportCalcoloNumeroFamiliari(String messaggio) {
        def lista = []

        if (messaggio) {
            String[] sequenza = messaggio.split("\r\n")
            sequenza.each { lista << it }
        }
        List<SoggettiReport> listaDati = new ArrayList<SoggettiReport>()
        SoggettiReport soggettiReport = new SoggettiReport()
        soggettiReport.soggetti = lista

        listaDati.add(soggettiReport)
        JasperReportDef reportDef = new JasperReportDef(name: 'calcoloNumeroFamiliari.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: listaDati
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte(),
                               lista        : lista])
        return (messaggio) ? jasperService.generateReport(reportDef) : null
    }

    def listaFamiliariSoggettoResidente() {

        String sql = """
					  SELECT faso.anno, faso.anno
                      FROM familiari_soggetto faso, soggetti sogg
                      WHERE faso.ni = sogg.ni AND sogg.tipo_residente = 1
                      GROUP BY faso.anno
                      ORDER BY 2 DESC
				"""
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.anno = it['ANNO']
            records << record
        }

        return records
    }

    private duplicaNumeroFamiliari(Long anno, Date data, Long annoDuplica) {

        String messaggio = ""
        Long result = 1

        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call DUPLICA_FASO_CONT(?, ?, ?)}', [anno, new Timestamp(data.getTime()), annoDuplica])
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                messaggio = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                result = 2
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                messaggio = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                result = 2
            } else {
                throw e
            }
        }

        return [result: result, messaggio: messaggio]
    }

    def listaDelegheBancarie(String codiceFiscale) {

        String sql = """					
                SELECT DELEGHE_BANCARIE.COD_FISCALE,
                       DELEGHE_BANCARIE.TIPO_TRIBUTO,
                       DELEGHE_BANCARIE.COD_ABI,
                       DELEGHE_BANCARIE.COD_CAB,
                          NVL (AD4_BANCHE.DENOMINAZIONE, 'BANCA ASSENTE')
                       || ' - '
                       || NVL (AD4_SPORTELLI.DESCRIZIONE, 'SPORTELLO ASSENTE')
                          descrizione,
                       DELEGHE_BANCARIE.CONTO_CORRENTE,
                       DELEGHE_BANCARIE.COD_CONTROLLO_CC,
                       DELEGHE_BANCARIE.UTENTE,
                       DELEGHE_BANCARIE.DATA_VARIAZIONE,
                       DELEGHE_BANCARIE.NOTE,
                       DELEGHE_BANCARIE.CODICE_FISCALE_INT,
                       DELEGHE_BANCARIE.COGNOME_NOME_INT,
                       DELEGHE_BANCARIE.FLAG_DELEGA_CESSATA,
                       DELEGHE_BANCARIE.DATA_RITIRO_DELEGA,
                       DELEGHE_BANCARIE.FLAG_RATA_UNICA,
                       deleghe_bancarie.cin_bancario,
                       deleghe_bancarie.iban_paese,
                       deleghe_bancarie.iban_cin_europa,
                       LPAD ( :p_utente, 10) ute,
                       f_descrizione_titr (DELEGHE_BANCARIE.TIPO_TRIBUTO,
                                           TO_NUMBER (TO_CHAR (SYSDATE, 'yyyy')))
                          des_titr,
                          deleghe_bancarie.iban_paese
                       || LPAD (deleghe_bancarie.iban_cin_europa, 2, '0')
                       || deleghe_bancarie.cin_bancario
                       || LPAD (deleghe_bancarie.cod_abi, 5, '0')
                       || LPAD (deleghe_bancarie.cod_cab, 5, '0')
                       || SUBSTR (
                             LPAD (
                                   deleghe_bancarie.conto_corrente
                                || deleghe_bancarie.cod_controllo_cc,
                                13,
                                '0'),
                             -12)
                          iban
                  FROM DELEGHE_BANCARIE,
                       AD4_SPORTELLI,
                       AD4_BANCHE,
                       dati_generali dage
                 WHERE     (deleghe_bancarie.cod_fiscale = :p_scf)
                       AND (LPAD (TO_CHAR (DELEGHE_BANCARIE.COD_ABI), 5, '0') =
                               AD4_SPORTELLI.ABI(+))
                       AND (LPAD (TO_CHAR (DELEGHE_BANCARIE.COD_CAB), 5, '0') =
                               AD4_SPORTELLI.CAB(+))
                       AND (LPAD (TO_CHAR (DELEGHE_BANCARIE.COD_ABI), 5, '0') =
                               AD4_BANCHE.ABI(+))
                       AND dage.flag_competenze IS NULL
                UNION
                SELECT DELEGHE_BANCARIE.COD_FISCALE,
                       DELEGHE_BANCARIE.TIPO_TRIBUTO,
                       DELEGHE_BANCARIE.COD_ABI,
                       DELEGHE_BANCARIE.COD_CAB,
                          NVL (AD4_BANCHE.DENOMINAZIONE, 'BANCA ASSENTE')
                       || ' - '
                       || NVL (AD4_SPORTELLI.DESCRIZIONE, 'SPORTELLO ASSENTE')
                          descrizione,
                       DELEGHE_BANCARIE.CONTO_CORRENTE,
                       DELEGHE_BANCARIE.COD_CONTROLLO_CC,
                       DELEGHE_BANCARIE.UTENTE,
                       DELEGHE_BANCARIE.DATA_VARIAZIONE,
                       DELEGHE_BANCARIE.NOTE,
                       DELEGHE_BANCARIE.CODICE_FISCALE_INT,
                       DELEGHE_BANCARIE.COGNOME_NOME_INT,
                       DELEGHE_BANCARIE.FLAG_DELEGA_CESSATA,
                       DELEGHE_BANCARIE.DATA_RITIRO_DELEGA,
                       DELEGHE_BANCARIE.FLAG_RATA_UNICA,
                       deleghe_bancarie.cin_bancario,
                       deleghe_bancarie.iban_paese,
                       deleghe_bancarie.iban_cin_europa,
                       LPAD ( :p_utente, 10) ute,
                       f_descrizione_titr (DELEGHE_BANCARIE.TIPO_TRIBUTO,
                                           TO_NUMBER (TO_CHAR (SYSDATE, 'yyyy')))
                          des_titr,
                          deleghe_bancarie.iban_paese
                       || LPAD (deleghe_bancarie.iban_cin_europa, 2, '0')
                       || deleghe_bancarie.cin_bancario
                       || LPAD (deleghe_bancarie.cod_abi, 5, '0')
                       || LPAD (deleghe_bancarie.cod_cab, 5, '0')
                       || SUBSTR (
                             LPAD (
                                   deleghe_bancarie.conto_corrente
                                || deleghe_bancarie.cod_controllo_cc,
                                13,
                                '0'),
                             -12)
                          iban
                  FROM DELEGHE_BANCARIE,
                       AD4_SPORTELLI,
                       AD4_BANCHE,
                       dati_generali dage,
                       si4_competenze comp
                 WHERE     (deleghe_bancarie.cod_fiscale = :p_scf)
                       AND (LPAD (TO_CHAR (DELEGHE_BANCARIE.COD_ABI), 5, '0') =
                               AD4_SPORTELLI.ABI(+))
                       AND (LPAD (TO_CHAR (DELEGHE_BANCARIE.COD_CAB), 5, '0') =
                               AD4_SPORTELLI.CAB(+))
                       AND (LPAD (TO_CHAR (DELEGHE_BANCARIE.COD_ABI), 5, '0') =
                               AD4_BANCHE.ABI(+))
                       AND DELEGHE_BANCARIE.TIPO_TRIBUTO = comp.oggetto
                       AND comp.Utente = :p_utente
                       AND comp.id_abilitazione IN (6, 7)
                       AND dage.flag_competenze = 'S'
                ORDER BY 2
				"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('p_utente', springSecurityService.currentUser?.id)
            setString('p_scf', codiceFiscale)

            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.codFiscale = it['COD_FISCALE']
            record.tipoTributo = it['TIPO_TRIBUTO']
//TipoTributo.findByTipoTributo(it['TIPO_TRIBUTO'])?.tipoTributoAttuale
            record.codAbi = it['COD_ABI']
            record.codCab = it['COD_CAB']
            record.descrizione = it['DESCRIZIONE']
            record.contoCorrente = it['CONTO_CORRENTE']
            record.codControlloCc = it['COD_CONTROLLO_CC']
            record.lastUpdated = it['DATA_VARIAZIONE']
            record.note = it['NOTE']
            record.codiceFiscaleInt = it['CODICE_FISCALE_INT']
            record.cognomeNomeInt = it['COGNOME_NOME_INT']
            record.flagDelegaCessata = (it['FLAG_DELEGA_CESSATA'] && it['FLAG_DELEGA_CESSATA'].equals("S")) ? true : false
            record.dataRitiroDelega = it['DATA_RITIRO_DELEGA']
            record.flagRataUnica = (it['FLAG_RATA_UNICA'] && it['FLAG_RATA_UNICA'].equals("S")) ? true : false
            record.cinBancario = it['CIN_BANCARIO']
            record.ibanPaese = it['IBAN_PAESE']
            record.ibanCinEuropa = it['IBAN_CIN_EUROPA']
            record.descrizioneTributo = it['DES_TITR']
            record.iban = it['IBAN']
            records << record
        }

        return records
    }

    def listaBanche(String valore) {

        String sql = " select abi,cin_abi,denominazione from AD4_BANCHE where abi like :p_abi order by 1"
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('p_abi', "%" + valore + "%")
            list()
        }

        def records = []

        def recordVuoto = [:]
        recordVuoto.codAbi = ""
        recordVuoto.denominazioneAbi = " "
        records << recordVuoto

        results.each {
            def record = [:]
            record.codAbi = it['ABI']
            record.denominazioneAbi = it['DENOMINAZIONE']
            records << record
        }
        return records
    }


    def listaBanche() {

        String sql = " select abi,cin_abi,denominazione from AD4_BANCHE order by 1"
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            list()
        }

        def records = []

        def recordVuoto = [:]
        recordVuoto.codAbi = ""
        recordVuoto.denominazioneAbi = " "
        records << recordVuoto

        results.each {
            def record = [:]
            record.codAbi = it['ABI']
            record.denominazioneAbi = it['DENOMINAZIONE']
            records << record
        }
        return records
    }

    def listaSportelli(String codAbi) {

        String sql = """ select * from AD4_SPORTELLI
                         where abi = lpad(:p_abi,5,'0')
                         order by 2 """
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('p_abi', codAbi)

            list()
        }

        def records = []

        def recordVuoto = [:]
        recordVuoto.abi = ""
        recordVuoto.codCab = ""
        recordVuoto.denominazioneCab = ""
        records << recordVuoto

        results.each {
            def record = [:]
            record.abi = it['ABI']
            record.codCab = it['CAB']
            record.cinCab = it['CIN_CAB']
            record.denominazioneCab = it['DESCRIZIONE']
            record.indirizzo = it['INDIRIZZO']
            record.localita = it['LOCALTA']
            record.comune = it['COMUNE']
            record.provincia = it['PROVINCIA']
            record.cap = it['CAP']
            record.dipendenza = it['DIPENDENZA']
            record.bic = it['BIC']
            records << record
        }

        return records
    }

    def controlloBanca(String codAbi) {

        String sql = " select * from AD4_BANCHE where abi = lpad(:p_abi,5,'0') "
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('p_abi', codAbi)
            list()
        }

        def records = []
        results.each {
            def record = [:]
            record.codAbi = it['ABI']
            record.denominazioneAbi = it['DENOMINAZIONE']
            records << record
        }
        return records
    }

    def controlloSportello(String codAbi, String codCab) {

        String sql = """ select * from AD4_SPORTELLI
                         where abi = lpad(:p_abi,5,'0')
                               and cab = lpad(:p_cab,5,'0')
                         order by 2 """
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('p_abi', codAbi)
            setString('p_cab', codCab)

            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.abi = it['ABI']
            record.codCab = it['CAB']
            record.cinCab = it['CIN_CAB']
            record.denominazioneCab = it['DESCRIZIONE']
            record.indirizzo = it['INDIRIZZO']
            record.localita = it['LOCALTA']
            record.comune = it['COMUNE']
            record.provincia = it['PROVINCIA']
            record.cap = it['CAP']
            record.dipendenza = it['DIPENDENZA']
            record.bic = it['BIC']
            records << record
        }

        return records
    }

    def variazioniResidenze(Long tipoEvento, def dataDal, def dataAl, int pageSize, int activePage, def tipoSoggetto, boolean wholeList = false) {
        String sql = """
                        SELECT COGNOMENOME cognomeNome,
                             CODFISCALE codFiscale,
                             DATANASCITA dataNascita,
                             PARTITAIVA partitaIva,
                             NI ni,
                             MATRICOLA matricola,
                             TIPORESIDENTE tipoResidente,
                             TIPORAPPORTO tipoRapporto,
                             DATAEVENTO dataEvento,
                             CODFISCALECONTRIBUENTE codFiscaleContribuente,
                             CODICECONTROLLO codiceControllo,
                             COGNOME cognome,
                             NOME nome,
                             RESIDENTE residente, 
                             INDIRIZZO indirizzo,
                             CONTRIBUENTE contribuente,
                             CODCONTRIBUENTE  codContribuente,
                             COMUNE comune,
                             COMUNEEVENTO comuneEvento,
                             CODFAMIGLIA codFamiglia,
                             FASCIA fascia
                      FROM (
                        SELECT DISTINCT SOGG.COGNOME_NOME cognomeNome,
                             SOGG.COD_FISCALE codFiscale,
                             SOGG.DATA_NAS dataNascita,
                             SOGG.PARTITA_IVA partitaIva,
                             SOGG.NI ni,
                             SOGG.MATRICOLA matricola,
                             SOGG.TIPO_RESIDENTE tipoResidente,
                             SOGG.RAPPORTO_PAR tipoRapporto,
                             to_date(to_char(ANAE.DATA_EVE),'j') dataEvento ,
                             CONT.COD_FISCALE codFiscaleContribuente,
                             CONT.COD_CONTROLLO codiceControllo,   
                             upper(replace(SOGG.COGNOME,' ',''))  cognome,
                             upper(replace(SOGG.NOME,' ','')) nome,  
                             decode( sogg.tipo_residente,0, decode(sogg.fascia,1,'SI','NO'),'NO') residente,
                             decode(SOGG.COD_VIA,NULL,SOGG.DENOMINAZIONE_VIA,ARVI.DENOM_UFF)
                                 ||decode( sogg.num_civ,NULL,'', ', '||to_char(sogg.num_civ) )
                                 ||decode( sogg.suffisso,NULL,'', '/'||sogg.suffisso ) indirizzo,   
                             decode(CONT.NI, NULL, 'NO', 'SI') contribuente,  
                             decode( CONT.COD_CONTROLLO , NULL, to_char(CONT.COD_CONTRIBUENTE), 
                                    CONT.COD_CONTRIBUENTE||'-'||CONT.COD_CONTROLLO) codContribuente,   
                             COM_RES.DENOMINAZIONE
                                 || decode( PRO_RES.SIGLA,NULL, '', ' (' || PRO_RES.SIGLA || ')') comune,   
                             COM_EVE.DENOMINAZIONE
                                 || decode( PRO_EVE.SIGLA,NULL, '', ' (' || PRO_EVE.SIGLA || ')') comuneEvento,
                             SOGG.COD_FAM codFamiglia,   
                             SOGG.FASCIA fascia      
                         FROM AD4_PROVINCIE PRO_EVE,
                             AD4_COMUNI COM_EVE,
                             AD4_PROVINCIE PRO_RES,
                             AD4_COMUNI COM_RES,
                             ARCHIVIO_VIE ARVI,
                             CONTRIBUENTI CONT,
                             SOGGETTI SOGG,   
                             ANAEVE ANAE   
                       WHERE COM_EVE.PROVINCIA_STATO    = PRO_EVE.PROVINCIA (+)  
                         and ANAE.COD_PRO_EVE            = COM_EVE.PROVINCIA_STATO (+)
                         and ANAE.COD_COM_EVE            = COM_EVE.COMUNE (+)
                         and COM_RES.PROVINCIA_STATO = PRO_RES.PROVINCIA (+)  
                         and SOGG.COD_PRO_RES            = COM_RES.PROVINCIA_STATO (+)
                         and SOGG.COD_COM_RES            = COM_RES.COMUNE (+)
                          and SOGG.COD_VIA                = ARVI.COD_VIA (+)
                         and SOGG.NI                        = CONT.NI (+)   
                         and ANAE.MATRICOLA          = SOGG.MATRICOLA   
                         and ANAE.COD_EVE            = :p_evento   
                         and nvl(to_date(to_char(ANAE.DATA_EVE),'j'),to_date('2222222','j'))
                                               between nvl(:p_dal,to_date('2222222','j'))   
                                                   and nvl(:p_al ,to_date('3333333','j'))   
                         and ANAE.COD_MOV            = 11   
                         and SOGG.TIPO_RESIDENTE     = 0   
                       ORDER BY upper(replace(SOGG.COGNOME,' ',''))  ASC,
                                upper(replace(SOGG.NOME,' ',''))  ASC,         
                                SOGG.NI   
                       )
			"""

        if (tipoSoggetto == 1) {
            sql += """
                   WHERE CONTRIBUENTE = 'SI'
                 """
        }

        if (tipoSoggetto == 2) {
            sql += """
                   WHERE CONTRIBUENTE = 'NO'
                 """
        }

        def sqlTotali = """
				SELECT COUNT(*) AS TOT_COUNT
				FROM ($sql)
				"""

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def totali
        if (!wholeList) {
            totali = sessionFactory.currentSession.createSQLQuery(sqlTotali).with {
                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
                setLong('p_evento', tipoEvento)
                setDate('p_dal', dataDal)
                setDate('p_al', dataAl)

                list()
            }[0]
        }

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('p_evento', tipoEvento)
            setDate('p_dal', dataDal)
            setDate('p_al', dataAl)

            if (!wholeList) {
                setFirstResult(params.offset)
                setMaxResults(params.max)
            }


            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.contribuente = it['CONTRIBUENTE']
            record.ni = it['NI']
            record.cognome = it['COGNOME']
            record.nome = it['NOME']
            record.codFiscale = it['CODFISCALE']
            record.dataNascita = it['DATANASCITA']
            record.codContribuente = it['CODCONTRIBUENTE']
            record.partitaIva = it['PARTITAIVA']
            record.indirizzo = it['INDIRIZZO']
            record.comune = it['COMUNE']
            record.matricola = it['MATRICOLA']
            record.dataEvento = it['DATAEVENTO']
            record.comuneEvento = it['COMUNEEVENTO']
            records << record
        }

        def totals = [
                totalCount: (!wholeList) ? totali.TOT_COUNT : records.size(),
        ]

        return [totalCount: totals.totalCount, totals: totals, records: records]

    }

    def variazioniAnagrafiche(Long tipoEvento, def comune, def provincia, def dataDal, def dataAl, int pageSize, int activePage, def tipoSoggetto, boolean wholeList = false) {
        String sql = """
                      SELECT COGNOMENOME cognomeNome,
                             CODFISCALE codFiscale,
                             DATANASCITA dataNascita,
                             PARTITAIVA partitaIva,
                             NI ni,
                             MATRICOLA matricola,
                             TIPORESIDENTE tipoResidente,
                             TIPORAPPORTO tipoRapporto,
                             DATAEVENTO dataEvento,
                             CODFISCALECONTRIBUENTE codFiscaleContribuente,
                             CODICECONTROLLO codiceControllo,
                             COGNOME cognome,
                             NOME nome,
                             RESIDENTE residente, 
                             INDIRIZZO indirizzo,
                             CONTRIBUENTE contribuente,
                             CODCONTRIBUENTE  codContribuente,
                             COMUNE comune,
                             COMUNEEVENTO comuneEvento,
                             CODFAMIGLIA codFamiglia,
                             FASCIA fascia
                      FROM (
                      SELECT DISTINCT
                             SOGG.COGNOME_NOME cognomeNome,
                             SOGG.COD_FISCALE codFiscale,
                             SOGG.DATA_NAS dataNascita,
                             SOGG.PARTITA_IVA partitaIva,
                             SOGG.NI ni,
                             SOGG.MATRICOLA matricola,
                             SOGG.TIPO_RESIDENTE tipoResidente,
                             SOGG.RAPPORTO_PAR tipoRapporto,
                             SOGG.DATA_ULT_EVE dataEvento,
                             CONT.COD_FISCALE codFiscaleContribuente,
                             CONT.COD_CONTROLLO codiceControllo,
                             UPPER (REPLACE (SOGG.COGNOME, ' ', '')) cognome,
                             UPPER (REPLACE (SOGG.NOME, ' ', '')) nome,
                             DECODE (sogg.tipo_residente,0, DECODE (sogg.fascia, 1, 'SI', 'NO'),'NO') residente, 
                             DECODE (SOGG.COD_VIA, NULL, SOGG.DENOMINAZIONE_VIA, ARVI.DENOM_UFF)
                             || DECODE (num_civ, NULL, '', ', ' || num_civ)
                             || DECODE (suffisso, NULL, '', '/' || suffisso) indirizzo,
                             DECODE (CONT.NI, NULL, 'NO', 'SI') contribuente,
                             DECODE (CONT.COD_CONTROLLO,
                                     NULL, TO_CHAR (CONT.COD_CONTRIBUENTE),
                                     CONT.COD_CONTRIBUENTE || '-' || CONT.COD_CONTROLLO)  codContribuente,
                             COM_RES.DENOMINAZIONE || DECODE (PRO_RES.SIGLA, NULL, '', ' (' || PRO_RES.SIGLA || ')') comune,
                             COM_EVE.DENOMINAZIONE || DECODE (PRO_EVE.SIGLA, NULL, '', ' (' || PRO_EVE.SIGLA || ')') comuneEvento,
                             SOGG.COD_FAM codFamiglia,
                             SOGG.FASCIA fascia
                        FROM AD4_PROVINCIE PRO_EVE,
                             AD4_COMUNI COM_EVE,
                             AD4_PROVINCIE PRO_RES,
                             AD4_COMUNI COM_RES,
                             ARCHIVIO_VIE ARVI,
                             CONTRIBUENTI CONT,
                             SOGGETTI SOGG
                       WHERE     COM_EVE.PROVINCIA_STATO = PRO_EVE.PROVINCIA(+)
                             AND SOGG.COD_PRO_EVE = COM_EVE.PROVINCIA_STATO(+)
                             AND SOGG.COD_COM_EVE = COM_EVE.COMUNE(+)
                             AND COM_RES.PROVINCIA_STATO = PRO_RES.PROVINCIA(+)
                             AND SOGG.COD_PRO_RES = COM_RES.PROVINCIA_STATO(+)
                             AND SOGG.COD_COM_RES = COM_RES.COMUNE(+)
                             AND SOGG.COD_VIA = ARVI.COD_VIA(+)
                             AND SOGG.NI = CONT.NI(+)
                             AND SOGG.STATO = :p_evento
           """
        if (comune) {
            sql += """ AND SOGG.COD_COM_EVE = :p_codice_comune  
                       AND SOGG.COD_PRO_EVE = :p_codice_provincia  """
        }
        sql += """
                            AND NVL(SOGG.DATA_ULT_EVE,TO_DATE('2222222','j'))
                                               BETWEEN NVL(:p_dal,TO_DATE('2222222','j'))
                                                   AND NVL(:p_al ,TO_DATE('3333333','j'))                          
                    ORDER BY UPPER (REPLACE (SOGG.COGNOME, ' ', '')) ASC,
                             UPPER (REPLACE (SOGG.NOME, ' ', '')) ASC
                    )
			"""

        if (tipoSoggetto == 1) {
            sql += """
                   WHERE CONTRIBUENTE = 'SI'
                 """
        }

        if (tipoSoggetto == 2) {
            sql += """
                   WHERE CONTRIBUENTE = 'NO'
                 """
        }

        def sqlTotali = """
				SELECT COUNT(*) AS TOT_COUNT
				FROM ($sql)
				"""

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def totali
        if (!wholeList) {
            totali = sessionFactory.currentSession.createSQLQuery(sqlTotali).with {
                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
                setLong('p_evento', tipoEvento)
                setDate('p_dal', dataDal)
                setDate('p_al', dataAl)
                if (comune) {
                    setLong('p_codice_comune', comune)
                    setLong('p_codice_provincia', provincia)
                }
                list()
            }[0]
        }

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('p_evento', tipoEvento)
            setDate('p_dal', dataDal)
            setDate('p_al', dataAl)
            if (comune) {
                setLong('p_codice_comune', comune)
                setLong('p_codice_provincia', provincia)
            }

            if (!wholeList) {
                setFirstResult(params.offset)
                setMaxResults(params.max)
            }

            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.contribuente = it['CONTRIBUENTE']
            record.ni = it['NI']
            record.cognome = it['COGNOME']
            record.nome = it['NOME']
            record.codFiscaleContribuente = it['CODFISCALECONTRIBUENTE']
            record.codFiscale = it['CODFISCALE']
            record.dataNascita = it['DATANASCITA']
            record.codContribuente = it['CODCONTRIBUENTE']
            record.partitaIva = it['PARTITAIVA']
            record.indirizzo = it['INDIRIZZO']
            record.comune = it['COMUNE']
            record.matricola = it['MATRICOLA']
            record.dataEvento = it['DATAEVENTO']
            record.comuneEvento = it['COMUNEEVENTO']
            records << record
        }

        def totals = [
                totalCount: (!wholeList) ? totali.TOT_COUNT : records.size(),
        ]

        return [totalCount: totals.totalCount, totals: totals, records: records]

    }

    def codiciFiscaliIncoerenti(int tipo, int pageSize, int activePage, boolean wholeList = false) {
        String sql = """
                           select translate(sogg.cognome_nome, '/', ' ') cognomenome,
                             sogg.cod_fiscale cod_fiscale_soggetto,
                             contribuenti.cod_fiscale cod_fiscale_contribuente,
                             to_char(sogg.data_nas,'DD/MM/YYYY') data_nas,
                             com_nas.denominazione ||
                             decode(ad4_provincie2.sigla,
                                    null,
                                    '',
                                    ' (' || ad4_provincie2.sigla || ')') comune_nas,
                             sogg.sesso,
                             f_cod_fiscale(sogg.cognome,
                                           sogg.nome,
                                           sogg.sesso,
                                           data_nas,
                                           com_nas.sigla_cfis) cod_fiscale_calc,
                             decode(sogg.cod_via,
                                    null,
                                    sogg.denominazione_via,
                                    archivio_vie.denom_uff) ||
                             decode(num_civ, null, '', ', ' || num_civ) ||
                             decode(suffisso, null, '', '/' || suffisso) indirizzo,
                             nvl(sogg.cap, com_res.cap) cap,
                             com_res.denominazione ||
                             decode(ad4_provincie.sigla,
                                    null,
                                    '',
                                    ' (' || ad4_provincie.sigla || ')') comune
                        from ad4_provincie,
                             ad4_provincie ad4_provincie2,
                             ad4_comuni    com_nas,
                             ad4_comuni    com_res,
                             archivio_vie,
                             soggetti      sogg,
                             contribuenti
                       where ad4_provincie.provincia(+) = com_res.provincia_stato
                         and ad4_provincie2.provincia(+) = com_nas.provincia_stato
                         and com_nas.provincia_stato(+) = sogg.cod_pro_nas
                         and com_nas.comune(+) = sogg.cod_com_nas
                         and com_res.provincia_stato(+) = sogg.cod_pro_res
                         and com_res.comune(+) = sogg.cod_com_res
                         and archivio_vie.cod_via(+) = sogg.cod_via
                         and sogg.cod_fiscale <>
                             f_cod_fiscale(sogg.cognome,
                                           sogg.nome,
                                           sogg.sesso,
                                           data_nas,
                                           com_nas.sigla_cfis)
                         and sogg.ni = contribuenti.ni
                         and length(contribuenti.cod_fiscale) = 16
                         and :p_tipo in (1, 4)
                      union
                      select translate(sogg.cognome_nome, '/', ' ') cognome_nome,
                             sogg.cod_fiscale cod_fiscale_soggetto,
                             contribuenti.cod_fiscale cod_fiscale_contribuente,       
                             to_char(sogg.data_nas,'DD/MM/YYYY') data_nas,
                             com_nas.denominazione ||
                             decode(ad4_provincie2.sigla,
                                    null,
                                    '',
                                    ' (' || ad4_provincie2.sigla || ')') comune_nas,
                             sogg.sesso,
                             f_cod_fiscale(sogg.cognome,
                                           sogg.nome,
                                           sogg.sesso,
                                           data_nas,
                                           com_nas.sigla_cfis) cod_fiscale_calc,
                             decode(sogg.cod_via,
                                    null,
                                    sogg.denominazione_via,
                                    archivio_vie.denom_uff) ||
                             decode(num_civ, null, '', ', ' || num_civ) ||
                             decode(suffisso, null, '', '/' || suffisso) indirizzo,
                             nvl(sogg.cap, com_res.cap) cap,
                             com_res.denominazione ||
                             decode(ad4_provincie.sigla,
                                    null,
                                    '',
                                    ' (' || ad4_provincie.sigla || ')') comune
                        from ad4_provincie,
                             ad4_provincie ad4_provincie2,
                             ad4_comuni    com_nas,
                             ad4_comuni    com_res,
                             archivio_vie,
                             soggetti      sogg,
                             contribuenti
                       where ad4_provincie.provincia(+) = com_res.provincia_stato
                         and ad4_provincie2.provincia(+) = com_nas.provincia_stato
                         and com_nas.provincia_stato(+) = sogg.cod_pro_nas
                         and com_nas.comune(+) = sogg.cod_com_nas
                         and com_res.provincia_stato(+) = sogg.cod_pro_res
                         and com_res.comune(+) = sogg.cod_com_res
                         and archivio_vie.cod_via(+) = sogg.cod_via
                         and contribuenti.cod_fiscale <>
                             f_cod_fiscale(sogg.cognome,
                                           sogg.nome,
                                           sogg.sesso,
                                           data_nas,
                                           com_nas.sigla_cfis)
                         and sogg.ni = contribuenti.ni
                         and length(contribuenti.cod_fiscale) = 16
                         and :p_tipo in (2, 4)
                      union
                      select translate(sogg.cognome_nome, '/', ' ') cognome_nome,
                             sogg.cod_fiscale cod_fiscale_soggetto,
                             contribuenti.cod_fiscale cod_fiscale_contribuente,
                             to_char(sogg.data_nas,'DD/MM/YYYY') data_nas,
                             com_nas.denominazione ||
                             decode(ad4_provincie2.sigla,
                                    null,
                                    '',
                                    ' (' || ad4_provincie2.sigla || ')') comune_nas,
                             sogg.sesso,
                             f_cod_fiscale(sogg.cognome,
                                           sogg.nome,
                                           sogg.sesso,
                                           data_nas,
                                           com_nas.sigla_cfis) cod_fiscale_calc,
                             decode(sogg.cod_via,
                                    null,
                                    sogg.denominazione_via,
                                    archivio_vie.denom_uff) ||
                             decode(num_civ, null, '', ', ' || num_civ) ||
                             decode(suffisso, null, '', '/' || suffisso) indirizzo,
                             nvl(sogg.cap, com_res.cap) cap,
                             com_res.denominazione ||
                             decode(ad4_provincie.sigla,
                                    null,
                                    '',
                                    ' (' || ad4_provincie.sigla || ')') comune
                        from ad4_provincie,
                             ad4_provincie ad4_provincie2,
                             ad4_comuni    com_nas,
                             ad4_comuni    com_res,
                             archivio_vie,
                             soggetti      sogg,
                             contribuenti
                       where ad4_provincie.provincia(+) = com_res.provincia_stato
                         and ad4_provincie2.provincia(+) = com_nas.provincia_stato
                         and com_nas.provincia_stato(+) = sogg.cod_pro_nas
                         and com_nas.comune(+) = sogg.cod_com_nas
                         and com_res.provincia_stato(+) = sogg.cod_pro_res
                         and com_res.comune(+) = sogg.cod_com_res
                         and archivio_vie.cod_via(+) = sogg.cod_via
                         and sogg.cod_fiscale <> contribuenti.cod_fiscale
                         and sogg.ni = contribuenti.ni
                         and length(contribuenti.cod_fiscale) = 16
                         and :p_tipo in (3, 4)
                       order by 1, 2, 3, 9
			"""

        def sqlTotali = """
				SELECT COUNT(*) AS TOT_COUNT
				FROM ($sql)
				"""

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def totali
        if (!wholeList) {
            totali = sessionFactory.currentSession.createSQLQuery(sqlTotali).with {
                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
                setLong('p_tipo', tipo)

                list()
            }[0]
        }

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('p_tipo', tipo)

            if (!wholeList) {
                setFirstResult(params.offset)
                setMaxResults(params.max)
            }
            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.cognomeNome = it['COGNOMENOME']
            record.codFiscaleSoggetto = it['COD_FISCALE_SOGGETTO']
            record.codFiscaleContribuente = it['COD_FISCALE_CONTRIBUENTE']
            record.dataNasc = it['DATA_NAS']
            record.comuneNasc = it['COMUNE_NAS']
            record.sesso = it['SESSO']
            record.codFiscaleCalcolato = it['COD_FISCALE_CALC']
            record.indirizzo = it['INDIRIZZO']
            record.cap = it['CAP']
            record.comune = it['COMUNE']
            records << record
        }

        def totals = [
                totalCount: (!wholeList) ? totali.TOT_COUNT : records.size(),
        ]

        return [totalCount: totals.totalCount, totals: totals, records: records]
    }

    def generaReportCodiciFiscaliIncoerenti(String tipo, def lista) {
        List<SoggettiReport> listaDati = new ArrayList<SoggettiReport>()
        SoggettiReport soggetti = new SoggettiReport()
        soggetti.testata = tipo
        soggetti.soggetti = lista

        listaDati.add(soggetti)
        JasperReportDef reportDef = new JasperReportDef(name: 'codiciFiscaliIncoerenti.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: listaDati
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])
        return (soggetti.soggetti.empty) ? null : jasperService.generateReport(reportDef)
    }

    def famiglieNonContribuenti(def filtri, int pageSize, int activePage, boolean wholeList = false, def ordinamento) {

        String sql = """
                 select distinct sogg1.cod_fam cod_famiglia,
                        translate(sogg1.cognome_nome, '/', ' ') cognome_nome,
                        decode(sogg1.cod_via,
                               to_number(''),
                               sogg1.denominazione_via,
                               arvi.denom_uff) ||
                        decode(sogg1.num_civ,
                               to_number(''),
                               '',
                               ', ' || sogg1.num_civ ||
                               decode(sogg1.suffisso,
                                      to_char(''),
                                      '',
                                      '/' || sogg1.suffisso)) indirizzo,
                        decode(sogg1.cod_via,
                               to_number(''),
                               sogg1.denominazione_via,
                               arvi.denom_ord) ||
                        decode(sogg1.num_civ,
                               to_number(''),
                               '',
                               ', ' || sogg1.num_civ ||
                               decode(sogg1.suffisso,
                                      to_char(''),
                                      '',
                                      '/' || sogg1.suffisso)) indirizzo_ord,
                        sogg1.cod_fiscale,
                        sogg1.ni,
                        upper(replace(sogg1.cognome, ' ', '')) cognome,
                        upper(replace(sogg1.nome, ' ', '')) nome,
                        decode(sogg1.ni_presso,
                               null,
                               null,
                               f_get_dati_presso(sogg1.ni_presso)) dati_presso
                from archivio_vie arvi, soggetti sogg1
                where  sogg1.cod_via = arvi.cod_via(+)
                       and sogg1.tipo_residente + 0 = 0
                       and sogg1.fascia + 0 = 1
                       and sogg1.sequenza_par = 1
                       and sogg1.ni = decode(:p_ni, -1, sogg1.ni, :p_ni)
                       and sogg1.cod_fam = decode(:p_cod_fam, -1, sogg1.cod_fam, :p_cod_fam)
                       and sogg1.cod_via = decode(:p_cod_via, -1, sogg1.cod_via, :p_cod_via)
                       and sogg1.cod_fiscale like nvl(:p_cf, sogg1.cod_fiscale)
                       and upper(sogg1.cognome_nome_ric) like nvl(upper(:p_nome), sogg1.cognome_nome_ric)
                       and :p_titr in ('ICIAP', 'ICI')
                       and not exists
                         (select 'x'
                                  from soggetti             sogg3,
                                       contribuenti         cont3,
                                       oggetti_pratica      ogpr3,
                                       oggetti_contribuente ogco3,
                                       pratiche_tributo     prtr3,
                                       rapporti_tributo     ratr3
                                 where ratr3.pratica = prtr3.pratica
                                   and ratr3.cod_fiscale = cont3.cod_fiscale
                                   and cont3.ni = sogg3.ni
                                   and sogg3.cod_fam = sogg1.cod_fam
                                   and sogg3.fascia = sogg1.fascia
                                   and prtr3.tipo_tributo = :p_titr
                                   and ogpr3.pratica = prtr3.pratica
                                   and ogco3.oggetto_pratica = ogpr3.oggetto_pratica
                                   and ogco3.cod_fiscale = cont3.cod_fiscale
                                   and ogco3.flag_possesso = 'S')
                union all (select distinct sogg1.cod_fam cod_famiglia,
                           translate(sogg1.cognome_nome, '/', ' ') cognome_nome,
                           decode(sogg1.cod_via,
                                  to_number(''),
                                  sogg1.denominazione_via,
                                  arvi.denom_uff) ||
                           decode(sogg1.num_civ,
                                  to_number(''),
                                  '',
                                  ', ' || sogg1.num_civ ||
                                  decode(sogg1.suffisso,
                                         to_char(''),
                                         '',
                                         '/' || sogg1.suffisso)) indirizzo,
                           decode(sogg1.cod_via,
                                  to_number(''),
                                  sogg1.denominazione_via,
                                  arvi.denom_ord) ||
                           decode(sogg1.num_civ,
                                  to_number(''),
                                  '',
                                  ', ' || sogg1.num_civ ||
                                  decode(sogg1.suffisso,
                                         to_char(''),
                                         '',
                                         '/' || sogg1.suffisso)) indirizzo_ord,
                           sogg1.cod_fiscale,
                           sogg1.ni,
                           upper(replace(sogg1.cognome, ' ', '')) cognome,
                           upper(replace(sogg1.nome, ' ', '')) nome,
                           decode(sogg1.ni_presso,
                                  null,
                                  null,
                                  f_get_dati_presso(sogg1.ni_presso)) dati_presso
                from archivio_vie arvi, soggetti sogg1
                where sogg1.cod_via = arvi.cod_via(+)
                      and sogg1.tipo_residente + 0 = 0
                      and sogg1.fascia + 0 = 1
                      and sogg1.sequenza_par = 1
                      and sogg1.ni = decode(:p_ni, -1, sogg1.ni, :p_ni)
                      and sogg1.cod_fam = decode(:p_cod_fam, -1, sogg1.cod_fam, :p_cod_fam)
                      and sogg1.cod_via = decode(:p_cod_via, -1, sogg1.cod_via, :p_cod_via)
                      and sogg1.cod_fiscale like nvl(:p_cf, sogg1.cod_fiscale)
                      and upper(sogg1.cognome_nome_ric) like nvl(upper(:p_nome), sogg1.cognome_nome_ric)
                      and :p_titr in ('TOSAP', 'TARSU', 'ICP')
                     minus
                    select distinct sogg1.cod_fam,
                           translate(sogg1.cognome_nome, '/', ' ') cognomeNome,
                           decode(sogg1.cod_via,
                                  to_number(''),
                                  sogg1.denominazione_via,
                                  arvi.denom_uff) ||
                           decode(sogg1.num_civ,
                                  to_number(''),
                                  '',
                                  ', ' || sogg1.num_civ ||
                                  decode(sogg1.suffisso,
                                         to_char(''),
                                         '',
                                         '/' || sogg1.suffisso)) indirizzo,
                           decode(sogg1.cod_via,
                                  to_number(''),
                                  sogg1.denominazione_via,
                                  arvi.denom_ord) ||
                           decode(sogg1.num_civ,
                                  to_number(''),
                                  '',
                                  ', ' || sogg1.num_civ ||
                                  decode(sogg1.suffisso,
                                         to_char(''),
                                         '',
                                         '/' || sogg1.suffisso)) indirizzo_ord,
                           sogg1.cod_fiscale,
                           sogg1.ni,
                           upper(replace(sogg1.cognome, ' ', '')) cognome,
                           upper(replace(sogg1.nome, ' ', '')) nome,
                           decode(sogg1.ni_presso,
                                  null,
                                  null,
                                  f_get_dati_presso(sogg1.ni_presso)) dati_presso
                    from archivio_vie arvi, soggetti sogg1
                    where sogg1.cod_via = arvi.cod_via(+)
                      and sogg1.tipo_residente + 0 = 0
                      and sogg1.fascia + 0 = 1
                      and sogg1.sequenza_par = 1
                      and sogg1.ni = decode(:p_ni, -1, sogg1.ni, :p_ni)
                      and sogg1.cod_fam = decode(:p_cod_fam, -1, sogg1.cod_fam, :p_cod_fam)
                      and sogg1.cod_via = decode(:p_cod_via, -1, sogg1.cod_via, :p_cod_via)
                      and sogg1.cod_fiscale like nvl(:p_cf, sogg1.cod_fiscale)
                      and upper(sogg1.cognome_nome_ric) like nvl(upper(:p_nome), sogg1.cognome_nome_ric)
                      and :p_titr in ('TOSAP', 'TARSU', 'ICP')
                      and (sogg1.cod_fam, sogg1.fascia) in
                          (select sogg2.cod_fam, sogg2.fascia
                             from oggetti_validita ogva,
                                  contribuenti     cont2,
                                  soggetti         sogg2,
                                  oggetti_pratica  ogpr,
                                  categorie        cate
                            where ogva.tipo_tributo = :p_titr
                              and ogva.cod_fiscale = cont2.cod_fiscale
                              and sogg2.ni = cont2.ni
                              and ogva.al is null
                              and ogva.oggetto_pratica = ogpr.oggetto_pratica
                              and ogpr.categoria = cate.categoria
                              and ogpr.tributo = cate.tributo
                              and decode(ogva.tipo_tributo,
                                         'TARSU',
                                         cate.flag_domestica,
                                         'S') = 'S'))                       
			"""

        if (ordinamento == 'a') {
            sql += """ order by cognome,nome,cod_fiscale,cod_famiglia,indirizzo_ord """
        } else {
            if (ordinamento == 'c') {
                sql += """ order by cod_fiscale,cognome,nome,cod_famiglia,indirizzo_ord """
            } else {
                if (ordinamento == 'i') {
                    sql += """ order by indirizzo_ord,cod_fiscale,cognome,nome,cod_famiglia """
                }
            }
        }


        def sqlTotali = """
				SELECT COUNT(*) AS TOT_COUNT
				FROM ($sql)
				"""

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def filtroCognomeNome = ""
        if (filtri.cognome != null && !filtri.cognome.empty) {
            filtroCognomeNome += filtri.cognome + "/"
        } else {
            filtroCognomeNome += "%/"
        }

        if (filtri.nome != null && !filtri.nome.empty) {
            filtroCognomeNome += filtri.nome
        } else {
            filtroCognomeNome += "%"
        }

        filtroCognomeNome = filtroCognomeNome.empty ? null : filtroCognomeNome

        def totali
        if (!wholeList) {
            totali = sessionFactory.currentSession.createSQLQuery(sqlTotali).with {
                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
                setString('p_titr', filtri.tipoTributo.codice)
                setString('p_nome', filtroCognomeNome)
                setString('p_cf', filtri.codFiscale)
                setLong('p_cod_via', (filtri.codiceVia) ? filtri.codiceVia : -1)
                setLong('p_ni', (filtri.id) ? filtri.id : -1)
                setLong('p_cod_fam', (filtri.codFamiglia) ? filtri.codFamiglia : -1)

                list()
            }[0]
        }

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            setString('p_titr', filtri.tipoTributo.codice)
            setString('p_nome', filtroCognomeNome)
            setString('p_cf', filtri.codFiscale)
            setLong('p_cod_via', (filtri.codiceVia) ? filtri.codiceVia : -1)
            setLong('p_ni', (filtri.id) ? filtri.id : -1)
            setLong('p_cod_fam', (filtri.codFamiglia) ? filtri.codFamiglia : -1)

            if (!wholeList) {
                setFirstResult(params.offset)
                setMaxResults(params.max)
            }
            list()
        }

        def totals = [
                totalCount: (!wholeList) ? totali.TOT_COUNT : results.size(),
        ]

        return [totalCount: totals.totalCount, totals: totals, records: results]
    }

    def generaReportFamiglieNonContribuenti(String testata, def lista) {
        List<SoggettiReport> listaDati = new ArrayList<SoggettiReport>()
        SoggettiReport soggetti = new SoggettiReport()
        soggetti.testata = testata
        soggetti.soggetti = lista

        listaDati.add(soggetti)
        JasperReportDef reportDef = new JasperReportDef(name: 'famiglieNonContribuenti.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: listaDati
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])
        return (soggetti.soggetti.empty) ? null : jasperService.generateReport(reportDef)
    }

    def codiciFiscaliDoppi(int pageSize, int activePage, boolean wholeList = false, def ordinamento) {

        String sql = """
                 select  to_char(soggetti.ni) ni,
                         translate(soggetti.cognome_nome, '/', ' ') nominativo,
                         soggetti.cod_fiscale,
                         soggetti.partita_iva,         
                         soggetti.data_nas data_nas,
                         decode(ad4_comuni.cap, null, '', ad4_comuni.denominazione) || ' ' ||
                         decode(ad4_provincie.sigla,
                                null,
                                '',
                                ' (' || ad4_provincie.sigla || ')') comune_nas,
                         decode(soggetti.tipo_residente,0,1,0) flag_gsd,                       
                         decode(soggetti.tipo_residente,0,'SI','NO') tipo_residente,
                         decode(tipo_residente, 0, decode(fascia, 1, 1, 0), 0) flag_res,
                         decode(tipo_residente, 0, decode(fascia, 1, 'SI', 'NO'), 'NO') residente,
                         decode(cont.ni, null, 0, 1) flag_contr,
                         decode(cont.ni, null, 'NO', 'SI') contribuente,
                         cont.cod_fiscale cont_cod_fiscale,
                         decode(cont.cod_controllo,
                                null,
                                to_char(cont.cod_contribuente),
                                cont.cod_contribuente || '-' || cont.cod_controllo) cod_contr,
                         cont.cod_contribuente,
                         cont.cod_controllo
                    from ad4_comuni, ad4_provincie, contribuenti cont, soggetti
                   where 1 < (select count(ni)
                                from soggetti sogg2
                               where sogg2.cod_fiscale = soggetti.cod_fiscale
                                  or sogg2.partita_iva = soggetti.partita_iva)
                     and cont.ni(+) = soggetti.ni
                     and ad4_provincie.provincia(+) = ad4_comuni.provincia_stato
                     and ad4_comuni.comune(+) = soggetti.cod_com_nas
                     and ad4_comuni.provincia_stato(+) = soggetti.cod_pro_nas
			"""

        if (ordinamento == 'a') {
            sql += """ order by nominativo, nvl(cod_fiscale,partita_iva) """
        } else {
            if (ordinamento == 'c') {
                sql += """  order by nvl(cod_fiscale,partita_iva),nominativo """
            } else {
                if (ordinamento == 'p') {
                    sql += """  order by nvl(partita_iva,0),nominativo """
                }
            }
        }

        def sqlTotali = """
				SELECT COUNT(*) AS TOT_COUNT
				FROM ($sql)
				"""

        def params = [:]
        params.max = pageSize ?: 25
        params.activePage = activePage ?: 0
        params.offset = params.activePage * params.max

        def totali
        if (!wholeList) {
            totali = sessionFactory.currentSession.createSQLQuery(sqlTotali).with {
                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
                list()
            }[0]
        }

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            if (!wholeList) {
                setFirstResult(params.offset)
                setMaxResults(params.max)
            }

            list()
        }


        def records = []

        results.each {
            def record = [:]
            record.id = it['NI']
            record.cognomeNome = it['NOMINATIVO']
            record.codFiscale = it['COD_FISCALE']
            record.partitaIva = it['PARTITA_IVA']
            record.dataNas = it['DATA_NAS']
            record.comuneNas = it['COMUNE_NAS']
            record.gsd = it['TIPO_RESIDENTE']
            record.residente = it['RESIDENTE']
            record.contribuente = it['CONTRIBUENTE']
            record.flagGSD = (it['FLAG_GSD'] == 0) ? '' : 'X'
            record.flagRes = (it['FLAG_RES'] == 0) ? '' : 'X'
            record.flagContr = (it['FLAG_CONTR'] == 0) ? '' : 'X'
            record.codContr = it['COD_CONTR']
            records << record
        }

        def totals = [
                totalCount: (!wholeList) ? totali.TOT_COUNT : records.size(),
        ]

        return [totalCount: totals.totalCount, totals: totals, records: records]
    }

    def generaReportCodiciFiscaliDoppi(String testata, def lista) {
        List<SoggettiReport> listaDati = new ArrayList<SoggettiReport>()
        SoggettiReport soggetti = new SoggettiReport()
        soggetti.testata = testata
        soggetti.soggetti = lista

        listaDati.add(soggetti)
        JasperReportDef reportDef = new JasperReportDef(name: 'codiciFiscaliDoppi.jasper'
                , fileFormat: JasperExportFormat.PDF_FORMAT
                , reportData: listaDati
                , parameters: [SUBREPORT_DIR: servletContext.getRealPath('/reports') + "/",
                               ente         : ad4EnteService.getEnte()])
        return (soggetti.soggetti.empty) ? null : jasperService.generateReport(reportDef)
    }

    def verificaCAP(Long ni) {

        // Se siamo in inserimento non si effettua la verifica.
        if (ni == null) {
            return false
        }

        String sql = """
                      SELECT nvl(f_verifica_cap (SOGG.cod_pro_res,SOGG.cod_com_res,SOGG.cap),'') VERIFICA
                        FROM SOGGETTI SOGG
                       WHERE SOGG.NI = :P_NI
           """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('P_NI', ni)

            list()
        }

        boolean verifica = false
        results.each {
            if (it['VERIFICA'])
                verifica = true
        }
        return verifica
    }

    // Esegue query
    private eseguiQuery(def query, def filtri, def paging, def wholeList = false) {

        filtri = filtri ?: [:]

        if (!query || query.isEmpty()) {
            throw new RuntimeException("Query non specificata.")
        }

        def sqlQuery = sessionFactory.currentSession.createSQLQuery(query)
        sqlQuery.with {

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            filtri.each { k, v ->
                if (v instanceof List) {
                    setParameterList(k, v)
                } else {
                    setParameter(k, v)
                }
            }

            if (!wholeList) {
                setFirstResult(paging.offset)
                setMaxResults(paging.max)
            }
            list()
        }
    }

    def eliminaSoggetto(def soggettoDTO) {

        def messaggio = ""

        messaggio = checkSoggettoEliminabile(soggettoDTO.id)

        // Eliminazione possibile
        if (messaggio.empty) {

            //Controllo se il soggetto è indicato come presso di un altro soggetto
            if (checkSoggettoPresso(soggettoDTO.id)) {
                return "Soggetto usato come presso per altro/i soggetto/i"
            }

            Soggetto.get(soggettoDTO.id).delete(failOnError: true, flush: true)
        }
        return messaggio
    }

    def checkSoggettoEliminabile(def nInd) {

        def params = []
        params << nInd

        Sql sql = new Sql(dataSource)
        sql.call('{call SOGGETTI_PD(?)}', params)

        return ''
    }

    def checkSoggettoPresso(def nInd) {

        def parametri = [:]

        parametri << ['p_ni': nInd]

        def query = """
                    SELECT count(*)
                    FROM soggetti
                    WHERE ni_presso = :p_ni
                    """
        def result = sessionFactory.currentSession.createSQLQuery(query).with {
            parametri.each { k, v ->
                setParameter(k, v)
            }
            list()
        }

        return result.get(0) > 0
    }


    def getListaRecapiti(def idSoggetto) {
        RecapitoSoggetto.createCriteria().list {
            eq("soggetto.id", idSoggetto)

            order("tipoTributo", 'asc')
            order("tipoRecapito", 'asc')
            order("dal", 'desc')

        }.toDTO(["tipoRecapito", "comuneRecapito", "comuneRecapito.ad4Comune", "comuneRecapito.ad4Comune.provincia", "archivioVie"])
    }

    def eliminaRecapito(def recapito) {
        recapito.delete(failOnError: true, flush: true)
    }

    def sostituisciContribuenteRecapiti(def soggOrigine, def soggDestinazione, def listaRecapiti, def listaRecapitiEliminati) {

        def result = [:]

        // Tutto in un'unica transazione

        // withNewSession usato per non causare la chiusura della sessione tra l'eliminazione/salvataggio dei recapiti e la chiamata a procedure
        Contribuente.withNewSession {

            // Eliminazione recapiti eliminati manualmente
            listaRecapitiEliminati.each {
                eliminaRecapito(it.toDomain())
            }


            // Eliminazione recapiti dai soggetti
            listaRecapiti.each {
                eliminaRecapito(it.toDomain())
            }

            // Set dei nuovi recapiti sul soggetto di origine e salvataggio
            listaRecapiti.each {
                it.soggetto = soggOrigine.toDTO()
                it.id = null
                salvaRecapitoSoggetto(it)
            }

            // Invocazione procedure sostituzione
            result = sostituisciContribuente(soggOrigine.id, soggOrigine.codFiscale, soggDestinazione.id, soggDestinazione.codFiscale)

            // Se è presente un errore, si effettua il rollback lanciando un'eccezione
            if (result.result != 0) {
                throw new Application20999Error(result.messaggio, result.result)
            }

        }

        return result
    }

    def getErediSoggetto(SoggettoDTO soggetto) {
        return EredeSoggetto.createCriteria().list {


            eq('soggetto.id', soggetto.id)
            order('numeroOrdine')
        }.toDTO(["soggettoEredeId"])
    }

    def isDeceduto(SoggettoDTO soggetto) {
        return soggetto?.stato?.id == STATO_SOGGETTO_DECEDUTO
    }

    def allineamentoComuni(){
        Sql sql = new Sql(dataSource)
        sql.call('{call ALLINEAMENTO_COMUNI()}')
    }

    def controllaEsistenzaSoggetto(def nome, def cognome, def codFiscale) {

        def listaSoggetti = Soggetto.createCriteria().list {
            ilike("nome", nome)
            ilike("cognome", cognome)
            ilike("codFiscale", codFiscale ?: "%")
        }

        if (listaSoggetti.size() > 0) {
            return ["soggetto": listaSoggetti[0], "exists": true]
        } else {
            return ["soggetto": null, "exists": false]
        }
    }

}
