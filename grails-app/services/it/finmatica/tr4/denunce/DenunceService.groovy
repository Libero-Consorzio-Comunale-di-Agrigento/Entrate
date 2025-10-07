package it.finmatica.tr4.denunce

import grails.orm.PagedResultList
import grails.plugins.springsecurity.SpringSecurityService
import grails.transaction.NotTransactional
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.tr4.*
import it.finmatica.tr4.bonificaDati.GestioneAnomalieService
import it.finmatica.tr4.commons.CommonService
import it.finmatica.tr4.commons.TipoEventoDenuncia
import it.finmatica.tr4.contribuenti.LiquidazioniAccertamentiService
import it.finmatica.tr4.datiesterni.DocumentoCaricato
import it.finmatica.tr4.dto.CodiceRfidDTO
import it.finmatica.tr4.dto.VersamentoDTO
import it.finmatica.tr4.dto.pratiche.FamiliarePraticaDTO
import it.finmatica.tr4.dto.pratiche.OggettoContribuenteDTO
import it.finmatica.tr4.dto.pratiche.OggettoPraticaDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.jobs.Tr4AfcElaborazioneService
import it.finmatica.tr4.pratiche.*
import it.finmatica.tr4.sportello.FiltroRicercaCanoni
import org.hibernate.criterion.*
import org.hibernate.transform.AliasToEntityMapResultTransformer
import transform.AliasToEntityCamelCaseMapResultTransformer

@Transactional
class DenunceService {

    static final def VISUALIZZA_DOC_ID =
            ["ICI"  : true,
             "TASI" : true,
             "TARSU": false,
             "CUNI" : false]

    static final String DENUNCE = "denunce"
    def dataSource


    static final String DOCFCA = "docfca"
    def sessionFactory

    GestioneAnomalieService gestioneAnomalieService

    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    ImposteService imposteService
    SpringSecurityService springSecurityService
    CommonService commonService
    Tr4AfcElaborazioneService tr4AfcElaborazioneService

    /**
     * Legge tipo documento agganciato a pratica
     **/
    def getTitoloDocumentoPratica(Long idPratica) {

        Long titoloDocumento = 0

        def filtri = [:]

        filtri << ['idPratica': idPratica]

        String query = """
					SELECT
						PRTR.DOCUMENTO_ID,
						DOCA.TITOLO_DOCUMENTO
					FROM
						PRATICHE_TRIBUTO PRTR,
						DOCUMENTI_CARICATI DOCA
					WHERE
						NVL(PRTR.DOCUMENTO_ID,0) = DOCA.DOCUMENTO_ID (+) AND
						PRTR.PRATICA = :idPratica
		"""

        def paging = [:]
        def results = eseguiQuery(query, filtri, paging, true)

        def records = []

        results.each {

            titoloDocumento = (it['TITOLO_DOCUMENTO'] ?: 0).toLong()
        }

        return titoloDocumento
    }

    /**
     * Legge dati Dichiarazione ENC
     **/
    def getDichiarazioniENC(Long idPratica, String tipoTributo) {

        def filtri = [:]

        filtri << ['idPratica': idPratica]
        filtri << ['tipoTributo': tipoTributo]

        String query = """
					SELECT
						DITE.DOCUMENTO_ID,
						DITE.PROGR_DICHIARAZIONE,
						DITE.ANNO_DICHIARAZIONE,
						DITE.ANNO_IMPOSTA,
						DITE.NUM_IMMOBILI_A,
						DITE.NUM_IMMOBILI_B,
						DITE.IMU_DOVUTA,
						DITE.ECCEDENZA_IMU_DIC_PREC,
						DITE.ECCEDENZA_IMU_DIC_PREC_F24,
						DITE.RATE_IMU_VERSATE,
						DITE.IMU_DEBITO,
						DITE.IMU_CREDITO,
						DITE.TASI_DOVUTA,
						DITE.ECCEDENZA_TASI_DIC_PREC,
						DITE.ECCEDENZA_TASI_DIC_PREC_F24,
						DITE.TASI_RATE_VERSATE,
						DITE.TASI_DEBITO,
						DITE.TASI_CREDITO,
						DITE.IMU_CREDITO_DIC_PRESENTE,
						DITE.CREDITO_IMU_RIMBORSO,
						DITE.CREDITO_IMU_COMPENSAZIONE,
						DITE.TASI_CREDITO_DIC_PRESENTE,
						DITE.CREDITO_TASI_RIMBORSO,
						DITE.CREDITO_TASI_COMPENSAZIONE
					FROM
						WRK_ENC_TESTATA DITE,
						DOCUMENTI_CARICATI DOCA
					WHERE
						NVL(DITE.DOCUMENTO_ID,0) = DOCA.DOCUMENTO_ID (+) AND
						DOCA.TITOLO_DOCUMENTO = 26 AND
						decode(:tipoTributo,'ICI',DITE.TR4_PRATICA_ICI,DITE.TR4_PRATICA_TASI) = :idPratica
		"""

        def paging = [:]
        def results = eseguiQuery(query, filtri, paging, true)

        def records = []

        results.each {

            def record = [:]

            record.idDocumento = it['DOCUMENTO_ID']

            record.dichiarazioneProgr = it['PROGR_DICHIARAZIONE']
            record.dichiarazioneAnno = it['ANNO_DICHIARAZIONE']
            record.annoImposta = it['ANNO_IMPOSTA']
            record.numImmobiliA = it['NUM_IMMOBILI_A']
            record.numImmobiliB = it['NUM_IMMOBILI_B']

            record.dovutoIMU = it['IMU_DOVUTA']
            record.eccedenzaDicPrecIMU = it['ECCEDENZA_IMU_DIC_PREC']
            record.eccedenzaDicPrecF24IMU = it['ECCEDENZA_IMU_DIC_PREC_F24']
            record.rateIMUVersate = it['RATE_IMU_VERSATE']
            record.debitoIMU = it['IMU_DEBITO']
            record.creditoIMU = it['IMU_CREDITO']

            record.dovutoTASI = it['TASI_DOVUTA']
            record.eccedenzaDicPrecFTASI = it['ECCEDENZA_TASI_DIC_PREC']
            record.eccedenzaDicPrecF24TASI = it['ECCEDENZA_TASI_DIC_PREC_F24']
            record.rateVersateTASI = it['TASI_RATE_VERSATE']
            record.debitoTASI = it['TASI_DEBITO']
            record.creditoTASI = it['TASI_CREDITO']

            record.creditoIMUDicPresente = it['IMU_CREDITO_DIC_PRESENTE']
            record.creditoIMURimborso = it['CREDITO_IMU_RIMBORSO']
            record.creditoIMUCompensazione = it['CREDITO_IMU_COMPENSAZIONE']
            record.creditoTASIDicPresente = it['TASI_CREDITO_DIC_PRESENTE']
            record.creditoTASIRimborso = it['CREDITO_TASI_RIMBORSO']
            record.creditoTASICompensazione = it['CREDITO_TASI_COMPENSAZIONE']

            records << record
        }

        return records
    }

    /*
     * Legge dettagli oggetto pratica ENC
     */

    def getDichiarazioniOggettoENC(def idOggPratica, String tipoTributo) {

        def filtri = [:]

        filtri << ['idOggPratica': idOggPratica]
        filtri << ['tipoTributo': tipoTributo]

        String query = """
					SELECT
						ENCI.DOCUMENTO_ID DOCUMENTO_ID,
						ENCI.PROGR_DICHIARAZIONE PROGR_DICHIARAZIONE,
						ENCI.TIPO_ATTIVITA TIPO_ATTIVITA,
						DECODE(ENCI.TIPO_ATTIVITA,
									1,'Attivita'' assistenziali',
									2,'Attivita'' previdenziali',
									3,'Attivita'' sanitarie',
									4,'Attivita'' didattiche',
									5,'Attivita'' ricettive',
									6,'Attivita'' culturali',
									7,'Attivita'' ricreative',
									8,'Attivita'' sportive',
									9,'Attivita'' di religione e di culto',
									10,'Attivita'' di ricerca scientifica',
									NULL) DESCR_ATTIVITA,
						DECODE(ENCI.TIPO_ATTIVITA,4,ENCI.D_CORRISPETTIVO_MEDIO,ENCI.A_CORRISPETTIVO_MEDIO_PERC) CORRISPETTIVO_MEDIO,
						DECODE(ENCI.TIPO_ATTIVITA,4,ENCI.D_COSTO_MEDIO,ENCI.A_CORRISPETTIVO_MEDIO_PREV) COSTO_MEDIO,
						DECODE(ENCI.TIPO_ATTIVITA,4,ENCI.D_RAPPORTO_SUPERFICIE,ENCI.A_RAPPORTO_SUPERFICIE) RAPPORTO_SUPERFICIE,
						DECODE(ENCI.TIPO_ATTIVITA,4,ENCI.D_RAPPORTO_SUP_GG,ENCI.A_RAPPORTO_SUP_GG) RAPPORTO_SUP_GG,
						DECODE(ENCI.TIPO_ATTIVITA,4,ENCI.D_RAPPORTO_SOGGETTI,ENCI.A_RAPPORTO_SOGGETTI) RAPPORTO_SOGGETTI,
						DECODE(ENCI.TIPO_ATTIVITA,4,ENCI.D_RAPPORTO_SOGG_GG,ENCI.A_RAPPORTO_SOGG_GG) RAPPORTO_SOGG_GG,
						DECODE(ENCI.TIPO_ATTIVITA,4,ENCI.D_RAPPORTO_GIORNI,ENCI.A_RAPPORTO_GIORNI) RAPPORTO_GIORNI,
						DECODE(ENCI.TIPO_ATTIVITA,4,ENCI.D_PERC_IMPONIBILITA,ENCI.A_PERC_IMPONIBILITA) PERC_IMPONIBILITA,
						DECODE(ENCI.TIPO_ATTIVITA,4,ENCI.D_VALORE_ASS_ART_5,ENCI.A_VALORE_ASSOGGETTATO) VALORE_ASSOGGETTATO,
						ENCI.D_VALORE_ASS_ART_4,
						ENCI.D_CASELLA_RIGO_G,
						ENCI.D_CASELLA_RIGO_H,
						ENCI.D_RAPPORTO_CMS_CM,
						ENCI.D_VALORE_ASS_PARZIALE,
						ENCI.D_VALORE_ASS_COMPL
					FROM
						WRK_ENC_IMMOBILI ENCI
					WHERE
						DECODE(:tipoTributo,'ICI',ENCI.TR4_OGGETTO_PRATICA_ICI,ENCI.TR4_OGGETTO_PRATICA_TASI) = :idOggPratica
					"""

        def paging = [:]
        def results = eseguiQuery(query, filtri, paging, true)

        def records = []

        results.each {

            def record = [:]

            record.idDocumento = it['DOCUMENTO_ID']

            record.dichiarazioneProgr = it['PROGR_DICHIARAZIONE']

            record.tipoAttivita = it['TIPO_ATTIVITA']
            record.descrAttivita = it['DESCR_ATTIVITA']

            record.corrispettivoMedio = it['CORRISPETTIVO_MEDIO']
            record.costoMedio = it['COSTO_MEDIO']
            record.rapportoSuperficie = it['RAPPORTO_SUPERFICIE']
            record.rapportoSupGG = it['RAPPORTO_SUP_GG']
            record.rapportoSoggetti = it['RAPPORTO_SOGGETTI']
            record.rapportoSoggGG = it['RAPPORTO_SOGG_GG']
            record.rapportoGiorni = it['RAPPORTO_GIORNI']
            record.percImponibilita = it['PERC_IMPONIBILITA']
            record.valoreAssoggettato = it['VALORE_ASSOGGETTATO']
            record.valoreAssArt4 = it['D_VALORE_ASS_ART_4']
            record.casellaRigoG = it['D_CASELLA_RIGO_G']
            record.casellaRigoH = it['D_CASELLA_RIGO_H']
            record.rapportoCmsCM = it['D_RAPPORTO_CMS_CM']
            record.valoreAssParziale = it['D_VALORE_ASS_PARZIALE']
            record.valoreAssCompl = it['D_VALORE_ASS_COMPL']

            records << record
        }

        return records
    }

    /**
     * Legge dati DocFA
     **/
    def getDocFA(Long idPratica) {

        def filtri = [:]

        filtri << ['idPratica': idPratica]

        String query = """
					SELECT
						PRTR.DOCUMENTO_ID,
						PRTR.DOCUMENTO_MULTI_ID
					FROM
						PRATICHE_TRIBUTO PRTR,
						DOCUMENTI_CARICATI DOCA
					WHERE
						NVL(PRTR.DOCUMENTO_ID,0) = DOCA.DOCUMENTO_ID (+) AND
						DOCA.TITOLO_DOCUMENTO = 22 AND
						PRTR.pratica = :idPratica
		"""

        def paging = [:]
        def results = eseguiQuery(query, filtri, paging, true)

        def documents = []

        results.each {

            def documentoId = it['DOCUMENTO_ID']
            def documentoMultiId = it['DOCUMENTO_MULTI_ID']

            def docCaricato = DocumentoCaricato.findById(documentoId)
            def docMulti = docCaricato.documentiCaricatiMulti.findAll { it.id == documentoMultiId }

            docMulti.each {

                documents << it
            }
        }

        return documents
    }

