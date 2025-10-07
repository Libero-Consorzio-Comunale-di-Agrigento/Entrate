package it.finmatica.tr4.datiesterni

import grails.transaction.NotTransactional
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.AnomalieCaricamento
import it.finmatica.tr4.dto.datiesterni.TitoloDocumentoDTO
import org.hibernate.criterion.CriteriaSpecification

@Transactional
class ImportDatiEsterniService {

    def dataSource

    @NotTransactional
    def caricaListaDocumenti(def filtri, int pageSize, int activePage) {
        def listaDocumenti = DocumentoCaricato.createCriteria().list {

            createAlias("titoloDocumento", "titolo", CriteriaSpecification.INNER_JOIN)

            projections {
                property("id")                    // 0
                property("titolo.descrizione")    // 1
                property("nomeDocumento")        // 2
                property("stato")                // 3
                property("titolo.id")            // 4
                property("lastUpdated")            // 5
                property("note")                // 6
                property("titolo.nomeBean")        // 7
                property("titolo.id")        // 8
            }

            if (filtri){
                if (filtri.titoloDocumentoId) {
                    eq("titoloDocumento.id", filtri.titoloDocumentoId)
                }
                if (filtri.stato) {
                    eq("stato", filtri.stato)
                }
                if (filtri.nomeFile) {
                    ilike("nomeDocumento", "%$filtri.nomeFile%")
                }
                if (filtri.daIdDocumento) {
                    ge("id", filtri.daIdDocumento)
                }
                if (filtri.aIdDocumento){
                    le("id", filtri.aIdDocumento)
                }
            }

            order("id", "desc")
            firstResult(pageSize * activePage)
            maxResults(pageSize)
        }.collect { row ->
            [id                : row[0]
             , descrizione     : row[1]
             , nomeDocumento   : row[2]
             , stato           : row[3]
             , descrizioneStato: getStato(row[3])
             , titolo          : row[4]
             , lastUpdated     : row[5].format("dd/MM/yyyy") + " (" + row[5].format("HH:mm") + ")"
             , note            : row[6]
             , nomeBean        : row[7]
             , titoloDocumento : row[8]
            ]
        }

        def totale = DocumentoCaricato.createCriteria().list {

            createAlias("titoloDocumento", "titolo", CriteriaSpecification.INNER_JOIN)

            projections {
                countDistinct("id")
            }

            if (filtri) {
                if (filtri.titoloDocumentoId) {
                    eq("titoloDocumento.id", filtri.titoloDocumentoId)
                }
                if (filtri.stato) {
                    eq("stato", filtri.stato)
                }
                if (filtri.nomeFile) {
                    ilike("nomeDocumento", "%$filtri.nomeFile%")
                }
                if (filtri.daIdDocumento) {
                    ge("id", filtri.daIdDocumento)
                }
                if (filtri.aIdDocumento) {
                    le("id", filtri.aIdDocumento)
                }
            }
        }

        return [lista: listaDocumenti, totale: totale]
    }

    @NotTransactional
    def getListaDocumenti(def filtri, def pageSize, def activePage) {

        def listaDocumenti = DocumentoCaricato.createCriteria().list(max: pageSize, offset: pageSize * activePage) {

            createAlias("titoloDocumento", "titolo", CriteriaSpecification.INNER_JOIN)

            projections {
                property("id")                    // 0
                property("titolo.descrizione")    // 1
                property("nomeDocumento")        // 2
                property("stato")                // 3
                property("titolo.id")            // 4
                property("lastUpdated")            // 5
                property("note")                // 6
                property("titolo.nomeBean")        // 7
                property("titolo.id")        // 8
            }

            ne("titolo.id", 40L)

            if (filtri) {

                if (filtri.titoloDocumentoId) {
                    eq("titoloDocumento.id", filtri.titoloDocumentoId)
                }
                if (filtri.stato) {
                    eq("stato", filtri.stato)
                }
                if (filtri.nomeFile) {
                    ilike("nomeDocumento", "%$filtri.nomeFile%")
                }
                if (filtri.daIdDocumento) {
                    ge("id", filtri.daIdDocumento)
                }
                if (filtri.aIdDocumento) {
                    le("id", filtri.aIdDocumento)
                }
            }

            order("id", "desc")
        }

        def lista = listaDocumenti.collect { row ->
            [id                : row[0]
             , descrizione     : row[1]
             , nomeDocumento   : row[2]
             , stato           : row[3]
             , descrizioneStato: getStato(row[3])
             , titolo          : row[4]
             , lastUpdated     : row[5].format("dd/MM/yyyy") + " (" + row[5].format("HH:mm") + ")"
             , note            : row[6]
             , nomeBean        : row[7]
             , titoloDocumento : row[8]
            ]
        }

        return [totale: listaDocumenti.totalCount, listaDocumenti: lista]
    }

