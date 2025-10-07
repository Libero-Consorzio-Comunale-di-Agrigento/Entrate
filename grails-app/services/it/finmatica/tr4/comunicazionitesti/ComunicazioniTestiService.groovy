package it.finmatica.tr4.comunicazionitesti

import grails.transaction.Transactional
import grails.util.Holders
import groovy.sql.Sql
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.comunicazioni.DettaglioComunicazione
import it.finmatica.tr4.comunicazioni.TipiCanale
import it.finmatica.tr4.comunicazioni.testi.AllegatoTesto
import it.finmatica.tr4.comunicazioni.testi.ComunicazioneTesti
import it.finmatica.tr4.dto.comunicazioni.TipiCanaleDTO
import org.hibernate.criterion.CriteriaSpecification
import org.springframework.transaction.annotation.Propagation

class ComunicazioniTestiService {
    static def TIPI_CANALE_GESTIONE_ALLEGATI = [TipiCanaleDTO.EMAIL, TipiCanaleDTO.PEC]

    CommonService commonService
    ComunicazioneTesto comunicazioneTesto
    def dataSource

    def generaCampiUnione(String tipoTributo = 'TRASV', String tipoComunicazione = 'LGE', Map input = null) {
        comunicazioneTesto.generateData(tipoTributo, tipoComunicazione, input)
        return comunicazioneTesto.output
    }

    def generaCampiUnioneRaggruppati(String tipoTributo = 'TRASV', String tipoComunicazione = 'LGE') {
        comunicazioneTesto.generateData(tipoTributo, tipoComunicazione, null)
        return comunicazioneTesto.groupedOutput
    }

    def mailMerge(String tipoTributo, String tipoComunicazione, String testo, Map input) {
        Map output = generaCampiUnione(tipoTributo, tipoComunicazione, input)
        def testoTrasformato = testo

        // Testo vuoto, nulla da fare
        if (!testo?.trim()) {
            return ""
        }

        output.keySet().each {
            testoTrasformato = testoTrasformato.replaceAll("<$it>", output[(it)])
        }

        // Se non sono stati sostituiti tutti i campi unione si aggiunge un messaggio di errore
        def found = testoTrasformato =~ /<.*?>/
        if (found) {
            testoTrasformato = testoTrasformato.replaceAll("<", "<ERRORE! Campo unione non trovato: ")
        }
        return testoTrasformato
    }

    def getListaTipiCanale() {

        def smartPndService = Holders.grailsApplication.mainContext.getBean("smartPndService")

        def lista = TipiCanale.findAll()
                .findAll()
                .sort { it.id }.toDTO()
        if (!smartPndService.smartPNDAbilitato()) {
            lista = lista.findAll { it.id != 4 }
        }

        return lista
    }

    def getListaComunicazioneTesti(def filter) {
        def lista = ComunicazioneTesti.createCriteria().list {

            createAlias("tipoCanale", "tica", CriteriaSpecification.INNER_JOIN)

            eq("tipoTributo", filter.tipoTributo)
            eq("tipoComunicazione", filter.tipoComunicazione)

            if (filter?.tipoCanale != null) {
                eq("tica.id", filter.tipoCanale.id)
            }
            if (filter?.tipiCanale != null && !filter.tipiCanale.empty) {
                inList("tica.id", filter.tipiCanale)
            }
            if (filter?.descrizione) {
                ilike("descrizione", filter.descrizione)
            }
            if (filter?.oggetto) {
                ilike("oggetto", filter.oggetto)
            }
            if (filter?.testo) {
                ilike("testo", "%${filter.testo}%")
            }
            if (filter?.note) {
                ilike("note", "%${filter.note}%")
            }
        }.toDTO(["tipoCanale"])

        lista.each {
            it.presenzaAllegati = AllegatoTesto.countByComunicazioneTesti(it.toDomain()) > 0
        }

        return lista

    }

    def salvaComunicazioneTesto(def comunicazioneTesti) {
        def ct = comunicazioneTesti.toDomain().save(flush: true, failOnError: true)
        salvaAllegatiTesto(ct.toDTO(), comunicazioneTesti.allegatiTesto)
        return ct
    }

    void elimina(def comunicazioneTesto) {
        def ct = comunicazioneTesto.toDomain()

        def allegati = AllegatoTesto.findAllByComunicazioneTesti(ct)
        if (!allegati.empty) {
            AllegatoTesto.deleteAll(allegati)
        }

        ct.delete(flush: true, failOnError: true)
    }

    def generaCampiUnioneDefault() {
        return generaCampiUnione()
    }

    def esisteDettaglioComunicazione(def tipoTributo, def tipoCoamunicazione, def tipoCanale, def tipoComunicazionePnd, def sequenza) {

        return DettaglioComunicazione.createCriteria().count() {
            eq("tipoTributo", tipoTributo)
            eq("tipoComunicazione", tipoCoamunicazione)
            eq("tipoComunicazionePnd", tipoComunicazionePnd)
            eq("tipoCanale", tipoCanale)

            // In caso di update se deve escludere il dettaglio in modifica
            if (sequenza != null) {
                ne("sequenza", sequenza)
            }
        } > 0

    }

    def getListaAllegatiTesto(def comunicazioneTesti) {
        if (!comunicazioneTesti?.id) {
            return []
        }
        return AllegatoTesto.findAllByComunicazioneTesti(comunicazioneTesti.toDomain()).toDTO()
    }

    AllegatoTesto creallegatoTesto(def comunicazioneTesti) {
        def allegato = new AllegatoTesto(comunicazioneTesti: comunicazioneTesti)
        return allegato
    }

    private salvaAllegatiTesto(def comunicazione, def allegati) {

        AllegatoTesto.deleteAll(
                AllegatoTesto.createCriteria().list {
                    eq("comunicazioneTesti", comunicazione.toDomain())
                    not { "in"("sequenza", allegati.collect { it.sequenza } + [-1 as short]) }
                })

        allegati.each { a ->
            a.comunicazioneTesti = comunicazione

            a.sequenza = allegatiTestoNR(a)

            a.toDomain().save(flush: true, failOnError: true)
        }

    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    private allegatiTestoNR(def allegatoTesto) {
        def sequenza = allegatoTesto.sequenza
        if (sequenza == null) {
            Sql sql = new Sql(dataSource)
            sql.call('{call ALLEGATI_TESTO_NR(?, ?)}', [allegatoTesto.comunicazioneTesti.id, Sql.NUMERIC],
                    {
                        sequenza = it
                    })
        }
        return sequenza
    }
}