    /**
     * Legge dati della successione
     **/
    def getDatiSuccessione(Long idSuccessione, String tipoTributo) {

        def filtri = [:]

        filtri << ['idSuccessione': idSuccessione]
        filtri << ['tipoTributo': tipoTributo]

        String query = """
					SELECT
						SUDE.SUCCESSIONE,
						SUDE.UFFICIO,
						SUDE.ANNO,
						SUDE.VOLUME,
						SUDE.NUMERO,
						DECODE(SUDE.SOTTONUMERO,NULL,NULL,0,NULL,'/ ' || TO_CHAR(SUDE.SOTTONUMERO)) SOTTONUMERO,
						SUDE.COMUNE,
						DECODE(SUDE.TIPO_DICHIARAZIONE,
								'P','Prima Dichiarazione' ,
								'R','Rettificativa',
								'I','Integrativa',
								'S','Sostitutiva',
								'M','Modificativa',
								'A','Aggiuntiva',
								'') TIPO_DICHIARAZIONE,
						SUDE.DATA_APERTURA DATA_MORTE,
						SUDE.COD_FISCALE,
						SUDE.COGNOME || '/' || SUDE.NOME COGNOME_NOME,
						SUDE.SESSO,
						'Nato a ' || SUDE.CITTA_NAS || ' (' || SUDE.PROV_NAS || ')' || '  il ' || TO_CHAR(SUDE.DATA_NAS,'dd/mm/yyyy') NASCITA,
						'Ultima Residenza: ' || SUDE.CITTA_RES || ' (' || SUDE.PROV_RES || ')' || '  in ' || SUDE.INDIRIZZO RESIDENZA,
						SUTD.PRATICA,
						PRTR.TIPO_TRIBUTO
					FROM
						SUCCESSIONI_DEFUNTI SUDE,
						PRATICHE_TRIBUTO PRTR,
						SUCCESSIONI_TRIBUTO_DEFUNTI SUTD
					WHERE
						SUDE.SUCCESSIONE = :idSuccessione AND
						SUTD.SUCCESSIONE = SUDE.SUCCESSIONE AND
						SUTD.TIPO_TRIBUTO = :tipoTributo AND
						PRTR.PRATICA = SUTD.PRATICA
		"""

        def paging = [:]
        def results = eseguiQuery(query, filtri, paging, true)

        def records = []

        results.each {

            def record = [:]

            record.idSuccessione = it['SUCCESSIONE']
            record.pratica = it['PRATICA']
            record.tipoTributo = it['TIPO_TRIBUTO']

            record.ufficio = it['UFFICIO']
            record.anno = it['ANNO']
            record.volume = it['VOLUME']
            record.numero = it['NUMERO']
            record.sottoNumero = it['SOTTONUMERO']
            record.comune = it['COMUNE']

            record.tipoDichiarazione = it['TIPO_DICHIARAZIONE']
            record.cognomeNome = it['COGNOME_NOME']
            record.codFiscale = it['COD_FISCALE']
            record.sesso = it['SESSO']
            record.nascita = it['NASCITA']
            record.dataMorte = it['DATA_MORTE']?.format("dd/MM/yyyy")
            record.residenza = it['RESIDENZA']

            records << record
        }

        return records
    }

