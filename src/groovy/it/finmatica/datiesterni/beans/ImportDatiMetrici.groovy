package it.finmatica.datiesterni.beans

import it.finmatica.datiesterni.datimetrici.DatiOut
import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.datiesterni.ImportaService
import org.apache.log4j.Logger

import javax.xml.bind.JAXBContext
import javax.xml.bind.Unmarshaller
import javax.xml.transform.Source
import javax.xml.transform.stream.StreamSource

class ImportDatiMetrici {

    private static final Logger log = Logger.getLogger(ImportDatiMetrici.class)

    ImportaService importaService

    def importaDatiMetrici(def parametri) {

        long idDocumento = parametri.idDocumento
        DocumentoCaricato doc = DocumentoCaricato.get(idDocumento)

        try {

            String xml = new String(doc.contenuto)

            JAXBContext jaxbContext = JAXBContext.newInstance("it.finmatica.datiesterni.datimetrici")
            Unmarshaller jaxbUnmarshaller = jaxbContext.createUnmarshaller()

            Source source = new StreamSource(new StringReader(xml.replaceFirst(/<DatiOut xmlns=[\s\S]*?>/, '<DatiOut xmlns="http://">')))

            DatiOut dati = (DatiOut) jaxbUnmarshaller.unmarshal(source)

            def tipologia = determinaTipologia(xml)
            importaService.creaDatiMetrici(dati, parametri, tipologia)

            def totUiu = dati.uiu.size()
            def totSoggetti = 0
            dati.uiu.soggetti?.each {
                totSoggetti += ((it?.pf?.size() ?: 0) + (it?.pnf?.size() ?: 0))
            }

            def totDatiNuovi = 0
            dati.uiu.each {
                totDatiNuovi += (it.datiNuovi ? 1 : 0)
            }

            doc.note = "Immobili inseriti: $totUiu\n" +
                    "Soggetti inseriti: $totSoggetti\n" +
                    "DatiNuovi inseriti $totDatiNuovi"

            doc.stato = 2
            doc.utente = parametri.utente.getDomainObject()
            doc.save(flush: true, failOnError: true)

            return "file " + doc.nomeDocumento + " importato con successo"
        } catch (Throwable e) {
            log.error("Errore in importazione dati metrici " + e.getMessage())
            doc.stato = 4
            doc.utente = parametri.utente.getDomainObject()
            doc.save(flush: true, failOnError: true)
            throw e
        }
    }

    def determinaTipologia(String dati) {
        if (dati.indexOf('xmlns="http://www.agenziaterritorio.it/TARSU.xsd"') > 0) {
            return 'TARSU'
        } else if (dati.indexOf('xmlns="http://www.agenziaentrate.it/TARES"') > 0) {
            return 'TARES'
        } else {
            throw new RuntimeException("Tipologia non supportata")
        }
    }
}
