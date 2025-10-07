package it.finmatica.tr4.datiesterni.anagrafetributaria

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.AnomalieCaricamento
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.elaborazioni.AttivitaElaborazione
import it.finmatica.tr4.elaborazioni.DettaglioElaborazione
import it.finmatica.tr4.servizianagraficimassivi.*
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.codehaus.groovy.grails.plugins.DomainClassGrailsPlugin
import transform.AliasToEntityCamelCaseMapResultTransformer

@Transactional
class AllineamentoAnagrafeTributariaService {

    private static Log log = LogFactory.getLog(AllineamentoAnagrafeTributariaService)

    def sessionFactory
    def propertyInstanceMap = DomainClassGrailsPlugin.PROPERTY_INSTANCE_MAP

    def dataSource

    CommonService commonService

    def records = [:]
    def belfiore

    // Generazione richiesta
    def generateOutput(List<DettaglioElaborazione> dettagli, AttivitaElaborazione attivita) {

        File atPF = File.createTempFile(UUID.randomUUID().toString(), '.tmp')
        File atPG = File.createTempFile(UUID.randomUUID().toString(), '.tmp')

        records = [:]
        def i = 0
        dettagli.each {
            if (it.contribuente.codFiscale.trim().length() == 16) {
                atPF.append(recordToString(createRecord1(it.contribuente.codFiscale, attivita.elaborazione.id, attivita.id)))
            } else {
                atPG.append(recordToString(createRecord2(it.contribuente.codFiscale, attivita.elaborazione.id, attivita.id)))
            }

            it.anagrId = attivita.id
            it.save(flush: true, failOnError: true)

            // Reset al primo ciclo o ogni 100 elementi
            if (++i % 100 == 0 || i == 1) {
                cleanUpGorm()
                log.info "Attività [${attivita.id}]: elaborati $i dettagli di ${dettagli.size()}."
            }
        }

        File at = File.createTempFile(UUID.randomUUID().toString(), '.tmp')
        at.append(recordToString(createRecord0()))
        at.append(atPF.text)
        at.append(atPG.text)
        at.append(recordToString(createRecod9()))

        at.deleteOnExit()
        atPF.deleteOnExit()
        atPG.deleteOnExit()

        return at
    }