    String getStato(Short stato) {
        String descrizioneStato
        switch (stato) {
            case 1:
                descrizioneStato = "Da caricare"
                break
            case 2:
                descrizioneStato = "Caricato"
                break
            case 3:
                descrizioneStato = "Annullato"
                break
            case 4:
                descrizioneStato = "Errore"
                break
            case 15:
                descrizioneStato = "Caricamento in corso"
        }
        return descrizioneStato
    }

    def cambiaStato(Long idDocumento, short stato) {

        def doc = DocumentoCaricato.get(idDocumento)
        doc.stato = stato
        doc.save(flush: true, failOnError: true)

    }

    def loadContenuto(def id) {
        return DocumentoCaricato.findById(id).contenuto
    }

    def findByNomeDocumento(String nome) {
        return DocumentoCaricato.findByNomeDocumento(nome)
    }

    def annullaDocumento(def id) {
        def doc = DocumentoCaricato.findById(id)
        doc.stato = 3
        doc.save(flush: true, failOnError: true)
    }

    def loadFile(TitoloDocumentoDTO titoloDocumento, String nome, def file, Map<String, ByteArrayInputStream> listaAllegati) {
        Date date = new Date()
        DocumentoCaricato documento = new DocumentoCaricato()

        documento.titoloDocumento = TitoloDocumento.get(titoloDocumento.id)
        documento.nomeDocumento = nome
        documento.contenuto = file.getBytes()
        documento.stato = 1

        documento.save(failOnError: true, flush: true)

        listaAllegati?.each { key, value ->
            String[] splits = key.split("\\.")
            // Se DOCFA
            if (titoloDocumento.id == 22) {
                if (splits[1] == "DAT") {
                    DocumentoCaricatoMulti allegato = new DocumentoCaricatoMulti()
                    allegato.documentoCaricato = documento
                    allegato.nomeDocumento = key
                    allegato.contenuto = value.getBytes()

                    if (listaAllegati.containsKey(splits[0] + ".PDF")) {
                        allegato.nomeDocumento2 = splits[0] + ".PDF"
                        allegato.contenuto2 = (listaAllegati.getAt(splits[0] + ".PDF")).getBytes()
                    }

                    allegato.save(failOnError: true, flush: true)
                }
            } else {
                // Altri titoli documento
                DocumentoCaricatoMulti allegato = new DocumentoCaricatoMulti()
                allegato.documentoCaricato = documento
                allegato.nomeDocumento = key
                allegato.contenuto = value.getBytes()
                allegato.save(failOnError: true, flush: true)
            }
        }
        documento.save(failOnError: true)
    }

    @NotTransactional
    def caricaAnomalie(def idDocumento) {

        def listaAnomalieSoggetti = AnomalieCaricamento.createCriteria().list {
            eq('documentoId', idDocumento)
            isNull('oggetto')
        }

        def listaAnomalieOggetti = AnomalieCaricamento.createCriteria().list {
            eq('documentoId', idDocumento)
            isNotNull('oggetto')
        }

        return [anomalieSoggetti: listaAnomalieSoggetti, anomalieOggetti: listaAnomalieOggetti]
    }

    def verificaCaricamento(def documentoId) {

        String r
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_CARICA_DIC_NOTAI_VERIFICA(?)}'
                , [Sql.VARCHAR
                   , documentoId
        ]) { r = it }

        return r
    }
}