    def elencoMotivazioni(def tipoTributo, def tipoPratica, def anno) {
        def sql = """
            select motivi_pratica.tipo_pratica "tipoPratica",
                   motivi_pratica.motivo "motivo",
                   motivi_pratica.tipo_tributo "tipoTributo",
                   motivi_pratica.sequenza "sequenza",
                   motivi_pratica.anno "anno"
              from motivi_pratica
             where (nvl(motivi_pratica.tipo_tributo, :tipoTributo) = :tipoTributo)
               and (nvl(motivi_pratica.tipo_pratica, :tipoPratica) = :tipoPratica)
               and (nvl(motivi_pratica.anno, :anno) = :anno)
             order by motivi_pratica.tipo_pratica asc

        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('tipoTributo', tipoTributo)
            setString('tipoPratica', tipoPratica)
            setLong('anno', anno)

            list()
        }

        def motivi = []
        results.each { motivi << MotiviPratica.findByTipoTributoAndSequenza(it.tipoTributo, it.sequenza)?.toDTO() }

        return motivi
    }

    /**
     * Riporta elenco immobili della successione coerenti con loggetto
     **/
    def getImmobiliSuccessione(Long idSuccessione, Long idOggetto) {

        def filtri = [:]

        filtri << ['idSuccessione': idSuccessione]
        filtri << ['idOggetto': idOggetto]

        String query = """
					SELECT
						SUIM.SUCCESSIONE,
						SUIM.PROGRESSIVO,
						SUIM.PROGR_IMMOBILE,
						SUIM.NUMERATORE_QUOTA_DEF,
						SUIM.DENOMINATORE_QUOTA_DEF,
						SUIM.DIRITTO,
						SUIM.PROGR_PARTICELLA,
						SUIM.CATASTO,
						SUIM.SEZIONE,
						SUIM.FOGLIO,
						SUIM.PARTICELLA_1,
						SUIM.PARTICELLA_2,
						SUIM.SUBALTERNO_1,
						SUIM.SUBALTERNO_2,
						SUIM.DENUNCIA_1,
						SUIM.DENUNCIA_2,
						SUIM.ANNO_DENUNCIA,
						SUIM.NATURA,
						SUIM.SUPERFICIE_ETTARI,
						SUIM.SUPERFICIE_MQ,
						SUIM.VANI,
						SUIM.INDIRIZZO,
						SUIM.VALORE,
						SUIM.OGGETTO
					FROM
						SUCCESSIONI_IMMOBILI SUIM
					WHERE
						SUIM.SUCCESSIONE = :idSuccessione AND
						SUIM.OGGETTO = :idOggetto
		"""

        def paging = [:]
        def results = eseguiQuery(query, filtri, paging, true)

        def records = []

        results.each {

            def record = [:]

            record.idSuccessione = it['SUCCESSIONE']
            record.idOggetto = it['OGGETTO']
            record.progressivo = it['PROGRESSIVO']

            record.progrImmobile = it['PROGR_IMMOBILE']

            record.numeratoreQuotaDef = (it['NUMERATORE_QUOTA_DEF'] ?: 0).toDouble()
            record.denominatoreQuotaDef = (it['DENOMINATORE_QUOTA_DEF'] ?: 0).toDouble()
            record.diritto = it['DIRITTO']
            record.progrParticella = it['PROGR_PARTICELLA']
            record.catasto = it['CATASTO']
            record.sezione = it['SEZIONE']
            record.foglio = it['FOGLIO']
            record.particella1 = it['PARTICELLA_1']
            record.particella2 = it['PARTICELLA_2']
            record.subalterno1 = it['SUBALTERNO_1']
            record.subalterno2 = it['SUBALTERNO_2']
            record.denuncia1 = it['DENUNCIA_1']
            record.denuncia2 = it['DENUNCIA_2']
            record.annoDenuncia = it['ANNO_DENUNCIA']
            record.natura = it['NATURA']
            record.superficieEttari = it['SUPERFICIE_ETTARI']
            record.superficieMQ = it['SUPERFICIE_MQ']
            record.vani = it['VANI']
            record.indirizzo = it['INDIRIZZO']
            record.valore = it['VALORE']

            switch (record.diritto) {
                default:
                    record.desDiritto = "ALTRO (" + record.diritto + ")"
                    break
                case '01':
                    record.desDiritto = "PROPRIETA'"
                    break
                case '02':
                    record.desDiritto = "NUDA PROPRIETA'"
                    break
                case '03':
                    record.desDiritto = "DIR. DI ABITAZIONE"
                    break
                case '04':
                    record.desDiritto = "DIR. CONC. ENFITEUSI"
                    break
                case '05':
                    record.desDiritto = "DIR. ENFITEUTA"
                    break
                case '06':
                    record.desDiritto = "DIR. DI SUPERFICIE"
                    break
                case '07':
                    record.desDiritto = "USO"
                    break
                case '08':
                    record.desDiritto = "USUFRUTTO"
                    break
                case '1S':
                    record.desDiritto = "PROPRIETA' SUPERFICIARIA"
                    break
                case '2S':
                    record.desDiritto = "NUDA PROPRIETA' SUPERFICIARIA"
                    break
                case '8S':
                    record.desDiritto = "USUFRUTTO SU PROPRIETA' SUPERFICIARIA"
                    break
                case '1T':
                    record.desDiritto = "PROPRIETA' PER AREA"
                    break
                case '2T':
                    record.desDiritto = "NUDA PROPRIETA' PER AREA"
                    break
                case '8T':
                    record.desDiritto = "USUFRUTTO SU PROPRIETA' PER AREA"
                    break
                case '3S':
                    record.desDiritto = "ABITAZIONE SU PROPRIETA' SUPERFICIARIA"
                    break
                case '7S':
                    record.desDiritto = "USO SU PROPRIETA' SUPERFICIARIA"
                    break
                case '7T':
                    record.desDiritto = "USO SU PROPRIETA' PER AREA"
                    break
                case '09':
                    record.desDiritto = "SERVITU'"
                    break
            }

            if (Math.abs(record.denominatoreQuotaDef) > 0.001) {

                record.possesso = (record.numeratoreQuotaDef / record.denominatoreQuotaDef) * 100.0
            } else {
                record.possesso = 0.0
            }

            records << record
        }

        return records
    }

    /**
     * Legge eredi dell'immobile
     **/
    def getErediImmobile(Long idSuccessione, Long idOggetto, String tipoTributo) {

        def filtri = [:]

        filtri << ['idSuccessione': idSuccessione]
        filtri << ['idOggetto': idOggetto]
        filtri << ['tipoTributo': tipoTributo]

        String query = """
					SELECT
						SUIM.SUCCESSIONE,
						SUIM.PROGRESSIVO,
						SUIM.PROGR_IMMOBILE,
						SUDE.NUMERATORE_QUOTA,
						SUDE.DENOMINATORE_QUOTA,
						SUDE.AGEVOLAZIONE_PRIMA_CASA,
						SUER.COD_FISCALE,
						CASE WHEN LENGTH(NVL(SUER.DENOMINAZIONE,'')) IS NULL
							THEN (SUER.COGNOME || '/' || SUER.NOME)
								ELSE SUER.DENOMINAZIONE
									END COGNOME_NOME,
						SUER.SESSO,
						SUER.CITTA_NAS || ' (' || SUER.PROV_NAS || ')' LUOGO_NAS,
						SUER.DATA_NAS,
						SUER.CITTA_RES || ' (' || SUER.PROV_RES || ')' LUOGO_RES,
						SUER.INDIRIZZO,
						SUIM.OGGETTO,
						SUTE.PRATICA
					FROM
						SUCCESSIONI_DEVOLUZIONI SUDE,
						SUCCESSIONI_EREDI SUER,
						SUCCESSIONI_IMMOBILI SUIM,
						SUCCESSIONI_TRIBUTO_EREDI SUTE
					WHERE
						SUIM.SUCCESSIONE = SUER.SUCCESSIONE AND
						SUDE.SUCCESSIONE = SUER.SUCCESSIONE(+) AND
						SUDE.PROGR_EREDE = SUER.PROGR_EREDE(+) AND
						SUDE.SUCCESSIONE = SUTE.SUCCESSIONE(+) AND
						SUDE.PROGR_EREDE = SUTE.PROGRESSIVO(+) AND
						SUDE.PROGR_IMMOBILE = SUIM.PROGR_IMMOBILE AND 
						SUIM.SUCCESSIONE = :idSuccessione AND
						SUIM.OGGETTO = :idOggetto AND 
						SUTE.TIPO_TRIBUTO = :tipoTributo
					ORDER BY 
						SUER.PROGR_EREDE
		"""

        def paging = [:]
        def results = eseguiQuery(query, filtri, paging, true)

        def records = []

        results.each {

            def record = [:]

            record.idSuccessione = it['SUCCESSIONE']
            record.idOggetto = it['OGGETTO']
            record.progressivo = it['PROGRESSIVO']

            record.progrImmobile = it['PROGR_IMMOBILE']

            record.pratica = it['PRATICA']
            record.numeratoreQuota = (it['NUMERATORE_QUOTA'] ?: 0).toDouble()
            record.denominatoreQuota = (it['DENOMINATORE_QUOTA'] ?: 0).toDouble()
            record.agevolazionePC = it['AGEVOLAZIONE_PRIMA_CASA']
            record.codFiscale = it['COD_FISCALE']
            record.cognomeNome = it['COGNOME_NOME']
            record.sesso = it['SESSO']
            record.luogoNas = it['LUOGO_NAS']
            record.dataNas = it['DATA_NAS']?.format("dd/MM/yyyy")
            record.luogoRes = it['LUOGO_RES']
            record.indirizzo = it['INDIRIZZO']

            if (Math.abs(record.denominatoreQuota) > 0.001) {

                record.possesso = (record.numeratoreQuota / record.denominatoreQuota) * 100.0
            } else {
                record.possesso = 0.0
            }

            records << record
        }

        return records
    }

    /**
     * Ritorna gli oggetti di una denuncia IMU/TASI
     * @param idPratica
     * @param codFiscale
     * @return
     */
    @NotTransactional
    def oggettiDenuncia(long idPratica, String codFiscale) {

        String query = """
					SELECT ogco 
					FROM OggettoContribuente ogco
						INNER JOIN FETCH ogco.contribuente cont
						INNER JOIN FETCH ogco.oggettoPratica ogpr
						INNER JOIN FETCH ogpr.oggettoPraticaRendita ogprre
						LEFT JOIN FETCH ogpr.oggettoPraticaRifAp ogprifap
						LEFT JOIN FETCH ogco.attributiOgco atog
						LEFT JOIN FETCH ogpr.categoriaCatasto caca
						LEFT JOIN FETCH ogpr.tipoOggetto tiog
						INNER JOIN FETCH ogpr.oggetto ogg
						LEFT JOIN FETCH ogg.archivioVie
					WHERE
						ogpr.pratica.id = :idPratica AND
						ogco.tipoRapporto in ('A', 'D') AND
						ogco.contribuente.codFiscale = :codFiscale
					ORDER BY
						LPAD(ogco.oggettoPratica.numOrdine, 2, '0')
		"""
        def lista = OggettoContribuente.executeQuery(query, [codFiscale: codFiscale, idPratica: idPratica]).toDTO(['oggettoPratica.pratica', 'attributiOgco.documentoId'])

        lista.each {
            if (it?.oggettoPratica?.oggettoPraticaRifAp != null) {
                it.flagAbPrincipale = OggettoContribuente.findByContribuenteAndOggettoPraticaAndFlagAbPrincipale(Contribuente.findByCodFiscale(codFiscale),
                        it.oggettoPratica.oggettoPraticaRifAp.toDomain(),
                        true) != null
            }
        }

        return lista
    }

    boolean presenzaDetrazioni(def pratica, def codiceFiscale, def tipoTributo) {
        String msg = ""
        try {
            Sql sql = new Sql(dataSource)
            sql.call('{? = call f_esiste_detrazione_ogco(?,?,?)}',
                    [Sql.VARCHAR,
                     pratica.id,
                     codiceFiscale,
                     tipoTributo]) { resMsg -> msg = resMsg
            }
        } catch (Exception e) {
            e.printStackTrace()
            commonService.serviceException(e)
        }
        return (msg) ? msg : false
    }

    boolean presenzaAliquote(def pratica, def codiceFiscale, def tipoTributo) {
        String msg = ""
        try {
            Sql sql = new Sql(dataSource)
            sql.call('{? = call f_esiste_aliquota_ogco(?,?,?)}',
                    [Sql.VARCHAR,
                     pratica.id,
                     codiceFiscale,
                     tipoTributo]) { resMsg -> msg = resMsg
            }
        } catch (Exception e) {
            e.printStackTrace()
            commonService.serviceException(e)
        }
        return (msg) ? msg : false
    }

    boolean presenzaUtilizziOggetto(def tipoTributo, def anno, def oggetto, def dataDa, def dataA) {
        String msg = ""
        try {
            Sql sql = new Sql(dataSource)
            sql.call('{? = call f_conta_utilizzi_oggetto(?,?,?,?,?)}',
                    [Sql.VARCHAR,
                     tipoTributo,
                     anno,
                     oggetto,
                     new java.sql.Timestamp(dataDa.getTime()),
                     new java.sql.Timestamp(dataA.getTime())]) { resMsg -> msg = resMsg
            }
        } catch (Exception e) {
            e.printStackTrace()
            commonService.serviceException(e)
        }
        return (msg && msg.equals("S")) ? true : false
    }


    def calcolaNumeroOrdine(Long idPratica) {
        String numero = "1"

        try {

            def filtri = [:]
            filtri << ['idPratica': idPratica]

            String query = """
							SELECT    MAX (DECODE (INSTR (num_ordine, '/'),
													 0, '',
													 SUBSTR (num_ordine, 0, INSTR (num_ordine, '/'))))
													   || TO_CHAR (
															   MAX (
																  TO_NUMBER (
																	 DECODE (
																		INSTR (num_ordine, '/'),
																		0, num_ordine,
																		NVL (
																		   SUBSTR (num_ordine,
																				   INSTR (num_ordine, '/') + 1,
																				   LENGTH (num_ordine)),
																		   1))))
															 + 1)
										  NUMERO 
          					FROM OGGETTI_PRATICA ogpr
							WHERE
								ogpr.pratica = :idPratica 
							"""
            def paging = [:]
            def results = eseguiQuery(query, filtri, paging, true)

            def records = []

            results.each {

                numero = (it['NUMERO'] ?: 1).toString()
            }
        } catch (Exception e) {
            numero = null
        }
        return numero
    }

    /**
     * Lista delle denunce
     *
     * @param cerca
     * @param deceduti
     * @param nonDeceduti
     * @param ordinamento
     * @param parRicerca
     * @param tipoTributo
     * @param tipoPratica
     * @param pageSize
     * @param activePage
     * @return
     */
    @NotTransactional
    def listaDenunce(boolean deceduti, boolean nonDeceduti,
                     def ordinamento,
                     def parRicerca, String tipoTributo, String tipoPratica, int pageSize, int activePage) {

        // Al momento la maschera di ricerca visualizza questi filtri solo per CUNI
        FiltroRicercaCanoni filtriAggiunti = (tipoTributo in ['CUNI']) ? parRicerca.filtriAggiunti : null

        def closureListaDenunce = {
            createAlias("rapportiTributo", "ratr", CriteriaSpecification.INNER_JOIN)
            createAlias("ratr.contribuente", "cont", CriteriaSpecification.INNER_JOIN)
            createAlias("cont.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
            createAlias("sogg.comuneResidenza", "comRes", CriteriaSpecification.LEFT_JOIN)
            createAlias("sogg.archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)

            projections {
                property("id")                        // 0
                property("sogg.cognomeNome")        // 1
                property("cont.codFiscale")            // 2
                property("anno")                    // 3
                property("data")                    // 4
                property("numero")                    // 5
                property("ratr.tipoRapporto")        // 6
                property("cont.soggetto")            // 7
                property("tipoTributo.tipoTributo")    // 8
                property("dataNotifica")            // 9
                property("comRes.ad4Comune")        // 10
                property("tipoEvento")        // 11
                property("tipoPratica")        // 12
                property("denunciante")        // 13
                property("codFiscaleDen")        // 14
                property("tipoCarica")        // 15
                property("indirizzoDen")        // 16
                property("comuneDenunciante")        // 17
                property("flagAnnullamento")        // 18

            }

            eq("tipoTributo.tipoTributo", tipoTributo)
            if (tipoPratica == '*') {
                'in'("tipoPratica", ['D', 'P'])
            } else {
                eq("tipoPratica", tipoPratica)
            }

            if (deceduti) {
                eq("sogg.stato.id", 50 as Long)
            }

            if (VISUALIZZA_DOC_ID[tipoTributo] && parRicerca?.document && parRicerca?.document.documentoId) {
                eq("documentoId", (parRicerca.document.documentoId as BigDecimal).longValue())
            }

            if (nonDeceduti) {
                or {
                    isNull("sogg.stato")
                    ne("sogg.stato.id", 50 as Long)
                }
            }
            if (parRicerca?.cognome) {
                ilike("sogg.cognomeRic", parRicerca?.cognome.toUpperCase() + "%")
            }
            if (parRicerca?.nome) {
                ilike("sogg.nomeRic", parRicerca?.nome.toUpperCase() + "%")
            }
            if (parRicerca?.cf) {
                ilike("cont.codFiscale", parRicerca?.cf + "%")
            }
            if (parRicerca?.numeroIndividuale) {
                eq("sogg.id", parRicerca?.numeroIndividuale)
            }
            if (parRicerca?.codContribuente) {
                eq("cont.codContribuente", parRicerca?.codContribuente)
            }

            def daNumero = parRicerca?.daNumero
            def aNumero = parRicerca?.aNumero
            def isDaNumeroNotEmpty = daNumero != null && daNumero != ""
            def isANumeroNotEmpty = aNumero != null && aNumero != ""

            if (isDaNumeroNotEmpty) {
                if (daNumero.contains('%')) {
                    ilike("numero", daNumero?.toUpperCase())
                } else {
                    add(Restrictions.ge("numeroPadded", aNumero?.padLeft(15)).ignoreCase())
                }
            }

            if (isANumeroNotEmpty) {
                add(Restrictions.le("numeroPadded", aNumero?.padLeft(15)).ignoreCase())
            }

            if (parRicerca?.daAnno) {
                ge("anno", (short) parRicerca?.daAnno)
            }
            if (parRicerca?.aAnno) {
                le("anno", (short) parRicerca?.aAnno)
            }
            if (parRicerca?.daNumeroPratica) {
                ge("id", parRicerca?.daNumeroPratica)
            }
            if (parRicerca?.aNumeroPratica) {
                le("id", parRicerca?.aNumeroPratica)
            }
            if (parRicerca?.daData) {
                ge("data", parRicerca?.daData)
            }
            if (parRicerca?.aData) {
                //SOLO se non è stato impostato l'estremo superiore dell'intervallo di date,
                // si cercano anche le pratiche con data di presentazione null
                if (!parRicerca?.daData) {
                    or {
                        le("data", parRicerca?.aData)
                        isNull("data")
                    }
                } else {
                    le("data", parRicerca?.aData)
                }
            }
            if (parRicerca?.dichiaranti) {
                eq("ratr.tipoRapporto", "D")
            }
            if (parRicerca?.frontespizio) {
                isEmpty("oggettiPratica")
            }
            if (parRicerca?.flagAnnullamento) {
                eq("flagAnnullamento", "S")
            }

            if (parRicerca?.flagEsclusione) {
                DetachedCriteria subQuery = DetachedCriteria.forClass(OggettoPratica, "ogpr").setProjection(Projections.property("id"))
                subQuery.createAlias("oggettiContribuente", "ogco")
                subQuery.with {
                    add(Restrictions.eqProperty("ogpr.pratica", "this.id"))
                    add(Restrictions.eq("ogco.flagEsclusione", "S"))
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists ", subQuery)
                add(exists)
            }
            if (parRicerca?.flagAbitazionePrincipale) {
                DetachedCriteria subQuery = DetachedCriteria.forClass(OggettoPratica, "ogpr").setProjection(Projections.property("id"))
                subQuery.createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                subQuery.with {
                    add(Restrictions.eqProperty("ogpr.pratica", "this.id"))
                    add(Restrictions.eqProperty("ogco.contribuente.codFiscale", "cont.codFiscale"))
                    add(Restrictions.eq("ogco.flagAbPrincipale", "S"))
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists ", subQuery)
                add(exists)
            }
            if (parRicerca?.fonte) {
                DetachedCriteria subQuery = DetachedCriteria.forClass(OggettoPratica, "ogpr").setProjection(Projections.property("id"))
                subQuery.createAlias("fonte", "font", CriteriaSpecification.INNER_JOIN)
                subQuery.with {
                    add(Restrictions.eqProperty("ogpr.pratica", "this.id"))
                    //add(Restrictions.eqProperty("ogpr.utente", "TR4"))
                    add(Restrictions.eq("font.fonte", parRicerca?.fonte.fonte))
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists ", subQuery)
                add(exists)
            }

            def codiciTributo = parRicerca.codiciTributo ?: []
            def tipiTariffa = parRicerca.tipiTariffa ?: []
            if ((codiciTributo.size() > 0) || (tipiTariffa.size() > 0)) {
                DetachedCriteria subQuery = DetachedCriteria.forClass(OggettoPratica, "ogpr").setProjection(Projections.property("id"))
                subQuery.createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                subQuery.with {
                    add(Restrictions.eqProperty("ogpr.pratica", "this.id"))
                    add(Restrictions.eqProperty("ogco.contribuente.codFiscale", "cont.codFiscale"))
                    if (tipiTariffa.size() > 0) {
                        String listTariffe = tipiTariffa.join(", ")
                        add(Restrictions.sqlRestriction("TO_NUMBER(LPAD({alias}.tributo,4,'0')||LPAD({alias}.tipo_tariffa,2,'0')) IN (${listTariffe})"))
                    } else {
                        add(Restrictions.'in'("ogpr.codiceTributo.id", codiciTributo))
                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists ", subQuery)
                add(exists)
            }

            if ((filtriAggiunti) && (filtriAggiunti.isDirty())) {
                DetachedCriteria subQuery = DetachedCriteria.forClass(OggettoPratica, "ogpr").setProjection(Projections.property("id"))
                subQuery.createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                subQuery.createAlias("oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
                subQuery.createAlias("ogge.archivioVie", "arve", CriteriaSpecification.LEFT_JOIN)    //

                subQuery.with {
                    add(Restrictions.eqProperty("ogpr.pratica", "this.id"))
                    add(Restrictions.eqProperty("ogco.contribuente.codFiscale", "cont.codFiscale"))
                    if (filtriAggiunti.descrizione) {
                        add(Restrictions.ilike("ogge.descrizione", filtriAggiunti.descrizione))
                    }
                    if (filtriAggiunti.indirizzo) {
                        String indirizzoOgg = filtriAggiunti.indirizzo.toLowerCase()
                        add(Restrictions.sqlRestriction("""LOWER(DECODE(ogge2_.cod_via,NULL,ogge2_.indirizzo_localita,arve3_.denom_uff) ||
																DECODE(ogge2_.num_civ,NULL,'', ', ' || ogge2_.num_civ) ||
																	DECODE(ogge2_.suffisso,NULL,'', '/' || ogge2_.suffisso)) like('${indirizzoOgg}') """))
                    }

                    if (filtriAggiunti.localita) {
                        add(Restrictions.ilike("ogpr.indirizzoOcc", filtriAggiunti.localita))
                    }
                    if (filtriAggiunti.codPro) {
                        add(Restrictions.eq("ogpr.codProOcc", filtriAggiunti.codPro))
                    }
                    if (filtriAggiunti.codCom) {
                        add(Restrictions.eq("ogpr.codComOcc", filtriAggiunti.codCom))
                    }
                    if (filtriAggiunti.daKMDa) {
                        add(Restrictions.ge("ogpr.daChilometro", filtriAggiunti.daKMDa as BigDecimal))
                    }
                    if (filtriAggiunti.daKMA) {
                        add(Restrictions.le("ogpr.daChilometro", filtriAggiunti.daKMA as BigDecimal))
                    }
                    if (filtriAggiunti.aKMDa) {
                        add(Restrictions.ge("ogpr.aChilometro", filtriAggiunti.aKMDa as BigDecimal))
                    }
                    if (filtriAggiunti.aKMA) {
                        add(Restrictions.le("ogpr.aChilometro", filtriAggiunti.aKMA as BigDecimal))
                    }
                    if (filtriAggiunti.concessioneDa) {
                        add(Restrictions.ge("ogpr.numConcessione", filtriAggiunti.concessioneDa as Integer))
                    }
                    if (filtriAggiunti.concessioneA) {
                        add(Restrictions.le("ogpr.numConcessione", filtriAggiunti.concessioneA as Integer))
                    }
                    if (filtriAggiunti.dataConcessioneDa) {
                        add(Restrictions.ge("ogpr.dataConcessione", filtriAggiunti.dataConcessioneDa as Date))
                    }
                    if (filtriAggiunti.dataConcessioneA) {
                        add(Restrictions.le("ogpr.dataConcessione", filtriAggiunti.dataConcessioneA as Date))
                    }
                    if (filtriAggiunti.esenzione) {
                        def esenzione = filtriAggiunti.esenzione?.codice
                        if (esenzione == 'S') {
                            add(Restrictions.eq("ogpr.flagContenzioso", 'S'))
                        }
                        if (esenzione == 'N') {
                            add(Restrictions.isNull("ogpr.flagContenzioso"))
                        }
                    }
                    if (filtriAggiunti.flagNullaOsta) {
                        def flagNullaOsta = filtriAggiunti.flagNullaOsta?.codice
                        if (flagNullaOsta == 'S') {
                            add(Restrictions.eq("ogpr.flagNullaOsta", 'S'))
                        }
                        if (flagNullaOsta == 'N') {
                            add(Restrictions.isNull("ogpr.flagNullaOsta"))
                        }
                    }
                    delegate
                }
                ExistsSubqueryExpression exists = new ExistsSubqueryExpression("exists ", subQuery)
                add(exists)
            }

            //TODO cercare un metodo migliore (abbiamo provato con una in (select..
            //ma non funzionava perchè la seconda select deve leggere dei valori dalla prima
            if (parRicerca?.doppie) {
                sqlRestriction(" f_denuncia_doppia({alias}.pratica, ratr1_.cod_fiscale) = 'S' ")
            }
        }

        def lista = PraticaTributo.createCriteria().list {

            closureListaDenunce.delegate = delegate
            closureListaDenunce()

            switch (ordinamento.tipo) {
                case CampiOrdinamento.ALFA:
                    if (ordinamento.ascendente) {
                        order("sogg.cognomeNome", "asc")
                        order("cont.codFiscale", "asc")
                        order("anno", "asc")
                    } else {
                        order("sogg.cognomeNome", "desc")
                        order("cont.codFiscale", "desc")
                        order("anno", "desc")
                    }
                    break
                case CampiOrdinamento.CF:
                    if (ordinamento.ascendente) {
                        order("cont.codFiscale", "asc")
                        order("anno", "asc")
                        order("data", "asc")
                        order("numeroPadded", "asc")
                    } else {
                        order("cont.codFiscale", "desc")
                        order("anno", "desc")
                        order("data", "desc")
                        order("numeroPadded", "desc")
                    }
                    break
                case CampiOrdinamento.ANNO:
                    if (ordinamento.ascendente) {
                        order("anno", "asc")
                        order("sogg.cognomeNome", "asc")
                        order("data", "asc")
                        order("numeroPadded", "asc")
                    } else {
                        order("anno", "desc")
                        order("sogg.cognomeNome", "desc")
                        order("data", "asc")
                        order("numeroPadded", "desc")
                    }
                    break
                case CampiOrdinamento.DATA:
                    if (ordinamento.ascendente) {
                        order("data", "asc")
                        order("sogg.cognomeNome", "asc")
                        order("anno", "asc")
                        order("numeroPadded", "asc")
                    } else {
                        order("data", "desc")
                        order("sogg.cognomeNome", "desc")
                        order("anno", "desc")
                        order("numeroPadded", "desc")
                    }
                    break
                default:
                    break
            }

            firstResult(pageSize * activePage)
            maxResults(pageSize)
        }.collect { row ->
            def praticaSuccessiva = functionProssimaPratica(row[0], row[2], row[8])
            [id                  : row[0]
             , cognomeNome       : row[1]
             , codFiscale        : row[2]
             , anno              : row[3]
             , data              : row[4]?.format("dd/MM/yyyy")
             , numero            : row[5]
             , tipoRapporto      : row[6]
             , indirizzo         : row[7]?.indirizzo
             , comune            : row[10]
             , tipoTributo       : row[8]
             , tipoTributoAttuale: TipoTributo.get(row[8])?.toDTO()?.getTipoTributoAttuale(row[3] as Short)
             , dataNotifica      : row[9]
             , tipoEvento        : "${row[11]?.id} - ${row[11]?.descrizione}"
             , eventoSuccessivo  : praticaSuccessiva?.substring(0, 1) ? "${praticaSuccessiva?.substring(0, 1)} - ${TipoEventoDenuncia.getById(praticaSuccessiva?.substring(0, 1))?.descrizione}" : null
             , praticaSuccessiva : praticaSuccessiva?.substring(1)?.replaceFirst("^0*", "")
             , denunciante       : row[13]
             , codFiscaleDen     : row[14]
             , tipoCarica        : row[15] ? "${row[15]?.id} - ${row[15]?.descrizione}" : ""
             , indirizzoDen      : row[16]
             , comuneDen         : row[17] ? row[17]?.ad4Comune?.denominazione : ""
             , provinciaDen      : row[17] ? row[17]?.ad4Comune?.provincia?.sigla : ""
             , tipoPratica       : row[12]
             , flagAnnullata     : row[18]]
        }
        def totalCount = PraticaTributo.createCriteria().count() {
            closureListaDenunce.delegate = delegate
            closureListaDenunce()
        }

        return [total: totalCount, result: lista]
    }

    // Verifica se può modificare anno della denuncia
    boolean consentiModificaAnno(def denuncia) {

        boolean result = true

        short annoNuovo = denuncia.pratica.anno

        def denunciaSalva = denuncia.getDomainObject()
        if (denunciaSalva != null) {

            PraticaTributo pratica = denunciaSalva.pratica
            short annoDenuncia = pratica.anno

            if (annoDenuncia != annoNuovo) {

                short annoMin = Math.min(annoNuovo, annoDenuncia)
                short annoMax = Math.max(annoNuovo, annoDenuncia)
                def elencoPratiche = elencoLiquidazioniAccertamentiOggPr(pratica.id, annoMin, annoMax)
                if (elencoPratiche.size() > 0) result = false
            }
        }

        return result
    }

    // Verifica se può salvare la denuncia
    def salvaDenunciaCheck(def denuncia) {

        String message = ""
        Integer result = 0

        short annoNuovo = denuncia.pratica.anno

        def denunciaSalva = denuncia.getDomainObject()
        if (denunciaSalva != null) {

            PraticaTributo pratica = denunciaSalva.pratica
            short annoDenuncia = pratica.anno

            if (annoDenuncia != annoNuovo) {

                short annoMin = Math.min(annoNuovo, annoDenuncia)
                short annoMax = Math.max(annoNuovo, annoDenuncia)
                def accertamenti = elencoLiquidazioniAccertamentiOggPr(pratica.id, annoMin, annoMax)
                if (accertamenti.size() > 0) {

                    String listaAccertamenti = creaListaPratiche(accertamenti)

                    if (result <= 2) {

                        if (message != "") message += "\n\n"
                        message += "Impossibile modificare l'anno in quanto esistono, su uno o piu' oggetti, " + "Liquidazione e/o Accertamenti in conflitto di annualita' !\n\n" + "- ${listaAccertamenti}"
                        result = 2
                    }
                }

                def ravvedimenti = elencoRavvedimentiOggPr(pratica.id, annoMin, annoMax)
                if (ravvedimenti.size() > 0) {

                    String listaRavvedimenti = creaListaPratiche(ravvedimenti)

                    if (result <= 2) {

                        if (message != "") message += "\n\n"
                        message += "Impossibile modificare l'anno in quanto esistono Ravvedimenti in conflitto di annualita'\n\n" + "- ${listaRavvedimenti}"

                        result = 2
                    }
                }
            }
        }

        return [result: result, message: message]
    }

    // Salva la denuncia - Da implementare per TARSU/TARI
    def salvaDenuncia(def denuncia, def listaFetch, String tipoRapporto, boolean flagCf, String prefissoTelefonico,
                      Integer numTelefonico, boolean flagFirma, boolean flagDenunciante, String tipoTributo) {

        boolean variatoAnno = false

        def denunciaSalvaDTO = null
        def denunciaSalva

        def ravvedimentiPosteriori = []
        // Ravvedimenti per gli oggetti della pratica posteriori all'annualità della pratica

        PraticaTributo pratica
        Contribuente cont

        try {

            //bisogna salvare i contribuenti, così da crearli se nuovi
            cont = denuncia.pratica.contribuente.getDomainObject() ?: new Contribuente()
            if (!cont.codFiscale) {
                cont.codFiscale = denuncia.pratica.contribuente.codFiscale.toUpperCase()
                cont.soggetto = denuncia.pratica.contribuente.soggetto?.getDomainObject()
                cont.codContribuente = denuncia.pratica.contribuente.codContribuente
                cont.codControllo = denuncia.pratica.contribuente.codControllo
                cont.note = denuncia.pratica.contribuente.note
                cont.codAttivita = denuncia.pratica.contribuente.codAttivita

                cont.save(failOnError: true, flush: true)
            }

            short anno = denuncia.pratica.anno
            short annoPrec = anno

            pratica = denuncia.pratica.getDomainObject()
            if (pratica == null) {
                pratica = new PraticaTributo()
                pratica.anno = anno
            }

            denunciaSalva = denuncia.getDomainObject()
            if (denunciaSalva == null) {
                switch (tipoTributo) {
                    case 'ICI':
                        denunciaSalva = new DenunciaIci()
                        break
                    case 'TASI':
                        denunciaSalva = new DenunciaTasi()
                        break
                    case 'TARSU':
                        denunciaSalva = new DenunciaTarsu()
                        break
                    default:
                        throw new RuntimeException("${tipoTributo} non suppoortato")

                }
            }

            if (pratica.id <= 0) {    //se pratica nuova, settare i valori di default
                pratica.tipoTributo = TipoTributo.get(tipoTributo)
                pratica.tipoEvento = denuncia.pratica.tipoEvento ?: TipoEventoDenuncia.I
                pratica.tipoPratica = "D"
                //in modifica il rapporto ed il contribuente non si toccano
                //in caso di pratica nuova creo il rapporto
                //gli metto lo stesso contribuente della pratica e lo associo alla pratica
                RapportoTributo ratr = new RapportoTributo()
                ratr.tipoRapporto = tipoRapporto
                ratr.contribuente = cont
                pratica.addToRapportiTributo(ratr) //così si associa il rapporto alla pratica
            }
            //salvo i dati di PRATICHE_TRIBUTO
            pratica.contribuente = cont //posso farlo perchè per la tasi il contribuente è uno solo ???????
            if (pratica.anno != anno) {
                annoPrec = pratica.anno
                pratica.anno = anno
                variatoAnno = true
            }
            pratica.note = denuncia.pratica.note
            pratica.motivo = denuncia.pratica.motivo
            pratica.numero = denuncia.pratica.numero
            pratica.data = denuncia.pratica.data
            pratica.denunciante = denuncia.pratica.denunciante?.toUpperCase() ?: ""
            pratica.indirizzoDen = denuncia.pratica.indirizzoDen?.toUpperCase() ?: ""
            pratica.tipoCarica = denuncia.pratica.tipoCarica?.getDomainObject() ?: null
            pratica.comuneDenunciante = denuncia.pratica.comuneDenunciante?.getDomainObject() ?: null
            pratica.codFiscaleDen = denuncia.pratica.codFiscaleDen?.toUpperCase() ?: ""
            pratica.partitaIvaDen = denuncia.pratica.partitaIvaDen?.toUpperCase() ?: ""
            pratica.flagAnnullamento = denuncia.pratica.flagAnnullamento
            pratica.save(failOnError: true, flush: true)
            // aggiorna le note degli iter
            denuncia.pratica.iter*.toDomain()*.save(flush: true, failOnError: true)
            //se nuova, scrivo sulla denuncia lo stesso id della pratica
            //sia nel campo pratica sia nel campo denuncia
            if (denunciaSalva.id <= 0) {
                denunciaSalva.id = pratica.id

                if (!(denunciaSalva instanceof DenunciaTarsu)) {
                    denunciaSalva.denuncia = denunciaSalva.id
                }
            }
            if (!(denunciaSalva instanceof DenunciaTarsu)) {
                denunciaSalva.prefissoTelefonico = prefissoTelefonico
                denunciaSalva.numTelefonico = numTelefonico
                denunciaSalva.flagCf = flagCf
                denunciaSalva.flagFirma = flagFirma
                denunciaSalva.flagDenunciante = flagDenunciante
                denunciaSalva.fonte = (denuncia.fonte) ? denuncia.fonte.getDomainObject() : new Fonte(fonte: 3)
            }
            denunciaSalva.pratica = pratica
            denunciaSalva.save(failOnError: true, flush: true)

            if (variatoAnno) {

                pratica.oggettiPratica.each {

                    impostaAnnoOggettoPratica(it, anno)
                }

                short annoMin = Math.min(anno, annoPrec)
                short annoMax = Math.min(anno, annoPrec)
                ravvedimentiPosteriori = elencoRavvedimentiOggPr(pratica.id, annoMin, annoMax)
            }


            // Gestione versamenti
            List<VersamentoDTO> versamentiNew = denuncia.pratica.versamenti?.toList()
            List<VersamentoDTO> versamentiOld = getVersamenti(denuncia.pratica.id,
                    denuncia.pratica.tipoPratica,
                    denuncia.pratica.tipoTributo.tipoTributo)

            pratica.versamenti?.clear()

            // Eliminazione dei versamenti
            versamentiOld?.each { versOld ->
                if (!versamentiNew.find { versNew -> versNew.sequenza != null && versOld.sequenza == versNew.sequenza }) {
                    versOld.toDomain().delete(flush: true)
                }
            }

            // Aggiunte/modificate
            versamentiNew?.each {
                it.toDomain().save(failOnError: true, flush: true)
            }

            // Gestione familiari
            List<FamiliarePraticaDTO> familiariNew = denuncia.pratica.familiariPratica?.toList()
            List<FamiliarePraticaDTO> familiariOld =
                    FamiliarePratica.findAllByPratica(PraticaTributo.get(denuncia.pratica.id)).toDTO()

            pratica.familiariPratica?.clear()

            // Eliminazione dei familiari
            familiariOld?.each { famOld ->
                if (!familiariNew.find { famNew -> famNew.soggetto.id == famOld.soggetto.id }) {
                    famOld.toDomain().delete(flush: true)
                }
            }

            // Aggiunte/modificate
            familiariNew?.each {
                it.toDomain().save(failOnError: true, flush: true)
            }

            denunciaSalvaDTO = denunciaSalva.toDTO(listaFetch)
        } catch (Exception e) {
            commonService.serviceException(e)
        }

        return [denuncia: denunciaSalvaDTO, ravvedimentiPosteriori: ravvedimentiPosteriori]
    }

    // Imposta anno per Oggetto Pratica ed a catena tutti quelli rilevanti
    private
    def impostaAnnoOggettoPratica(OggettoPratica oggetto, short anno) {

        oggetto.anno = anno
        oggetto.save(failOnError: true, flush: true)

        oggetto.oggettiContribuente.each {

            OggettoContribuente oggCo = it
            oggCo.anno = anno
            oggCo.save(failOnError: true, flush: true)
        }

        return
    }

    // Esegue aggiornamento immobili per i ravvedimenti per oggetto della pratica per anno
    def aggiornaImmobiliRavvedimenti(def ravvedimenti) {

        String message = ""
        Integer result = 0

        if (ravvedimenti.size() > 0) {

            ravvedimenti.each {

                String messageThis = ""

                try {

                    PraticaTributoDTO pratica = PraticaTributo.findById(it).toDTO()

                    messageThis = " - " + pratica.numero.toString() + "/" + pratica.anno.toString() + " : "

                    liquidazioniAccertamentiService.creaRavvedimento(pratica.contribuente.codFiscale,
                            pratica.anno,
                            pratica.data,
                            pratica.tipoEvento.tipoEventoDenuncia,
                            pratica.tipoRavvedimento,
                            pratica.tipoTributo.tipoTributo,
                            pratica.id)

                    imposteService.proceduraCalcolaImpostaRavv(pratica.id)
                    liquidazioniAccertamentiService.calcolaSanzioniRavvedimento(pratica.id)

                    messageThis += "Ok"
                } catch (Exception e) {

                    if (e?.message?.startsWith("ORA-20999")) {
                        messageThis += e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
                        if (result < 1) result = 1
                    } else if (e?.cause?.cause?.message?.startsWith("ORA-20999")) {
                        messageThis += e.cause.cause.message.substring('ORA-20999: '.length(), e.cause.cause.message.indexOf('\n'))
                        if (result < 1) result = 1
                    } else {
                        messageThis += e.message
                        if (result < 2) result = 2
                    }
                }

                if (message.size() > 0) message += "\n"
                message += messageThis
            }
        }

        return [result: result, message: message]
    }

    // Verifica presenza Liquidazioni e/o Accertamenti antecedenti su oggetti della pratica e per anno
    private
    def elencoLiquidazioniAccertamentiOggPr(def pratica, short annoMin, short annoMax) {

        String sql = """
					SELECT DISTINCT
						PRTR_LV.PRATICA,
						PRTR_LV.ANNO,
						PRTR_LV.NUMERO
					FROM
						PRATICHE_TRIBUTO PRTR_LV,
						OGGETTI_PRATICA OGPR_LV
					WHERE
						PRTR_LV.TIPO_PRATICA IN ('L','A') AND
						NVL(PRTR_LV.STATO_ACCERTAMENTO,'D') = 'D' AND
						PRTR_LV.PRATICA = OGPR_LV.PRATICA AND
						PRTR_LV.ANNO BETWEEN :annoMin AND :annoMax AND
						OGPR_LV.OGGETTO_PRATICA_RIF IN
						(SELECT
							OGPR.OGGETTO_PRATICA
						FROM 
							OGGETTI_PRATICA OGPR
						WHERE 
							OGPR.PRATICA = :pratica)
					ORDER BY
						PRTR_LV.ANNO,
						PRTR_LV.NUMERO
		"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            setParameter("pratica", pratica)
            setParameter("annoMin", annoMin)
            setParameter("annoMax", annoMax)

            list()
        }