    def datiEnte() {
        def sql = "select * from as4_v_soggetti_correnti soco where soco.ni = 1"

        return sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0]
    }

    String generaIdentificativoEnte(String codFiscale, Long elaborazioneId, Long attivitaId) {

        String tipoInterrogazione = "CO1.151"

        if (belfiore == null) {
            belfiore = commonService.codiceBelfioreCliente()
        }
        Long sequenza = sessionFactory.currentSession.createSQLQuery("select ALLANAGR_SEQ.nextval from dual").list()[0] as Long

        String identificativo = "${belfiore}${(sequenza as String).padLeft(11, '0')}"

        SamTipo tipo = SamTipo.get(tipoInterrogazione)
        if (tipo != null) {
            SamInterrogazione interrogazione = new SamInterrogazione()
            interrogazione.tipo = tipo
            interrogazione.codFiscale = codFiscale
            interrogazione.codFiscaleIniziale = codFiscale
            interrogazione.identificativoEnte = identificativo
            interrogazione.elaborazioneId = elaborazioneId
            interrogazione.attivitaId = attivitaId
            interrogazione.save(flush: true, failOnError: true)
        } else {
            throw new Exception('Tipo interrogazione ' + tipoInterrogazione + ' non configurato correttamente in SAM_TIPI')
        }

        return identificativo
    }

    private createRecord0() {

        def datiEnte = datiEnte()

        def rec0 = [:]
        rec0.tipoRecord = [value: "0", length: 1]

        // Parametri Ente
        rec0.codiceFiscaleEnte = [value: datiEnte?.codiceFiscale, length: 16, align: "left"]
        rec0.denominazioneEnte = [value: datiEnte?.cognome, length: 60]

        // DATI IDENTIFICATIVI DEL SOGGETTO RESPONSABILE DEL TRATTAMENTO DELLE INFORMAZIONI
        rec0.codFiscaleResponsabile = [value: "", length: 16, align: "left"] // TODO: da dove si recupera
        rec0.cognomeResponsabile = [value: "", length: 40] // TODO: da dove si recupera
        rec0.nomeResponsabile = [value: "", length: 40] // TODO: da dove si recupera
        rec0.sessoResponsabile = [value: "", length: 1] // TODO: da dove si recupera
        rec0.dataNascitaResponsabile = [value: "", length: 8] // TODO: da dove si recupera
        rec0.comuneNascitaResponsabile = [value: "", length: 45] // TODO: da dove si recupera
        rec0.provinciaNascitaResponsabile = [value: "", length: 2] // TODO: da dove si recupera

        // Codice Servizio
        rec0.codiceServizio = [value: "CO1.151", length: 10]

        // Caratteri di controllo
        rec0.filler = [value: "", length: 60]
        rec0.carattereControllo = [value: "A", length: 1]

        return rec0
    }

    private createRecord1(String codiceFiscale, Long elaborazioneId, Long idAttivita) {

        String identificativoEnte = generaIdentificativoEnte(codiceFiscale, elaborazioneId, idAttivita)

        def rec1 = [:]
        rec1.tipoRecord = [value: "1", length: 1]

        rec1.identificativoEnte = [value: identificativoEnte, length: 15]
        rec1.codFiscale = [value: codiceFiscale, length: 16]

        rec1.cognome = [value: "", length: 40] // Al momento non utilizzato
        rec1.nome = [value: "", length: 40] // Al momento non utilizzato
        rec1.sesso = [value: "", length: 1] // Al momento non utilizzato
        rec1.dataNascita = [value: "", length: 8] // Al momento non utilizzato
        rec1.codCatComuneNascita = [value: "", length: 4] // Al momento non utilizzato
        rec1.comuneNascita = [value: "", length: 45] // Al momento non utilizzato
        rec1.provinciaNascita = [value: "", length: 2] // Al momento non utilizzato

        rec1.filler = [value: "", length: 127] // Al momento non utilizzato
        rec1.carattereControllo = [value: "A", length: 1]

        return rec1
    }

    private createRecord2(String codiceFiscale, Long elaborazioneId, Long idAttivita) {

        String identificativoEnte = generaIdentificativoEnte(codiceFiscale, elaborazioneId, idAttivita)

        def rec2 = [:]
        rec2.tipoRecord = [value: "2", length: 1]

        rec2.identificativoEnte = [value: identificativoEnte, length: 15]
        rec2.codFiscale = [value: codiceFiscale, length: 11]

        rec2.denominazione = [value: "", length: 150] // Al momento non utilizzato
        rec2.codCatComune = [value: "", length: 4] // Al momento non utilizzato
        rec2.comune = [value: "", length: 45] // Al momento non utilizzato
        rec2.provincia = [value: "", length: 2] // Al momento non utilizzato

        rec2.filler = [value: "", length: 71] // Al momento non utilizzato
        rec2.carattereControllo = [value: "A", length: 1]

        return rec2
    }

    private createRecod9() {
        def datiEnte = datiEnte()

        def rec9 = [:]
        rec9.tipoRecord = [value: "9", length: 1]

        // Parametri Ente
        rec9.codiceFiscaleEnte = [value: datiEnte?.codiceFiscale, length: 16, align: "left"]
        rec9.denominazioneEnte = [value: datiEnte?.cognome, length: 60]

        // DATI IDENTIFICATIVI DEL SOGGETTO RESPONSABILE DEL TRATTAMENTO DELLE INFORMAZIONI
        rec9.codFiscaleResponsabile = [value: "", length: 16, align: "left"] // TODO: da dove si recupera
        rec9.cognomeResponsabile = [value: "", length: 40] // TODO: da dove si recupera
        rec9.nomeResponsabile = [value: "", length: 40] // TODO: da dove si recupera
        rec9.sessoResponsabile = [value: "", length: 1] // TODO: da dove si recupera
        rec9.dataNascitaResponsabile = [value: "", length: 8] // TODO: da dove si recupera
        rec9.comuneNascitaResponsabile = [value: "", length: 45] // TODO: da dove si recupera
        rec9.provinciaNascitaResponsabile = [value: "", length: 2] // TODO: da dove si recupera

        // Codice Servizio
        rec9.codiceServizio = [value: "CO1.151", length: 10]

        rec9.recordTotali = [value: "", length: 6, align: "left"]
        rec9.record1 = [value: "", length: 6, align: "left"]
        rec9.record2 = [value: "", length: 6, align: "left"]

        // Caratteri di controllo
        rec9.filler = [value: "", length: 42]
        rec9.carattereControllo = [value: "A", length: 1]

        return rec9
    }

    private recordToString(def record) {

        def strRecord = ""

        record.each { k, v ->
            if (v.align == "left") {
                strRecord += v.value.padLeft(v.length)
            } else {
                strRecord += v.value.padRight(v.length)
            }
        }

        return "${strRecord}\r\n"
    }

    private createData(def records) {
        def data = ""
        records.each { k, v ->
            switch (k) {
                case ['0', '9']:
                    data += recordToString(v)
                    break
                case ['1', '2']:
                    v.each {
                        data += recordToString(it)
                    }
                    break
            }
        }

        return data
    }

    // Import Risultato
    def importaRecord0(String line, def fileData) {

        def templates = [
                [start: 1, end: 1, size: 1, name: 'tipoRecord', format: 'AN'],
                [start: 2, end: 17, size: 16, name: 'codFiscale', format: 'AN'],
                [start: 18, end: 77, size: 60, name: 'denominazione', format: 'AN'],

                [start: 78, end: 93, size: 16, name: 'codFiscaleResp', format: 'AN'],
                [start: 94, end: 133, size: 40, name: 'cognomeResp', format: 'AN'],
                [start: 134, end: 173, size: 40, name: 'nomeResp', format: 'AN'],
                [start: 174, end: 174, size: 1, name: 'sessoResp', format: 'AN'],
                [start: 175, end: 182, size: 8, name: 'dataNascitaResp', format: 'DT'],
                [start: 183, end: 227, size: 45, name: 'comuneNascitaResp', format: 'AN'],
                [start: 228, end: 229, size: 2, name: 'provNascitaResp', format: 'AN'],
                [start: 230, end: 239, size: 10, name: 'codServizio', format: 'AN'],

                [start: 240, end: 699, size: 460, name: 'filler01', format: 'FF'],
                [start: 700, end: 700, size: 1, name: 'controllo', format: 'CK'],
        ]

        def recordData = parseRecord(line, 0, templates)

        String codFiscaleEnte = datiEnte().codiceFiscale
        if (recordData.codFiscale != codFiscaleEnte) {
            throw new Throwable("Dati non relativi a questo Ente : atteso ${codFiscaleEnte}, trovato ${recordData.codFiscale}")
        }
        String codServizio = recordData.codServizio
        SamTipo tipo = SamTipo.findByTipo(codServizio)
        if (tipo == null) {
            throw new Throwable("Tipo servizio ${codServizio} non configurato")
        }

        fileData.rispostaAttuale = null

        return 1
    }

    def importaRecord9(String line, def fileData) {

        def templates = [
                [start: 1, end: 1, size: 1, name: 'tipoRecord', format: 'AN',],
                [start: 2, end: 17, size: 16, name: 'codFiscale', format: 'AN',],
                [start: 18, end: 77, size: 60, name: 'denominazione', format: 'AN',],

                [start: 78, end: 93, size: 16, name: 'codFiscaleResp', format: 'AN',],
                [start: 94, end: 133, size: 40, name: 'cognomeResp', format: 'AN',],
                [start: 134, end: 173, size: 40, name: 'nomeResp', format: 'AN',],
                [start: 174, end: 174, size: 1, name: 'sessoResp', format: 'AN',],
                [start: 175, end: 182, size: 8, name: 'dataNascitaResp', format: 'DT',],
                [start: 183, end: 227, size: 45, name: 'comuneNascitaResp', format: 'AN',],
                [start: 228, end: 229, size: 2, name: 'provNascitaResp', format: 'AN',],

                [start: 230, end: 239, size: 10, name: 'codServizio', format: 'AN',],

                [start: 240, end: 245, size: 6, name: 'recordTrasmessi', format: 'NU',],
                [start: 246, end: 251, size: 6, name: 'recordTrasmessi1', format: 'NU',],
                [start: 252, end: 257, size: 6, name: 'recordTrasmessi2', format: 'NU',],

                [start: 258, end: 263, size: 6, name: 'record1Restituiti', format: 'NU',],
                [start: 264, end: 269, size: 6, name: 'record2Restituiti', format: 'NU',],
                [start: 270, end: 275, size: 6, name: 'recordNonElaborati', format: 'NU',],
                [start: 276, end: 281, size: 6, name: 'recordIRestituiti', format: 'NU',],
                [start: 282, end: 287, size: 6, name: 'recordRRestituiti', format: 'NU',],
                [start: 288, end: 293, size: 6, name: 'recordSRestituiti', format: 'NU',],

                [start: 294, end: 699, size: 406, name: 'filler01', format: 'FF',],
                [start: 700, end: 700, size: 1, name: 'controllo', format: 'CK',],
        ]

        def recordData = parseRecord(line, 0, templates)

        return 1
    }

    def importaRecord1(String line, def fileData) {

        def templates = [
                [start: 1, end: 1, size: 1, name: 'tipoRecord', format: 'AN',],
                [start: 2, end: 16, size: 15, name: 'identificativo', format: 'AN',],

                [start: 17, end: 32, size: 16, name: 'codFiscaleInvio', format: 'AN',],
                [start: 33, end: 72, size: 40, name: 'cognomeInvio', format: 'AN',],
                [start: 73, end: 112, size: 40, name: 'nomeInvio', format: 'AN',],
                [start: 113, end: 113, size: 1, name: 'sessoInvio', format: 'AN',],
                [start: 114, end: 121, size: 8, name: 'dataNascitaInvio', format: 'DT',],
                [start: 122, end: 125, size: 4, name: 'codComuneNascitaInvio', format: 'AN',],
                [start: 126, end: 170, size: 45, name: 'comuneNascitaInvio', format: 'AN',],
                [start: 171, end: 172, size: 2, name: 'provinciaNascitaInvio', format: 'AN',],

                [start: 173, end: 228, size: 56, name: 'filler02', format: 'FF',],

                [start: 229, end: 238, size: 10, name: 'codiceRitorno', format: 'AN',],

                [start: 239, end: 254, size: 16, name: 'codFiscale', format: 'AN',],
                [start: 255, end: 294, size: 40, name: 'cognome', format: 'AN',],
                [start: 295, end: 334, size: 40, name: 'nome', format: 'AN',],
                [start: 335, end: 335, size: 1, name: 'sesso', format: 'AN',],
                [start: 336, end: 343, size: 8, name: 'dataNascita', format: 'DT',],
                [start: 344, end: 388, size: 45, name: 'comuneNascita', format: 'AN',],
                [start: 389, end: 390, size: 2, name: 'provinciaNascita', format: 'AN',],

                [start: 391, end: 435, size: 45, name: 'comuneDomicilio', format: 'AN',],
                [start: 436, end: 437, size: 2, name: 'provinciaDomicilio', format: 'AN',],
                [start: 438, end: 442, size: 5, name: 'capDomicilio', format: 'AN',],
                [start: 443, end: 477, size: 35, name: 'indirizzoDomicilio', format: 'AN',],
                [start: 478, end: 478, size: 1, name: 'fonteDomicilio', format: 'AN',],
                [start: 479, end: 486, size: 8, name: 'dataDomicilio', format: 'DT',],

                [start: 487, end: 487, size: 1, name: 'fonteDecesso', format: 'AN',],
                [start: 488, end: 495, size: 8, name: 'dataDecesso', format: 'DT',],

                [start: 496, end: 506, size: 11, name: 'partitaIva', format: 'AN',],
                [start: 507, end: 507, size: 1, name: 'statoPartitaIva', format: 'AN',],
                [start: 508, end: 513, size: 6, name: 'codAttivita', format: 'AN',],
                [start: 514, end: 514, size: 1, name: 'tipologiaCodifica', format: 'AN',],
                [start: 515, end: 522, size: 8, name: 'dataInizioAttivita', format: 'DT',],
                [start: 523, end: 530, size: 8, name: 'dataFineAttivita', format: 'DT',],

                [start: 531, end: 575, size: 45, name: 'comuneSedeLegale', format: 'AN',],
                [start: 576, end: 577, size: 2, name: 'provinciaSedeLegale', format: 'AN',],
                [start: 578, end: 582, size: 5, name: 'capSedeLegale', format: 'AN',],
                [start: 583, end: 617, size: 35, name: 'indirizzoSedeLegale', format: 'AN',],
                [start: 618, end: 618, size: 1, name: 'fonteSedeLegale', format: 'AN',],
                [start: 619, end: 626, size: 8, name: 'dataSedeLegale', format: 'DT',],

                [start: 627, end: 699, size: 73, name: 'filler01', format: 'FF',],
                [start: 700, end: 700, size: 1, name: 'controllo', format: 'CK',],
        ]

        def recordData = parseRecord(line, 0, templates)

        def identificativoEnte = recordData.identificativo
        def codFiscaleInvio = recordData.codFiscaleInvio
        def codRitorno = recordData.codiceRitorno

        SamInterrogazione interrogazione = SamInterrogazione.findByIdentificativoEnte(identificativoEnte)
        if (interrogazione == null) {
            throw new Throwable("Identificativo interrogazione non trovato in banca dati : ${identificativoEnte}")
        }
        if (interrogazione.codFiscaleIniziale != codFiscaleInvio) {
            throw new Throwable("Codice fiscale iniziale interrogazione non corrispondente : ${identificativoEnte} / ${codFiscaleInvio}")
        }

        SamCodiceRitorno codiceRitorno = SamCodiceRitorno.findByCodRitorno(codRitorno)
        if (codiceRitorno == null) {
            throw new Throwable("Codice di ritorno ${codiceRitorno} non configurato")
        }

        SamRisposta risposta = new SamRisposta()

        risposta.documentoId = fileData.documentoId
        risposta.utente = fileData.utente

        risposta.interrogazione = interrogazione
        risposta.codiceRitorno = codiceRitorno

        risposta.tipoRecord = recordData.tipoRecord

        risposta.codFiscale = recordData.codFiscale
        risposta.cognome = recordData.cognome
        risposta.nome = recordData.nome
        //	risposta.denominazione = recordData.denominazione
        risposta.sesso = recordData.sesso
        risposta.dataNascita = recordData.dataNascita
        risposta.comuneNascita = recordData.comuneNascita
        risposta.provinciaNascita = recordData.provinciaNascita
        risposta.comuneDomicilio = recordData.comuneDomicilio
        risposta.provinciaDomicilio = recordData.provinciaDomicilio
        risposta.capDomicilio = recordData.capDomicilio
        risposta.indirizzoDomicilio = recordData.indirizzoDomicilio
        risposta.dataDomicilio = recordData.dataDomicilio
        risposta.dataDecesso = recordData.dataDecesso
        risposta.partitaIva = recordData.partitaIva
        risposta.statoPartitaIva = recordData.statoPartitaIva
        risposta.codAttivita = recordData.codAttivita
        risposta.tipologiaCodifica = recordData.tipologiaCodifica
        risposta.dataInizioAttivita = recordData.dataInizioAttivita
        risposta.dataFineAttivita = recordData.dataFineAttivita
        risposta.comuneSedeLegale = recordData.comuneSedeLegale
        risposta.provinciaSedeLegale = recordData.provinciaSedeLegale
        risposta.capSedeLegale = recordData.capSedeLegale
        risposta.indirizzoSedeLegale = recordData.indirizzoSedeLegale
        risposta.dataSedeLegale = recordData.dataSedeLegale

        risposta.fonteDomicilio = SamFonteDomSede.findByFonte(recordData.fonteDomicilio)
        risposta.fonteDecesso = SamFonteDecesso.findByFonteDecesso(recordData.fonteDecesso)
        risposta.fonteSedeLegale = SamFonteDomSede.findByFonte(recordData.fonteSedeLegale)

        risposta.save(flush: true, failOnError: true)

        fileData.rispostaAttuale = risposta

        verificaAnomaliaRisposta(fileData, risposta)

        return 1
    }

    def importaRecord2(String line, def fileData) {

        def templates = [
                [start: 1, end: 1, size: 1, name: 'tipoRecord', format: 'AN',],
                [start: 2, end: 16, size: 15, name: 'identificativo', format: 'AN',],

                [start: 17, end: 27, size: 11, name: 'codFiscaleInvio', format: 'AN',],
                [start: 28, end: 177, size: 150, name: 'denominazioneInvio', format: 'AN',],

                [start: 178, end: 181, size: 4, name: 'codComuneDomicilioFiscaleInvio', format: 'AN',],
                [start: 182, end: 226, size: 45, name: 'comuneDomicilioFiscaleInvio', format: 'AN',],
                [start: 227, end: 228, size: 2, name: 'provinciaDomicilioFiscaleInvio', format: 'AN',],

                [start: 229, end: 238, size: 10, name: 'codiceRitorno', format: 'AN',],

                [start: 239, end: 249, size: 11, name: 'codFiscale', format: 'AN',],
                [start: 250, end: 399, size: 150, name: 'denominazione', format: 'AN',],

                [start: 400, end: 444, size: 45, name: 'comuneDomicilio', format: 'AN',],
                [start: 445, end: 446, size: 2, name: 'provinciaDomicilio', format: 'AN',],
                [start: 447, end: 451, size: 5, name: 'capDomicilio', format: 'AN',],
                [start: 452, end: 486, size: 35, name: 'indirizzoDomicilio', format: 'AN',],
                [start: 487, end: 487, size: 1, name: 'fonteDomicilio', format: 'AN',],
                [start: 488, end: 495, size: 8, name: 'dataDomicilio', format: 'DT',],

                [start: 496, end: 496, size: 1, name: 'presenzaEstinzione', format: 'AN',],
                [start: 497, end: 504, size: 8, name: 'dataEstinzione', format: 'DT',],

                [start: 505, end: 515, size: 11, name: 'partitaIva', format: 'AN',],
                [start: 516, end: 516, size: 1, name: 'statoPartitaIva', format: 'AN',],
                [start: 517, end: 522, size: 6, name: 'codAttivita', format: 'AN',],
                [start: 523, end: 523, size: 1, name: 'tipologiaCodifica', format: 'AN',],
                [start: 524, end: 531, size: 8, name: 'dataInizioAttivita', format: 'DT',],
                [start: 532, end: 539, size: 8, name: 'dataFineAttivita', format: 'DT',],

                [start: 540, end: 584, size: 45, name: 'comuneSedeLegale', format: 'AN',],
                [start: 585, end: 586, size: 2, name: 'provinciaSedeLegale', format: 'AN',],
                [start: 587, end: 591, size: 5, name: 'capSedeLegale', format: 'AN',],
                [start: 592, end: 626, size: 35, name: 'indirizzoSedeLegale', format: 'AN',],
                [start: 627, end: 627, size: 1, name: 'fonteSedeLegale', format: 'AN',],
                [start: 628, end: 635, size: 8, name: 'dataSedeLegale', format: 'DT',],

                [start: 636, end: 651, size: 16, name: 'codFiscaleRap', format: 'AN',],
                [start: 652, end: 652, size: 1, name: 'codiceCarica', format: 'AN',],
                [start: 653, end: 660, size: 8, name: 'dataDecorrenzaRap', format: 'DT',],

                [start: 661, end: 699, size: 39, name: 'filler01', format: 'FF',],
                [start: 700, end: 700, size: 1, name: 'controllo', format: 'CK',],
        ]

        def recordData = parseRecord(line, 0, templates)

        def identificativoEnte = recordData.identificativo
        def codFiscaleInvio = recordData.codFiscaleInvio
        def codRitorno = recordData.codiceRitorno

        SamInterrogazione interrogazione = SamInterrogazione.findByIdentificativoEnte(identificativoEnte)
        if (interrogazione == null) {
            throw new Throwable("Identificativo interrogazione non trovato in banca dati : ${identificativoEnte}")
        }
        if (interrogazione.codFiscaleIniziale != codFiscaleInvio) {
            throw new Throwable("Codice fiscale iniziale interrogazione non corrispondente : ${identificativoEnte} / ${codFiscaleInvio}")
        }

        SamCodiceRitorno codiceRitorno = SamCodiceRitorno.findByCodRitorno(codRitorno)
        if (codiceRitorno == null) {
            throw new Throwable("Codice di ritorno ${codiceRitorno} non configurato")
        }

        SamRisposta risposta = new SamRisposta()

        risposta.documentoId = fileData.documentoId
        risposta.utente = fileData.utente

        risposta.interrogazione = interrogazione
        risposta.codiceRitorno = codiceRitorno

        risposta.tipoRecord = recordData.tipoRecord

        risposta.codFiscale = recordData.codFiscale
        risposta.denominazione = recordData.denominazione
        risposta.comuneDomicilio = recordData.comuneDomicilio
        risposta.provinciaDomicilio = recordData.provinciaDomicilio
        risposta.capDomicilio = recordData.capDomicilio
        risposta.indirizzoDomicilio = recordData.indirizzoDomicilio
        risposta.dataDomicilio = recordData.dataDomicilio
        risposta.presenzaEstinzione = recordData.presenzaEstinzione
        risposta.dataEstinzione = recordData.dataEstinzione
        risposta.partitaIva = recordData.partitaIva
        risposta.statoPartitaIva = recordData.statoPartitaIva
        risposta.codAttivita = recordData.codAttivita
        risposta.tipologiaCodifica = recordData.tipologiaCodifica
        risposta.dataInizioAttivita = recordData.dataInizioAttivita
        risposta.dataFineAttivita = recordData.dataFineAttivita
        risposta.comuneSedeLegale = recordData.comuneSedeLegale
        risposta.provinciaSedeLegale = recordData.provinciaSedeLegale
        risposta.capSedeLegale = recordData.capSedeLegale
        risposta.indirizzoSedeLegale = recordData.indirizzoSedeLegale
        risposta.dataSedeLegale = recordData.dataSedeLegale
        risposta.codFiscaleRap = recordData.codFiscaleRap
        risposta.dataDecorrenzaRap = recordData.dataDecorrenzaRap

        risposta.fonteDomicilio = SamFonteDomSede.findByFonte(recordData.fonteDomicilio)
        risposta.fonteSedeLegale = SamFonteDomSede.findByFonte(recordData.fonteSedeLegale)
        risposta.codiceCarica = SamCodiceCarica.findByCodCarica(recordData.codiceCarica)

        risposta.save(flush: true, failOnError: true)

        fileData.rispostaAttuale = risposta

        verificaAnomaliaRisposta(fileData, risposta)

        return 1
    }

    def importaRecordI(String line, def fileData) {

        def templates = [
                [start: 1, end: 1, size: 1, name: 'tipoRecord', format: 'AN',],
                [start: 2, end: 16, size: 15, name: 'identificativo', format: 'AN',],

                [start: 17, end: 27, size: 11, name: 'codFiscaleInvio', format: 'AN',],
                [start: 28, end: 228, size: 201, name: 'datiInterrogazione', format: 'AN',],

                [start: 229, end: 238, size: 10, name: 'codiceRitorno', format: 'AN',],

                [start: 239, end: 254, size: 16, name: 'codFiscale', format: 'AN',],

                [start: 255, end: 256, size: 2, name: 'numeroOccorrenze', format: 'NU',],

                [start: 647, end: 699, size: 53, name: 'filler01', format: 'FF',],
                [start: 700, end: 700, size: 1, name: 'controllo', format: 'CK',],
        ]

        def subTemplates = [
                [start: 1, end: 11, size: 11, name: 'partitaIva', format: 'AN',],
                [start: 12, end: 17, size: 6, name: 'codAttivita', format: 'AN',],
                [start: 18, end: 18, size: 1, name: 'tipologiaCodifica', format: 'AN',],
                [start: 19, end: 19, size: 1, name: 'stato', format: 'AN',],
                [start: 20, end: 27, size: 8, name: 'dataCessazione', format: 'DT',],
                [start: 28, end: 28, size: 1, name: 'tipoCessazione', format: 'AN',],
                [start: 29, end: 39, size: 11, name: 'partitaIvaConfluenza', format: 'AN',],
        ]

        def recordData = parseRecord(line, 0, templates)

        def identificativoEnte = recordData.identificativo
        def codRitorno = recordData.codiceRitorno

        SamCodiceRitorno codiceRitorno = SamCodiceRitorno.findByCodRitorno(codRitorno)
        if (codiceRitorno == null) {
            throw new Throwable("Codice di ritorno ${codiceRitorno} non configurato")
        }

        SamRisposta rispostaAttuale = fileData.rispostaAttuale
        String identificativoRisposta = rispostaAttuale?.interrogazione?.identificativoEnte

        if (identificativoEnte != identificativoRisposta) {
            throw new Throwable("Identificativo record non valido : trovato ${identificativoEnte}, atteso ${identificativoRisposta}")
        }

        Integer occorrenze = recordData.numeroOccorrenze
        Integer occorrenza

        Integer offset = 257 - 1
        Integer occorrenzaSize = 39

        for (occorrenza = 0; occorrenza < occorrenze; occorrenza++) {

            def itemData = parseRecord(line, offset, subTemplates)

            SamRispostaPartitaIva risposta = new SamRispostaPartitaIva()

            risposta.risposta = rispostaAttuale
            risposta.codiceRitorno = codiceRitorno

            risposta.partitaIva = itemData.partitaIva
            risposta.codAttivita = itemData.codAttivita
            risposta.tipologiaCodifica = itemData.tipologiaCodifica
            risposta.stato = itemData.stato
            risposta.dataCessazione = itemData.dataCessazione
            risposta.partitaIvaConfluenza = itemData.partitaIvaConfluenza

            risposta.tipoCessazione = SamTipoCessazione.findByTipoCessazione(recordData.tipoCessazione)

            risposta.save(flush: true, failOnError: true)

            offset += occorrenzaSize
        }

        return occorrenze
    }

    def importaRecordR(String line, def fileData) {

        def templates = [
                [start: 1, end: 1, size: 1, name: 'tipoRecord', format: 'AN',],
                [start: 2, end: 16, size: 15, name: 'identificativo', format: 'AN',],

                [start: 17, end: 27, size: 11, name: 'codFiscaleInvio', format: 'AN',],
                [start: 28, end: 228, size: 201, name: 'datiInterrogazione', format: 'AN',],

                [start: 229, end: 238, size: 10, name: 'codiceRitorno', format: 'AN',],

                [start: 239, end: 249, size: 11, name: 'codFiscale', format: 'AN',],

                [start: 250, end: 251, size: 2, name: 'numeroOccorrenze', format: 'NU',],

                [start: 582, end: 699, size: 119, name: 'filler01', format: 'FF',],
                [start: 700, end: 700, size: 1, name: 'controllo', format: 'CK',],
        ]

        def subTemplates = [
                [start: 1, end: 16, size: 16, name: 'codFiscaleRap', format: 'AN',],
                [start: 17, end: 17, size: 1, name: 'codiceCarica', format: 'AN',],
                [start: 18, end: 25, size: 8, name: 'dataDecorrenza', format: 'DT',],
                [start: 26, end: 33, size: 8, name: 'dataFineCarica', format: 'DT',],
        ]

        def recordData = parseRecord(line, 0, templates)

        def identificativoEnte = recordData.identificativo
        def codRitorno = recordData.codiceRitorno

        SamCodiceRitorno codiceRitorno = SamCodiceRitorno.findByCodRitorno(codRitorno)
        if (codiceRitorno == null) {
            throw new Throwable("Codice di ritorno ${codiceRitorno} non configurato")
        }

        SamRisposta rispostaAttuale = fileData.rispostaAttuale
        String identificativoRisposta = rispostaAttuale?.interrogazione?.identificativoEnte

        if (identificativoEnte != identificativoRisposta) {
            throw new Throwable("Identificativo record non valido : trovato ${identificativoEnte}, atteso ${identificativoRisposta}")
        }

        Integer occorrenze = recordData.numeroOccorrenze
        Integer occorrenza

        Integer offset = 252 - 1
        Integer occorrenzaSize = 33

        for (occorrenza = 0; occorrenza < occorrenze; occorrenza++) {

            def itemData = parseRecord(line, offset, subTemplates)

            SamRispostaRap risposta = new SamRispostaRap()

            risposta.risposta = rispostaAttuale
            risposta.codiceRitorno = codiceRitorno

            risposta.codFiscaleRap = itemData.codFiscaleRap
            risposta.dataDecorrenza = itemData.dataDecorrenza
            risposta.dataFineCarica = itemData.dataFineCarica

            risposta.codiceCarica = SamCodiceCarica.findByCodCarica(itemData.codiceCarica)

            risposta.save(flush: true, failOnError: true)

            offset += occorrenzaSize
        }

        return occorrenze
    }

    def importaRecordS(String line, def fileData) {

        def templates = [
                [start: 1, end: 1, size: 1, name: 'tipoRecord', format: 'AN',],
                [start: 2, end: 16, size: 15, name: 'identificativo', format: 'AN',],

                [start: 17, end: 27, size: 11, name: 'codFiscaleInvio', format: 'AN',],
                [start: 28, end: 228, size: 201, name: 'datiInterrogazione', format: 'AN',],

                [start: 229, end: 238, size: 10, name: 'codiceRitorno', format: 'AN',],

                [start: 239, end: 254, size: 16, name: 'codFiscale', format: 'AN',],

                [start: 255, end: 256, size: 2, name: 'numeroOccorrenze', format: 'NU',],

                [start: 587, end: 699, size: 113, name: 'filler01', format: 'FF',],
                [start: 700, end: 700, size: 1, name: 'controllo', format: 'CK',],
        ]

        def subTemplates = [
                [start: 1, end: 16, size: 16, name: 'codFiscaleDitta', format: 'AN',],
                [start: 17, end: 17, size: 1, name: 'codiceCarica', format: 'AN',],
                [start: 18, end: 25, size: 8, name: 'dataDecorrenza', format: 'DT',],
                [start: 26, end: 33, size: 8, name: 'dataFineCarica', format: 'DT',],
        ]

        def recordData = parseRecord(line, 0, templates)

        def identificativoEnte = recordData.identificativo
        def codRitorno = recordData.codiceRitorno

        SamCodiceRitorno codiceRitorno = SamCodiceRitorno.findByCodRitorno(codRitorno)
        if (codiceRitorno == null) {
            throw new Throwable("Codice di ritorno ${codiceRitorno} non configurato")
        }

        SamRisposta rispostaAttuale = fileData.rispostaAttuale
        String identificativoRisposta = rispostaAttuale?.interrogazione?.identificativoEnte

        if (identificativoEnte != identificativoRisposta) {
            throw new Throwable("Identificativo record non valido : trovato ${identificativoEnte}, atteso ${identificativoRisposta}")
        }

        Integer occorrenze = recordData.numeroOccorrenze
        Integer occorrenza

        Integer offset = 257 - 1
        Integer occorrenzaSize = 33

        for (occorrenza = 0; occorrenza < occorrenze; occorrenza++) {

            def itemData = parseRecord(line, offset, subTemplates)

            SamRispostaDitta risposta = new SamRispostaDitta()

            risposta.risposta = rispostaAttuale
            risposta.codiceRitorno = codiceRitorno

            risposta.codFiscaleDitta = itemData.codFiscaleDitta
            risposta.dataDecorrenza = itemData.dataDecorrenza
            risposta.dataFineCarica = itemData.dataFineCarica

            risposta.codiceCarica = SamCodiceCarica.findByCodCarica(itemData.codiceCarica)

            risposta.save(flush: true, failOnError: true)

            offset += occorrenzaSize
        }

        return occorrenze
    }

    private def parseRecord(String line, Integer offset, def templates) {

        def recordData = [:]

        templates.each {

            def template = it

            parseRecordConTemplate(line, offset, template, recordData)
        }

        return recordData
    }

    private def parseRecordConTemplate(String line, Integer offset, def template, def recordData) {

        def start = (template.start + offset) - 1    // 0 Indexed
        def end = start + template.size

        String porzione = line.substring(start, end)
        String trimmed

        def value = null

        switch (template.format) {
            case 'NU':
                trimmed = porzione.trim()
                if (trimmed.size() != 0) {
                    value = Integer.parseInt(porzione)
                } else {
                    value = null
                }
                break
            case 'DT':
                trimmed = porzione.trim()
                if (trimmed.size() != 0) {
                    value = Date.parse("ddMMyyyy", trimmed)
                } else {
                    value = null
                }
                break
            case 'FF':
                value = porzione.trim().length() == 0
                break
            case 'CK':
                value = porzione == 'A'
                break
            case 'AN':
            default:
                value = porzione.trim()
                break
        }

        recordData[template.name] = value
    }

    def verificaAnomaliaRisposta(def fileData, SamRisposta risposta) {

        SamCodiceRitorno codiceRitorno = risposta.codiceRitorno
        if (codiceRitorno.esito != 'OK') {

            def datiAnomalia = [
                    oggetto    : null,
                    datiOggetto: null,
                    descrizione: codiceRitorno.descrizione,
                    note       : codiceRitorno.riscontro,
            ]

            creaAnomaliaRisposta(fileData, risposta, datiAnomalia)
        } else {
            SamInterrogazione interrogazione = risposta.interrogazione

            if (interrogazione.codFiscale != interrogazione.codFiscaleIniziale) {

                def datiAnomalia = [
                        oggetto    : null,
                        datiOggetto: null,
                        descrizione: 'Codice fiscale iniziale non piu\' corrispondente',
                        note       : 'Era ' + interrogazione.codFiscaleIniziale + ', contribuente attuale ' + interrogazione.codFiscale
                ]

                creaAnomaliaRisposta(fileData, risposta, datiAnomalia)
            } else {
                if (risposta.codFiscale != interrogazione.codFiscaleIniziale) {

                    def datiAnomalia = [
                            oggetto    : null,
                            datiOggetto: null,
                            descrizione: 'Codice fiscale non corrispondente',
                            note       : 'Era ' + interrogazione.codFiscaleIniziale
                    ]

                    creaAnomaliaRisposta(fileData, risposta, datiAnomalia)
                }
            }
        }
    }

    def creaAnomaliaRisposta(def fileData, SamRisposta risposta, def datiAnomalia) {

        AnomalieCaricamento anomalia = new AnomalieCaricamento()

        String value
        Integer size

        anomalia.documentoId = fileData.documentoId

        anomalia.oggetto = datiAnomalia.oggetto
        anomalia.datiOggetto = datiAnomalia.datiOggetto

        value = datiAnomalia.descrizione ?: '-'
        size = value.size()
        if (size > 100) size = 100
        anomalia.descrizione = value.substring(0, size)

        value = datiAnomalia.note ?: '-'
        size = value.size()
        if (size > 2000) size = 2000
        anomalia.note = value.substring(0, size)

        anomalia.codFiscale = risposta.codFiscale

        if (risposta.tipoRecord == '1') {
            anomalia.cognome = risposta.cognome
            anomalia.nome = risposta.nome
        } else {
            anomalia.cognome = risposta.denominazione
            anomalia.nome = null
        }

        getNuovaSequenzaAnomaliaCaricamento(anomalia)

        anomalia.save(flush: true, failOnError: true)

        fileData.anomalie++
    }

    // Ricava nuovo numero sequenza
    def getNuovaSequenzaAnomaliaCaricamento(AnomalieCaricamento anomalia) {

        Short sequenza = 1

        def maxSequenza = AnomalieCaricamento.createCriteria().list {
            projections {
                max("sequenza")
            }
            eq("documentoId", anomalia.documentoId)
        }

        if (maxSequenza.size() > 0) {
            sequenza = (maxSequenza[0] ?: 0) as Short
            sequenza++
        }

        anomalia.sequenza = sequenza
    }

    // Controlla AT
    String controlloAT(List<DettaglioElaborazione> dettagli, AttivitaElaborazione attivita) {

        String resultNow
        String result = ""

        Boolean modified

        if (dettagli) {
            dettagli.each {

                modified = false

                resultNow = controlloATSingolo(it, attivita)

                if (!(resultNow.isEmpty())) {
                    it.note = resultNow
                    result += "- " + it.contribuente.codFiscale + " : " + resultNow
                    modified = true
                }

                if (modified) {
                    it.save(flush: true, failOnError: true)
                }
            }
        } else {
            result = controlloATSingolo(null, attivita)
        }
        if (attivita) {
            attivita.note = result
            attivita.save(flush: true, failOnError: true)
        }

        return result
    }

    String controlloATSingolo(DettaglioElaborazione dettaglio, AttivitaElaborazione attivita) {

        String message = ""

        try {
            Long elaborazioneId = attivita?.elaborazione?.id
            Long attivitaId = attivita?.id
            Long dettaglioId = dettaglio?.id

            Sql sql = new Sql(dataSource)
            sql.call('{call CONTROLLO_AT(?,?,?,?)}',
                    [
                            elaborazioneId,
                            attivitaId,
                            dettaglioId,
                            Sql.VARCHAR
                    ],
                    { msg ->
                        log.info(msg)
                    }
            )

            message = ''
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
            } else {
                message += e.message
            }
        }

        return message
    }

    // Allinea AT
    String allineamentoAT(List<DettaglioElaborazione> dettagli, AttivitaElaborazione attivita) {

        String resultNow
        String result = ""

        Boolean modified

        if (dettagli) {
            dettagli.each {

                modified = false

                resultNow = allineamentoATSingolo(it, attivita)

                if (!(resultNow.isEmpty())) {
                    it.note = resultNow
                    result += "- " + it.contribuente.codFiscale + " : " + resultNow
                    modified = true
                }
                if (modified) {
                    it.save(flush: true, failOnError: true)
                }
            }
        } else {
            result = allineamentoATSingolo(null, attivita)
        }
        if (attivita) {
            attivita.note = result
            attivita.save(flush: true, failOnError: true)
        }

        return result
    }

    String allineamentoATSingolo(DettaglioElaborazione dettaglio, AttivitaElaborazione attivita) {

        String message = ""

        try {
            Long elaborazioneId = attivita?.elaborazione?.id
            Long attivitaId = attivita?.id
            Long dettaglioId = dettaglio?.id
			
            Sql sql = new Sql(dataSource)
            sql.call('{call ALLINEAMENTO_AT(?,?,?,?)}',
                    [
                            elaborazioneId,
                            attivitaId,
                            dettaglioId,
                            Sql.VARCHAR
                    ],
                    { msg ->
                        log.info(msg)
                    }
            )

            message = ''
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                message += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                message += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
            } else {
                message += e.message
            }
        }

        return message
    }

    private def cleanUpGorm() {
        def session = sessionFactory.currentSession
        session.flush()
        session.clear()
        propertyInstanceMap.get().clear()
    }
}
