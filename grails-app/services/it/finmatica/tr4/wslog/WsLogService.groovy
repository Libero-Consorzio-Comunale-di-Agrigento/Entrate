package it.finmatica.tr4.wslog

import it.finmatica.tr4.WsLog
import org.hibernate.SessionFactory
import transform.AliasToEntityCamelCaseMapResultTransformer

class WsLogService {

    SessionFactory sessionFactory

    void saveSmartPndLog(def details) {
        WsLog.withNewTransaction {
            new WsLog(tipo: WsLog.LOG_TYPE.SMART_PND,
                    data: new Date(),
                    endpoint: details.requestUrl,
                    logRichiesta: details.requestContent,
                    logRisposta: details.responseContent,
                    logErrore: getExceptionStackTrace(details.exception),
                    idComunicazione: details.idComunicazione).save(failOnError: true, flush: true)
        }
    }

    void saveSmartPndCallbackLog(def details) {
        WsLog.withNewTransaction {
            new WsLog(tipo: WsLog.LOG_TYPE.SMART_PND,
                    data: new Date(),
                    endpoint: details.requestUrl,
                    tipoCallback: details.tipoCallback,
                    logRichiesta: details.requestContent,
                    logRisposta: details.responseContent,
                    logErrore: getExceptionStackTrace(details.exception),
                    idComunicazione: details.idComunicazione).save(failOnError: true, flush: true)
        }
    }

    void saveDepagLog(def details) {
        WsLog.withNewTransaction {
            def retrievedCodIuv = null
            def retrievedCodFiscale = null
            if (details.codIuv == null || details.codFiscale == null) {
                def selectQuery = """
                select dedo.cod_iuv, dedo.codice_ident_pagatore
                  from depag_dovuti dedo
                 where dedo.servizio = :servizio
                   and dedo.idback = :idBack
            """
                def sqlQuery = sessionFactory.currentSession.createSQLQuery(selectQuery)
                def results = sqlQuery.with {
                    setParameter('servizio', details.servizio)
                    setParameter('idBack', details.idBack)
                    resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
                    list()
                }
                if (!results.empty) {
                    retrievedCodIuv = results[0]['codIuv']
                    retrievedCodFiscale = results[0]['codFiscale']
                }
            }

            new WsLog(tipo: WsLog.LOG_TYPE.DEPAG,
                    data: new Date(),
                    endpoint: details.requestUrl,
                    logRichiesta: details.requestContent,
                    logRisposta: details.responseContent,
                    logErrore: getExceptionStackTrace(details.exception),
                    idback: details.idBack,
                    codIuv: details.codIuv ?: retrievedCodIuv,
                    codFiscale: details.codFiscale ?: retrievedCodFiscale
            ).save(failOnError: true, flush: true)
        }
    }

    void savePortaleTrtibutiLog(def details) {
        WsLog.withNewTransaction {
            new WsLog(tipo: WsLog.LOG_TYPE.PORTALE,
                    data: new Date(),
                    endpoint: details.requestUrl,
                    logRichiesta: details.requestContent,
                    logRisposta: details.responseContent,
                    logErrore: getExceptionStackTrace(details.exception)
            ).save(failOnError: true, flush: true)
        }
    }

    private getExceptionStackTrace(Exception exception) {
        if (exception == null) {
            return null
        }
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        exception.printStackTrace(pw);
        return sw.toString()
    }

}
