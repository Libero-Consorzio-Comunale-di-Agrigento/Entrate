package it.finmatica.datiesterni.encecpf

import grails.util.Holders
import groovy.json.JsonSlurper
import org.apache.log4j.Logger

abstract class DichiarazioniImport {

    protected static final Logger log = Logger.getLogger(DichiarazioniImport.class)

    static enum CODICI_FORNITURA {
        TAT00,  // ECPF,
        TAS00 // ENC
    }

    private final TRACCIATI = [
            ENC : ["/dichimu/enc/2024/enc_2024.json"],
            ECPF: ["/dichimu/imuimpi/2024/imu_impi_2024.json"]
    ]

    def importa(def dati, def documentoId, def utente, def codiceBelfiore) {
        log.info("Validazione input...")
        validaFornitura(dati, codiceBelfiore)

        def codiceFornitura = determinaCodiceFornitura(dati)
        log.info("Codice Fornitura: $codiceFornitura")

        def dataTracciato = determinaDataTracciato(dati)
        log.info("Data Tracciato: $dataTracciato")

        log.info("Caricamento tracciato...")
        def tracciato = caricaTracciato(codiceFornitura, dataTracciato, codiceBelfiore)

        log.info("Elaborazione dati...")
        def datiElaborati = elaboraDati(dati, tracciato)

        log.info("Validazione dati caricati...")
        validaDati(datiElaborati)

        return convert(datiElaborati, documentoId, utente, tracciato.fields)

    }

    // Implementare nelle classi figlie, in caso di errore solleva un'eccezione
    protected void validaDati(def dati) {
    }

    final private decodificaRecord(def line) {
        if (line.length() == 1898) {
            def tipo = line.substring(0, 1)
            switch (tipo) {
                case ['0', 'A']:
                    return 'A'
                case ['9', 'Z']:
                    return 'Z'
                default:
                    return tipo
            }
        } else if (line.length() == 38) {
            return line.substring(0, 4)
        } else {
            throw new RuntimeException("Lunghezza record errata: [${line.length()}]")
        }
    }

    final protected def determinaCodiceFornitura(def dati) {
        if (dati instanceof String) {
            return dati.readLines().find { it.startsWith('0') }?.substring(15, 20)
        }

        if (dati instanceof Map) {
            return dati[1][3]?.valore
        }

        throw new RuntimeException("Codice fornitura non riconosciuto")
    }

    final protected determinaCodiceFornituraEnum(def dati) {
        return CODICI_FORNITURA.values().find { it.toString() == determinaCodiceFornitura(dati) }
    }

    final private def determinaDataTracciato(def dati) {

        if (!dati?.trim()) {
            throw new RuntimeException("Non sono presenti dati")
        }

        def primaRiga = dati.readLines()[0]

        if (primaRiga.length() != 38) {
            throw new RuntimeException("Lunghezza record errata: [${primaRiga.length()}]")
        }

        def data = primaRiga.substring(21, 27)
        try {
            return Date.parse('yyMMdd', data)
        } catch (Exception e) {
            log.error(e, e)
            throw new RuntimeException("Valore data non valido: [$data], atteso [AAMMGG]")
        }
    }

    final private def caricaTracciato(def codiceFornitura, Date data, def codiceBelfiore) {

        def jsonTracciati = []

        if (codiceFornitura == CODICI_FORNITURA.TAT00.toString()) {
             jsonTracciati += TRACCIATI.ECPF.collect {
                new JsonSlurper().parseText(readJsonFromClasspath(it)?.replace("<CODICE-BEFLIORE>", codiceBelfiore))
            }
        } else if (codiceFornitura == CODICI_FORNITURA.TAS00.toString()) {
            jsonTracciati += TRACCIATI.ENC.collect {
                new JsonSlurper().parseText(readJsonFromClasspath(it)?.replace("<CODICE-BEFLIORE>", codiceBelfiore))
            }
        }

        def tracciato = jsonTracciati.find {
            Date.parse('yyyyMMdd', it."$codiceBelfiore"?.validoDal) <= data
        }

        if (!tracciato) {
            throw new RuntimeException("Nessun tracciato valido per la data $data")
        }

        return tracciato

    }

    final private void validaFornitura(def fornitura, def codiceBelfiore) {
        // Verifica la presenza di informazioni
        if (!fornitura?.trim()) {
            throw new RuntimeException("Il file non contiene dati")
        }

        // La lunghezza delle righe deve essere 1900 o 40
        def index = 0
        fornitura.split(/(?<=\r?\n)/).each {
            index++
            if (!(it.length() in [40, 1900])) {
                log.error("Lunghezza record errata (riga $index): [${it.length()}]")
                log.error(it)
                throw new RuntimeException("Lunghezza record errata (riga $index): [${it.length()}]")
            }
        }

        // Si verifica che la fornitura appartenga al cliente
        if (decodificaRecord(fornitura.readLines()[0]) != codiceBelfiore) {
            throw new RuntimeException("Il file caricato non si riferisce all'ente $codiceBelfiore")
        }

        // Verifica il codice fornitura
        def codiceFornitura = fornitura.readLines().find { it.startsWith('0') }?.substring(15, 20)
        if (!CODICI_FORNITURA[codiceFornitura]) {
            throw new RuntimeException("Codice [${codiceFornitura}] fornitura non valido")
        }
    }

    final private def elaboraDati(def dati, def tracciato) {

        def loadedData = [:]
        def index = 0
        dati.readLines().each { line ->
            loadedData << [(index++): elaboraRecord(line, tracciato[decodificaRecord(line)])]
        }

        log.info("Elaborate $index righe")

        return loadedData
    }

    final protected String determinaTipoRecord(def riga) {
        return riga.find { k, v -> v.descrizione = 'Tipo record' }?.value?.valore
    }

    final private def elaboraRecord(def line, def tracciato) {
        def lastField = tracciato.fields.max { it.campo }.campo
        def recordMap = [:]

        tracciato.fields.each {

            recordMap << [
                    (it.campo): [
                            descrizione: it.descrizione,
                            valore     : lastField == it.campo ? "" : line.substring(it.posizione - 1, it.posizione + it.lunghezza - 1),
                            formato    : it.formato,
                    ],
            ]
        }

        return recordMap
    }

    private static String readJsonFromClasspath(String path) {
        Holders.grailsApplication.mainContext.getBean("servletContext")?.getResource("/WEB-INF/$path")?.text
    }

    abstract def convert(def dati, def documentoId, def utente, def fields)
}
