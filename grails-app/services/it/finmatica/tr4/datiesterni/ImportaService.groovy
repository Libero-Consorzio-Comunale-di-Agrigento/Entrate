package it.finmatica.tr4.datiesterni

import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.datiesterni.beans.ImportDicEncEcPf
import it.finmatica.datiesterni.datimetrici.DatiOut
import it.finmatica.tr4.caricamento.*
import it.finmatica.tr4.pratiche.PraticaTributo
import org.apache.commons.lang.StringUtils
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.codehaus.groovy.grails.plugins.DomainClassGrailsPlugin

@Transactional
class ImportaService {

    private static Log log = LogFactory.getLog(ImportaService)

    def dataSource
    def springSecurityService

    def sessionFactory
    def propertyInstanceMap = DomainClassGrailsPlugin.PROPERTY_INSTANCE_MAP
    def ImportDicEncEcPf importDicEncEcPf

    def cleanUpGorm() {
        def session = sessionFactory.currentSession
        session.flush()
        session.clear()
        propertyInstanceMap.get().clear()
    }

    def gestioneNotai(def parametri) {
        String messaggio
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{call carica_dic_notai(?, ?, ?, ?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                parametri.ctrDenuncia,
                parametri.sezioneUnica,
                parametri.fonte,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def allineamentoDeleghe(def parametri) {
        log.info parametri.idDocumento + " " + parametri.nomeSupporto + " " + parametri.utente.id + " " + parametri.ente.codice
        String messaggio
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{call alde_risposta(?, ?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.nomeSupporto,
                parametri.utente.id,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def flussoRitornoMAV(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call flusso_ritorno_mav(?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def flussoRitornoMAV_TARSU(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call flusso_ritorno_mav_tarsu(?, ?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                parametri.spese,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def flussoRitornoMAV_TARSU_rm(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call flusso_ritorno_mav_tarsu(?, ?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                parametri.spese,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def flussoRitornoMAV_ICIviol(def parametri) {
        String messaggio
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{call flusso_ritorno_mav_ici_viol(?, ?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                parametri.spese,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def importaVersCosapPoste(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call importa_vers_cosap_poste(?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def flussoRitornoRID(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call flusso_ritorno_rid(?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }


    def caricaDicSuccessioni(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call carica_dic_successioni(?, ?, ?, ?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                parametri.ctrDenuncia,
                parametri.sezioneUnica,
                parametri.fonte,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def caricaVersamentiTitrF24(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call carica_versamenti_titr_F24(?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def caricaVersamentiTitrF24Province(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call ELABORAZIONE_FORNITURE_AE.ELABORA(?, ?)}'
                , [
                parametri.idDocumento,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio

    }

    def caricaVersamentiSolori(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call CARICA_VERSAMENTI_SOLORI(?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def caricaDocfa(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call carica_docfa(?, ?, ?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                parametri.sezioneUnica,
                parametri.fonte,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def importaCatastoCensuario(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call CARICA_CATASTO_CENSUARIO(?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def importaDichiarazioniENC(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call CARICA_DIC_ENC.ESEGUI(?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }

    def importaDichiarazioniEncEcPf(def parametri) {

        String messaggio
        def dati = new String(DocumentoCaricato.get(parametri.idDocumento)?.contenuto)

        def nuovoTracciato = false
        if (dati?.trim() && dati.length() > 28) {
            // Gestione nuovi tracciati in vigore dal 03/06/2024 (espressi nella forma 240603)
            def dataTracciato = dati[21..26].trim() ? dati[21..26]?.toInteger() : -1

            nuovoTracciato = dataTracciato > 240603
        }


        if (!nuovoTracciato) {
            Sql sql = new Sql(dataSource)
            sql.call('{call CARICA_DIC_ENC_ECPF.ESEGUI(?, ?, ?)}'
                    , [
                    parametri.idDocumento,
                    parametri.utente.id,
                    Sql.VARCHAR
            ]) { messaggio = it }
        } else {
            importDicEncEcPf.importa(parametri)
        }

        return messaggio
    }

    def importaAnagrafeLAC(def parametri) {
        String messaggio
        Sql sql = new Sql(dataSource)
        sql.call('{call CARICA_ANAGRAFE_ESTERNA(?, ?, ?)}'
                , [
                parametri.idDocumento,
                parametri.utente.id,
                Sql.VARCHAR
        ]) { messaggio = it }

        return messaggio
    }


    def creaFornituraUtenze(def fields, def parametri, def fornitura = null) {

        if (fields.tipoRecord == '0') {

            fornitura = new UtenzaFornitura()
            fornitura.documentoId = parametri.idDocumento
            fornitura.identificativo = fields.identificativoFornitura
            fornitura.progressivo = fields.progressivoFornitura.toInteger()
            fornitura.data = Date.parse("yyyyMMdd", fields.dataFornitura)
            fornitura.utenzeDati = []
        } else {

            def utenza = new UtenzaDatiFornitura()

            utenza.identificativoUtenza = fields.codIden
            utenza.tipoUtenza = new UtenzaTipiUtenza([tipoFornitura: fields.tipoFornitura, tipoUtenza: fields.tipoUte])
            utenza.annoRiferimento = fields.annoRifDati.toShort()
            utenza.codCatastaleUtenza = fields.codCatComune
            utenza.codFiscaleErogante = fields.codFisSoggErog
            utenza.codFiscaleTitolare = fields.codFisTitUte
            utenza.tipoSoggetto = fields.tipoSogg
            utenza.datiAnagraficiTitolare = fields.datiAnagrafici
            utenza.indirizzoUtenza = fields.indirizzoUte
            utenza.capUtenza = fields.capUte

            if (utenza.tipoUtenza.tipoFornitura == 'E') {
                utenza.ammontareFatturato = fields.spesaConsumo.toBigDecimal()
                utenza.consumoFatturato = fields.kwh.toBigDecimal()
            } else {
                utenza.ammontareFatturato = fields.fatturato.toBigDecimal()
                utenza.consumoFatturato = fields.consumo.toBigDecimal()
            }

            utenza.mesiFatturazione = fields.mesiFatturazione.toShort()

            utenza.utenzaFornitura = fornitura

            fornitura.utenzeDati << utenza
        }

        return fornitura
    }

    def salvaFornituraUtenze(def fornitura) {
        def dati = fornitura.utenzeDati

        fornitura.utenzeDati = []

        fornitura.save(flush: true, failOnError: true)
        def i = 0
        dati.each {
            it.save(flush: true, failOnError: true)
            if (++i % 100 == 0) cleanUpGorm()
        }

        return dati.size()

    }

    def importaDateNotifica(long pratica, Date dataNotifica) {
        PraticaTributo praticaTributo = null

        try {

            praticaTributo = PraticaTributo.findById(pratica)
            if (praticaTributo) {
                // Se si definisce la data di notifica ed il precedente valore era null, si effettua l'update prima del
                // salvataggio per evitare che venga segnalato l'errore in inserimento.
                if (!praticaTributo.dataNotifica) {
                    PraticaTributo.executeUpdate("""update PraticaTributo 
                                                set dataNotifica = to_date('${dataNotifica?.format("dd/MM/yyyy")}', 'DD/MM/YYYY')
                                                where id = ${praticaTributo.id}
                                                """)
                }
                praticaTributo.save(flush: true, failOnError: true)
                return ""
            } else {
                return ""
            }

        } catch (Exception e) {
            def cause = e.cause
            while (cause.cause != null) {
                cause = cause.cause
            }

            e.printStackTrace()
            return cause.message.substring(0, cause.message.indexOf("\n"))
        }
    }

    def importaTipiNotifica(long pratica, Integer tipoNotifica) {

        PraticaTributo praticaTributo = null

        try {

            praticaTributo = PraticaTributo.findById(pratica)

            if (praticaTributo) {

                // Se si definisce il tipo notifica ed il precedente valore era null, si effettua l'update prima del
                // salvataggio per evitare che venga segnalato l'errore in inserimento.
                if (!praticaTributo.tipoNotifica) {
                    PraticaTributo.executeUpdate("""update PraticaTributo 
                                                set tipoNotifica = ${tipoNotifica}
                                                where id = ${praticaTributo.id}
                                                """)
                }

                praticaTributo.save(flush: true, failOnError: true)
                return ""
            } else {
                return ""
            }

        } catch (Exception e) {
            def cause = e.cause
            while (cause.cause != null) {
                cause = cause.cause
            }

            e.printStackTrace()
            return cause.message.substring(0, cause.message.indexOf("\n"))
        }
    }

    void creaLocazioni(def fields, def parametri) {

        LocazioneTestata record0 = null
        LocazioneContratto recordA = null
        LocazioneImmobile recordI = null
        LocazioneSoggetto recordB = null

        try {
            def i = 0
            fields.each {
                switch (it.tipoRecord) {
                    case '0':
                        record0 = elaboraRecord0(it, parametri)
                        record0.save(flush: true, failOnError: true)
                        break
                    case 'A':
                        recordA = elaboraRecordA(it)
                        recordA.locazioneTestata = record0
                        recordA.save(flush: true, failOnError: true)
                        //record0.locazioniContratti << recordA
                        break
                    case 'B':
                        recordB = elaboraRecordB(it)
                        recordB.locazioneContratto = recordA
                        recordB.save(flush: true, failOnError: true)
                        //recordA.locazioneSoggetti << recordB
                        break
                    case 'I':
                        recordI = elaboraRecordI(it)
                        recordI.locazioneContratto = recordA
                        recordI.save(flush: true, failOnError: true)
                        //recordA.locazioneImmobili << recordI
                        break
                }

                if (++i % 100 == 0) cleanUpGorm()
            }
        } catch (Exception e) {
            throw e
        }

    }

    private def elaboraRecord0(def record, def parametri) {
        LocazioneTestata testata = new LocazioneTestata(
                [
                        documentoId       : parametri.idDocumento,
                        intestazione      : record.intestazione,
                        dataFile          : Date.parse("yyyy-MM-dd", record.dataFile),
                        anno              : record.anno,
                        locazioniContratti: []
                ]
        )

        return testata
    }

    private def elaboraRecordA(def record) {
        LocazioneContratto contratto = new LocazioneContratto(
                [
                        ufficio           : record.ufficio,
                        anno              : record.annoReg as Short,
                        serie             : record.serieReg,
                        numero            : record.numeroReg as Integer,
                        sottoNumero       : record.sottoNumeroReg as Integer,
                        progressivoNegozio: record.prgNegozio as Integer,
                        dataRegistrazione : record.dataReg ? Date.parse("yyyy-MM-dd", record.dataReg) : null,
                        dataStipula       : record.dataStipula ? Date.parse("yyyy-MM-dd", record.dataStipula) : null,
                        codiceOggetto     : record.codiceOggetto,
                        codiceNegozio     : record.codiceNegozio,
                        importoCanone     : (record.importoCanone ? record.importoCanone as BigDecimal : 0) / 100,
                        valutaCanone      : record.valutaCanone,
                        tipoCanone        : record.tipoCanone,
                        dataInizio        : record.dataInizio ? Date.parse("yyyy-MM-dd", record.dataInizio) : null,
                        dataFine          : record.dataFine ? Date.parse("yyyy-MM-dd", record.dataFine) : null,
                        locazioneSoggetti : [],
                        locazioneImmobili : []
                ]
        )

        return contratto

    }

    private def elaboraRecordB(def record) {
        LocazioneSoggetto soggetto = new LocazioneSoggetto(
                [
                        ufficio            : record.ufficio,
                        anno               : record.annoReg as Short,
                        serie              : record.serieReg,
                        numero             : record.numeroReg as Integer,
                        sottoNumero        : record.sottoNumeroReg as Integer,
                        progressivoSoggetto: record.prgSoggetto as Integer,
                        progressivoNegozio : record.prgNegozio as Integer,
                        tipoSoggetto       : record.tipoSoggetto,
                        codFiscale         : record.codFiscale,
                        sesso              : record.sesso,
                        cittaNascita       : record.cittaNas,
                        provNascita        : record.provNasc,
                        dataNascita        : record.dataNasc ? Date.parse("yyyy-MM-dd", record.dataNasc) : null,
                        cittaRes           : record.cittaRes,
                        provRes            : record.provRes,
                        indirizzoRes       : record.indirizzoRes,
                        numCivRes          : record.numCivRes,
                        dataSubentro       : record.dataSubentro ? Date.parse("yyyy-MM-dd", record.dataSubentro) : null,
                        dataCessione       : record.dataCessione ? Date.parse("yyyy-MM-dd", record.dataCessione) : null
                ]
        )

        return soggetto
    }

    private def elaboraRecordI(def record) {
        LocazioneImmobile immobile = new LocazioneImmobile(
                [
                        ufficio            : record.ufficio,
                        anno               : record.annoReg as Short,
                        serie              : record.serieReg,
                        numero             : record.numeroReg as Integer,
                        sottoNumero        : record.sottoNumeroReg as Integer,
                        progressivoImmobile: record.prgImmobile as Integer,
                        progressivoNegozio : record.prgNegozio as Integer,
                        immAccatastamento  : record.immAccatastamento,
                        tipoCatasto        : record.tipoCatasto,
                        flagIp             : record.flagIp,
                        codiceCatasto      : record.codCatastale,
                        sezUrbComCat       : StringUtils.stripStart(record.sezUrbComCat, '0')?.trim(),
                        foglio             : StringUtils.stripStart(record.foglio, '0')?.trim(),
                        particellaNum      : StringUtils.stripStart(record.particellaNum, '0')?.trim(),
                        particellaDen      : StringUtils.stripStart(record.particellaDen, '0')?.trim(),
                        subalterno         : StringUtils.stripStart(record.subalterno, '0')?.trim(),
                        indirizzo          : record.indirizzo
                ]
        )

        return immobile
    }

    void creaDatiMetrici(DatiOut dm, def parametri, tipologia) {

        log.info "Inizio salvataggio DatiMetrici..."
        def start = System.nanoTime()

        // Elaborazione testata
        DatiMetriciTestata testata = new DatiMetriciTestata(
                [
                        documentoId : parametri.idDocumento,
                        comune      : dm.comune,
                        iscrizione  : dm.datiRichiesta.iscrizione,
                        dataIniziale: dm.datiRichiesta.dataIniziale.toGregorianCalendar().getTime(),
                        nFile       : dm.datiRichiesta.nFile,
                        nFileTot    : dm.datiRichiesta.nFileTot,
                        tipologia   : tipologia
                ]
        )

        testata.save(flush: true, failOnError: true)

        int j = 0
        def nUiu = 0

        // Elaborazione UIU
        dm.uiu.each { u ->

            def startUiu = System.nanoTime()

            DatiMetriciUiu uiu = new DatiMetriciUiu(
                    [
                            // UIU
                            idUiu      : u.idUiu,
                            progressivo: u.prog,
                            categoria  : u.categoria,
                            beneComune : u.beneComune,
                            superficie : u.superficie,

                            // Testata
                            testata    : testata
                    ]

            )

            uiu.save(flush: true, failOnError: true)
            if (j++ % 100 == 0) cleanUpGorm()

            // Esiti agenzia
            u.esitiAgenzia.each { ea ->
                DatiMetriciEsitoAgenzia esitoAgenzia = new DatiMetriciEsitoAgenzia(
                        [
                                esitoSup: ea.esitoSup,
                                esitoAgg: ea.esitoAgg,

                                // UIU
                                uiu     : uiu
                        ]
                )

                esitoAgenzia.save(flush: true, failOnError: true)
                if (j++ % 100 == 0) cleanUpGorm()
            }

            // Esiti comune
            u.esitiComune.each { ec ->
                DatiMetriciEsitoComune esitoComune = new DatiMetriciEsitoComune(
                        [
                                riscontro    : ec.riscontro,
                                istanza      : ec.istanza,
                                richiestaPlan: ec.richiestaPlan,

                                // UIU
                                uiu          : uiu
                        ]
                )

                esitoComune.save(flush: true, failOnError: true)
                if (j++ % 100 == 0) cleanUpGorm()
            }

            // Identificativi
            u.identificativo.each { i ->
                DatiMetriciIdentificativi identificativo = new DatiMetriciIdentificativi(
                        [
                                sezione     : StringUtils.stripStart(i.sezUrb, '0')?.trim(),
                                foglio      : StringUtils.stripStart(i.foglio, '0')?.trim(),
                                numero      : StringUtils.stripStart(i.numero, '0')?.trim(),
                                denominatore: i.denominatore,
                                subalterno  : StringUtils.stripStart(i.sub, '0')?.trim(),
                                edificialita: i.edificialita,

                                // UIU
                                uiu         : uiu
                        ]
                )

                identificativo.save(flush: true, failOnError: true)
                if (j++ % 100 == 0) cleanUpGorm()
            }

            // Indirizzi
            u.indirizzo.each { i ->
                DatiMetriciIndirizzo indirizzo = new DatiMetriciIndirizzo(
                        [

                                codToponimo: i.codTopo,
                                toponimo   : i.toponimo?.take(16),
                                denom      : i.denom,
                                codice     : i.codice,
                                fonte      : i.fonte,
                                delibera   : i.delibera,
                                localita   : i.localita,
                                km         : i.km,
                                cap        : i.cap,

                                // UIU
                                uiu        : uiu
                        ]
                )
                // Civici
                int nCiv = 1
                i.civico.each { civ ->
                    indirizzo["civico$nCiv"] = civ
                }

                indirizzo.save(flush: true, failOnError: true)
                if (j++ % 100 == 0) cleanUpGorm()
            }

            // Ubicazione
            DatiOut.Uiu.Ubicazione ubi = u.ubicazione
            DatiMetriciUbicazione ubicazione = new DatiMetriciUbicazione(
                    [
                            lotto   : ubi.lotto,
                            edificio: ubi.edificio,
                            scala   : ubi.scala,

                            // UIU
                            uiu     : uiu
                    ]
            )

            // Piani
            int nPiano = 1
            ubi.piano.each {
                ubicazione["piano$nPiano"] = it
            }

            // Interni
            int nInt = 1
            ubi.interno.each {
                ubicazione["interno$nInt"] = it
            }

            ubicazione.save(flush: true, failOnError: true)
            if (j++ % 100 == 0) cleanUpGorm()

            // Soggetti PF
            u.soggetti?.pf?.each { pf ->
                DatiMetriciSoggetto soggettoF = new DatiMetriciSoggetto(
                        [
                                idSoggetto : pf.idSog,
                                tipo       : '0',
                                cognome    : pf.cognome,
                                nome       : pf.nome,
                                sesso      : pf.sesso,
                                dataNascita: pf.dataNascita ? Date.parse("ddMMyyyy", pf.dataNascita.toString()) : null,
                                comune     : pf.comune,
                                codFiscale : pf.cf,

                                // UIU
                                uiu        : uiu
                        ]
                )

                soggettoF.save(flush: true, failOnError: true)
                if (j++ % 100 == 0) cleanUpGorm()

                if (pf.datiAtto) {
                    DatiMetriciDatiAtto datiAtto = new DatiMetriciDatiAtto(
                            [
                                    tipo              : '1',
                                    sedeRogante       : pf.datiAtto.sedeRogante,
                                    data              : pf.datiAtto.data ? Date.parse("ddMMyyyy", pf.datiAtto.data.toString()) : null,
                                    numeroRepertorio  : pf.datiAtto.repertorio?.numero,
                                    raccoltaRepertorio: pf.datiAtto.repertorio?.raccolta,

                                    // Soggetto
                                    soggetto          : soggettoF
                            ]
                    )

                    datiAtto.save(flush: true, failOnError: true)
                    if (j++ % 100 == 0) cleanUpGorm()
                }
            }

            // Soggetti PG
            u.soggetti?.pnf?.each { pg ->
                DatiMetriciSoggetto soggettoG = new DatiMetriciSoggetto(
                        [
                                idSoggetto   : pg.idSog,
                                denominazione: pg.denominazione,
                                sede         : pg.sede,
                                codFiscale   : pg.cf,

                                // UIU
                                uiu          : uiu
                        ]
                )

                soggettoG.save(flush: true, failOnError: true)
                if (j++ % 100 == 0) cleanUpGorm()

                if (pg.datiAtto) {
                    DatiMetriciDatiAtto datiAtto = new DatiMetriciDatiAtto(
                            [
                                    sedeRogante       : pg.datiAtto.sedeRogante,
                                    data              : pg.datiAtto.data ? Date.parse("ddMMyyyy", pg.datiAtto.data.toString()) : null,
                                    numeroRepertorio  : pg.datiAtto.repertorio?.numero,
                                    raccoltaRepertorio: pg.datiAtto.repertorio?.raccolta,

                                    // Soggetto
                                    soggetto          : soggettoG
                            ]
                    )

                    datiAtto.save(flush: true, failOnError: true)
                    if (j++ % 100 == 0) cleanUpGorm()
                }
            }

            // Dati Metrici
            u.datiMetrici.each { datM ->
                DatiMetrici datiMetrici = new DatiMetrici(
                        [
                                ambiente          : datM.ambiente,
                                superficieAmbiente: datM.superficieA,
                                altezza           : datM.altezza,
                                altezzaMax        : datM.altezzaMax,

                                // UIU
                                uiu               : uiu
                        ]
                )

                datiMetrici.save(flush: true, failOnError: true)
                if (j++ % 100 == 0) cleanUpGorm()
            }

            // Dati Nuovi
            u.datiNuovi.each {
                DatiMetriciDatiNuovi datiNuovi = new DatiMetriciDatiNuovi(
                        [
                                superficieTot     : it.superficieTotale,
                                superficieConv    : it.superficieConvenzionale,
                                inizioValidita    : it.dataInizioValidita ? Date.parse("ddMMyyyy", it.dataInizioValidita) : null,
                                fineValidita      : it.dataFineValidita ? Date.parse("ddMMyyyy", it.dataFineValidita) : null,
                                comune            : it.codiceStradaNazionale?.comune,
                                progStrada        : it.codiceStradaNazionale?.progStrada,
                                dataCertificazione: it.dataCertificazione ? Date.parse("ddMMyyyy", it.dataCertificazione) : null,
                                dataProvv         : it.provvedimento?.data ? Date.parse("ddMMyyyy", it.provvedimento.data) : null,
                                protocolloProvv   : it.provvedimento?.protocollo,
                                codStradaCom      : it.codiceStradaComunale,

                                // UIU
                                uiu               : uiu
                        ]
                )

                datiNuovi.save(flush: true, failOnError: true)
                if (j++ % 100 == 0) cleanUpGorm()
            }

            if (j++ % 100 == 0) cleanUpGorm()

            if (++nUiu % 100 == 0) {
                def endUiu = System.nanoTime()
                log.info """
Inserite 100 UIU in ${(endUiu - startUiu) / 1000000000.0} secondi.
Totale UIU inserite $nUiu di $dm.uiu.size in ${(endUiu - start) / 1000000000.0} secondi."""
                startUiu = endUiu
            }

        }

        log.info "Fine salvataggio DatiMetrici [${(System.nanoTime() - start) / 1000000000.0} secondi]."
    }
}
