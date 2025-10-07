package it.finmatica.datiesterni.beans

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.datiesterni.encecpf.EncEcPfImport
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.datiesterni.DocumentoCaricato
import org.apache.log4j.Logger
import org.springframework.transaction.annotation.Propagation

class ImportDicEncEcPf {

    private static final Logger log = Logger.getLogger(ImportDicEncEcPf.class)

    CommonService commonService
    def dataSource

    def importa(def parametri) {

        def documentId = parametri.idDocumento
        DocumentoCaricato doc = DocumentoCaricato.get(documentId)

        try {

            def utente = parametri.utente.getDomainObject()

            log.info("Elaborazione dati per documentoId [$documentId]...")
            def dichiarazioni = new EncEcPfImport().importa(new String(doc.contenuto), documentId, utente, commonService.codiceBelfioreCliente())

            log.info("Salvataggio dati per documentoId [$documentId]...")
            dichiarazioni.each { k, v ->

                v.B.toDomain().save(flush: true, failOnError: true)

                v.C?.each { it ->
                    it.toDomain().save(flush: true, failOnError: true)
                }

                v.D?.each { it ->
                    it.toDomain().save(flush: true, failOnError: true)
                }

            }

            log.info("Esecuzione procedure di import per documentoId [$documentId]...")
            def msg = esegui(documentId, utente?.id)

            doc.stato = 2
            doc.utente = parametri.utente.getDomainObject()
            doc.note = msg
            doc.save(flush: true, failOnError: true)

            log.info("Importazione enc ecpf per documentoId [$documentId] completata con successo")
        } catch (Exception e) {
            log.error("Errore in importazione enc ecpf " + e.getMessage())
            doc.stato = 4
            doc.utente = parametri.utente.getDomainObject()
            doc.save(flush: true, failOnError: true)
            throw e
        }
    }

    def esegui(def idDocumento, def utente) {

        String messaggio = ""

        try {
            Sql sql = new Sql(dataSource)
            sql.call("{call CARICA_DIC_ENC_ECPF.ESEGUI_WEB(?, ?, ?)}",
                    [
                            idDocumento,
                            utente,
                            Sql.VARCHAR
                    ]
            )
                    {
                        resMsg ->
                            messaggio = resMsg
                    }
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                messaggio = e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                messaggio = e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
            } else {
                throw e
            }
        }

        return messaggio
    }
}