        def records = []

        results.each {

            def numero = it['PRATICA'].toBigDecimal()
            records << numero
        }

        return records
    }

    // Ricava elenco Ravvedimenti posteriori su oggetti della pratica e per anno
    private
    def elencoRavvedimentiOggPr(def pratica, short annoMin, short annoMax) {

        String sql = """
					SELECT DISTINCT
						PRTR_LV.PRATICA,
						PRTR_LV.ANNO,
						PRTR_LV.NUMERO
					FROM
						PRATICHE_TRIBUTO PRTR_LV,
						OGGETTI_PRATICA OGPR_LV
					WHERE
						PRTR_LV.TIPO_PRATICA IN ('V') AND
						NVL(PRTR_LV.STATO_ACCERTAMENTO,'D') = 'D' AND
						PRTR_LV.PRATICA = OGPR_LV.PRATICA AND
						PRTR_LV.ANNO BETWEEN :annoMin AND :annoMax AND
						OGPR_LV.OGGETTO_PRATICA_RIF IN
						(SELECT
							OGPR.OGGETTO_PRATICA
						FROM 
							OGGETTI_PRATICA OGPR
						WHERE 
							OGPR.PRATICA = :pratica)
					ORDER BY
						PRTR_LV.ANNO,
						PRTR_LV.NUMERO
		"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE

            setParameter("pratica", pratica)
            setParameter("annoMin", annoMin)
            setParameter("annoMax", annoMax)

            list()
        }

        def records = []

        results.each {

            def numero = it['PRATICA'].toBigDecimal()
            records << numero
        }

        return records
    }

    private
    String creaListaPratiche(def pratiche) {

        String listaPratiche = ""

        pratiche.each {

            PraticaTributoDTO pratica = PraticaTributo.findById(it).toDTO()

            if (listaPratiche.length() > 0) listaPratiche += ", "
            if (pratica.numero != null) {
                listaPratiche += pratica.numero.toString() + "/" + pratica.anno.toString()
            } else {
                listaPratiche += "Senza Numero" + "/" + pratica.anno.toString() + " [${pratica.id.toString()}]"
            }
        }

        return listaPratiche
    }

    boolean esisteDenunciaInTasi(def pratica) {
        return PraticaTributo.createCriteria().list {
            eq("tipoTributo.tipoTributo", "TASI")
            eq("anno", pratica.anno)
            eq("tipoPratica", pratica.tipoPratica)
            eq("contribuente.codFiscale", pratica.contribuente.codFiscale)
        }?.size > 0
    }

    String duplicaDenuncia(def pratica, def tipo, def anno, def codiceFiscale, boolean duplicaContitolari) {
        String msg = ""
        try {

            Sql sql = new Sql(dataSource)
            sql.call('{? = call F_DUPLICA_DENUNCIA(?,?,?,?,?,?)}'
                    , [Sql.VARCHAR,
                       pratica.id,
                       tipo,
                       anno,
                       codiceFiscale,
                       springSecurityService.currentUser.id,
                       (duplicaContitolari) ? 'S' : 'N']) { resMsg -> msg = resMsg
            }
        } catch (Exception e) {
            e.printStackTrace()
            commonService.serviceException(e)
        }
        return msg
    }

    String duplicaInTasi(def pratica) {
        String msg = ""
        try {
            Sql sql = new Sql(dataSource)
            sql.call('{? = call f_pratica_tasi_da_imu(?,?)}'
                    , [Sql.VARCHAR,
                       pratica.id,
                       springSecurityService.currentUser.id]) { resMsg -> msg = resMsg
            }
        } catch (Exception e) {
            e.printStackTrace()
            commonService.serviceException(e)
        }
        return msg
    }

    String eliminaPratica(def pratica) {

        def esito = eliminabile(pratica)

        if (esito.isEmpty()) {
            try {
                PraticaTributo pt

                if (pratica instanceof PraticaTributo) {
                    pt = pratica
                } else if (pratica instanceof PraticaTributoDTO) {
                    pt = pratica.getDomainObject()
                }

                // Se sono presenti alog o deog si eliminano
                def alogDaEliminare = []
                def deogDaEliminare = []
                pt.oggettiPratica.each { op ->
                    op.oggettiContribuente.each { oc ->
                        oc.aliquoteOgco.each {
                            alogDaEliminare << it
                        }
                        oc.aliquoteOgco.clear()
                        oc.detrazioniOgco.each {
                            deogDaEliminare << it
                        }
                        oc.detrazioniOgco.clear()
                    }
                }
                alogDaEliminare.each {
                    it.delete(flush: true)
                }
                deogDaEliminare.each {
                    it.delete(flush: true)
                }

                pt.delete(flush: true, failOnError: true)

            } catch (Exception e) {
                commonService.serviceException(e)
            }
        }
        return esito
    }

    def eliminaPraticaTarsu(def praticaId) {
        def pratica = PraticaTributo.get(praticaId)
        if (pratica.tipoTributo.tipoTributo != 'TARSU') {
            throw new RuntimeException("La pratica ${praticaId} non è una pratica TARSU")
        }
        pratica.delete(flush: true)
    }

    boolean controlloContitolariPratica(Long idPratica) {
        // Se esistono contitolari per la pratica con tipo rapporto C
        String query = """
                    SELECT ogco 
		            FROM PraticaTributo prtr
						 INNER JOIN prtr.oggettiPratica ogpr
					     INNER JOIN ogpr.oggettiContribuente ogco
				   WHERE
				       prtr.id = :pIdPratica					  
				   	   AND ogco.tipoRapporto in ('C')
		"""

        return (PraticaTributo.executeQuery(query, [pIdPratica: idPratica]).size() > 0)
    }

    def eliminabile(def pratica) {
        try {
            Sql sql = new Sql(dataSource)
            sql.call('{call PRATICHE_TRIBUTO_PD(?)}', [pratica.id])

            return ''

        } catch (Exception e) {
            e.printStackTrace()
            return e.message.substring('ORA-20006: '.length(), e.message.indexOf('\n'))
        }
    }

    String eliminaOgCo(def ogCoDaEliminare) {

        OggettoContribuente ogco = ogCoDaEliminare instanceof OggettoContribuenteDTO ? ogCoDaEliminare.getDomainObject() : ogCoDaEliminare

        String sqlOgPrRifD = """
								SELECT ogpr
								FROM OggettoPratica ogpr
								WHERE ogpr.oggettoPraticaRif.id = :pIdOgPrRif OR
								 	  ogpr.oggettoPraticaRifAp.id = :pIdOgPrRifAp
							"""

        String sqlOgPrRifC = """
								SELECT ogpr
								FROM OggettoPratica ogpr
								INNER JOIN ogpr.oggettiContribuente ogco
								WHERE (ogpr.oggettoPraticaRif.id = :pIdOgPrRif OR
								 	  ogpr.oggettoPraticaRifAp.id = :pIdOgPrRifAp) AND
									  ogco.contribuente.codFiscale = :pCodFiscale
							"""

        PraticaTributo p = ogco.oggettoPratica.pratica

        try {
            // Se il tipo di rapporto è C si elimina solo la OGCO
            if (ogco.tipoRapporto == 'C') {

                // Se la ogpr non è ogpr_rif o ogpr_rif_ap si può eliminare
                if (OggettoPratica.executeQuery(sqlOgPrRifC, [pIdOgPrRif  : ogco.oggettoPratica.id,
                                                              pIdOgPrRifAp: ogco.oggettoPratica.id,
                                                              pCodFiscale : ogco.contribuente.codFiscale]).isEmpty()) {

                    // Si eliminano le anomalie associate
                    gestioneAnomalieService.eliminaAnomaliePratica(ogco)

                    ogco.delete(failOnError: true, flush: true)

                    // Se per lo stesso CF non è presente nessun altro record in OGCO,
                    // per OGPR della stessa pratica, si devono eliminare i record
                    // della RAPPORTI_TRIBUTO relativi alla pratica con CF e tipo rapporto C
                    if (eliminaRapportiTributo(p.id, ogco.contribuente.codFiscale)) {
                        def result = RapportoTributo.createCriteria().list {
                            eq('tipoRapporto', 'C')
                            eq('pratica.id', p.id)
                            eq('contribuente', ogco.contribuente)
                        }
                        result.each { it.delete(failOnError: true, flush: true) }
                    }
                } else {
                    return "Impossibile eliminare l'oggetto.\nEsistono pratiche successive."
                }

            } else if (ogco.tipoRapporto == 'D') {

                OggettoPratica ogpr = OggettoPratica.get(ogco.oggettoPratica.id)

                // Si può eliminare solo se non esistono contitolari
                if (ogpr.oggettiContribuente.findAll { it.tipoRapporto == 'C' }.isEmpty()) {
                    // Se la ogpr non è ogpr_rif o ogpr_rif_ap si può eliminare
                    if (OggettoPratica.executeQuery(sqlOgPrRifD, [pIdOgPrRif: ogco.oggettoPratica.id, pIdOgPrRifAp: ogco.oggettoPratica.id]).isEmpty()) {

                        // Si eliminano le anomalie associate
                        gestioneAnomalieService.eliminaAnomaliePratica(ogco)

                        ogpr.delete(failOnError: true, flush: true) //senza questo la delete non viene lanciata

                        p.save(failOnError: true)

                    } else {
                        return "Impossibile eliminare l'oggetto.\nEsistono pratiche successive."
                    }
                } else {
                    // Esiste un contitolare, non si può eliminare la OGCO
                    return "Impossibile eliminare l'oggetto.\nEsistono dei contitolari"
                }
            }
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                return e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20006")) {
                return e.cause.cause.message.substring('ORA-20006: '.length(), e.cause.cause.message.indexOf('\n'))
            } else {
                throw e
            }
        }

        return null
    }

    String eliminaOgCoTarsu(def ogCoDaEliminare) {
        try {

            Sql sql = new Sql(dataSource)
            sql.call('{call oggetti_pratica_pd(?)}', [ogCoDaEliminare.oggettoPratica.id])

            OggettoPratica ogpr = OggettoPratica.get(ogCoDaEliminare.oggettoPratica.id)
            ogpr?.delete(flush: true)
        } catch (Exception e) {
            if (e?.message?.startsWith("ORA-20999")) {
                return e.message.substring('ORA-20999: '.length(), e.message.indexOf('\n'))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20006")) {
                return e.cause.cause.message.substring('ORA-20006: '.length(), e.cause.cause.message.indexOf('\n'))
            } else if (e?.cause?.cause?.message?.startsWith("ORA-20008")) {
                return e.cause.cause.message.substring('ORA-20008: '.length(), e.cause.cause.message.indexOf('\n'))
            } else {
                throw e
            }
        }

    }

    private boolean eliminaRapportiTributo(Long idPratica, String codFiscale) {
        // Se per lo stesso CF non è presente nessun altro record in OGCO,
        // per OGPR della stessa pratica, si devono eliminare i record
        // della RAPPORTI_TRIBUTO relativi alla pratica con CF e tipo rapporto C
        String query = """
                    SELECT ogco 
		            FROM PraticaTributo prtr
						 INNER JOIN prtr.oggettiPratica ogpr
					     INNER JOIN ogpr.oggettiContribuente ogco
				   WHERE
				       prtr.id = :pIdPratica
					   AND ogco.contribuente.codFiscale = :pCodFiscale
				   	   AND ogco.tipoRapporto in ('C')
		"""

        return (PraticaTributo.executeQuery(query, [pIdPratica: idPratica, pCodFiscale: codFiscale]).size() == 0)
    }

    //eliminando ogpr elimina anche tutti gli oggetti figli (es. gli ogco)
    def eliminaOgpr(OggettoPraticaDTO ogprDaEliminare) {
        PraticaTributo p = ogprDaEliminare.pratica.getDomainObject()
        OggettoPratica ogpr = ogprDaEliminare.getDomainObject()
        ogpr.delete(failOnError: true, flush: true) //senza questo la delete non viene lanciata
        p.removeFromOggettiPratica(ogpr)
        p.save(failOnError: true)
    }

    @NotTransactional
    def contitolariOggetto(Long idOggPratica) {
        String query = """
                    SELECT ogco 
		            FROM OggettoContribuente ogco
						  INNER JOIN FETCH ogco.contribuente cont
						  INNER JOIN FETCH cont.soggetto sogg
						  INNER JOIN FETCH ogco.oggettoPratica ogpr
						  INNER JOIN FETCH ogpr.oggetto ogg
						  LEFT JOIN FETCH ogg.archivioVie
				   WHERE
				       ogpr.id = :idOggPratica
				   AND ogco.tipoRapporto in ('C')
		"""
        def lista = OggettoContribuente.executeQuery(query, [idOggPratica: idOggPratica]).toDTO()
    }

    @NotTransactional
    def getOggettiPratica(Long idPratica) {

        def lista = OggettoContribuente.createCriteria().list {
            createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.oggettoPraticaRifAp", "ogprRifAp", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogpr.codiceTributo", "codTri", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogpr.tariffa", "tari", CriteriaSpecification.LEFT_JOIN)
            createAlias("tari.categoria", "cate", CriteriaSpecification.LEFT_JOIN)
            createAlias("ogg.archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)

            eq("prtr.id", idPratica)

            order("ogpr.numOrdine", "asc")
            order("ogpr.oggetto.id", "asc")
            order("dataDecorrenza", "asc")
        }.toDTO(['oggettoPratica',
                 'oggettoPratica.tariffa',
                 'oggettoPratica.categoria',
                 'oggettoPratica.categoriaCatasto',
                 'oggettoPratica.oggetto.categoriaCatasto',
                 'oggettoPratica.oggetto.tipoOggetto',
                 'oggettoPratica.tipoOggetto',
                 'oggettoPratica.tipoOccupazione',
                 'contribuente.soggetto'])

        if (lista.empty) {
            return lista
        }

        def filter = [codFiscale   : lista.first().contribuente.codFiscale,
                      idOggettoList: lista.collect { it.oggettoPratica.oggetto.id }]
        List codiciRfid = getCodiciRfid(filter)
        if (codiciRfid.empty) {
            return lista
        }

        def codiciRfidMap = codiciRfid.collectEntries { [(it.oggetto.id): it] }
        lista.each {
            CodiceRfidDTO codiceRfid = codiciRfidMap[it.oggettoPratica.oggetto.id]
            if (codiceRfid) {
                it.oggettoPratica.oggetto.addToCodiciRfid(codiceRfid)
            }
        }

        return lista
    }

    @NotTransactional
    def getVersamenti(Long idPratica, String tipoPratica, String tipoTributo) {

        def lista = Versamento.createCriteria().list {

            createAlias("fonte", "fonte", CriteriaSpecification.LEFT_JOIN)
            createAlias("pratica", "prt", CriteriaSpecification.INNER_JOIN)

            eq("prt.tipoTributo.id", tipoTributo)
            eq("prt.tipoPratica", tipoPratica)
            eq("prt.id", idPratica)

            order("dataPagamento", "asc")
        }.toDTO()

        return lista
    }

    @NotTransactional
    def getCategorie(Long idCodiceTributo) {

        return Categoria.createCriteria().list { eq("codiceTributo.id", idCodiceTributo) }.toDTO().sort { it.categoria }
    }

    @NotTransactional
    def getTariffe(Long idCategoria, Short anno) {

        def lista = Tariffa.createCriteria().list {
            eq("categoria.id", idCategoria)
            eq("anno", anno)
        }.toDTO(['categoria', 'categoria.codiceTributo'])
    }

    @NotTransactional
    def getPartizioni(Long idOggPratica) {
        def lista = PartizioneOggettoPratica.createCriteria().list {

            eq("oggettoPratica.id", idOggPratica)

            order("tipoArea.id", "asc")
        }.toDTO()
    }

    /**
     * Lista possibili pertinenze per TARI
     * @param filtri
     * @param pageSize
     * @param activePage
     * @param listaFetch
     * @return
     */
    @NotTransactional
    def pertinenzeTARIBandBox(def filtri, int pageSize, int activePage, def listaFetch) {
        PagedResultList lista = OggettoValidita.createCriteria().list(max: pageSize, offset: pageSize * activePage) {
            isNull("oggettoPraticaRifAp")
            eq("contribuente.codFiscale", filtri.codFiscale)
            eq("tipoTributo.tipoTributo", "TARSU")
            ne("oggettoPratica.id", (Long) filtri.oggettoPratica ?: 0)
            lt("dal", java.sql.Date.valueOf(String.valueOf(filtri.anno) + "-12-31"))
            or {
                gt("al", java.sql.Date.valueOf(String.valueOf(filtri.anno) + "-01-01"))
                isNull("al")
            }
        }
        return [lista: lista.toDTO(listaFetch), totale: lista.size()]
    }

    /**
     * Lista possibili pertinenze per IMU e TASI
     * @param filtri
     * @param pageSize
     * @param activePage
     * @param listaFetch
     * @return
     */
    @NotTransactional
    def pertinenzeBandBox(def filtri, int pageSize, int activePage, def listaFetch) {
        listaFetch = listaFetch ?: []
        String query = """
                    SELECT distinct ogco 
		            FROM OggettoContribuente ogco
						  INNER JOIN FETCH ogco.contribuente cont
						  INNER JOIN FETCH ogco.oggettoPratica ogpr
						  INNER JOIN FETCH ogpr.pratica prtr 
						  INNER JOIN FETCH ogpr.oggetto ogge
						  LEFT JOIN FETCH ogge.archivioVie
				   WHERE
				       prtr.tipoTributo.tipoTributo||'' = :tipoTributo
				   AND prtr.tipoPratica in ('A', 'D')
				   AND ogco.contribuente.codFiscale = :codFiscale
				   AND ogpr.tipoOggetto.tipoOggetto = 3
                   AND COALESCE(ogpr.categoriaCatasto.categoriaCatasto,ogge.categoriaCatasto.categoriaCatasto) like 'A%'
				   AND COALESCE(ogco.anno, 0) <= :anno
                   AND (COALESCE(ogco.anno, 0) = :anno
                       OR ogpr.id      = F_MAX_OGPR_CONT_OGGE(ogge.id
                                                         ,:codFiscale
                                                         ,prtr.tipoTributo.tipoTributo
                                                         ,decode(:anno,9999,'%',prtr.tipoPratica)
                                                         ,:anno
                                                         ,'%'
                                                         )    
					  )
                   AND DECODE(ogco.flagPossesso, 'S', ogco.flagPossesso, DECODE(:anno, 9999, 'S', prtr.anno, 'S', null)) = 'S'
                   ORDER BY ogge.id
		"""
        //per il calcolo del totale righe tolgo le tabelle in outer join e le fetch
        String queryTot = """
                    SELECT count(distinct ogco.oggettoPratica)
		            FROM OggettoContribuente ogco
						  INNER JOIN ogco.oggettoPratica ogpr
						  INNER JOIN ogpr.pratica prtr                        
						  INNER JOIN ogpr.oggetto ogge
				   WHERE
				       prtr.tipoTributo.tipoTributo||'' = :tipoTributo
				   AND prtr.tipoPratica in ('A', 'D')
				   AND ogco.contribuente.codFiscale = :codFiscale
				   AND ogpr.tipoOggetto.tipoOggetto = 3
                   AND COALESCE(ogpr.categoriaCatasto.categoriaCatasto,ogge.categoriaCatasto.categoriaCatasto) like 'A%'
				   AND COALESCE(ogco.anno, 0) <= :anno
                   AND (COALESCE(ogco.anno, 0) = :anno
                       OR ogpr.id      = F_MAX_OGPR_CONT_OGGE(ogge.id
                                                         ,:codFiscale
                                                         ,prtr.tipoTributo.tipoTributo
                                                         ,decode(:anno,9999,'%',prtr.tipoPratica)
                                                         ,:anno
                                                         ,'%'
                                                         )    
					  )
                   AND DECODE(ogco.flagPossesso, 'S', ogco.flagPossesso, DECODE(:anno, 9999, 'S', prtr.anno, 'S', null)) = 'S'
		"""

        def lista = OggettoContribuente.executeQuery(query
                , [codFiscale: filtri.codFiscale, anno: filtri.anno, tipoTributo: filtri.tipoTributo]
                , [max: pageSize, offset: pageSize * activePage])
        def totalCount = OggettoContribuente.executeQuery(queryTot
                , [codFiscale: filtri.codFiscale, anno: filtri.anno, tipoTributo: filtri.tipoTributo])[0]

        return [lista: lista.toDTO(), totale: totalCount.intValue()]
    }

    def findPraticaTributoDTOById(def idPraticaTributo) {
        return PraticaTributo.findById(idPraticaTributo).toDTO()
    }

    @NotTransactional
    def anniOgco(def filtri) {
        def elencoAnni = PraticaTributo.createCriteria().list() {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
            eq("tipoTributo.tipoTributo", filtri.tipoTributo)
            isNull("flagAnnullamento")
            'in'("tipoPratica", ["A", "D", "L"])
            if (filtri.codFiscale) {
                eq("ogco.contribuente.codFiscale", filtri.codFiscale)
            }
            order("ogco.anno", "asc")
            projections {
                distinct("ogco.anno")                    // 0
            }
        }

    }

    @NotTransactional
    def functionProssimaPratica(Long idPratica, String codFiscale, String tipoTributo) {

        String r
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)

        sql.call('{? = call f_prossima_pratica(?, ?, ?)}'
                , [Sql.VARCHAR, idPratica, codFiscale, tipoTributo]) { r = it }

        return r
    }

    def getFamiliari(Long pratica) {

        String sql = """
				SELECT FAMILIARI_PRATICA.RAPPORTO_PAR,
				FAMILIARI_PRATICA.NI,
				FAMILIARI_PRATICA.PRATICA,
				SOGGETTI.COD_FISCALE,
				SOGGETTI.COGNOME_NOME,
				SOGGETTI.DATA_NAS,
				SOGGETTI.SESSO,
				SOGGETTI.STATO,
				AD4_COMUNI.DENOMINAZIONE ||
				DECODE(AD4_PROVINCIE.SIGLA,
					   NULL,
					   '',
					   '(' || AD4_PROVINCIE.SIGLA || ')') COMUNE_NAS
		   FROM FAMILIARI_PRATICA, SOGGETTI, AD4_PROVINCIE, AD4_COMUNI
		  WHERE (SOGGETTI.COD_COM_NAS = AD4_COMUNI.COMUNE(+))
			AND (SOGGETTI.COD_PRO_NAS = AD4_COMUNI.PROVINCIA_STATO(+))
			AND (AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA(+))
			AND (FAMILIARI_PRATICA.NI = SOGGETTI.NI)
			AND ((FAMILIARI_PRATICA.PRATICA = :P_PRAT))
		"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('P_PRAT', pratica)

            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.rapportoPar = it['RAPPORTO_PAR']
            record.ni = it['NI']
            record.pratica = it['PRATICA']
            record.codFiscale = it['COD_FISCALE']
            record.cognomeNome = it['COGNOME_NOME']
            record.dataNascita = it['DATA_NAS']
            record.sesso = it['SESSO'] == 'M' ? 'Maschio' : 'Femmina'
            record.stato = it['STATO']
            record.comuneNascita = it['COMUNE_NAS']

            records << record
        }

        return records
    }

    def popolaDaCatastoTasi(def codFiscale, def fonte, def titolo) {

        String r

        Sql sql = new Sql(dataSource)

        sql.call("{? = call F_WEB_POPOLAMENTO_TASI_CATASTO(?, ?, ?)}"
                , [Sql.VARCHAR, codFiscale, fonte, titolo]) {
            r = it
        }

        return r
    }

    def popolaDaCatastoImu(def codFiscale, def anno, def fonte, def storico, def tipoImmobile = 'X') {

        if (!anno) {
            anno = 1992
        }

        String r

        Sql sql = new Sql(dataSource)

        sql.call("{? = call popolamento_imu_catasto.crea_dichiarazioni(?, ?, ?, ?, ?, ?)}"
                , [Sql.VARCHAR, codFiscale, anno, fonte, (storico ? 'S' : 'N'), tipoImmobile, -1]) {
            r = it
        }

        return r
    }

    def popolaDaImu(def codFiscale, def fonte) {

        String r

        Sql sql = new Sql(dataSource)
        sql.call("{? = call F_WEB_POPOLAMENTO_TASI_IMU(?, ?)}"
                , [Sql.VARCHAR, codFiscale, fonte]) {
            r = it
        }

        return r
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

            filtri.each { k, v -> setParameter(k, v)
            }

            if (!wholeList) {
                setFirstResult(paging.offset)
                setMaxResults(paging.max)
            }
            list()
        }
    }

    @NotTransactional
    def calcolaMesi(def mp, def mip, def m1s, boolean fp, def modificato) {

        def fnMIp = { def inMp, def inFp -> return ((inFp ? 13 : 1) - inMp) }
        def fnM1s = { def inMp, def inMIp, def inFp ->
            if (inMIp > 6) {
                return 0
            } else {
                if ((inMIp + inMp - 1) >= 6) {
                    return 6 - inMIp + 1
                } else {
                    return inMp
                }
            }
        }

        if (!(modificato in ['mp', 'mip'])) {
            throw new RuntimeException("calcolaDa deve valere mp o mip")
        }

        def outMp = -1
        def outMIp = -1
        def outM1s = -1

        if (mp == null && fp) {
            outMp = null
            mip = outMIp
            m1s = outM1s
        } else {

            def modificatoMp = modificato == 'mp'
            def modificatoMIp = modificato == 'mip'

            log.info "Calcolo ${modificatoMp ? 'mp' : 'mip'}"
            // Calcolo del mip
            if (modificatoMIp) {

                // solo se Possesso è nullo e 1S nullo al cambio di MIP ricalcoliamo 1S dal MIP
                if (!fp && m1s == null && mip) {
                    outM1s = fnM1s(mp, mip, fp)
                }

                // solo se Possesso ='S' e 1S è nullo al cambio di MIP ricalcoliamo 1S da MP (non da MIP)
                if (fp && m1s == null) {
                    outM1s = fnM1s(mp, fnMIp(mp, fp), fp)
                }
            } else if (modificatoMp) {

                // se si modifica MP con Flag Possesso valorizzato si ricalcola sempre sia MIP per 1S
                if (fp) {
                    outMIp = fnMIp(mp, fp)
                    outM1s = fnM1s(mp, outMIp, fp)
                } else {
                    // se si modifica MP senza flag possesso si valorizzano nulli i MIP e 1S ad esclusione dei MP=12 dove MIP sarà 1 e 1S sarà 6
                    // Se mp == 12
                    if (mp == 12) {
                        outMIp = 1
                        outM1s = 6
                    } else {
                        // Se mp != 12
                        outMIp = null
                        outM1s = null
                    }
                }
            }
        }
        log.info([mp: mp, mip: mip, m1s: outM1s])
        return [mp: outMp, mip: outMIp, m1s: outM1s]
    }


    def calcolaTitoloMesiPossesso(String titolo, Date dataEvento) {
        int mp

        Sql sql = new Sql(dataSource)
        sql.call("{? = call F_TITOLO_MESI_POSSESSO(?, ?)}"
                , [Sql.NUMERIC, titolo, new java.sql.Date(dataEvento.getTime())]) {
            mp = it
        }

        return mp
    }

    def calcolaTitoloDaMesiPossesso(def titolo, def dataEvento) {
        int mpi

        Sql sql = new Sql(dataSource)
        sql.call("{? = call F_TITOLO_DA_MESE_POSSESSO(?, ?)}"
                , [Sql.NUMERIC, titolo, new java.sql.Date(dataEvento.getTime())]) {
            mpi = it
        }

        return mpi
    }

    def calcolaTitoloMesiPossesso1Sem(def titolo, def dataEvento) {
        int mp1Sem

        Sql sql = new Sql(dataSource)
        sql.call("{? = call F_TITOLO_MESI_POSSESSO_1SEM(?, ?)}"
                , [Sql.NUMERIC, titolo, new java.sql.Date(dataEvento.getTime())]) {
            mp1Sem = it
        }

        return mp1Sem
    }

    def getDenunceTariCessate(String codFiscale, Long idPratica, String tipoTributo) {
        def sql = """
            select 
                   to_number(lpad(prtr.anno, 4, '0') || lpad(ogpr.TRIBUTO, 4, '0') || lpad(ogpr.CATEGORIA, 4, '0') || lpad(ogpr.TIPO_TARIFFA, 2, '0')) tariffa,
                   ogpr.oggetto,
                   ogpr.tributo,
                   ogpr.categoria,
                   ogpr.tipo_tariffa,
                   ogpr.consistenza,
                   ogpr.larghezza,
                   ogpr.profondita,
                   ogpr.consistenza_reale,
                   ogpr.quantita,
                   ogpr.data_concessione,
                   ogpr.num_concessione,
                   ogpr.indirizzo_occ,
                   ogpr.da_chilometro,
                   ogpr.a_chilometro,
                   ogpr.lato,
                   ogpr.cod_pro_occ,
                   ogpr.cod_com_occ,
                   ogpr.tipo_occupazione,
                   ogpr.assenza_estremi_catasto,
                   ad4_comuni.denominazione des_occ,
                   nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) tipo_oggetto,
                   ogge.cod_via,
                   ogge.num_civ,
                   ogge.suffisso,
                   ogge.sezione,
                   ogge.foglio,
                   ogge.numero,
                   ogge.subalterno,
                   ogge.zona,
                   ogge.partita,
                   decode(ogge.cod_via, null, ogge.indirizzo_localita, arvi.denom_uff) indirizzo_ogg,
                   decode(ogge.cod_via,
                          null,
                          ogge.indirizzo_localita,
                          arvi.denom_uff || ', ' || ogge.num_civ ||
                          decode(suffisso, null, '', '/' || suffisso)) indirizzo,
                   ogge.indirizzo_localita,
                   ogpr.oggetto_pratica,
                   ogco.perc_possesso,
                   nvl(ogpr.oggetto_pratica_rif, ogpr.oggetto_pratica) ogpr_rif,
                   prtr.tipo_pratica,
                   prtr.tipo_evento,
                   ogpr.titolo_occupazione,
                   ogpr.natura_occupazione,
                   ogpr.destinazione_uso,
                   ogpr.numero_familiari,
                   ogco.flag_ab_principale,
                   ogva.al data_cessazione
              from oggetti_pratica      ogpr,
                   oggetti              ogge,
                   archivio_vie         arvi,
                   oggetti_contribuente ogco,
                   pratiche_tributo     prtr,
                   oggetti_validita     ogva,
                   ad4_comuni
             where ogge.cod_via = arvi.cod_via(+)
               and ogpr.oggetto = ogge.oggetto
               and ogpr.cod_pro_occ = ad4_comuni.provincia_stato(+)
               and ogpr.cod_com_occ = ad4_comuni.comune(+)
               and ogpr.pratica = prtr.pratica
               and ogco.oggetto_pratica = ogpr.oggetto_pratica
               and ogco.cod_fiscale = :pCodFis
               and prtr.tipo_tributo = :pTipoTrib
               and decode(prtr.tipo_pratica, 'A', nvl(prtr.flag_denuncia, ' '), 'S') = 'S'
               and prtr.tipo_pratica <> 'C'
               and prtr.tipo_evento <> 'C'
               and ogva.cod_fiscale = ogco.cod_fiscale
               and ogva.oggetto_pratica = ogco.oggetto_pratica
               and ogva.al =
                   (select max(nvl(ogva2.al, to_date('31122999', 'ddmmyyyy')))
                      from oggetti_validita ogva2
                     where ogva2.cod_fiscale = :pCodFis
                       and ogva2.tipo_tributo = :pTipoTrib
                       and ogva2.oggetto = ogva.oggetto
                       and ogva2.tipo_pratica <> 'C'
                       and ogva2.tipo_evento <> 'C')
               and f_esiste_oggetto_in_prat(ogge.oggetto, :pPratica, :pTipoTrib) = 'N'
             order by ogpr.oggetto desc,
                      nvl(ogco.data_decorrenza, to_date('01011900', 'ddmmyyyy')) desc,
                      nvl(prtr.data, to_date('01011900', 'ddmmyyyy')) desc,
                      prtr.pratica desc,
                      ogpr.oggetto_pratica desc
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setLong('pPratica', idPratica)
            setString('pCodFis', codFiscale)
            setString('pTipoTrib', tipoTributo)

            list()
        }

        return results
    }

    def getLocaliAreeVariazioneCessazione(String codFiscale, Long idPratica, String tipoTributo, TipoEventoDenuncia te = null) {

        def tipoEvento = PraticaTributo.get(idPratica)?.tipoEvento ?: te

        if (tipoEvento == null) {
            throw new RuntimeException("Indicare l'id della pratica o il tipo evento")
        }

        def whereCessazioni = """
                and ogva.cod_fiscale = ogco.cod_fiscale
               and ogva.oggetto_pratica = ogco.oggetto_pratica
               and trunc(sysdate) between
               nvl(ogva.dal, to_date('01011900', 'ddmmyyyy')) and
               nvl(ogva.al, to_date('31122999', 'ddmmyyyy'))
               """

        def sql = """
            select ogpr.oggetto_pratica,
                   to_number(lpad(prtr.anno, 4, '0') || lpad(ogpr.TRIBUTO, 4, '0') || lpad(ogpr.CATEGORIA, 4, '0') || lpad(ogpr.TIPO_TARIFFA, 2, '0')) tariffa,
                   ogpr.oggetto,
                   ogpr.tributo,
                   ogpr.categoria,
                   ogpr.tipo_tariffa,
                   ogpr.consistenza,
                   ogpr.larghezza,
                   ogpr.profondita,
                   ogpr.consistenza_reale,
                   ogpr.quantita,
                   ogpr.data_concessione,
                   ogpr.num_concessione,
                   ogpr.indirizzo_occ,
                   ogpr.da_chilometro,
                   ogpr.a_chilometro,
                   ogpr.lato,
                   ogpr.cod_pro_occ,
                   ogpr.cod_com_occ,
                   ad4_comuni.denominazione des_occ,
                   nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) tipo_oggetto,
                   ogge.cod_via,
                   ogge.num_civ,
                   ogge.suffisso,
                   ogge.sezione,
                   ogge.foglio,
                   ogge.numero,
                   ogge.subalterno,
                   ogge.zona,
                   ogge.partita,
                   decode(ogge.cod_via, null, ogge.indirizzo_localita, arvi.denom_uff) indirizzo_ogg,
                   decode(ogge.cod_via,
                          null,
                          ogge.indirizzo_localita,
                          arvi.denom_uff || ', ' || ogge.num_civ ||
                          decode(suffisso, null, '', '/' || suffisso)) indirizzo,
                   ogge.indirizzo_localita,
                   ogpr.oggetto_pratica,
                   ogco.perc_possesso,
                   ogco.flag_punto_raccolta,
                   nvl(ogpr.oggetto_pratica_rif, ogpr.oggetto_pratica) ogpr_rif,
                   prtr.tipo_pratica,
                   prtr.tipo_evento,
                   ogpr.titolo_occupazione,
                   ogpr.natura_occupazione,
                   ogpr.destinazione_uso,
                   ogpr.numero_familiari,
                   ogco.flag_ab_principale,
                   ogco.data_decorrenza,
                   ogco.inizio_occupazione,
                   ogpr.FLAG_DATI_METRICI,
                   ogpr.PERC_RIDUZIONE_SUP
              from oggetti_pratica      ogpr,
                   oggetti              ogge,
                   archivio_vie         arvi,
                   rapporti_tributo     ratr,
                   oggetti_contribuente ogco,
                   pratiche_tributo     prtr,
                   ${tipoEvento == TipoEventoDenuncia.C ? 'oggetti_validita     ogva,' : ''}
                   ad4_comuni
             where (ogge.cod_via = arvi.cod_via(+))
               and (ogpr.oggetto = ogge.oggetto)
               and (ratr.cod_fiscale = ogco.cod_fiscale)
               and (ogpr.cod_pro_occ = ad4_comuni.provincia_stato(+))
               and (ogpr.cod_com_occ = ad4_comuni.comune(+))
               and (prtr.pratica = ratr.pratica)
               and (ogpr.pratica = prtr.pratica)
               and (ogco.oggetto_pratica = ogpr.oggetto_pratica)
               and (ogco.cod_fiscale = :p_cf)
               and (prtr.tipo_tributo || '' = :p_tipo_trib)
               and (decode(prtr.tipo_pratica, 'A', nvl(prtr.flag_denuncia, ' '), 'S') = 'S')
               and (prtr.tipo_pratica <> 'C')
               and (prtr.tipo_evento <> 'C')
               and (ogco.data_cessazione is null)
               and (prtr.pratica <> :p_prat)
               ${tipoEvento == TipoEventoDenuncia.C ? whereCessazioni : ''}

               and not exists
             (select 'x'
                      from pratiche_tributo prtr_sub, oggetti_pratica ogpr_sub
                     where prtr_sub.pratica = ogpr_sub.pratica
                       and prtr_sub.tipo_evento = 'C'
                       and prtr_sub.flag_annullamento is null
                       and ogpr_sub.oggetto_pratica_rif =
                           nvl(ogpr.oggetto_pratica_rif, ogpr.oggetto_pratica))
             order by ogpr.oggetto desc,
                      nvl(ogco.data_decorrenza, to_date('01011900', 'ddmmyyyy')) desc,
                      nvl(prtr.data, to_date('01011900', 'ddmmyyyy')) desc,
                      prtr.pratica desc,
                      ogpr.oggetto_pratica desc
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setLong('p_prat', idPratica)
            setString('p_cf', codFiscale)
            setString('p_tipo_trib', tipoTributo)

            list()
        }

        return results
    }

    def esistonoOggettiDaVariareCessare(String codFiscale) {
        def sql = """
            select count(*) as numero_oggetti
              from OGGETTI_PRATICA,   
                   OGGETTI,   
                   RAPPORTI_TRIBUTO,   
                   OGGETTI_CONTRIBUENTE,   
                   PRATICHE_TRIBUTO  
             where oggetti_pratica.oggetto = oggetti.oggetto 
               and oggetti_pratica.pratica = pratiche_tributo.pratica 
               and pratiche_tributo.pratica = rapporti_tributo.pratica 
               and oggetti_contribuente.oggetto_pratica = oggetti_pratica.oggetto_pratica 
               and rapporti_tributo.cod_fiscale = :p_codfis 
               and pratiche_tributo.tipo_tributo = 'TARSU' 
               and pratiche_tributo.tipo_evento <> 'C' 
               and pratiche_tributo.flag_annullamento is null
               and oggetti_contribuente.data_cessazione is NULL 
               and not exists (select 'x' 
                                  from PRATICHE_TRIBUTO PRTR,
                                       OGGETTI_PRATICA OGPR        
                                 where prtr.pratica = ogpr.pratica 
                                   and prtr.tipo_evento = 'C' 
                                   and prtr.flag_annullamento is null
                                   and ogpr.oggetto_pratica_rif = nvl(oggetti_pratica.oggetto_pratica_rif,oggetti_pratica.oggetto_pratica))
        """
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setString('p_codfis', codFiscale)

            list()
        }

        return results[0].numeroOggetti > 0
    }

    def fCheckRipristinoAnno(Long idPratica) {
        String r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_CHECK_RIPRISTINO_ANN(?)}'
                , [Sql.VARCHAR, idPratica]) {
            r = it
        }
        return r
    }

    def fCheckOgprARuolo(Long idPratica) {
        String r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_CHECK_OGPR_A_RUOLO(?)}'
                , [Sql.VARCHAR, idPratica]) {
            r = it
        }
        return r
    }

    def fOgPrInviato(Long idOgPr) {
        String r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_ogpr_inviato(?)}'
                , [Sql.VARCHAR, idOgPr]) {
            r = it
        }
        return r == 'S'
    }

    def fPraticaAnnullabile(Long idPratica) {
        String r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_pratica_annullabile(?)}'
                , [Sql.VARCHAR, idPratica]) {
            r = it
        }

        if (!r) {
            return null
        } else {
            return [tipoErrore: r?.substring(0, 3), messaggio: r?.substring(3)]
        }
    }

    def fCheckPeriodiOggetto(String codFiscale, Long idOggetto,
                             String tipoTributo, String tipoPratica, String tipoEvento,
                             Short anno,
                             Date dataDal, Date dataAl,
                             Long idOggettoPratica,
                             Date oldDataDal, Date oldDataAl,
                             String insVar) {
        String paramCodFiscale = codFiscale ? "'$codFiscale'" : null
        String paramTipoTributo = tipoTributo ? "'$tipoTributo'" : null
        String paramTipoPratica = tipoPratica ? "'$tipoPratica'" : null
        String paramTipoEvento = tipoEvento ? "'$tipoEvento'" : null
        String paramInsVar = insVar ? "'$insVar'" : null
        String paramDataDal = dataDal ? "to_date('${new java.sql.Date(dataDal.time)}','YYYY-MM-DD')" : null
        String paramDataAl = dataAl ? "to_date('${new java.sql.Date(dataAl.time)}','YYYY-MM-DD')" : null
        String paramOldDataDal = oldDataDal ? "to_date('${new java.sql.Date(oldDataDal.time)}','YYYY-MM-DD')" : null
        String paramOldDataAl = oldDataAl ? "to_date('${new java.sql.Date(oldDataAl.time)}','YYYY-MM-DD')" : null

        def periodiOggettoCollection = commonService.refCursorToCollection("F_CHECK_PERIODI_OGGETTO($paramCodFiscale,$idOggetto,$paramTipoTributo,$paramTipoPratica,$paramTipoEvento,$anno,$paramDataDal,$paramDataAl,$idOggettoPratica,$paramOldDataDal,$paramOldDataAl,$paramInsVar)")
        String errore = periodiOggettoCollection.find { it.ERRORE != null }?.ERRORE
        if (errore) {
            throw new Exception(errore)
        }

        return periodiOggettoCollection
    }

    def fGetDecorrenzaCessazione(Date dataInizioOccupazione, Integer flagGiorno) {

        if (!dataInizioOccupazione) {
            throw new RuntimeException("Indicare [dataInizioOccupazione]")
        }

        if (flagGiorno == null) {
            throw new RuntimeException("Indicare [flagGiorno]")
        }

        Date r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_get_decorrenza_cessazione(?, ?)}'
                , [Sql.DATE, new java.sql.Date(dataInizioOccupazione.getTime()), flagGiorno]) {
            r = it
        }

        return r
    }

    def fCessazioniRuolo(String codFiscale, Long idOgPr, Short anno) {
        Float r = null
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_CESSAZIONI_RUOLO(?, ?, ?)}'
                , [Sql.DECIMAL, codFiscale, idOgPr, anno]) {
            r = it
        }

        def numeroSgravi = (r / 10000).trunc()
        r -= numeroSgravi * 10000
        def mesi = (r / 100).trunc()
        r -= mesi * 100
        def mesiRuolo = r

        return (numeroSgravi > 0 || (mesi > 0 && mesi == mesiRuolo))

    }

    def getScadenza(String tipoTributo, int anno, String tipoScadenza) {
        return Scadenza.findByTipoTributoAndAnnoAndTipoScadenza(TipoTributo.get(tipoTributo),
                anno,
                tipoScadenza)
    }

    def denunciaTarsuEliminabile(def praticaId) {
        // non esistono oggetti_pratica relativi alla denuncia inseriti in un ruolo inviato a consorzio

        // Esitono Oggetti pratica inviati a consorzio
        def sql = """
            select count(1) inviato_consorzio
            from oggetti_pratica ogpr
                where f_ogpr_inviato(ogpr.oggetto_pratica) = 'S'
                    and ogpr.pratica = :p_pratica
        """

        def inviatiAConsorzio = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setLong('p_pratica', praticaId)

            list()
        }

        if (inviatiAConsorzio[0].inviatoConsorzio > 0) {
            return "Non e' possibile eliminare la pratica. Esistono oggetti_pratica con ruoli inviati al consorzio"
        }

        // Non esistono sgravi inseriti in ruoli inviati a consorzio per oggetti collegati a quelli della denuncia
        PraticaTributo pratica = PraticaTributo.get(praticaId)
        for (def ogpr in pratica.oggettiPratica) {
            def anno = pratica.tipoEvento != TipoEventoDenuncia.C ? ogpr.oggettiContribuente[0].dataDecorrenza[Calendar.YEAR] : ogpr.oggettiContribuente[0].dataCessazione[Calendar.YEAR]
            if (esistonoSgraviInRuoliConsorzio(praticaId, ogpr.id, anno)) {
                return "Non e' possibile eliminare la pratica. Esistono sgravi su ruoli inviati al consorzio"
            }
        }

        // Esecuzione pratiche_tributo_pd
        def eliminabile = eliminabile(pratica)
        if (eliminabile != '') {
            return eliminabile
        }

        return null

    }

    def getInfoTariffe(String tipoTributo, Long tributo, Short categoria, BigDecimal tipoTariffa) {
        def sql = """
            select distinct tariffe.tariffa,
                codici_tributo.tributo || ' - ' ||
                codici_tributo.descrizione trib_desc,
                categorie.categoria || ' - ' || categorie.descrizione cate_desc,
                tariffe.tipo_tariffa || ' - ' || tariffe.descrizione tari_desc,
                tariffe.anno,
                tariffe.tipo_tariffa || ' - ' || tariffe.descrizione tari_desc2
              from tariffe, codici_tributo, categorie
             where tariffe.tributo = codici_tributo.tributo
               and categorie.tributo = tariffe.tributo
               and categorie.categoria = tariffe.categoria
               and tariffe.tributo = :p_trib
               and tariffe.categoria = :p_cate
               and tariffe.tipo_tariffa = :p_tipo_tari
               and codici_tributo.tipo_tributo = :p_tipo_trib
             order by tariffe.anno desc, tariffe.tariffa asc, 4 asc
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setString('p_tipo_trib', tipoTributo)
            setLong('p_trib', tributo)
            setShort('p_cate', categoria)
            setBigDecimal('p_tipo_tari', tipoTariffa)

            list()
        }

        return results

    }

    def dataMaxRuoloTarsu() {
        def sql = """
            select max(ruoli.data_emissione) max_emis_ruolo
              from ruoli
             where ruoli.tipo_tributo = 'TARSU'
        """
        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        def maxEmisRuolo = results[0].maxEmisRuolo

        sql = """
            select max(ruoli.data_emissione) max_invio_ruolo
              from ruoli
             where ruoli.tipo_tributo = 'TARSU'
               and ruoli.invio_consorzio is not null
        """

        results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        def maxInvioRuolo = results[0].maxInvioRuolo

        return [maxEmisRuolo: maxEmisRuolo, maxInvioRuolo: maxInvioRuolo]
    }

    def oggettiImportoCalcolatoTarsu(String codFiscale, Long idPratica) {

        def sql = """
             select sum(oggetti_imposta.imposta) imposta,
                count(oggetti_pratica.oggetto) num_oggetti
               from oggetti_contribuente, oggetti_imposta, oggetti_pratica
              where oggetti_contribuente.cod_fiscale = oggetti_imposta.cod_fiscale
                and oggetti_contribuente.anno = oggetti_imposta.anno
                and oggetti_contribuente.oggetto_pratica =
                    oggetti_imposta.oggetto_pratica
                and oggetti_pratica.oggetto_pratica =
                    oggetti_contribuente.oggetto_pratica
                and oggetti_pratica.tipo_occupazione = 'T'
                and oggetti_contribuente.cod_fiscale = :pCodFiscale
                and oggetti_pratica.pratica = :pIdPratica having
              count(oggetti_pratica.oggetto) > 0
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setString('pCodFiscale', codFiscale)
            setLong('pIdPratica', idPratica)

            list()
        }


        return results.empty ? null : [imposta: results[0].imposta, numOggetti: results[0].numOggetti]

    }

    private def esistonoSgraviInRuoliConsorzio(Long ogprId, Long ogprRifId, Integer anno) {
        def sql = """
            select count(1) sgravi
              from ruoli_contribuente ruco, ruoli, sgravi, oggetti_imposta ogim
             where ruoli.ruolo = ruco.ruolo
               and ruco.oggetto_imposta = ogim.oggetto_imposta
               and ogim.oggetto_pratica =
                   (select max(ogprt.oggetto_pratica)
                      from (select ogpr2.oggetto_pratica
                              from oggetti_pratica ogpr2, pratiche_tributo prtr2
                             where ogpr2.oggetto_pratica_rif = :nogpr_rif
                               and ogpr2.pratica = prtr2.pratica
                               and ogpr2.oggetto_pratica <> :nogpr
                            union
                            select ogpr3.oggetto_pratica
                              from oggetti_pratica ogpr3, pratiche_tributo prtr3
                             where ogpr3.oggetto_pratica = :nogpr_rif
                               and ogpr3.pratica = prtr3.pratica
                               and ogpr3.oggetto_pratica <> :nogpr) ogprt)
               and sgravi.ruolo = ruoli.ruolo
               and sgravi.cod_fiscale = ruco.cod_fiscale
               and ruoli.anno_ruolo >= :nanno_ces
               and (nvl(ruoli.tipo_emissione, 'X') != 'T' or
                   nvl(ruoli.tipo_emissione, 'X') = 'T' and
                   ruoli.ruolo =
                   f_get_ultimo_ruolo(ruco.cod_fiscale,
                                       ruoli.anno_ruolo,
                                       ruoli.tipo_tributo,
                                       ruoli.tipo_emissione))
        """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setLong('nogpr', ogprId)
            setLong('nogpr_rif', ogprRifId)
            setInteger('nanno_ces', anno)

            list()
        }

        return results[0].sgravi > 0

    }

    def getProgrDocumenti(String ambito, filter = [:]) {

        if (ambito != DOCFCA && ambito != DENUNCE) {
            throw new Exception("Ambito non consentito")
        }

        def customQuery = ""

        def commonQuery = """
            SELECT DOCUMENTO_ID,
                DOCUMENTO_ID || ' - ' || NOME_DOCUMENTO || ' del ' ||
                TO_CHAR(DATA_VARIAZIONE, 'dd/mm/yyyy') as DESCRIZIONE
            FROM DOCUMENTI_CARICATI DOCA
            WHERE DOCA.STATO = 2   """

        if (ambito == DOCFCA) {
            customQuery += " AND DOCA.TITOLO_DOCUMENTO IN (10,11,22)"
        }

        if (ambito == DENUNCE) {
            customQuery = """
                AND EXISTS (SELECT 'x' FROM pratiche_tributo prtr
                WHERE prtr.DOCUMENTO_ID = DOCA.DOCUMENTO_ID
                and prtr.tipo_tributo =:pTipoTributo )
            """
        }

        String orderby = "  ORDER BY 1 DESC"

        def query = """
        $commonQuery
        $customQuery
        $orderby
        """

        def result = sessionFactory.currentSession.createSQLQuery(query).with {

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            if (ambito == DENUNCE) {
                setString("pTipoTributo", filter.tipoTributo)
            }

            list()
        }
    }

    def variazioneAutomatiche(def parametri) {

        def report = [result : 0,
                      message: null]

        Integer codVia = (parametri.codVia != null) ? parametri.codVia : -1

        try {
            Sql sql = new Sql(dataSource)
            def statement = """
						DECLARE
						BEGIN
							? := F_DENUNCE_V_AUTOMATICHE(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
						END;
					"""
            def params = [Sql.NUMERIC,
                          parametri.tipoTributo.tipoTributo,
                          parametri.anno as short,
                          codVia,
                          new java.sql.Date(parametri.dataDenuncia.getTime()),
                          new java.sql.Date(parametri.dataDecorrenza.getTime()),
                          parametri.codiceTributo.id,
                          parametri.categoriaDa.categoria,
                          parametri.categoriaA.categoria,
                          parametri.tariffaDa?.tipoTariffa,
                          parametri.tariffaA?.tipoTariffa,
                          parametri.codFiscale?.toUpperCase() ?: null,
                          parametri.utente.id,
                          Sql.VARCHAR]
            if (parametri.codiceElaborazione?.trim()) {
                tr4AfcElaborazioneService.saveDatabaseCall(parametri.codiceElaborazione, statement, params)
            }
            sql.call(statement,
                    params,
                    { p_result, p_messaggio ->

                        report.message = p_messaggio
                        report.result = p_result
                    })
        } catch (Exception e) {
            e.printStackTrace()
            commonService.serviceException(e)

            report.message = e.message
            report.result = 2
        }

        return report
    }

    def getListaCostiStorici(def oggPraticaId) {

        return CostoStorico.createCriteria().list {
            eq("oggettoPratica.id", oggPraticaId)
            order("anno", "asc")
        }
    }

    def existCostoStorico(def anno, oggPraticaId) {

        def costo = CostoStorico.createCriteria().list {

            eq("oggettoPratica.id", oggPraticaId)
            eq("anno", anno)
        }
    }

    def salvaCostoStorico(def costoStorico) {
        costoStorico.save(failOnError: true, flush: true)
    }

    def eliminaCostoStorico(def costoStorico) {
        costoStorico.delete(failOnError: true, flush: true)
    }

    def documentoNota(def documentoId, def numeroNota) {
        def documento

        Sql sql = new Sql(dataSource)

        sql.call("{? = call F_NOTAI_TO_HTML(?, ?)}"
                , [Sql.CLOB, documentoId, numeroNota]) {
            documento = it?.asciiStream?.text
        }

        return documento
    }

    def utenzeSenzaTariffa(anno, utenze) {
        return utenze.findAll { utenza ->
            def idTariffe = (utenza.tariffa as String).replaceFirst((utenza.tariffa as String)[0..3], (anno as String)) as Long
            def tariffaNonPresente = Tariffa.countById(idTariffe) == 0

            return tariffaNonPresente
        }
    }

    def getContenitori() {
        Contenitore.createCriteria().list {
            order('id', 'asc')
        }.toDTO()
    }

    def getCodiciRfid(def filter) {
        CodiceRfid.createCriteria().list {
            eq('contribuente.codFiscale', filter.codFiscale)
            if (filter.idOggetto) {
                eq('oggetto.id', filter.idOggetto)
            }
            if (filter.idOggettoList) {
                inList('oggetto.id', filter.idOggettoList)
            }
            order('dataConsegna', 'DESC')
        }.toDTO()
    }

    void saveCodiciRfid(def filter, def listaCodiciRfid) {
        def oldListaCodiciRfid = getCodiciRfid(filter)
        oldListaCodiciRfid.each { CodiceRfidDTO oldCodiceRfid ->
            def found = listaCodiciRfid.find { CodiceRfidDTO it -> it.contribuente.codFiscale == oldCodiceRfid.contribuente.codFiscale && it.oggetto.id == oldCodiceRfid.oggetto.id && it.codRfid == oldCodiceRfid.codRfid
            } != null
            if (!found) {
                oldCodiceRfid.toDomain().delete(failOnError: true, flush: true)
            }
        }
        listaCodiciRfid.each {
            it.toDomain().save(failOnError: true, flush: true)
        }
    }

    def sostituzioneRfid(String codFiscale, Long oggettoOld, Long oggettoNew) {

        int moved = 0

        try {
            Oggetto oggetto = Oggetto.get(oggettoNew)
            if (oggetto == null) throw new Exception("Nuovo oggetto non trovato !")

            List<CodiceRfid> codiciRfid = CodiceRfid.createCriteria().list {
                eq('contribuente.codFiscale', codFiscale)
                eq('oggetto.id', oggettoOld)
            }

            codiciRfid.each { rfid ->

                sessionFactory.currentSession.createSQLQuery("UPDATE CODICI_RFID CORF " + "SET CORF.OGGETTO = ? " + "WHERE CORF.OGGETTO = ? AND COD_FISCALE = ? AND CORF.COD_RFID = ?")
                        .setLong(0, oggettoNew)
                        .setLong(1, oggettoOld)
                        .setString(2, codFiscale)
                        .setString(3, rfid.codRfid)
                        .executeUpdate()

                moved++
            }
        } catch (Exception e) {
            commonService.serviceException(e)
        }

        return moved
    }

    def presenzaRavvedimentoOperoso(def denuncia, def ruoloOggettiDenuncia) {
        if (!(denuncia.pratica.tipoEvento in [TipoEventoDenuncia.I, TipoEventoDenuncia.V])) {
            return false
        }

        return PraticaTributo.createCriteria().count {
            createAlias('debitiRavvedimento', 'dera', CriteriaSpecification.INNER_JOIN)
            eq('contribuente.codFiscale', denuncia.pratica.contribuente.codFiscale)
            eq('dera.ruolo', ruoloOggettiDenuncia as Long)
        } > 0
    }

}
