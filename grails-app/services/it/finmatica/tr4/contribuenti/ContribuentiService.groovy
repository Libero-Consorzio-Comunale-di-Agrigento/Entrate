package it.finmatica.tr4.contribuenti

import grails.orm.PagedResultList
import grails.plugins.springsecurity.SpringSecurityService
import grails.transaction.Transactional
import groovy.sql.Sql
import it.finmatica.ad4.dizionari.Ad4Comune
import it.finmatica.tr4.*
import it.finmatica.tr4.anomalie.AnomaliaIci
import it.finmatica.tr4.anomalie.AnomaliaParametro
import it.finmatica.tr4.caricamento.*
import it.finmatica.tr4.commons.*
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.denunce.DenunceService
import it.finmatica.tr4.dto.*
import it.finmatica.tr4.dto.pratiche.DenunciaTarsuDTO
import it.finmatica.tr4.dto.pratiche.PraticaTributoDTO
import it.finmatica.tr4.imposte.ImposteService
import it.finmatica.tr4.oggetti.OggettiService
import it.finmatica.tr4.pratiche.*
import org.apache.commons.lang.StringUtils
import org.apache.log4j.Logger
import org.hibernate.FetchMode
import org.hibernate.criterion.CriteriaSpecification
import org.hibernate.transform.AliasToEntityMapResultTransformer
import org.springframework.transaction.annotation.Propagation
import transform.AliasToEntityCamelCaseMapResultTransformer

import java.math.RoundingMode
import java.text.DecimalFormat
import java.text.SimpleDateFormat

class ContribuentiService {

    private static final Logger log = Logger.getLogger(ContribuentiService.class)

    static transactional = false
    private static final String ALIQUOTA_FORMAT = '#,##0.00'

    def sessionFactory


    def dataSource
    SpringSecurityService springSecurityService
    ImposteService imposteService
    DenunceService denunceService
    OggettiService oggettiService
    CommonService commonService
    LiquidazioniAccertamentiService liquidazioniAccertamentiService
    CompetenzeService competenzeService

    def tipiAmbiente = [
            A: [codice: 'A', descrizione: 'Vani (o locali) aventi funzione principale nella specifica categoria e vani (o locali) accessori a diretto servizio dei principali (ad eccezione delle categorie C1 e C6)'],
            I: [codice: 'I', descrizione: 'Vani (o locali) aventi funzione principale nella specifica categoria (per le sole categorie C1 e C6)'],
            L: [codice: 'L', descrizione: 'Vani (o locali) accessori a diretto servizio dei principali per unità (per le sole categorie C1 e C6)'],
            B: [codice: 'B', descrizione: 'Vani (o locali) accessori a indiretto servizio di quelli identificati nella precedente tipologia A (ovvero 1 per le categorie C1 e C6), qualora comunicanti con gli stessi'],
            C: [codice: 'C', descrizione: 'Vani (o locali) accessori a indiretto servizio di quelli identificati nella precedente tipologia A (ovvero 1 per le categorie C1 e C6), qualora non comunicanti con gli stessi anche attraverso scale interne'],
            D: [codice: 'D', descrizione: 'Balconi, terrazzi e simili comunicanti con i vani o locali di cui al precedente ambiente di tipo A (ovvero  1 per le categorie C1 e C6), anche attraverso scale'],
            E: [codice: 'E', descrizione: 'Balconi, terrazzi e simili non comunicanti con i vani o locali di cui al precedente ambiente di tipo A  ovvero A1 per le categorie C1 e C6), pertinenze esclusive della uiu trattata'],
            F: [codice: 'F', descrizione: 'Aree scoperte o comunque assimilabili, pertinenza esclusiva della uiu trattata '],
            G: [codice: 'G', descrizione: 'Superfici di ambienti non classificabili tra i precedenti casi e non rilevanti ai fini del calcolo della superficie catastale'],
    ]

    /**
     * Ritorna le pratiche di un contribuente
     * @param codiceFiscale
     * @return
     */

    def praticheContribuente(String codiceFiscale, def tipo = "list", List<String> listaTipiTributo = [], List<String> listaTipiPratica = [], def orderPratiche = [:]) {
        List<TipoTributoDTO> tipiTributo = OggettiCache.TIPI_TRIBUTO.valore
        List<TipoStatoDTO> tipiStato = OggettiCache.TIPI_STATO.valore

        def lista = PraticaTributo.createCriteria().list {
            createAlias("rapportiTributo", "ratr", CriteriaSpecification.INNER_JOIN)
            createAlias("ratr.contribuente", "cont", CriteriaSpecification.INNER_JOIN)
            createAlias("cont.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
            createAlias("tipoStato", "tist", CriteriaSpecification.LEFT_JOIN)

            if (tipo == 'exportxls') {
                createAlias("sogg.archivioVie", "avre", CriteriaSpecification.LEFT_JOIN)
                createAlias("sogg.comuneResidenza", "core", CriteriaSpecification.LEFT_JOIN)
                createAlias("core.ad4Comune", "adre", CriteriaSpecification.LEFT_JOIN)
                createAlias("adre.provincia", "prre", CriteriaSpecification.LEFT_JOIN)
                createAlias("adre.stato", "stre", CriteriaSpecification.LEFT_JOIN)
                createAlias("comuneDenunciante", "code", CriteriaSpecification.LEFT_JOIN)
                createAlias("code.ad4Comune", "adco", CriteriaSpecification.LEFT_JOIN)
                createAlias("adco.provincia", "prco", CriteriaSpecification.LEFT_JOIN)
                createAlias("adco.stato", "stco", CriteriaSpecification.LEFT_JOIN)
                createAlias("tipoCarica", "tica", CriteriaSpecification.LEFT_JOIN)
            }

            projections {
                if (tipo in ["list", 'exportxls']) {
                    property("id")                      // 0
                    property("anno")                    // 1
                    property("data")                    // 2
                    property("numero")                  // 3
                    property("tipoTributo.tipoTributo") // 4
                    property("ratr.tipoRapporto")       // 5
                    property("tist.tipoStato")          // 6
                    property("dataNotifica")            // 7
                    property("tipoEvento")              // 8
                    property("tipoPratica")             // 9
                    property("cont.codFiscale")         // 10
                    property("sogg.cognomeNome")        // 11
                    property("flagAnnullamento")        // 12
                    property("importoTotale")           // 13
                    property("tipoAtto")                // 14
                    property("flagDePag")               // 15
                    property("tipoNotifica")            // 16
                    property("tipoViolazione")          // 17

                    if (tipo == 'exportxls') {
                        property("motivo")                    // 18
                        property("note")                    // 19
                        property("denunciante")                // 20
                        property("codFiscaleDen")            // 21
                        property("indirizzoDen")            // 22
                        property("tica.descrizione")        // 23
                        property("adco.denominazione")        // 24
                        property("prco.sigla")                // 25
                        property("stco.sigla")                // 26
                        property("adre.denominazione")        // 27
                        property("prre.sigla")                // 28
                        property("stre.sigla")                // 29
                        property("sogg.denominazioneVia")    // 30
                        property("sogg.numCiv")                // 31
                        property("sogg.suffisso")            // 32
                        property("avre.denomUff")            // 33
                        property("utente")                  // 34
                        property("dataRiferimentoRavvedimento") // 35
                    } else {
                        // L'export per xlsx estrae più campi rispetto a quello per la visualizzazione
                        // nella lista. Nell'ottimizzazione è stato estratto l'utente di modifica solo per
                        // l'export Excel, poiché è necessario anche per la lista si aggiunge n volte
                        // l'estrazione del campo ID per allineare gli indici della mappa restituita.

                        property("id")                    // 18
                        property("id")                    // 19
                        property("id")                // 20
                        property("id")            // 21
                        property("id")            // 22
                        property("id")        // 23
                        property("id")        // 24
                        property("id")                // 25
                        property("id")                // 26
                        property("id")        // 27
                        property("id")                // 28
                        property("id")                // 29
                        property("id")    // 30
                        property("id")                // 31
                        property("id")            // 32
                        property("id")            // 33
                        property("utente")                  // 34
                        property("id") // 35
                    }
                } else if (tipo == "count") {
                    count()
                } else {
                    throw new RuntimeException("Tipo [${tipo}] non supportato.")
                }
            }

            if (!listaTipiTributo.empty) {
                'in'('tipoTributo.tipoTributo', listaTipiTributo)
            } else {
                // Se non è passato almeno un tributo non si restituiscono record
                eq('id', -1L)
            }

            if (!listaTipiPratica.empty) {
                'in'('tipoPratica', listaTipiPratica)
            } else {
                // Se non è passato almeno un tipo pratica non si restituiscono record
                eq('id', -1L)
            }

            eq("cont.codFiscale", codiceFiscale)
            or {
                and {
                    ne("tipoPratica", "K")
                    sqlRestriction("""
                                DECODE({alias}.tipo_pratica, 'A', DECODE({alias}.stato_accertamento, null, COALESCE({alias}.flag_denuncia, 'N')
                                                                                                   , 'D', COALESCE({alias}.flag_denuncia, 'N')
                                                                                                   , 'N')
                                                           , 'N') <> 'S' 
                                        """)
                }
                and {
                    eq("tipoPratica", "A")
                    eq("flagDenuncia", true)
                    ne("ratr.tipoRapporto", "C")
                    or {
                        isNull("tipoStato")
                        eq("tist.tipoStato", "D")
                    }
                }
            }
            or {
                isNull("praticaTributoRif")
                and {
                    isNotNull("praticaTributoRif")
                    eq("tipoPratica", "G")
                }
            }
            orderPratiche.sort { it.value.posizione }.each {
                def field = it.value
                if (field.attivo) {
                    order(field.id, field.verso)
                }
            }
        }

        def utentiCreazionePratiche = [:]
        if (tipo in ['list', 'exportxls'] && !lista.empty) {
            def praticaIds = lista.collect { it[0] }.unique()
            utentiCreazionePratiche = getUtenteCreazionePraticaTributo(praticaIds)
        }

        lista = lista.collect { row ->
            if (tipo in ['list', 'exportxls']) {

                TipoTributoDTO tipoTributo = tipiTributo.find { it.tipoTributo == row[4] }

                String docSuccessivo = denunceService.functionProssimaPratica(row[0], row[10], row[4])

                // Il toLong permette di eliminare la sequenza di 0 iniziali
                String praticaSuccessiva = docSuccessivo?.substring(2, docSuccessivo?.length())?.toLong()
                String eventoSuccessivo = docSuccessivo?.substring(0, 1)

                def utenteCreazione = utentiCreazionePratiche[row[0] as Long]

                if (tipo == 'list') {
                    [id                  : row[0]
                     , anno              : row[1]
                     , data              : row[2]?.format("dd/MM/yyyy")
                     , numero            : row[3]
                     , tipoTributo       : tipoTributo
                     , descrizioneTributo: tipoTributo.getTipoTributoAttuale(row[1])
                     , tipoRapporto      : row[5]
                     , stato             : (row[6]) ? tipiStato.find { it.tipoStato == row[6] }?.descrizione : ""
                     , dataNotifica      : row[7]?.format("dd/MM/yyyy")
                     , dataNotificaDate  : row[7]
                     , tipoEvento        : row[8]
                     , tipoPratica       : row[9]
                     , codFiscale        : row[10]
                     , cognomeNome       : row[11]
                     , flagAnnullamento  : row[12] ? '(ANN)' : ''
                     , praticaSuccessiva : praticaSuccessiva != null ? praticaSuccessiva + ' (' + eventoSuccessivo + ')' : ''
                     , importoTotale     : row[9] in ['L'] ? (row[13] ?: 0) : row[9] in ['A', 'V', 'S'] ? fImportAccLordo(row[0], 'N') : null
                     , tipoAtto          : row[14]?.toDTO()
                     , presenzaVersamenti: false
                     , flagDePag         : row[15] ? row[15] : 'N'
                     , tipoNotifica      : row[16]?.toDTO()
                     , tipoViolazione    : row[17]
                     , utenteModifica    : row[34]
                    ]
                } else {
                    [id                           : row[0]
                     , anno                       : row[1]
                     , data                       : row[2]?.format("dd/MM/yyyy")
                     , numero                     : row[3]
                     , tipoTributo                : tipoTributo
                     , descrizioneTributo         : tipoTributo.getTipoTributoAttuale(row[1])
                     , tipoRapporto               : row[5]
                     , stato                      : (row[6]) ? tipiStato.find { it.tipoStato == row[6] }?.descrizione : ""
                     , dataNotifica               : row[7]?.format("dd/MM/yyyy")
                     , dataNotificaDate           : row[7]
                     , tipoEvento                 : row[8]
                     , tipoPratica                : row[9]
                     , codFiscale                 : row[10]
                     , cognomeNome                : row[11]
                     , flagAnnullamento           : row[12] ? '(ANN)' : ''
                     , praticaSuccessiva          : praticaSuccessiva != null ? praticaSuccessiva + ' (' + eventoSuccessivo + ')' : ''
                     , importoTotale              : row[9] in ['L'] ? (row[13] ?: 0) : row[9] in ['A', 'V', 'S'] ? fImportAccLordo(row[0], 'N') : null
                     , tipoAtto                   : row[14]?.toDTO()
                     , presenzaVersamenti         : false
                     , flagDePag                  : row[15] ? row[15] : 'N'
                     , tipoNotifica               : row[16]?.toDTO()
                     , tipoViolazione             : row[17]
                     ///
                     , motivo                     : row[18]
                     , note                       : row[19]
                     , indirizzoRes               : (row[33] ?: row[30] ?: "") + (row[31] ? ", ${row[31]} " : "") + (row[32] ? "/${row[32]} " : "")
                     , comuneRes                  : row[27]
                     , provinciaRes               : row[28] ?: row[29]
                     , denunciante                : row[20]
                     , codFiscaleDen              : row[21]
                     , indirizzoDen               : row[22]
                     , caricaDen                  : row[23]
                     , comuneDen                  : row[24]
                     , provinciaDen               : row[25] ?: row[26]
                     , utenteCreazione            : utenteCreazione
                     , utenteModifica             : row[34]
                     , dataRiferimentoRavvedimento: row[35]
                    ]
                }
            } else {
                [count: row]
            }
        }

        if (tipo in ['list', 'exportxls']) {

            def tipoViolazione = [
                    ID: 'Infedele Denuncia',
                    OD: 'Omessa Denuncia'
            ]

            def listaVersamenti = [:]
            if (!lista.empty) {
                listaVersamenti = Versamento.executeQuery("select pratica.id, sum(importoVersato), max(dataPagamento), count(pratica.id) from Versamento where pratica.id in :pList group by pratica.id",
                        [pList: lista.collect { it.id }])
                        .collectEntries { [(it[0]): [multi: it[3] > 1, tot: it[1], data: it[2]]] }
            }

            lista.each {
                if (it.tipoPratica in ['A', 'L', 'V', 'S']) {
                    def impAccRid = fImportAccLordo(it.id, 'S')
                    it.presenzaVersamenti = (listaVersamenti[it.id as Long]?.tot ?: 0) > 0 ?: false
                    it.importoVersato = listaVersamenti[it.id as Long]?.tot
                    it.dataPagamento =
                            (listaVersamenti[it.id as Long]?.data ?
                                    (new SimpleDateFormat("dd/MM/yyyy")).format(listaVersamenti[it.id as Long]?.data) : "").toString() + (listaVersamenti[it.id as Long]?.multi ? " <" : "")
                    it.versamentiMultipli = listaVersamenti[it.id as Long]?.multi
                    it.importoRidottoAccertato = it.importoTotale != impAccRid ? impAccRid : null
                }

                it.tipoEventoViolazione = it.tipoViolazione != null ?
                        "${it.tipoEvento} - ${it.tipoViolazione}" : it.tipoEvento
                it.tipoEventoViolazioneTooltip = it.tipoViolazione != null ?
                        "${it.tipoEvento} - ${tipoViolazione[it.tipoViolazione]}" : ''
            }
        }

        return lista
    }

    private def getUtenteCreazionePraticaTributo(List<Long> praticaIds) {
        def query = """            
            select new Map(
                   itpr.pratica.id  as praticaId
                 , itpr.utente      as utenteCreazione)
              from IterPratica itpr
             where itpr.pratica.id in :pList
               and itpr.data = (select min(itprInner.data)
                                  from IterPratica itprInner
                                 where itprInner.pratica = itpr.pratica)
        """
        def queryResult = IterPratica.executeQuery(query, [pList: praticaIds])

        def resultMap = [:]

        queryResult.each { row ->
            resultMap[row.praticaId] = row.utenteCreazione
        }

        return resultMap
    }

    /**
     * Ritorna le imposte di un contribuente
     * @param codiceFiscale
     * @return
     */
    def imposteContribuente(String codiceFiscale, boolean conta = false) {

        String sqlConta1 = """
                        SELECT new Map(
                            ogim.tipoTributo.tipoTributo 			AS tipoTributo,
                            max(prtr.tipoPratica) 					AS tipoPratica,
                            ogim.anno								AS anno)
                        FROM
                            OggettoPratica as ogpr         
                        INNER JOIN
                            ogpr.pratica as prtr         
                        INNER JOIN
                            ogpr.oggettiContribuente as ogco                   
                        INNER JOIN
                            ogco.oggettiImposta as ogim        
                        WHERE
                            ogco.contribuente.codFiscale = :pCodiceFiscale       
                            AND  (
                                prtr.tipoPratica   = 'D'             
                                OR (
                                    prtr.tipoPratica    = 'A'             
                                    AND ogim.anno > prtr.anno
                                )
                            )
                            AND prtr.tipoTributo IN ('ICI', 'TASI')
                        GROUP BY 
                            ogim.anno,
                            ogim.tipoTributo.tipoTributo
                        """

        String sql1 = """
                        SELECT new Map(
                            ogco.contribuente.codFiscale			AS codFiscale,
                            ogco.contribuente.soggetto.cognomeNome  AS cognomeNome,
                            COALESCE(SUM(ogim.imposta),0) 			AS imposta,
                            COALESCE(SUM(ogim.impostaAcconto), 0)	AS impostaAcconto,
                            COALESCE(SUM(ogim.impostaErariale), 0)	AS impostaErariale,
                            COALESCE(SUM(ogim.impostaMini), 0)		AS impostaMini,
                            COALESCE(SUM(ogim.addizionaleEca), 0) + coalesce(SUM(ogim.maggiorazioneEca), 0) as addMaggEca,
                            COALESCE(SUM(ogim.addizionalePro), 0) 	AS addPro,
                            0 	AS csgravio,
                            COALESCE(SUM(ogim.iva), 0) 				AS iva,
                            MAX(ogim.lastUpdated) 					AS dataVariazione,
                            COALESCE(f_importo_vers(:pCodiceFiscale, ogim.tipoTributo.tipoTributo, ogim.anno, NULL) + 
                                     f_importo_vers_ravv(:pCodiceFiscale, ogim.tipoTributo.tipoTributo, ogim.anno, 'U'), 0) as versato,
                            ogim.anno 								AS anno,
                            ogim.tipoTributo.tipoTributo	 		AS tipoTributo,
                            f_descrizione_titr(ogim.tipoTributo.tipoTributo, ogim.anno) as descrTipoTributo,
                            ''										AS aRuolo,
                            max(prtr.tipoPratica) 					AS tipoPratica,
                            COALESCE(sum(ogim.maggiorazioneTares), 0) 		    AS maggiorazioneTares,
                            max(prtr.id) AS praticaBase,
                            DECODE(sign(f_esiste_pratica_notificata(:pCodiceFiscale, ogim.anno, ogim.tipoTributo.tipoTributo, 'A')), 1, 'true', 'false') AS accertamentoPresente,
                            DECODE(sign(f_esiste_pratica_notificata(:pCodiceFiscale, ogim.anno, ogim.tipoTributo.tipoTributo, 'L')), 1, 'true', 'false') AS liquidazionePresente,  
                            DECODE(sign(f_esiste_versamento_pratica(:pCodiceFiscale, ogim.anno, ogim.tipoTributo.tipoTributo)), 1, 'true', 'false') AS versamentoPresente) 
                        FROM
                            OggettoPratica as ogpr         
                        INNER JOIN
                            ogpr.pratica as prtr         
                        INNER JOIN
                            ogpr.oggettiContribuente as ogco                   
                        INNER JOIN
                            ogco.oggettiImposta as ogim        
                        WHERE
                            ogco.contribuente.codFiscale = :pCodiceFiscale       
                            AND  (
                                prtr.tipoPratica   = 'D'             
                                OR (
                                    prtr.tipoPratica    = 'A'             
                                    AND ogim.anno > prtr.anno
                                )
                            )
                            AND prtr.tipoTributo IN ('ICI', 'TASI')            
                        GROUP BY
                            ogim.anno,
                            ogim.tipoTributo.tipoTributo,
                            ogco.contribuente.codFiscale,
                            ogco.contribuente.soggetto.cognomeNome
    
                        """

        String sqlConta2 = """
                        SELECT new Map(
                            ogim.tipoTributo.tipoTributo			AS tipoTributo,
                            max(prtr.tipoPratica) 					AS tipoPratica,
                            ogim.anno								AS anno)
                        FROM
                            OggettoPratica as ogpr         
                        INNER JOIN
                            ogpr.pratica as prtr         
                        INNER JOIN
                            ogpr.oggettiContribuente as ogco                   
                        INNER JOIN
                            ogco.oggettiImposta as ogim        
                        WHERE
                            ogco.contribuente.codFiscale = :pCodiceFiscale       
                            AND  (
                                prtr.tipoPratica   = 'D'             
                                OR (
                                    prtr.tipoPratica    = 'A'             
                                    AND ogim.anno > prtr.anno
                                )
                            )
                            AND (prtr.tipoTributo not in ('ICI', 'TASI', 'TARSU') OR
                                (prtr.tipoTributo || '' = 'TARSU' AND NOT EXISTS 
                                (SELECT 'x' FROM Ruolo ruol WHERE ruol.id = ogim.ruolo)))  
                        GROUP BY
                            ogim.anno,
                            ogim.tipoTributo.tipoTributo
                        """

        String sql2 = """
                        SELECT new Map(
                            ogco.contribuente.codFiscale			AS codFiscale,
                            ogco.contribuente.soggetto.cognomeNome  AS cognomeNome,
                            COALESCE(SUM(ogim.imposta),0) 			AS imposta,
                            0										AS impostaAcconto,
                            0										AS impostaErariale,
                            0										AS impostaMini,
                            COALESCE(SUM(ogim.addizionaleEca), 0) + coalesce(SUM(ogim.maggiorazioneEca), 0) as addMaggEca,
                            COALESCE(SUM(ogim.addizionalePro), 0) 	AS addPro,
                             0 	AS csgravio,
                            COALESCE(SUM(ogim.iva), 0) 				AS iva,
                            MAX(ogim.lastUpdated) 					AS dataVariazione,
                            COALESCE(f_importo_vers(:pCodiceFiscale, ogim.tipoTributo.tipoTributo, ogim.anno, NULL) + 
                                     f_importo_vers_ravv(:pCodiceFiscale, ogim.tipoTributo.tipoTributo, ogim.anno, 'U'), 0) as versato,
                            ogim.anno 								AS anno,
                            ogim.tipoTributo.tipoTributo 			AS tipoTributo,
                            f_descrizione_titr(ogim.tipoTributo.tipoTributo, ogim.anno) as descrTipoTributo,
                            DECODE(cotr.flagRuolo, 'S', 'A Ruolo', '') 	AS aRuolo,
                            max(prtr.tipoPratica) 						AS tipoPratica,
                            COALESCE(sum(ogim.maggiorazioneTares), 0) 		    AS maggiorazioneTares,
                            max(prtr.id) AS praticaBase,
                            DECODE(sign(f_esiste_pratica_notificata(:pCodiceFiscale, ogim.anno, ogim.tipoTributo.tipoTributo, 'A')), 1, 'true', 'false') AS accertamentoPresente,
                            DECODE(sign(f_esiste_pratica_notificata(:pCodiceFiscale, ogim.anno, ogim.tipoTributo.tipoTributo, 'L')), 1, 'true', 'false') AS liquidazionePresente,  
                            DECODE(sign(f_esiste_versamento_pratica(:pCodiceFiscale, ogim.anno, ogim.tipoTributo.tipoTributo)), 1, 'true', 'false') AS versamentoPresente)  
                        FROM
                            OggettoPratica as ogpr         
                        INNER JOIN
                            ogpr.codiceTributo as cotr         
                        INNER JOIN
                            ogpr.pratica as prtr         
                        INNER JOIN
                            ogpr.oggettiContribuente as ogco                   
                        INNER JOIN
                            ogco.oggettiImposta as ogim        
                        WHERE
                            ogco.contribuente.codFiscale = :pCodiceFiscale       
                            AND  (
                                prtr.tipoPratica   = 'D'             
                                OR (
                                    prtr.tipoPratica    = 'A'             
                                    AND ogim.anno > prtr.anno
                                )
                            )
                            AND (prtr.tipoTributo not in ('ICI', 'TASI', 'TARSU') OR
                                (prtr.tipoTributo || '' = 'TARSU' AND NOT EXISTS
                                (SELECT 'x' FROM Ruolo ruol WHERE ruol.id = ogim.ruolo)))             
                        GROUP BY
                            ogim.anno,
                            ogim.tipoTributo.tipoTributo,
                            cotr.flagRuolo,
                            ogco.contribuente.codFiscale,
                            ogco.contribuente.soggetto.cognomeNome       
                        """

        String sqlConta3 = """
                        SELECT new Map(
                            ogim.tipoTributo.tipoTributo 			AS tipoTributo,
                            max(prtr.tipoPratica) 					AS tipoPratica,
                            ogim.anno								AS anno)      
                        FROM
                            OggettoPratica as ogpr         
                        INNER JOIN
                            ogpr.pratica as prtr         
                        INNER JOIN
                            ogpr.oggettiContribuente as ogco                   
                        INNER JOIN
                            ogco.oggettiImposta as ogim
                        INNER JOIN
                            ogim.ruolo ruolo
                        WHERE
                            ogco.contribuente.codFiscale = :pCodiceFiscale       
                            AND  (
                                prtr.tipoPratica   = 'D'             
                                OR (
                                    prtr.tipoPratica    = 'A'             
                                    AND ogim.anno > prtr.anno
                                )
                            )
                            AND prtr.tipoTributo || '' = 'TARSU'
                           AND nvl(ogim.ruolo, -1) = nvl(nvl(f_ruolo_totale(ogim.oggettoContribuente.contribuente.codFiscale,
                                                                            ogim.anno,
                                                                            prtr.tipoTributo,
                                                                            -1),
                                                             ogim.ruolo),
                                                         -1)
                           AND ruolo.invioConsorzio is not null
                        GROUP BY
                            ogim.anno,
                            ogim.tipoTributo.tipoTributo
                        """

        String sql3 = """
                        SELECT new Map(
                            ogco.contribuente.codFiscale			AS codFiscale,
                            ogco.contribuente.soggetto.cognomeNome  AS cognomeNome,
                            COALESCE(SUM(ogim.imposta),0) 			AS imposta,
                            0										AS impostaAcconto,
                            0										AS impostaErariale,
                            0										AS impostaMini,
                            COALESCE(SUM(ogim.addizionaleEca), 0) + coalesce(SUM(ogim.maggiorazioneEca), 0) as addMaggEca,
                            COALESCE(SUM(ogim.addizionalePro), 0) 	AS addPro,
                            nvl(f_dovuto(0,ogim.anno,ogim.tipoTributo.tipoTributo,0,-1,'S',NULL,:pCodiceFiscale), 0) AS csgravio,
                            COALESCE(SUM(ogim.iva), 0) 				AS iva,
                            MAX(ogim.lastUpdated) 					AS dataVariazione,
                            COALESCE(f_importo_vers(:pCodiceFiscale, ogim.tipoTributo.tipoTributo, ogim.anno, NULL) + 
                                     f_importo_vers_ravv(:pCodiceFiscale, ogim.tipoTributo.tipoTributo, ogim.anno, 'U'), 0) as versato,
                            ogim.anno 								AS anno,
                            ogim.tipoTributo.tipoTributo 			AS tipoTributo,
                            f_descrizione_titr(ogim.tipoTributo.tipoTributo, ogim.anno) as descrTipoTributo,
                            DECODE(cotr.flagRuolo, 'S', 'S', '') 	AS aRuolo,
                            max(prtr.tipoPratica) 						AS tipoPratica,
                            COALESCE(sum(ogim.maggiorazioneTares), 0) 		    AS maggiorazioneTares,
                            max(prtr.id) AS praticaBase,
                            DECODE(sign(f_esiste_pratica_notificata(:pCodiceFiscale, ogim.anno, ogim.tipoTributo.tipoTributo, 'A')), 1, 'true', 'false') AS accertamentoPresente,
                            DECODE(sign(f_esiste_pratica_notificata(:pCodiceFiscale, ogim.anno, ogim.tipoTributo.tipoTributo, 'L')), 1, 'true', 'false') AS liquidazionePresente,  
                            DECODE(sign(f_esiste_versamento_pratica(:pCodiceFiscale, ogim.anno, ogim.tipoTributo.tipoTributo)), 1, 'true', 'false') AS versamentoPresente)     
                        FROM
                            OggettoPratica as ogpr         
                        INNER JOIN
                            ogpr.codiceTributo as cotr         
                        INNER JOIN
                            ogpr.pratica as prtr         
                        INNER JOIN
                            ogpr.oggettiContribuente as ogco                   
                        INNER JOIN
                            ogco.oggettiImposta as ogim
                        INNER JOIN
                            ogim.ruolo ruolo
                        WHERE
                            ogco.contribuente.codFiscale = :pCodiceFiscale       
                            AND  (
                                prtr.tipoPratica   = 'D'             
                                OR (
                                    prtr.tipoPratica    = 'A'             
                                    AND ogim.anno > prtr.anno
                                )
                            )
                            AND prtr.tipoTributo || '' = 'TARSU'
                           AND nvl(ogim.ruolo, -1) = nvl(nvl(f_ruolo_totale(ogim.oggettoContribuente.contribuente.codFiscale,
                                                                            ogim.anno,
                                                                            prtr.tipoTributo,
                                                                            -1),
                                                             ogim.ruolo),
                                                         -1)
                           AND ruolo.invioConsorzio is not null        
                        GROUP BY
                            ogim.anno,
                            ogim.tipoTributo.tipoTributo,
                            cotr.flagRuolo,
                            ogco.contribuente.codFiscale,
                            ogco.contribuente.soggetto.cognomeNome       
                        """

        def parametriQuery = [:]
        parametriQuery.pCodiceFiscale = codiceFiscale

        def lista = []
        // Si restituisce solo la count
        if (conta) {
            lista = PraticaTributo.executeQuery(sqlConta1, parametriQuery) +
                    PraticaTributo.executeQuery(sqlConta2, parametriQuery) +
                    PraticaTributo.executeQuery(sqlConta3, parametriQuery)

        } else {
            // Lista dei ruoli

            def lista1 = []
            lista1 = PraticaTributo.executeQuery(sql1, parametriQuery)

            def lista2 = []
            lista2 = PraticaTributo.executeQuery(sql2, parametriQuery)

            def lista3 = []
            lista3 = PraticaTributo.executeQuery(sql3, parametriQuery)


            lista.addAll(lista1)
            lista.addAll(lista2)
            lista.addAll(lista3)

            lista.sort { a, b ->
                b.anno <=> a.anno ?: a.tipoTributo <=> b.tipoTributo
            }

            //Calcolo residuo
            lista.each {
                if (it.tipoTributo == "TARSU") {
                    it.residuo = ((it.imposta ?: 0) + (it.maggiorazioneTares ?: 0) + (it.addMaggEca ?: 0) + (it.addPro ?: 0) + (it.iva ?: 0) - (it.csgravio ?: 0)) - it.versato ?: 0
                } else {
                    it.residuo = (it.imposta ?: 0) - (it.versato ?: 0)
                }
                //Arrotondamento
                it.residuo = Math.round(it.residuo)
                it.impostaRound = Math.round(it.imposta ?: 0)
                it.versatoRound = Math.round(it.versato ?: 0)

                it.accertamentoPresente = it.accertamentoPresente?.toBoolean()
                it.liquidazionePresente = it.liquidazionePresente?.toBoolean()
                it.versamentoPresente = it.versamentoPresente?.toBoolean()
            }
        }

        return lista
    }

    /**
     * Ritorna i versamenti di un contribuente
     *
     * @param codFiscale
     * @param tipoTributo
     *
     * @return
     */
    def versamentiContribuente(String codFiscale, String cognomeNome, def listaTributi, int pageSize, int activePage, boolean wholeList = false) {

        def filtroTipiTributi = ""
        if (listaTributi.size() > 0) {
            for (tipo in listaTributi) {
                filtroTipiTributi += "'" + tipo + "' ,"
            }
            filtroTipiTributi = " ( VERSAMENTI.TIPO_TRIBUTO in (" + filtroTipiTributi.substring(0, filtroTipiTributi.length() - 1) + ")) AND "
        } else {
            filtroTipiTributi = " ( VERSAMENTI.TIPO_TRIBUTO like '%' ) AND "
        }

        String sql = """    SELECT   VERSAMENTI.TIPO_TRIBUTO,   
                                         f_descrizione_titr(VERSAMENTI.tipo_tributo,VERSAMENTI.anno) DESCRIZIONE_TRIBUTO,
                                         VERSAMENTI.ANNO,   
                                         VERSAMENTI.RATA,   
                                         VERSAMENTI.TIPO_VERSAMENTO,   
                                         VERSAMENTI.IMPORTO_VERSATO,   
                                         VERSAMENTI.DATA_PAGAMENTO,   
                                         VERSAMENTI.RUOLO,
                                         VERSAMENTI.FABBRICATI,   
                                         VERSAMENTI.TERRENI_AGRICOLI,   
                                         VERSAMENTI.AREE_FABBRICABILI,   
                                         VERSAMENTI.AB_PRINCIPALE,   
                                         VERSAMENTI.ALTRI_FABBRICATI,   
                                         VERSAMENTI.DETRAZIONE,   
                                         VERSAMENTI.FONTE,   
                                         PRATICHE_TRIBUTO.TIPO_PRATICA,   
                                         PRATICHE_TRIBUTO.TIPO_EVENTO, 
                                         PRATICHE_TRIBUTO.PRATICA,   
                                         SCADENZE.DATA_SCADENZA,                                        
                                         VERSAMENTI.FABBRICATI_D,
                                         VERSAMENTI.RURALI,
                                         VERSAMENTI.MAGGIORAZIONE_TARES,
                                         VERSAMENTI.FABBRICATI_MERCE,
                                         VERSAMENTI.ADDIZIONALE_PRO,
                                         VERSAMENTI.SEQUENZA,
                                         decode(versamenti.id_compensazione,'','N','S') CHECK_COMPENSAZIONE
                                    FROM PRATICHE_TRIBUTO, SCADENZE, VERSAMENTI 
                                   WHERE ( VERSAMENTI.PRATICA  = PRATICHE_TRIBUTO.PRATICA (+)) AND  
                                         ( SCADENZE.TIPO_SCADENZA (+) = 'V' ) AND
                                         ( VERSAMENTI.TIPO_TRIBUTO    = SCADENZE.TIPO_TRIBUTO (+)) AND  
                                         ( VERSAMENTI.ANNO            = SCADENZE.ANNO (+)) AND  
                                         ( VERSAMENTI.TIPO_VERSAMENTO = SCADENZE.TIPO_VERSAMENTO (+)) AND  
                                         """
        sql += filtroTipiTributi
        sql += """
                                         ( VERSAMENTI.COD_FISCALE = :p_cf ) and
                                         f_get_competenza_utente(:p_utente,versamenti.tipo_tributo) is not null     
                                ORDER BY VERSAMENTI.TIPO_TRIBUTO ASC,   
                                         VERSAMENTI.ANNO DESC,   
                                         VERSAMENTI.DATA_PAGAMENTO DESC,   
                                         VERSAMENTI.TIPO_VERSAMENTO DESC,   
                                         VERSAMENTI.RATA ASC,   
                                         PRATICHE_TRIBUTO.PRATICA ASC,
                                         VERSAMENTI.SEQUENZA ASC   """

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
                setString('p_utente', springSecurityService.currentUser?.id)
                setString('p_cf', codFiscale)
                list()
            }[0]
        }

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('p_utente', springSecurityService.currentUser?.id)
            setString('p_cf', codFiscale)

            if (!wholeList) {
                setFirstResult(params.offset)
                setMaxResults(params.max)
            }

            list()
        }

        def tipiTributi = [
                ICI  : false,
                TASI : false,
                TARSU: false,
                ICP  : false,
                TOSAP: false
        ]

        def records = []

        results.each {
            def record = [:]

            record.descrizioneTributo = it['DESCRIZIONE_TRIBUTO']
            record.anno = it['ANNO']
            record.tipoPratica = it['TIPO_PRATICA']
            record.tipoVersamento = it['TIPO_VERSAMENTO']
            record.rata = it['RATA']
            record.importoVersato = it['IMPORTO_VERSATO']
            record.dataPagamento = it['DATA_PAGAMENTO']
            record.ruolo = it['RUOLO']
            record.fabbricati = it['FABBRICATI']
            record.terreniAgricoli = it['TERRENI_AGRICOLI']
            record.areeFabbricabili = it['AREE_FABBRICABILI']
            record.abPrincipale = it['AB_PRINCIPALE']
            record.altriFabbricati = it['ALTRI_FABBRICATI']
            record.detrazione = it['DETRAZIONE']
            record.rurali = it['RURALI']
            record.fabbricatiD = it['FABBRICATI_D']
            record.fabbricatiMerce = it['FABBRICATI_MERCE']
            record.addizionalePro = it['ADDIZIONALE_PRO']
            record.maggiorazioneTares = it['MAGGIORAZIONE_TARES']
            record.fonte = it['FONTE']
            record.chekCompensazione = it['CHECK_COMPENSAZIONE']


            if (wholeList) {
                record.codFiscale = codFiscale
                record.cognomeNome = cognomeNome
            }
            records << record

            // Tributi attivi
            tipiTributi.ICI |= (it['TIPO_TRIBUTO'] == "ICI" || it['TIPO_TRIBUTO'] == "IMU")
            tipiTributi.TASI |= (it['TIPO_TRIBUTO'] == "TASI")
            tipiTributi.TARSU |= (it['TIPO_TRIBUTO'] == "TARSU")
            tipiTributi.ICP |= (it['TIPO_TRIBUTO'] == "ICP")
            tipiTributi.TOSAP |= (it['TIPO_TRIBUTO'] == "TOSAP")
        }

        def totals = [
                totalCount: (!wholeList) ? totali.TOT_COUNT : records.size(),
        ]

        return [totalCount: totals.totalCount, totals: totals, records: records, tipiTributi: tipiTributi]

    }

    /**
     * Ritorna i versamenti di un contribuente
     *
     * @param codFiscale
     * @return
     */
    def versamentiContribuente(String codFiscale, def tipo = 'list', List<String> listaTipiTributo = [], List<String> listaTipiPratica = []) {
        def lista = Versamento.createCriteria().list {
            createAlias("pratica", "prtr", CriteriaSpecification.LEFT_JOIN)

            eq("contribuente.codFiscale", codFiscale)

            if (!listaTipiTributo.empty) {
                'in'('tipoTributo.tipoTributo', listaTipiTributo)
            } else {
                // Se non è passato almeno un tipo tributo non si estraggono dati
                eq('prtr.id', -1L)
            }

            if (!listaTipiPratica.empty) {
                if (listaTipiPratica.indexOf('D') > -1) {
                    or {
                        'in'('prtr.tipoPratica', listaTipiPratica)
                        isNull('prtr.tipoPratica')
                    }
                } else {
                    'in'('prtr.tipoPratica', listaTipiPratica)
                }
            } else {
                // Se non è passato almeno un tipo pratica non si estraggono dati
                eq('prtr.id', -1L)
            }

            fetchMode("tipoTributo", FetchMode.JOIN)
            order("tipoTributo", "asc")
            order("anno", "desc")
            order("dataPagamento", "desc")
            order("tipoVersamento", "desc")
            order("rata", "asc")
            order("prtr.id", "asc")

            if (tipo == 'count') {
                projections {
                    count()
                }
            }
        }

        if (tipo == 'count') {
            return lista[0]
        } else {
            lista.toDTO([
                    "contribuente",
                    "contribuente.soggetto"
            ])
        }

    }

    /**
     * Ritorna i contatti del contribuente
     *
     * @param codFiscale
     * @return
     */
    def contattiContribuente(String codFiscale, def listaTipiTributo) {
        /*
        TODO: poiché la praticak potrebbe essere eliminata è stato usato ignoreNotFound sull'entity.
          Nella trasformazione in DTO vengono eseguite n query per recuperare le pratiche.
          Riscrivere la query in SQL.
         */

        listaTipiTributo.isEmpty() ? [] :
                ContattoContribuente.createCriteria().list {
                    createAlias("tipoContatto", "tico", CriteriaSpecification.LEFT_JOIN)
                    createAlias("tipoRichiedente", "tiri", CriteriaSpecification.LEFT_JOIN)
                    createAlias("tipoTributo", "titr", CriteriaSpecification.LEFT_JOIN)
                    createAlias("contribuente", "cont", CriteriaSpecification.LEFT_JOIN)

                    eq("contribuente.codFiscale", codFiscale)

                    or {
                        'in'("titr.tipoTributo", listaTipiTributo)
                        isNull("titr.tipoTributo")
                    }

                    order("data", "asc")
                    order("numero", "asc")
                    order("anno", "asc")
                }.toDTO([
                        "contribuente",
                        "contribuente.soggetto"
                ])
    }

    def salvaContatto(ContattoContribuente contatto) {
        contatto.save(failOnError: true, flush: true)
    }

    def eliminaContatto(ContattoContribuente contatto) {
        contatto.delete(failOnError: true, flush: true)
    }

    def getNuovaSequenzaContatto(def codFiscale) {

        Short progressivo = 1

        Sql sql = new Sql(dataSource)
        sql.call('{call CONTATTI_CONTRIBUENTE_NR(?, ?)}',
                [
                        codFiscale,
                        Sql.NUMERIC
                ],
                { progressivo = it }
        )

        return progressivo
    }

    def ruoliContribuente(String codFiscale, boolean conta = false, def filtroRuoli = [:]) {

        def contribuente = Contribuente.findByCodFiscale(codFiscale)

        def listaRuoli = Ruolo.createCriteria().list {
            createAlias("ruoliContribuente", "ruco", CriteriaSpecification.INNER_JOIN)
            createAlias("ruco.oggettoImposta", "ogim", CriteriaSpecification.LEFT_JOIN)

            projections {
                groupProperty("ruco.codiceTributo", "codiceTributo")
                groupProperty("id", "id")
                groupProperty("specieRuolo", "specieRuolo")
                groupProperty("tipoTributo", "tipoTributo")
                groupProperty("tipoRuolo", "tipoRuolo")
                groupProperty("annoRuolo", "annoRuolo")
                groupProperty("annoEmissione", "annoEmissione")
                groupProperty("progrEmissione", "progrEmissione")
                groupProperty("dataEmissione", "dataEmissione")
                groupProperty("invioConsorzio", "invioConsorzio")
                groupProperty("importoLordo", "importoLordo")
                groupProperty("percAcconto", "percAcconto")
                groupProperty("flagTariffeRuolo", "flagTariffeRuolo")
                groupProperty("flagCalcoloTariffaBase", "flagCalcoloTariffaBase")
                groupProperty("flagDePag", "flagDePag")

                sum("ruco.importo", "importo")
                sum("ogim.addizionaleEca", "addizionaleEca")
                sum("ogim.maggiorazioneEca", "maggiorazioneEca")
                sum("ogim.addizionalePro", "addizionalePro")
                sum("ogim.iva", "iva")
                sum("ogim.imposta", "imposta")
                max("tipoCalcolo", "tipoCalcolo")
                max("ruco.contribuente.codFiscale", "codFiscale")
                max("tipoEmissione", "tipoEmissione")
                sum("ogim.maggiorazioneTares", "maggiorazioneTares")
            }
            eq("ruco.contribuente.codFiscale", codFiscale)

            if (filtroRuoli.ruoloDa != null) {
                gte("id", filtroRuoli.ruoloDa as Long)
            }
            if (filtroRuoli.ruoloA != null) {
                lte("id", filtroRuoli.ruoloA as Long)
            }

            if (filtroRuoli.annoDa != null) {
                gte("annoRuolo", filtroRuoli.annoDa as Short)
            }
            if (filtroRuoli.annoA != null) {
                lte("annoRuolo", filtroRuoli.annoA as Short)
            }

            order("tipoRuolo", "asc")
            order("annoRuolo", "desc")
            order("annoEmissione", "desc")
            order("progrEmissione", "asc")
            order("ruco.codiceTributo", "asc")
            order("dataEmissione", "asc")
            order("invioConsorzio", "asc")

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
        }

        def listaEccedenze = Ruolo.createCriteria().list {
            createAlias("ruoliEccedenze", "ruec", CriteriaSpecification.LEFT_JOIN)

            projections {
                groupProperty("ruec.ruolo", "ruolo")
                groupProperty("ruec.codiceTributo", "codiceTributo")

                sum("ruec.importoRuolo", "importoEcc")
                sum("ruec.imposta", "impostaEcc")
                sum("ruec.addizionalePro", "addProEcc")
            }
            eq("ruec.contribuente.codFiscale", codFiscale)

            if (filtroRuoli.ruoloDa != null) {
                gte("id", filtroRuoli.ruoloDa as Long)
            }
            if (filtroRuoli.ruoloA != null) {
                lte("id", filtroRuoli.ruoloA as Long)
            }

            if (filtroRuoli.annoDa != null) {
                gte("annoRuolo", filtroRuoli.annoDa as Short)
            }
            if (filtroRuoli.annoA != null) {
                lte("annoRuolo", filtroRuoli.annoA as Short)
            }

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
        }

        def listaSgravi = []

        if (!conta) {

            listaSgravi = Ruolo.createCriteria().list {
                createAlias("ruoliContribuente", "ruco", CriteriaSpecification.INNER_JOIN)
                createAlias("ruco.oggettoImposta", "ogim", CriteriaSpecification.LEFT_JOIN)
                createAlias("ruco.sgravi", "sgra", CriteriaSpecification.LEFT_JOIN)

                projections {
                    groupProperty("ruco.codiceTributo", "codiceTributo")
                    groupProperty("id", "id")

                    sum("sgra.importo", "sgravio")
                }
                eq("ruco.contribuente.codFiscale", codFiscale)

                if (filtroRuoli.ruoloDa != null) {
                    gte("id", filtroRuoli.ruoloDa as Long)
                }
                if (filtroRuoli.ruoloA != null) {
                    lte("id", filtroRuoli.ruoloA as Long)
                }

                if (filtroRuoli.annoDa != null) {
                    gte("annoRuolo", filtroRuoli.annoDa as Short)
                }
                if (filtroRuoli.annoA != null) {
                    lte("annoRuolo", filtroRuoli.annoA as Short)
                }

                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            }
        }

        List carichiTarsu = OggettiCache.CARICHI_TARSU.valore

        def listaRuoliContribuente = []
        for (ruco in listaRuoli) {
            def ruoloContribuente = [:]

            if (conta) {
                TipoTributoDTO tipoTributo = ruco.tipoTributo.toDTO()
                ruoloContribuente.tipoTributo = tipoTributo.tipoTributo
            } else {
                def sgravio = listaSgravi.find { it.id == ruco.id && it.codiceTributo == ruco.codiceTributo }

                TipoTributoDTO tipoTributo = ruco.tipoTributo.toDTO()

                ruoloContribuente.codFiscale = contribuente.codFiscale
                ruoloContribuente.cognomeNome = contribuente.soggetto.cognomeNome

                ruoloContribuente.descrizioneTributo = tipoTributo.getTipoTributoAttuale(ruco.annoRuolo)
                ruoloContribuente.tipoTributo = tipoTributo.tipoTributo
                ruoloContribuente.ruolo = ruco.id
                ruoloContribuente.tipoRuolo = ruco.tipoRuolo
                ruoloContribuente.tipoRuoloStr = ruco.tipoRuolo == 1 ? 'P' : 'S'
                ruoloContribuente.anno = ruco.annoRuolo
                ruoloContribuente.annoEmissione = ruco.annoEmissione
                ruoloContribuente.progrEmissione = ruco.progrEmissione
                ruoloContribuente.dataEmissione = ruco.dataEmissione?.format("dd/MM/yyyy")
                ruoloContribuente.invioConsorzio = ruco.invioConsorzio?.format("dd/MM/yyyy")
                ruoloContribuente.codiceTributo = ruco.codiceTributo.toDTO().toDomain()
                // Inizializzazione oggetto

                ruoloContribuente.importo = ruco.importo
                ruoloContribuente.importoLordo = ruco.importoLordo
                ruoloContribuente.importoLordoStr = ruco.importoLordo ? 'S' : 'N'

                ruoloContribuente.sgravio = sgravio?.sgravio

                ruoloContribuente.imposta = ruco.imposta
                ruoloContribuente.addMaggEca = new BigDecimal(ruco.addizionaleEca ?: 0).add(new BigDecimal(ruco.maggiorazioneEca ?: 0))
                ruoloContribuente.addProv = ruco.addizionalePro ?: 0
                ruoloContribuente.iva = ruco.iva
                ruoloContribuente.specie = ruco.specieRuolo ? 'Coattivo' : 'Ordinario'
                ruoloContribuente.specieRuolo = ruco.specieRuolo
                ruoloContribuente.compensazione = calcolaCompensazioneRuolo(ruco.id, codFiscale, null)
                ruoloContribuente.tipoEmissione = ruco.tipoEmissione
                ruoloContribuente.tipoCalcolo = ruco.tipoCalcolo
                ruoloContribuente.maggiorazioneTares = ruco.maggiorazioneTares
                ruoloContribuente.percAcconto = ruco.percAcconto
                ruoloContribuente.flagCalcoloTariffaBase = ruco.flagCalcoloTariffaBase
                ruoloContribuente.flagTariffeRuolo = ruco.flagTariffeRuolo
                ruoloContribuente.flagDePag = ruco.flagDePag
                ruoloContribuente.descrizioneSpecie = ruoloContribuente.specie ? 1 : 0
                ruoloContribuente.tipoTributoAttuale = tipoTributo.getTipoTributoAttuale(ruco.annoRuolo)

                ruoloContribuente.importoImp = ruoloContribuente.importo
                ruoloContribuente.addProvImp = ruoloContribuente.addProv

                def cata = carichiTarsu.find { it.anno == ruco.annoRuolo }
                ruoloContribuente.flagErroreCaTa = (cata == null) ? 'S' : null

                if(ruco.tipoRuolo == 2) { // SOLO supplettivo
                    ruoloContribuente.flagTariffaPuntuale = cata?.flagTariffaPuntuale
                }
                else{
                    ruoloContribuente.flagTariffaPuntuale = null
                }

                if(ruoloContribuente.flagTariffaPuntuale == 'S') {

                    def eccedenza = listaEccedenze.find { it.ruolo.id == ruoloContribuente.ruolo && 
                                                            it.codiceTributo.id  == ruoloContribuente.codiceTributo.id }

                    ruoloContribuente.eccedenze = eccedenza?.impostaEcc ?: 0
                    ruoloContribuente.addProvEcc = eccedenza?.addProEcc ?: 0

                    ruoloContribuente.importo += eccedenza?.importoEcc ?: 0
                    ruoloContribuente.addProv += ruoloContribuente.addProvEcc
                }
                else {
                    ruoloContribuente.eccedenze = null
                    ruoloContribuente.addProvEcc = null
                }

                switch (ruoloContribuente.tipoCalcolo) {
                    case 'N': ruoloContribuente.descrizioneCalcolo = 'Normalizzato'; break
                    case 'T': ruoloContribuente.descrizioneCalcolo = 'Tradizionale'; break
                    default: ruoloContribuente.descrizioneCalcolo = ''
                }
                switch (ruoloContribuente.tipoEmissione) {
                    case 'A': ruoloContribuente.descrizioneEmissione = 'Acconto'; break
                    case 'S': ruoloContribuente.descrizioneEmissione = 'Saldo'; break
                    case 'T': ruoloContribuente.descrizioneEmissione = 'Totale'; break
                    default: ruoloContribuente.descrizioneEmissione = ''
                }
            }
            listaRuoliContribuente << ruoloContribuente
        }

        listaRuoliContribuente
    }


    def oggettiRuolo(String codFiscale, long ruolo) {
        def listaOggetti = []
        def lista = RuoloOggetto.createCriteria().list {
            createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
            createAlias("ogg.archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)
            projections {
                property("ruoloContribuente")       // 0
                property("categoria")               // 1
                property("tipoTariffa")             // 2
                property("importo")                 // 3
                property("addizionaleEca")          // 4
                property("maggiorazioneEca")        // 5
                property("addizionalePro")          // 6
                property("iva")                     // 7
                property("ogg.indirizzoLocalita")   // 8
                property("ogg.numCiv")              // 9
                property("ogg.suffisso")            // 10
                property("ogg.archivioVie")         // 11
                property("ogg.id")                  // 12
                property("mesiRuolo")               // 13
                property("giorniRuolo")             // 14
                property("maggiorazioneTares")      // 15
                property("imposta")                 // 16
                property("importoLordo")            // 17
                property("codiceTributo.id")        // 18
                property("consistenza")             // 19
                property("ogg.tipoOggetto")         // 20
                property("ogg.sezione")            // 21
                property("ogg.foglio")                // 22
                property("ogg.numero")                // 23
                property("ogg.subalterno")          // 24
                property("ogg.zona")                // 25
                property("ogg.categoriaCatasto") // 26
                property("codiceTributo") // 27
                property("mesiRuolo") // 28
                property("giorniRuolo") // 29
                property("ruoloContribuente.sequenza") // 30
                property("annoRuolo") // 31
                property("oggettoImposta") // 32
                property("oggettoPratica") // 33
            }
            eq("ruoloContribuente.ruolo.id", ruolo)
            eq("ruoloContribuente.contribuente.codFiscale", codFiscale)
        }

        for (ruogg in lista) {
            def oggettiRuolo = [:]
            oggettiRuolo.categoria = ruogg[1]
            oggettiRuolo.tipoTariffa = ruogg[2]
            oggettiRuolo.importo = ruogg[3]
            oggettiRuolo.addMaggEca = new BigDecimal(ruogg[4] ?: 0).add(new BigDecimal(ruogg[5] ?: 0))
            oggettiRuolo.addProv = ruogg[6]
            oggettiRuolo.iva = ruogg[7]
            oggettiRuolo.indirizzo = (ruogg[11] ? ruogg[11].denomUff : ruogg[8] ?: "") + (ruogg[9] ? ", ${ruogg[9]}" : "") + (ruogg[10] ? "/ ${ruogg[10]}" : "")
            oggettiRuolo.id = ruogg[12]
            oggettiRuolo.mesiRuolo = ruogg[13]
            oggettiRuolo.giorniRuolo = ruogg[14]
            oggettiRuolo.maggiorazioneTares = ruogg[15]
            oggettiRuolo.imposta = ruogg[16]
            oggettiRuolo.importoLordo = ruogg[17]
            oggettiRuolo.codiceTributo = ruogg[18]
            oggettiRuolo.consistenza = ruogg[19]
            oggettiRuolo.sgravio = ruogg[0]?.sgravi?.flatten()?.sum { it.importo ?: 0 }
            oggettiRuolo.tipoOggetto = ruogg[20]?.tipoOggetto
            oggettiRuolo.sezione = ruogg[21]
            oggettiRuolo.foglio = ruogg[22]
            oggettiRuolo.numero = ruogg[23]
            oggettiRuolo.subalterno = ruogg[24]
            oggettiRuolo.zona = ruogg[25]
            oggettiRuolo.categoriaCatasto = ruogg[26]?.categoriaCatasto
            oggettiRuolo.codiceTributo = ruogg[27]?.id
            oggettiRuolo.mesiRuolo = ruogg[28]
            oggettiRuolo.giorniRuolo = ruogg[29]
            oggettiRuolo.sequenza = ruogg[30]

            oggettiRuolo.numFamiliari = getNumeroFamiliari(ruogg[33]?.id, ruogg[32].oggettoContribuente.flagAbPrincipale, ruogg[31], ruogg[32].id)
            oggettiRuolo.numeroFamiliariTooltip = tooltipFamiliariOgim(ruogg[32].id)

            oggettiRuolo.flagPuntoRaccolta = ruogg[32].oggettoContribuente.flagPuntoRaccolta

            listaOggetti << oggettiRuolo
        }

        return listaOggetti
    }

    def tooltipFamiliariOgim(def ogimId) {
        def query = """
        SELECT 
            TO_CHAR(NVL(faog.numero_familiari, ogpr.numero_familiari)) num_familiari,
            TO_CHAR(DECODE(faog.numero_familiari,
                           NULL,
                           NVL(ogva.dal, TO_DATE('01011900', 'ddmmyyyy')),
                           faog.dal),
                    'dd/mm/yyyy') dal,
            TO_CHAR(DECODE(faog.numero_familiari,
                           NULL,
                           NVL(ogva.al, TO_DATE('31122999', 'ddmmyyyy')),
                           faog.al),
                    'dd/mm/yyyy') al
        FROM 
            oggetti_pratica  ogpr,
            oggetti_imposta  ogim,
            familiari_ogim   faog,
            oggetti_validita ogva
        WHERE 
            ogim.oggetto_imposta = :ogimId
            AND ogpr.oggetto_pratica = ogim.oggetto_pratica
            AND faog.oggetto_imposta(+) = ogim.oggetto_imposta
            AND ogpr.oggetto_pratica = ogva.oggetto_pratica
        ORDER BY 
            2, 3
    """

        def result = []
        Sql sql = new Sql(dataSource)
        sql.eachRow(query, [ogimId: ogimId]) { row ->
            def familiare = [
                    numFamiliari: row.num_familiari,
                    dal         : row.dal,
                    al          : row.al
            ]
            result << familiare
        }

        def tooltipText = ""
        if (result.size() > 1) {
            result.each { familiare ->
                tooltipText += "Numero familiari ${familiare.numFamiliari} dal ${familiare.dal} al ${familiare.al == '31/12/2999' ? '' : familiare.al}\n"
            }
        }
        return tooltipText
    }

    def getNumeroFamiliari(def oggettoPratica, def flagAbPrincipale, annoRuolo, oggettoImposta) {

        Integer r
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_GET_NUM_FAM_COSU(?, ?, ?, ?)}'
                , [Sql.INTEGER, oggettoPratica, flagAbPrincipale ? 'S' : null, annoRuolo, oggettoImposta]) {
            r = it
        }
        return r
    }

    def praticheRuolo(String codFiscale, def ruolo) {
        List<TipoTributoDTO> tipiTributo = OggettiCache.TIPI_TRIBUTO.valore

        def listaPraticheRuolo = PraticaTributo.createCriteria().list {
            createAlias("contribuente", "cont", CriteriaSpecification.INNER_JOIN)
            createAlias("cont.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
            createAlias("rapportiTributo", "ratr", CriteriaSpecification.LEFT_JOIN)
            createAlias("tipoStato", "tist", CriteriaSpecification.LEFT_JOIN)
            createAlias("sanzioniPratica", "sapr", CriteriaSpecification.INNER_JOIN)

            projections {
                distinct("id")                         // 0
                property("tipoTributo.tipoTributo")    // 1
                property("anno")                       // 2
                property("tipoPratica")                // 3
                property("tipoEvento")                 // 4
                property("data")                       // 5
                property("numero")                     // 6
                property("dataNotifica")               // 7
                property("sogg.cognomeNome")           // 8
                property("cont.soggetto.id")           // 9
                property("ratr.tipoRapporto")          // 10
                property("tist.descrizione")           // 11
                property("flagAnnullamento")           // 12
                property("importoTotale")              // 13
                property("cont.codFiscale")            // 14
                property("tipoNotifica")               // 15
                property("tipoViolazione")             // 16
            }

            if (codFiscale) {
                eq("ratr.contribuente.codFiscale", codFiscale)
            }
            if (ruolo) {
                eq("sapr.ruolo.id", ruolo)
            }

            order("tipoTributo.tipoTributo", "asc")
            order("anno", "desc")
            order("tipoPratica", "asc")
        }

        Map sommaSgraviPerPratica = [:]
        if (!listaPraticheRuolo.isEmpty()) {
            def idPratiche = listaPraticheRuolo.collect { it[0] }
            sommaSgraviPerPratica = getSommaSgraviPerPratica(ruolo, idPratiche)
        }
        def listaPraticheRuoloProcessed = listaPraticheRuolo.collect { row ->

            String docSuccessivo
            if (codFiscale) {
                docSuccessivo = denunceService.functionProssimaPratica(row[0], codFiscale, row[1])
            } else {
                docSuccessivo = denunceService.functionProssimaPratica(row[0], row[15], row[1])
            }

            // Il toLong permette di eliminare la sequenza di 0 iniziali
            String praticaSuccessiva = docSuccessivo?.substring(2, docSuccessivo?.length())?.toLong()
            String eventoSuccessivo = docSuccessivo?.substring(0, 1)

            def tipoViolazione = [
                    ID: 'Infedele Denuncia',
                    OD: 'Omessa Denuncia'
            ]

            [pratica                      : row[0]
             , tipoTributo                : tipiTributo.find { it.tipoTributo == row[1] }
             , anno                       : row[2]
             , tipoPratica                : row[3]
             , tipoEvento                 : row[4]
             , data                       : row[5]
             , numero                     : row[6]
             , dataNotifica               : row[7]
             , stato                      : row[11]
             , codiceFiscale              : (codFiscale) ? codFiscale : row[14]
             , nome                       : row[8]
             , tipoRapporto               : row[10]
             , ni                         : row[9]
             , id                         : row[0]
             , flagAnnullamento           : row[12] ? '(ANN)' : ''
             , praticaSuccessiva          : praticaSuccessiva != null ? praticaSuccessiva + ' (' + eventoSuccessivo + ')' : ''
             , descrizioneTributo         : (tipiTributo.find { it.tipoTributo == row[1] }).getTipoTributoAttuale(row[2])
             , importoTotale              : row[13] ?: 0
             , tipoNotifica               : row[15]
             , tipoViolazione             : row[16]
             , tipoEventoViolazione       : row[16] != null ? "${row[4]} - ${row[16]}" : row[4]
             , tipoEventoViolazioneTooltip: row[16] != null ? "${row[4]} - ${tipoViolazione[row[16]]}" : ''
             , importoSgravio             : sommaSgraviPerPratica.get(row[0])
            ]
        }

        return listaPraticheRuoloProcessed
    }

    private def getSommaSgraviPerPratica(def ruolo, List idPratiche) {
        List sommaSgraviPratica = PraticaTributo.createCriteria().list {
            createAlias("ruoliContribuente", "ruco", CriteriaSpecification.INNER_JOIN)
            createAlias("ruco.sgravi", "sgra", CriteriaSpecification.INNER_JOIN)

            projections {
                sum("sgra.importo", "importo")
                groupProperty("id", "pratica")
            }

            inList("id", idPratiche)
            if (ruolo) {
                eq("ruco.ruolo.id", ruolo)
            }

            resultTransformer(AliasToEntityMapResultTransformer.INSTANCE)
        }
        Map sgraviPerPratica = sommaSgraviPratica.collectEntries {
            [(it.pratica): it.importo]
        }
        return sgraviPerPratica
    }

    /**
     * Calcola la compensazione del ruolo.
     * Potrebbe essere facilmente riscritta in groovy dato che la funzione fa solo delle select
     * @param ruolo
     * @param codFiscale
     * @param row
     * @return
     */
    BigDecimal calcolaCompensazioneRuolo(Long ruolo, String codFiscale, Long row) {
        BigDecimal r
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_compensazione_ruolo(?, ?, ?)}'
                , [
                Sql.DECIMAL
                ,
                ruolo
                ,
                codFiscale
                ,
                row
        ]) { r = it }

        return r
    }

    /**
     * Ritorna gli oggetti di una imposta legata ad un contribuente
     * @param codiceFiscale
     * @param anno
     * @param tipoTributo
     * @param tipoPratica
     * @return
     */
    def oggettiImposteContribuente(def codiceFiscale, def anno, def tipoTributo, def tipoPratica) {

        def lista = []
        def parametriQuery = [:]
        parametriQuery.pCodiceFiscale = codiceFiscale
        parametriQuery.pAnno = anno
        parametriQuery.pTipoTributo = tipoTributo
        parametriQuery.pTipoPratica = tipoPratica

        String sql = """
                        select new Map(
                            count(distinct ogim.aliquota)			as aliquotaCount, 
                            COALESCE(sum(ogim.imposta), 0) 			as imposta,
                            COALESCE(sum(ogim.impostaAcconto), 0)	as impostaAcconto,
                            MAX(ogim.lastUpdated)					as dataVariazione,
                            decode(count(distinct ogim.aliquota), 1, MAX(to_number(ogim.aliquota)), null) 		as aliquota,
                            MAX('')									as tipoAliquotaOgim,
                            ogge.annoCatasto								as anno,
                            prtr.tipoTributo.tipoTributo			as tipoTributo,
                            prtr.tipoPratica.tipoPratica			as tipoPratica,
                            decode(cotr.flagRuolo, 'S', 'A Ruolo', '')	as aRuolo,
                            ogpr.oggetto.id 							as oggetto,
                            max(ogge.tipoOggetto.id) 					as tipoOggetto,
                            MAX ( (DECODE (arvi.id, NULL, ogge.indirizzoLocalita, arvi.denomUff)
                                 				|| DECODE (ogge.numCiv, NULL, '', ', ' || ogge.numCiv)
                                                || DECODE (ogge.suffisso, NULL, '', '/' || ogge.suffisso)
                                                || DECODE (ogge.interno, NULL, '', ' int. ' || ogge.interno)))	as indirizzoOggetto,
                            MAX ( DECODE (cont.codControllo, NULL, TO_CHAR (cont.codContribuente)
                                        , cont.codContribuente || '-' || cont.codControllo))					as codContribuente,
                            MAX ( TRANSLATE(sogg.cognomeNome, '/',' ')) 										as cognomeNome,
                            MAX (cont.codFiscale)		as codFiscale,
                            MAX (ogge.sezione)			as sezione,
                            MAX (ogge.foglio)			as foglio,
                            MAX (ogge.numero)			as numero,
                            MAX (ogge.subalterno)		as subalterno,
                            MAX (ogge.zona)				as zona,
                            MAX (ogge.partita)			as partita,
                            MAX (ogpr.classeCatasto)						as classe,
                            coalesce (MAX (ogim.detrazione), 0) 			as detrazione,
                            coalesce (MAX (ogim.detrazioneAcconto), 0) 		as detrazioneAcconto,
                            coalesce (MAX (ogim.aliquotaErariale), TO_NUMBER(NULL)) as aliquotaErariale,
                            MAX (coalesce (ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto)) as categoriaCatasto,
                            MAX (ogim.aliquotaStd)				as aliquotaStd,
                            SUM (ogim.impostaAliquota)			as impostaAliquota,
                            SUM (ogim.impostaStd)				as impostaStd,
                            SUM (ogim.impostaMini)				as impostaMini,
                            MAX (ratr.tipoRapporto)				as tipoRapporto,
                            MAX (ogim.id)						as id,
                            decode(count(distinct ogim.aliquota), 1, MAX(tial.tipoAliquota), null)		as tipoAliquota,
                            COALESCE(sum(ogim.impostaErariale), 0) 	as impostaErariale,
                            MAX(ogim.aliquotaErariale)			as aliquotaErariale,
                            MAX(ogim.aliquotaStd)				as aliquotaStandard,
                            COALESCE(SUM(ogim.addizionaleEca), 0) + coalesce(SUM(ogim.maggiorazioneEca), 0) as addMaggEca,
                            COALESCE(SUM(ogim.addizionalePro), 0) 	AS addPro,
                            COALESCE(sum(ogim.maggiorazioneTares), 0) 		    AS maggiorazioneTares,
                            COALESCE(SUM(ogim.iva), 0) 				AS iva,
                            max(cotr.id) 					as codiceTributo,
                            max(cate.categoria) as categoria,
                            max(tari.tipoTariffa) as tipoTariffa,
                            max(ogpr.consistenza) as consistenza,
							max(nvl(ogpr.tipoOccupazione,'P')) as tipoOccupazione,
                            max(prtr.id) as pratica,
							max(prtr.numero) as numeroPratica,
                            max(tari.descrizione) as descrizioneTariffa,
                            max(cate.descrizione) as descrizioneCategoria,
                            sum(nvl(ogim.importoPf,0)) as importoPf,
                            sum(nvl(ogim.importoPv,0)) as importoPv
                            )
                        FROM
                            Contribuente AS cont,
                            OggettoPratica AS ogpr                
                                LEFT JOIN	ogpr.codiceTributo	 AS cotr       
                                INNER JOIN	ogpr.pratica		 AS prtr       
                                INNER JOIN	prtr.rapportiTributo AS ratr       
                                INNER JOIN	cont.soggetto		 AS sogg       
                                INNER JOIN	ogpr.oggetto 		 AS ogge       
                                LEFT JOIN	ogge.archivioVie 	 AS arvi        
                                INNER JOIN	ogpr.oggettiContribuente AS ogco                          
                                INNER JOIN	ogco.oggettiImposta 	AS ogim
                                LEFT JOIN  ogim.tipoAliquota		AS tial 
                                LEFT JOIN ogpr.categoria	as cate
                                LEFT JOIN ogpr.tariffa 	as tari
                                ${tipoTributo != 'TARSU' ? '' : 'LEFT JOIN ogim.ruolo as ruolo'}
                        WHERE
                                ogco.contribuente.codFiscale = :pCodiceFiscale       
                            AND ogim.anno = :pAnno       
                            AND cont.codFiscale = :pCodiceFiscale       
                            AND ratr.contribuente.codFiscale = :pCodiceFiscale       
                            AND (
                                    prtr.tipoPratica   = 'D'                      
                                OR (
                                        prtr.tipoPratica    = 'A'                       
                                    and ogim.anno > prtr.anno         
                                )        
                            )        
                            AND (
                                prtr.tipoPratica || '' in (:pTipoPratica) or 
                                (prtr.tipoPratica || '' in ('A') and prtr.flagDenuncia = 'S')
                            )        
                            AND ogim.tipoTributo || '' in (:pTipoTributo)
                            
                            ${
            tipoTributo != 'TARSU' ?
                    '' :
                    """AND (ruolo.id IS NULL OR (ruolo.id IS NOT NULL AND ruolo.invioConsorzio IS NOT NULL))
                            AND nvl(ogim.ruolo, -1) = nvl(nvl(f_ruolo_totale(ogim.oggettoContribuente.contribuente.codFiscale,
                                                                            ogim.anno,
                                                                            prtr.tipoTributo,
                                                                            -1),
                                                             ogim.ruolo),
                                                         -1)"""

        }
                        GROUP BY
                            ogge.annoCatasto,
                            prtr.tipoTributo.tipoTributo,
                            prtr.tipoPratica.tipoPratica,
                            cotr.flagRuolo,
                            ogpr.oggetto.id
		"""

        if (tipoTributo in ['CUNI']) {
            sql += """
                ORDER BY
                    6,4,7,
					45 desc,41,42,43
			"""
        } else {
            sql += """
                ORDER BY
                    6,4,7
			"""
        }

        lista = PraticaTributo.executeQuery(sql, parametriQuery)

        lista.each {
            it.aliquota = it.aliquota as BigDecimal
            def hasAliquoteMultipleOnOggettiImposte = it.aliquotaCount > 1
            def hasAliquoteMultipleOnOggettiOgim = it.aliquotaCount == 0 && it.aliquota == null && it.tipoAliquota == null
            it.hasAliquoteMultiple = hasAliquoteMultipleOnOggettiImposte || hasAliquoteMultipleOnOggettiOgim
            it.hasAliquoteMultipleOnOggettiOgim = hasAliquoteMultipleOnOggettiOgim
            it.quotaFissa = it.importoPf
            it.quotaVariale = it.importoPv
        }

        def carichiTarsu = OggettiCache.CARICHI_TARSU.valore.find { ct -> ct.anno == anno }

        lista.findAll {
            it.tipoTributo == 'TARSU' &&
                    (it.maggiorazioneTares + it.addMaggEca + it.addPro + it.iva == 0)
        }.each {
            if (it.addMaggEca + it.addPro + it.maggiorazioneTares + it.iva == 0) {

                it.addMaggEca = it.imposta * (((carichiTarsu?.addizionaleEca ?: 0) / 100) + ((carichiTarsu?.maggiorazioneEca ?: 0) / 100))
                it.addPro = it.imposta * ((carichiTarsu?.addizionalePro ?: 0) / 100)
                it.iva = it.imposta * ((carichiTarsu?.ivaFattura ?: 0) / 100)
                it.maggiorazioneTares = it.imposta * ((carichiTarsu?.maggiorazioneTares ?: 0) / 100)
            }
        }

        lista.findAll {
            it.tipoTributo in ['ICI', 'TASI']
        }.each {
            it.descrizioneALiquota = it.aliquotaCount == 1 ?
                    TipoAliquota.findByTipoTributoAndTipoAliquota(TipoTributo.get(it.tipoTributo), it.tipoAliquota)?.descrizione
                    : null
        }

        return lista
    }

    def getElencoAliquote(def oggettoImposta, def filter) {
        def aliquote = []
        if (oggettoImposta.hasAliquoteMultipleOnOggettiOgim) {
            def oggettiOgimCorrelati = OggettoOgim.executeQuery("""
                select ogoc
                from OggettoOgim ogoc
                where ogoc.contribuente.codFiscale = :pCodFiscale
                    and ogoc.anno = :pAnno
                    and ogoc.tipoAliquota.tipoTributo.tipoTributo = :pTipoTributo
                    and ogoc.oggettoPratica.oggetto.id = :pOggetto""",
                    [pCodFiscale : filter.codFiscale,
                     pAnno       : filter.anno,
                     pTipoTributo: filter.tipoTributo,
                     pOggetto    : oggettoImposta.oggetto]
            ).findAll { it.oggettoPratica.any { it.oggettiContribuente.any { it.oggettiImposta.any { it.flagCalcolo } } } }

            aliquote = oggettiOgimCorrelati.collect { it ->
                [aliquota    : it.aliquota,
                 tipoAliquota: it.tipoAliquota.tipoAliquota,
                 descrizione : it.tipoAliquota.descrizione]
            }
        } else {
            def oggettiImpostaCorrelati = OggettoImposta.executeQuery("""
                select ogim
                from OggettoImposta ogim
                where ogim.oggettoContribuente.contribuente.codFiscale = :pCodFiscale
                    and ogim.anno = :pAnno
                    and ogim.tipoAliquota.tipoTributo.tipoTributo = :pTipoTributo
                    and ogim.oggettoContribuente.oggettoPratica.oggetto.id = :pOggetto 
                    and ogim.flagCalcolo = true""",
                    [pCodFiscale : filter.codFiscale,
                     pAnno       : filter.anno,
                     pTipoTributo: filter.tipoTributo,
                     pOggetto    : oggettoImposta.oggetto])

            aliquote = oggettiImpostaCorrelati.collect { it ->
                [aliquota    : it.aliquota,
                 tipoAliquota: it.tipoAliquota.tipoAliquota,
                 descrizione : it.tipoAliquota.descrizione]
            }
        }

        return generaTestoElencoAlituote(aliquote)
    }


    private def generaTestoElencoAlituote(List aliquote) {
        DecimalFormat decimalFormat = new DecimalFormat(ALIQUOTA_FORMAT)
        def descrizioniAliquoteList = aliquote.collect { aliquota ->
            "$aliquota.tipoAliquota - $aliquota.descrizione (${decimalFormat.format(aliquota.aliquota)})"
        }
        return descrizioniAliquoteList.join('\n')
    }

    /**
     * Ritorna gli oggetti legati ad un contribuente
     * @param codiceFiscale
     * @param pratica
     * @return
     */
    def oggettiContribuente(def codiceFiscale, def anno) {
        List<TipoOggettoDTO> tipiOggetto = OggettiCache.TIPI_OGGETTO.valore
        List<CategoriaCatastoDTO> categorieCatasto = OggettiCache.CATEGORIE_CATASTO.valore
        if (anno == null || anno == "Tutti") {
            anno = 9999
        }

        def listaOggetti = []
        def listaComponentiSuperficie = ComponentiSuperficie.list().toDTO()
        def parametriQuery = [:]
        parametriQuery.pCodiceFiscale = codiceFiscale
        parametriQuery.pAnno = Integer.valueOf(anno)

        String sql = """
                        SELECT
                            ogco.contribuente.codFiscale
                          , ogco.anno                                                                                        
                          , ogco.tipoRapporto                                                                               
                          , ogco.dataDecorrenza                                                                             
                          , ogco.dataCessazione                                                                             
                          , ogco.mesiPossesso                                                                               
                          , ogpr.tipoCategoria                                                                                  
                          , ogpr.consistenza                                                                                
                          , ogpr.valore                                                                                     
                          , ogpr.id                                                                                         
                          , prtr.tipoTributo.tipoTributo                                                                    
                          , f_descrizione_titr(prtr.tipoTributo, prtr.anno)                                                 
                          , prtr.tipoPratica                                                                                
                          , prtr.tipoEvento                                                                                 
                          , ogge                                                                                            
                          , COALESCE(tiog.tipoOggetto, ogge.tipoOggetto.tipoOggetto)                            
                          , COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto)        
                          , COALESCE(ogpr.classeCatasto, ogge.classeCatasto)                                                
                          , DECODE(prtr.tipoTributo.tipoTributo, 'ICI', ogco.flagPossesso, 'TASI', ogco.flagPossesso, NULL) 
                          , ogco.percPossesso                                                                               
                          , ogco.flagEsclusione                                                                             
                          , ogpr.flagContenzioso                                                                            
                          , prtr.id                                                                                         
                          , ogco.flagAbPrincipale                                                                           
                          , f_ultimo_faso(cont.soggetto.id, :pAnno)                                                         
                          , ogpr.numeroFamiliari                                                                            
                          , ogpr.tipoTariffa
                          , ogpr.codiceTributo.id
                          , ogge.estremiCatasto
                          , ogge.annoCatasto
                          , ogge.protocolloCatasto
                          , ogge.dataCessazione
                          , ogco.contribuente.soggetto.cognomeNome
                          , ogpr.numOrdine
                          , (case when tiog.tipoOggetto in (1, 3, 55)
                                then f_rendita(ogpr.valore, tiog.tipoOggetto, ogpr.anno, COALESCE(ogpr.categoriaCatasto.categoriaCatasto, ogge.categoriaCatasto.categoriaCatasto))
                                else null end),
                          ogpr.immStorico
                        FROM
                            OggettoPratica AS ogpr                
                            INNER JOIN    ogpr.pratica        AS prtr               
                            INNER JOIN    ogpr.oggetto        AS ogge       
                            LEFT JOIN     ogge.archivioVie    AS arvi        
                            INNER JOIN    ogpr.oggettiContribuente    AS ogco                          
                            INNER JOIN    ogco.contribuente    AS cont    
                            LEFT JOIN     ogpr.tipoOggetto as tiog
                        WHERE 
                                ogco.contribuente.codFiscale = :pCodiceFiscale    
                            AND	prtr.tipoPratica.tipoPratica in ('A','D','L')
                            and prtr.flagAnnullamento IS NULL
                            AND COALESCE( TO_NUMBER(TO_CHAR(ogco.dataDecorrenza ,'YYYY')), COALESCE(ogco.anno,0) ) <= :pAnno
                            AND DECODE(prtr.tipoTributo, 'ICI', 
                                             DECODE(ogco.flagPossesso, 'S', 
                                                    ogco.flagPossesso, 
                                                    DECODE(:pAnno, 9999, 'S', prtr.anno, 'S', NULL)
                                             ), 'S') = 'S'
                            AND ogpr.id=f_max_ogpr_cont_ogge( ogge.id
                                        , ogco.contribuente.codFiscale
                                        , prtr.tipoTributo.tipoTributo
                                        , DECODE(:pAnno,9999, '%', prtr.tipoPratica)
                                        , :pAnno
                                        , '%') 
                            ORDER BY ogge.idImmobile, ogge.sezione, ogge.foglio, ogge.numero, ogge.subalterno , ogpr.numOrdine
                        """

        def lista = OggettoPratica.executeQuery(sql, parametriQuery)

        for (oggetto in lista) {
            def oggetti = [:]
            oggetti.codFiscale = oggetto[0]
            oggetti.cognomeNome = oggetto[32]
            oggetti.cfContr = oggetto[0]
            oggetti.anno = oggetto[1]
            oggetti.tipoRapporto = oggetto[2]
            oggetti.dataDecorrenza = oggetto[3]
            oggetti.dataCessazione = oggetto[4]
            oggetti.mesiPossesso = oggetto[5]
            oggetti.categoria = oggetto[6]
            oggetti.consistenza = oggetto[7]
            oggetti.valore = oggetto[8]
            oggetti.oggettoPratica = oggetto[9]
            oggetti.tipoTributo = oggetto[10]
            oggetti.tributoDescrizione = oggetto[11]
            oggetti.tipoPratica = oggetto[12]
            oggetti.tipoEvento = oggetto[13]
            oggetti.indirizzoCompleto = oggetto[14].indirizzo
            oggetti.indirizzo = oggetto[14].archivioVie?.denomUff
            oggetti.numCiv = oggetto[14].numCiv
            oggetti.interno = oggetto[14].interno
            oggetti.scala = oggetto[14].scala
            oggetti.partita = oggetto[14].partita
            oggetti.sezione = oggetto[14].sezione
            oggetti.foglio = oggetto[14].foglio
            oggetti.numero = oggetto[14].numero
            oggetti.subalterno = oggetto[14].subalterno
            oggetti.zona = oggetto[14].zona
            oggetti.oggetto = oggetto[14].id
            oggetti.tipoOggetto = tipiOggetto.find { it.tipoOggetto == oggetto[15] }
            oggetti.categoriaCatasto = categorieCatasto.find { it.categoriaCatasto == oggetto[16] }
            oggetti.classeCatasto = oggetto[17]
            oggetti.flagPossesso = oggetto[18]
            oggetti.percPossesso = oggetto[19]
            oggetti.flagEsclusione = oggetto[20]
            oggetti.flagEsclusioneStr = oggetto[20] ? 'S' : 'N'
            oggetti.flagContenzioso = oggetto[21]
            oggetti.flagContenziosoStr = oggetto[21] ? 'S' : 'N'
            oggetti.pratica = oggetto[22]
            oggetti.flagAbPrincipale = oggetto[23]
            oggetti.flagAbPrincipaleStr = oggetto[23] ? 'S' : 'N'
            oggetti.tipoTariffa = oggetto[26]
            oggetti.tributo = oggetto[27]
            oggetti.estremiCatasto = oggetto[28]
            oggetti.annoCatasto = oggetto[29]
            oggetti.protocolloCatasto = oggetto[30]
            oggetti.dataCessazioneCatasto = oggetto[31]
            oggetti.indirizzoLocalita = oggetto[14].indirizzoLocalita
            oggetti.numOrdine = oggetto[33]
            oggetti.idImmobile = oggetto[14].idImmobile
            oggetti.rendita = oggetto[34]
            oggetti.immStorico = oggetto[35] ? 'S' : 'N'

            if (oggetti.flagAbPrincipale) {
                oggetti.numeroFamiliari = oggetto[24]
            } else {
                if (oggetti.consistenza) {
                    short annoCosu = (parametriQuery.pAnno == 9999) ? Calendar.getInstance().get(Calendar.YEAR) : parametriQuery.pAnno
                    def cosu = listaComponentiSuperficie.find {
                        it.anno == annoCosu && oggetti.consistenza <= it.aConsistenza && oggetti.consistenza >= it.daConsistenza
                    }
                    oggetti.numeroFamiliari = oggetto[25] ?: cosu?.numeroFamiliari
                } else {
                    oggetti.numeroFamiliari = oggetto[25]
                }
            }

            listaOggetti << oggetti
        }

        return listaOggetti
    }

    def anniOggettiContribuente(def codiceFiscale, def tipiTributo, def anniPrescrizione = false) {

        def tipiT = []
        if (tipiTributo.ICI || tipiTributo == null) {
            tipiT << 'ICI'
        }
        if (tipiTributo.TASI || tipiTributo == null) {
            tipiT << 'TASI'
        }
        if (tipiTributo.TARSU || tipiTributo == null) {
            tipiT << 'TARSU'
        }
        if (tipiTributo.ICP || tipiTributo == null) {
            tipiT << 'ICP'
        }
        if (tipiTributo.TOSAP || tipiTributo == null) {
            tipiT << 'TOSAP'
        }

        def listaAnni = OggettoContribuente.createCriteria().list {
            createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)

            projections { property("anno") }

            isNull('prtr.flagAnnullamento')
            eq('contribuente.codFiscale', codiceFiscale)
            'in'('prtr.tipoPratica', ['D', 'A', 'L'])

            if (tipiT.size() > 0) {
                'in'('prtr.tipoTributo.tipoTributo', tipiT)
            }

        }.collect { it }


        def anniParam = commonService.decodificaAnniPresSucc()

        if (anniPrescrizione) {
            def annoCorrente = (new Date()).getYear() + 1900
            def ultimiNAnni = (annoCorrente..annoCorrente - (anniParam.anniPrec - 1))

            // Li trasformo in short per avere un tipo univoco nella lista. La query restituisce un elenco di short.
            ultimiNAnni = ultimiNAnni.collect { it as Short }
            listaAnni += ultimiNAnni
        }

        def maxAnno = listaAnni.max()

        listaAnni += (maxAnno..maxAnno + anniParam.anniSucc)
        listaAnni = listaAnni.collect { it as Short }

        listaAnni.unique().sort { -it }

        listaAnni << "Tutti"
        return listaAnni
    }

    def anniTributo(def codiceFiscale) {
        def listaAnni = OggettoContribuente.createCriteria().list {
            createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)

            projections {
                distinct([
                        "prtr.tipoTributo.tipoTributo",
                        "anno",
                        "prtr.tipoPratica"
                ])
            }

            isNull('prtr.flagAnnullamento')
            eq('contribuente.codFiscale', codiceFiscale)
            'in'('prtr.tipoPratica', ['A', 'D', 'L'])

        }.collect {
            [
                    tributo    : it[0],
                    anno       : it[1],
                    tipoPratica: it[2]
            ]
        }

        return listaAnni
    }

    /**
     * Ritorna gli oggetti di una pratica legata ad un contribuente
     * @param idPratica
     * @param codFiscale
     * @param tipoTributo
     * @return
     */
    def oggettiPraticaContribuente(long idPratica, String codFiscale, String tipoTributo) {

        List<TipoTributoDTO> tipiTributo = OggettiCache.TIPI_TRIBUTO.valore
        List<TipoStatoDTO> tipiStato = OggettiCache.TIPI_STATO.valore

        def lista = []

        if (tipoTributo == 'TASI' || tipoTributo == 'ICI') {
            /*
             * utilizzo due query per migliorare le prestazioni.
             * la query potrebbe essere unita facendo una left join sul
             * campo pratica_rif di PraticaTributo per prendere tutte le
             * pratiche "figlie" della T ma in questo modo c'è un full
             * access sulla tabella pratiche_tributo perché la query
             * viene tradotta utilizzando la notazione oracle (+)
             * che non consente l'utilizzo dell'indice in caso di campi nulli.
             * Se venisse utilizzata la notazione ANSI (left join on) la query
             * migliorerebbe le prestazioni.
             */
            def listaNonT = OggettoPratica.createCriteria().list {
                createAlias("pratica", "prtr1", CriteriaSpecification.INNER_JOIN)
                createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
                createAlias("ogg.archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)


                projections {
                    property("ogg.id")                    // 0
                    property("ogg.tipoOggetto.tipoOggetto")    // 1
                    property("ogg.indirizzoLocalita")    // 2
                    property("ogg.numCiv")                // 3
                    property("ogg.suffisso")            // 4
                    property("ogg.archivioVie")            // 5
                    property("ogco.percPossesso")        // 6
                    property("valore")                    // 7
                    property("ogco.flagPossesso")        // 8
                    property("ogco.flagAbPrincipale")    // 9
                    property("categoriaCatasto")    // 10
                    property("classeCatasto")        // 11
                    property("ogg.categoriaCatasto")    // 12
                    property("ogg.classeCatasto")        // 13
                    property("ogg.sezione")        // 14
                    property("ogg.foglio")        // 15
                    property("ogg.numero")        // 16
                    property("ogg.subalterno")        // 17
                    property("ogg.zona")        // 18
                    property("ogg.protocolloCatasto")        // 19
                    property("ogg.annoCatasto")        // 20
                    property("ogg.partita")        // 21
                    property("ogco.mesiPossesso") // 22
                    property("ogco.mesiEsclusione") //23
                    property("ogco.mesiRiduzione") // 24
                    property("ogco.flagEsclusione") // 25
                    property("ogco.flagRiduzione") // 26
                    property("flagProvvisorio") // 27
                    property("ogco.detrazione") // 28
                    property("prtr1.anno")
                }
                eq("prtr1.id", idPratica)
                eq("ogco.contribuente.codFiscale", codFiscale)
                ne("prtr1.tipoEvento", TipoEventoDenuncia.T)
            }.collect { row ->
                [id                 : row[0]
                 , tipoOggetto      : row[1]
                 , indirizzo        : (row[5] ? row[5].denomUff : row[2] ?: "") + (row[3] ? ", ${row[3]}" : "") + (row[4] ? "/ ${row[4]}" : "")
                 , categoriaCatasto : row[10] ? row[10].categoriaCatasto : row[12]?.categoriaCatasto
                 , classeCatasto    : row[11] ?: row[13]
                 , valore           : row[7]
                 , percPossesso     : row[6]
                 , flagPossesso     : row[8]
                 , flagAbPrincipale : row[9]
                 , sezione          : row[14]
                 , foglio           : row[15]
                 , numero           : row[16]
                 , subalterno       : row[17]
                 , zona             : row[18]
                 , protocolloCatasto: row[19]
                 , annoCatasto      : row[20]
                 , partita          : row[21]
                 , mesiPossesso     : row[22]
                 , mesiEsclusione   : row[23]
                 , mesiRiduzione    : row[24]
                 , flagEsclusione   : row[25]
                 , flagRiduzione    : row[26]
                 , flagProvvisorio  : row[27]
                 , detrazione       : row[28]
                 , anno             : row[29]
                ]
            }

            def listaT = OggettoPratica.createCriteria().list {
                createAlias("pratica", "prtr1", CriteriaSpecification.INNER_JOIN)
                createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
                createAlias("ogg.archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)
                createAlias("prtr1.praticaTributoRif", "prtr2", CriteriaSpecification.INNER_JOIN)

                projections {
                    property("ogg.id")                    // 0
                    property("ogg.tipoOggetto.tipoOggetto")    // 1
                    property("ogg.indirizzoLocalita")    // 2
                    property("ogg.numCiv")                // 3
                    property("ogg.suffisso")            // 4
                    property("ogg.archivioVie")            // 5
                    property("ogco.percPossesso")        // 6
                    property("valore")                    // 7
                    property("ogco.flagPossesso")        // 8
                    property("ogco.flagAbPrincipale")    // 9
                    property("categoriaCatasto")    // 10
                    property("classeCatasto")        // 11
                    property("ogg.categoriaCatasto")    // 12
                    property("ogg.classeCatasto")        // 13
                    property("ogg.sezione")        // 14
                    property("ogg.foglio")        // 15
                    property("ogg.numero")        // 16
                    property("ogg.subalterno")        // 17
                    property("ogg.zona")        // 18
                    property("ogg.protocolloCatasto")        // 19
                    property("ogg.annoCatasto")        // 20
                    property("ogg.partita")        // 21
                    property("ogco.mesiPossesso") // 22
                    property("ogco.mesiEsclusione") //23
                    property("ogco.mesiRiduzione") // 24
                    property("ogco.flagEsclusione") // 25
                    property("ogco.flagRiduzione") // 26
                    property("flagProvvisorio") // 27
                    property("ogco.detrazione") // 28
                    property("prtr1.anno") // 29
                }

                eq("prtr2.id", idPratica)
                eq("ogco.contribuente.codFiscale", codFiscale)
                ne("prtr1.tipoEvento", TipoEventoDenuncia.T)
                eq("prtr2.tipoEvento", TipoEventoDenuncia.T)
            }.collect { row ->
                [id                 : row[0]
                 , tipoOggetto      : row[1]
                 , indirizzo        : (row[5] ? row[5].denomUff : row[2] ?: "") + (row[3] ? ", ${row[3]}" : "") + (row[4] ? "/ ${row[4]}" : "")
                 , categoriaCatasto : row[10] ? row[10].categoriaCatasto : row[12]?.categoriaCatasto
                 , classeCatasto    : row[11] ?: row[13]
                 , valore           : row[7]
                 , percPossesso     : row[6]
                 , flagPossesso     : row[8]
                 , flagAbPrincipale : row[9]
                 , sezione          : row[14]
                 , foglio           : row[15]
                 , numero           : row[16]
                 , subalterno       : row[17]
                 , zona             : row[18]
                 , protocolloCatasto: row[19]
                 , annoCatasto      : row[20]
                 , partita          : row[21]
                 , mesiPossesso     : row[22]
                 , mesiEsclusione   : row[23]
                 , mesiRiduzione    : row[24]
                 , flagEsclusione   : row[25]
                 , flagRiduzione    : row[26]
                 , flagProvvisorio  : row[27]
                 , detrazione       : row[28]
                 , anno             : row[29]
                ]
            }
            lista = listaNonT + listaT

            lista.each { it ->
                if (it.tipoOggetto in [1L, 3L, 55L]) {
                    it.rendita = oggettiService.getRenditaOggettoPratica(it.valore, it.tipoOggetto, it.anno, CategoriaCatasto.get(it.categoriaCatasto)?.toDTO())
                }
            }

        } else if (tipoTributo in ['TARSU', 'ICP', 'TOSAP', 'CUNI']) {
            def listaNonT = OggettoPratica.createCriteria().list {
                createAlias("pratica", "prtr", CriteriaSpecification.INNER_JOIN)
                createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
                createAlias("tariffa", "tari", CriteriaSpecification.INNER_JOIN)
                createAlias("ogg.archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)
                createAlias("prtr.rapportiTributo", "ratr", CriteriaSpecification.INNER_JOIN)
                createAlias("prtr.tipoTributo", "titr", CriteriaSpecification.INNER_JOIN)
                createAlias("prtr.tipoStato", "tist", CriteriaSpecification.LEFT_JOIN)
                createAlias("ratr.contribuente", "cont", CriteriaSpecification.INNER_JOIN)
                createAlias("cont.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
                createAlias("sogg.archivioVie", "avre", CriteriaSpecification.LEFT_JOIN)
                createAlias("sogg.comuneResidenza", "core", CriteriaSpecification.LEFT_JOIN)
                createAlias("core.ad4Comune", "adre", CriteriaSpecification.LEFT_JOIN)
                createAlias("adre.provincia", "prre", CriteriaSpecification.LEFT_JOIN)
                createAlias("adre.stato", "stre", CriteriaSpecification.LEFT_JOIN)

                projections {
                    property("ogg.id")                    // 0
                    property("ogg.tipoOggetto.tipoOggetto")    // 1
                    property("ogg.indirizzoLocalita")    // 2
                    property("ogg.numCiv")                // 3
                    property("ogg.suffisso")            // 4
                    property("ogg.archivioVie")            // 5
                    property("ogco.percPossesso")        // 6
                    property("valore")                    // 7
                    property("ogco.flagPossesso")        // 8
                    property("ogco.flagAbPrincipale")    // 9
                    property("categoriaCatasto")    // 10
                    property("classeCatasto")        // 11
                    property("tariffa")                    // 12
                    property("ogco.inizioOccupazione")    // 13
                    property("ogco.fineOccupazione")    // 14
                    property("ogco.detrazione")        // 15
                    property("consistenza")                // 16
                    property("ogg.categoriaCatasto")    // 17
                    property("ogg.classeCatasto")        // 18
                    property("ogco.dataDecorrenza")        // 19
                    property("ogco.dataCessazione")        // 20
                    property("codiceTributo")        // 21
                    property("categoria")        // 22
                    property("tipoTariffa")        // 23
                    property("ogg.sezione")        // 24
                    property("ogg.foglio")        // 25
                    property("ogg.numero")        // 26
                    property("ogg.subalterno")        // 27

                    property("tipoOccupazione")            // 28
                    property("consistenzaReale")        // 29
                    property("larghezza")                // 30
                    property("profondita")                // 31
                    property("quantita")                // 32
                    property("ogco.percPossesso")        // 33
                    property("inizioConcessione")        // 34
                    property("fineConcessione")            // 35
                    property("numConcessione")            // 36
                    property("dataConcessione")            // 37
                    property("flagContenzioso")            // 38
                    property("note")                    // 39

                    property("prtr.id")                    // 40
                    property("prtr.anno")                // 41
                    property("prtr.data")                // 42
                    property("prtr.numero")                // 43
                    property("titr.tipoTributo")        // 44
                    property("ratr.tipoRapporto")        // 45
                    property("tist.tipoStato")            // 46
                    property("prtr.dataNotifica")        // 47
                    property("prtr.tipoEvento")            // 48
                    property("prtr.tipoPratica")        // 49
                    property("prtr.flagAnnullamento")    // 50
                    property("prtr.flagDePag")            // 51
                    property("cont.codFiscale")            // 52
                    property("prtr.motivo")            // 53
                    property("prtr.note")            // 54

                    property("cont.codFiscale")         // 55
                    property("sogg.cognomeNome")        // 56
                    property("adre.denominazione")        // 57
                    property("prre.sigla")                // 58
                    property("stre.sigla")                // 59
                    property("sogg.denominazioneVia")    // 60
                    property("sogg.numCiv")                // 61
                    property("sogg.suffisso")            // 62
                    property("avre.denomUff")            // 63

                    property("prtr.tipoViolazione")        // 64
                    property("prtr.tipoNotifica")        // 65
                }

                eq("prtr.id", idPratica)
                eq("ogco.contribuente.codFiscale", codFiscale)
            }.collect { row ->

                TipoTributoDTO tipoTributoDTO = tipiTributo.find { it.tipoTributo == row[44] }

                String docSuccessivo = denunceService.functionProssimaPratica(row[40], row[55], row[44])
                String praticaSuccessiva = docSuccessivo?.substring(2, docSuccessivo?.length())?.toLong()
                String eventoSuccessivo = docSuccessivo?.substring(0, 1)

                [id                    : row[0]
                 , tipoOggetto         : row[1]
                 , indirizzo           : (row[5] ? row[5].denomUff : row[2] ?: "") + (row[3] ? ", ${row[3]}" : "") + (row[4] ? "/ ${row[4]}" : "")
                 , categoriaCatasto    : row[10] ? row[10]?.categoriaCatasto : row[17]?.categoriaCatasto
                 , classeCatasto       : row[11] ?: row[18]
                 , valore              : row[7]
                 , percPossesso        : row[6]
                 , flagPossesso        : row[8]
                 , flagAbPrincipale    : row[9]
                 , inizioOccupazione   : row[13]
                 , fineOccupazione     : row[14]
                 , detrazione          : row[15]
                 , dataDecorrenza      : row[19]
                 , dataCessazione      : row[20]
                 , sezione             : row[24]
                 , foglio              : row[25]
                 , numero              : row[26]
                 , subalterno          : row[27]

                 , codiceTributo       : row[21]?.id
                 , desCodiceTributo    : (tipoTributo == 'CUNI') ? row[21]?.descrizioneRuolo : row[21]?.descrizione
                 , categoria           : row[22]?.categoria
                 , descrizioneCategoria: row[22]?.descrizione
                 , tipoTariffa         : row[23]
                 , descrizioneTariffa  : row[12]?.descrizione
                 , tariffa             : row[12]?.tariffa
                 , tipoOccupazione     : row[28]?.id
                 , larghezza           : row[30]
                 , profondita          : row[31]
                 , quantita            : row[32]
                 , consistenzaReale    : row[29]
                 , consistenza         : row[16]
                 , percPossesso        : row[33]
                 , inizioConcessione   : row[34]
                 , fineConcessione     : row[35]
                 , numConcessione      : row[36]
                 , dataConcessione     : row[37]
                 , esenzione           : row[38]
                 , noteOgPr            : row[39]

                 , praticaId           : row[40]
                 , anno                : row[41]
                 , data                : row[42]
                 , numeroPratica       : row[43]
                 , tipoTributo         : tipoTributoDTO
                 , desTipoTributo      : tipoTributoDTO.getTipoTributoAttuale(row[41])
                 , tipoRapporto        : row[45]
                 , stato               : (row[46]) ? tipiStato.find { it.tipoStato == row[46] }?.descrizione : ""
                 , dataNotifica        : row[47]
                 , tipoNotifica        : row[65]?.toDTO()
                 , tipoEvento          : row[48]?.id
                 , tipoViolazione      : row[64]
                 , tipoEventoViolazione: row[64] != null ? "${row[48]?.id} - ${row[64]}" : row[48]?.id
                 , tipoPratica         : row[49]
                 , flagAnnullamento    : row[50] ? '(ANN)' : ''
                 , praticaSuccessiva   : praticaSuccessiva != null ? praticaSuccessiva + ' (' + eventoSuccessivo + ')' : ''
                 , flagDePag           : row[51] ? row[51] : 'N'
                 , motivoPrat          : row[53]
                 , notePrat            : row[54]

                 , codFiscale          : row[55]
                 , cognomeNome         : row[56]
                 , indirizzoRes        : (row[63] ?: row[60] ?: "") + (row[61] ? ", ${row[61]} " : "") + (row[62] ? "/${row[62]} " : "")
                 , comuneRes           : row[57]
                 , provinciaRes        : row[58] ?: row[59]
                ]
            }

            def listaT = OggettoPratica.createCriteria().list {
                createAlias("pratica", "prtr1", CriteriaSpecification.INNER_JOIN)
                createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
                createAlias("oggetto", "ogg", CriteriaSpecification.INNER_JOIN)
                createAlias("ogg.archivioVie", "vie", CriteriaSpecification.LEFT_JOIN)
                createAlias("prtr1.praticaTributoRif", "prtr2", CriteriaSpecification.INNER_JOIN)

                projections {
                    property("ogg.id")                    // 0
                    property("ogg.tipoOggetto.tipoOggetto")    // 1
                    property("ogg.indirizzoLocalita")    // 2
                    property("ogg.numCiv")                // 3
                    property("ogg.suffisso")            // 4
                    property("ogg.archivioVie")            // 5
                    property("ogco.percPossesso")        // 6
                    property("valore")                    // 7
                    property("ogco.flagPossesso")        // 8
                    property("ogco.flagAbPrincipale")    // 9
                    property("categoriaCatasto")    // 10
                    property("classeCatasto")        // 11
                    property("tariffa")                    // 12
                    property("ogco.inizioOccupazione")    // 13
                    property("ogco.fineOccupazione")    // 14
                    property("ogco.detrazione")        // 15
                    property("consistenza")                // 16
                    property("ogg.categoriaCatasto")    // 17
                    property("ogg.classeCatasto")        // 18
                    property("ogg.sezione")        // 19
                    property("ogg.foglio")        // 20
                    property("ogg.numero")        // 21
                    property("ogg.subalterno")        // 22
                    property("ogg.zona")        // 23
                    property("ogg.protocolloCatasto")        // 24
                    property("ogg.annoCatasto")        // 25
                    property("ogg.partita")        // 26
                    property("ogco.mesiPossesso") // 27
                    property("ogco.mesiEsclusione") //28
                    property("ogco.mesiRiduzione") // 29
                    property("ogco.flagEsclusione") // 30
                    property("ogco.flagRiduzione") // 31
                    property("flagProvvisorio") // 32
                    property("ogco.detrazione") // 33
                    property("ogco.dataDecorrenza")        // 34
                    property("ogco.dataCessazione")        // 35
                    property("codiceTributo")        // 36
                    property("categoria")        // 37
                    property("tipoTariffa")        // 38
                }

                eq("prtr2.id", idPratica)
                eq("ogco.contribuente.codFiscale", codFiscale)
                ne("prtr1.tipoEvento", TipoEventoDenuncia.T)
                eq("prtr2.tipoEvento", TipoEventoDenuncia.T)
            }.collect { row ->
                [id                  : row[0]
                 , tipoOggetto       : row[1]
                 , indirizzo         : (row[5] ? row[5].denomUff : row[2] ?: "") + (row[3] ? ", ${row[3]}" : "") + (row[4] ? "/ ${row[4]}" : "")
                 , categoriaCatasto  : row[10] ? row[10]?.categoriaCatasto : row[17]?.categoriaCatasto
                 , classeCatasto     : row[11] ?: row[18]
                 , valore            : row[7]
                 , percPossesso      : row[6]
                 , flagPossesso      : row[8]
                 , flagAbPrincipale  : row[9]
                 , descrizioneTariffa: row[12]?.descrizione
                 , tariffa           : row[12]?.tariffa
                 , inizioOccupazione : row[13]
                 , fineOccupazione   : row[14]
                 , detrazione        : row[15]
                 , consistenza       : row[16]
                 , sezione           : row[19]
                 , foglio            : row[20]
                 , numero            : row[21]
                 , subalterno        : row[22]
                 , zona              : row[23]
                 , protocolloCatasto : row[24]
                 , annoCatasto       : row[25]
                 , partita           : row[26]
                 , mesiPossesso      : row[27]
                 , mesiEsclusione    : row[28]
                 , mesiRiduzione     : row[29]
                 , flagEsclusione    : row[30]
                 , flagRiduzione     : row[31]
                 , flagProvvisorio   : row[32]
                 , detrazione        : row[33]
                 , dataDecorrenza    : row[34]
                 , dataCessazione    : row[35]
                 , codiceTributo     : row[36]?.id
                 , categoria         : row[37]?.categoria
                 , tipoTariffa       : row[38]

                ]
            }

            lista = listaNonT + listaT
        }

        return lista
    }

    def listaContribuentiBandbox(def contribuente, int pageSize, int activePage) {
        PagedResultList elencoContribuenti = Contribuente.createCriteria().list(max: pageSize, offset: pageSize * activePage) {
            if (contribuente.codFiscale) {
                // se sto cercando i contribuenti devo filtrare sulla proprietà
                // codice fiscale della domain contribuente
                ilike("codFiscale", contribuente.codFiscale + "%")
            }
            if (contribuente.soggetto && contribuente.soggetto.cognomeNome) {
                createAlias("soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
                ilike("sogg.cognomeNome", contribuente.soggetto.cognomeNome + "%")
            }

            fetchMode("soggetto", FetchMode.JOIN)
            order("codFiscale", "asc")
        }
        return [lista: elencoContribuenti.list.toDTO(), totale: elencoContribuenti.totalCount]
    }

    /**
     * Ritorna le pratiche di un oggetto legato ad un contribuente
     * @param codiceFiscale
     * @param oggetto
     * @param tipoTributo
     * @return
     */
    def praticheOggettoContribuente(def pOggetto, def pCodiceFiscale, def pTipoTributo) {
        return praticheOggettoContribuente(pOggetto, pCodiceFiscale, pTipoTributo, null, null).lista
    }

    /**
     * Ritorna le pratiche di un oggetto
     * @param codiceFiscale se specificato vengono selezionate soltanto le pratiche solo per quel contribuente
     * @param oggetto
     * @param tipoTributo se specificato vengono selezionate soltanto le pratiche per quel tipo di tributo
     * @param listaTributi indica la lista dei tipi di tributi selezionati (ad esempio: ['IMU','TASI','TARSU','ICP','TOSAP'])
     * @param listaPratiche indica la lista delle pratiche selezionate (ad esempio: ['D','L','A','V'])
     * @return
     */
    def praticheOggettoContribuente(def pOggetto, def pCodiceFiscale, def pTipoTributo, def listaTributi, def listaPratiche) {
        List<TipoTributoDTO> tipiTributo = OggettiCache.TIPI_TRIBUTO.valore

        def lista = OggettoPratica.createCriteria().list {
            createAlias("oggetto", "ogge", CriteriaSpecification.INNER_JOIN)
            createAlias("pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("prtr.contribuente", "cont", CriteriaSpecification.INNER_JOIN)
            createAlias("cont.soggetto", "sogg", CriteriaSpecification.INNER_JOIN)
            createAlias("prtr.rapportiTributo", "ratr", CriteriaSpecification.LEFT_JOIN)
            createAlias("prtr.tipoStato", "tist", CriteriaSpecification.LEFT_JOIN)
            createAlias("oggettiContribuente", "ogco", CriteriaSpecification.LEFT_JOIN)

            projections {
                distinct("prtr.id")                            // 0
                property("prtr.tipoTributo.tipoTributo")    // 1
                property("prtr.anno")                        // 2
                property("prtr.tipoPratica")                // 3
                property("prtr.tipoEvento")                    // 4
                property("prtr.data")                        // 5
                property("prtr.numero")                        // 6
                property("prtr.dataNotifica")                // 7
                property("sogg.cognomeNome")                // 8
                property("cont.soggetto.id")                // 9
                property("ratr.tipoRapporto")                // 10
                property("tist.descrizione")                // 11
                property("ogge.id")                            // 12
                property("prtr.flagAnnullamento")                // 13
                property("prtr.importoTotale")                    //14
                property("cont.codFiscale")                    //15
                property("prtr.tipoNotifica")                    //16
                property("prtr.tipoViolazione")                    //17
            }

            eqProperty("ratr.contribuente.codFiscale", "ogco.contribuente.codFiscale")
            //Controllo sulle liste pratiche selezionate
            if (listaPratiche) {
                if (listaPratiche.size() > 0) {
                    or {
                        for (pratica in listaPratiche) {
                            eq("prtr.tipoPratica", pratica)
                        }
                    }
                } else
                    ne("prtr.tipoPratica", "K")
            } else
                ne("prtr.tipoPratica", "K")

            eq("oggetto.id", (long) pOggetto)

            if (pCodiceFiscale)
                eq("ratr.contribuente.codFiscale", pCodiceFiscale)

            if (pTipoTributo)
                eq("prtr.tipoTributo.tipoTributo", pTipoTributo)
            else {
                if (listaTributi.size() > 0) {
                    or {
                        for (tipo in listaTributi) {
                            eq("prtr.tipoTributo.tipoTributo", tipo)
                        }
                    }
                } else
                    eq("prtr.tipoTributo.tipoTributo", "")
            }

            or {
                eq("ratr.tipoRapporto", "D")
                eq("ratr.tipoRapporto", "A")
                eq("ratr.tipoRapporto", "E")
                eq("ratr.tipoRapporto", "C")
                isNull("ratr.tipoRapporto")
            }

            order("prtr.tipoTributo.tipoTributo", "asc")
            order("prtr.anno", "desc")
            order("prtr.tipoPratica", "asc")
        }.collect { row ->

            String docSuccessivo
            if (pCodiceFiscale) {
                docSuccessivo = denunceService.functionProssimaPratica(row[0], pCodiceFiscale, row[1])
            } else {
                docSuccessivo = denunceService.functionProssimaPratica(row[0], row[15], row[1])
            }

            // Il toLong permette di eliminare la sequenza di 0 iniziali
            String praticaSuccessiva = docSuccessivo?.substring(2, docSuccessivo?.length())?.toLong()
            String eventoSuccessivo = docSuccessivo?.substring(0, 1)

            def tipoViolazione = [
                    ID: 'Infedele Denuncia',
                    OD: 'Omessa Denuncia'
            ]

            [pratica                      : row[0]
             , tipoTributo                : tipiTributo.find { it.tipoTributo == row[1] }
             , anno                       : row[2]
             , tipoPratica                : row[3]
             , tipoEvento                 : row[4]
             , data                       : row[5]
             , numero                     : row[6]
             , dataNotifica               : row[7]
             , stato                      : row[11]
             , codiceFiscale              : (pCodiceFiscale) ? pCodiceFiscale : row[15]
             , nome                       : row[8]
             , tipoRapporto               : row[10]
             , ni                         : row[9]
             , id                         : row[0]
             , oggetto                    : row[12]
             , flagAnnullamento           : row[13] ? '(ANN)' : ''
             , praticaSuccessiva          : praticaSuccessiva != null ? praticaSuccessiva + ' (' + eventoSuccessivo + ')' : ''
             , descrizioneTributo         : (tipiTributo.find { it.tipoTributo == row[1] }).getTipoTributoAttuale(row[2])
             , importoTotale              : row[14] ?: 0
             , tipoNotifica               : row[16]
             , tipoViolazione             : row[17]
             , tipoEventoViolazione       : row[17] != null ? "${row[4]} - ${row[17]}" : row[4]
             , tipoEventoViolazioneTooltip: row[17] != null ? "${row[4]} - ${tipoViolazione[row[17]]}" : ''
            ]
        }

        def tributiPratiche = [
                ICI  : false,
                TASI : false,
                TARSU: false,
                ICP  : false,
                TOSAP: false,
                CUNI : false,
                D    : false,
                A    : false,
                L    : false,
                V    : false
        ]

        lista.each {
            // Tributi attivi
            tributiPratiche.ICI |= (it.tipoTributo.tipoTributo == "ICI" || it.tipoTributo.tipoTributo == "IMU")
            tributiPratiche.TASI |= (it.tipoTributo.tipoTributo == "TASI")
            tributiPratiche.TARSU |= (it.tipoTributo.tipoTributo == "TARSU")
            tributiPratiche.ICP |= (it.tipoTributo.tipoTributo == "ICP")
            tributiPratiche.TOSAP |= (it.tipoTributo.tipoTributo == "TOSAP")
            tributiPratiche.CUNI |= (it.tipoTributo.tipoTributo == "CUNI")
            // Pratiche attive
            tributiPratiche.D |= (it.tipoPratica == "D")
            tributiPratiche.A |= (it.tipoPratica == "A")
            tributiPratiche.L |= (it.tipoPratica == "L")
            tributiPratiche.V |= (it.tipoPratica == "V")
        }
        return [tributiPratiche: tributiPratiche, lista: lista]
    }


    def getRuoliOggettoContribuente(
            def tipoTributo, def cfContribuente, def idOggetto, def idpratica, def oggettoPratica) {

        def listaRuoli = []
        def parametriQuery = [:]
        parametriQuery.pTipoTributo = tipoTributo
        parametriQuery.pCfContribuente = cfContribuente
        parametriQuery.pIdOggetto = idOggetto as Long
        parametriQuery.pIdpratica = idpratica as Long
        parametriQuery.pOggPratica = oggettoPratica


        String sql = """SELECT
                            r.id,
                            r.tipoTributo.tipoTributo,
                            r.annoRuolo,
                            r.dataEmissione,
                            r.invioConsorzio,
                            ro.importo,
                            rc.sequenza,
                            rc.contribuente.codFiscale,
                            r.tipoRuolo,
                            r.annoEmissione,
                            r.progrEmissione,
                            ro.codiceTributo,
                            r.importoLordo,
                            rc.mesiRuolo,
                            rc.giorniRuolo,
                            r.id,
                            r.specieRuolo,
                            r.tipoEmissione,
                            sg.importo,
                            r.flagDePag,
                            r.progrEmissione,
                            r.importoLordo,
                            ro.mesiRuolo
                        FROM
                            RuoloOggetto AS ro
                                INNER JOIN ro.ruoloContribuente AS rc
                                LEFT JOIN rc.sgravi AS sg
                                INNER JOIN ro.ruolo AS r    
                        WHERE
                            (r.tipoTributo.tipoTributo = :pTipoTributo) AND
                            (rc.contribuente.codFiscale = :pCfContribuente) AND
                            (ro.oggetto.id = :pIdOggetto or ro.pratica.id = :pIdpratica) AND
                            (:pOggPratica is not null)
                        ORDER BY
                            r.annoRuolo ASC,
                            r.dataEmissione ASC,
                            r.invioConsorzio ASC """

        listaRuoli = RuoloOggetto.executeQuery(sql, parametriQuery)

        def listaRuoliOggetto = []
        for (ruogg in listaRuoli) {
            def ruoloOggetto = [:]
            ruoloOggetto.id = ruogg[0]
            ruoloOggetto.tipoTributo = ruogg[1]
            ruoloOggetto.annoRuolo = ruogg[2]
            ruoloOggetto.dataEmissione = ruogg[3]
            ruoloOggetto.invioConsorzio = ruogg[4]
            ruoloOggetto.importoRuoloContribuente = ruogg[5]
            ruoloOggetto.sequenza = ruogg[6]
            ruoloOggetto.codFiscale = ruogg[7]
            ruoloOggetto.tipoRuolo = ruogg[8] == 1 ? 'P' : 'S'
            ruoloOggetto.annoEmissione = ruogg[9]
            ruoloOggetto.progrEmissione = ruogg[10]
            ruoloOggetto.codiceTributo = ruogg[11]?.id
            ruoloOggetto.importoLordo = ruogg[12]
            ruoloOggetto.mesiRuolo = ruogg[13]
            ruoloOggetto.giorniRuolo = ruogg[14]
            ruoloOggetto.ruolo = ruogg[15]
            ruoloOggetto.specie = ruogg[16] ? 1 : 0
            ruoloOggetto.tipoEmissione = ruogg[17] == 'A' ? "Acconto" : ruogg[17] == 'S' ? "Saldo" : ruogg[17] == 'T' ? 'Totale' : ''
            ruoloOggetto.importoSgravio = ruogg[18]
            ruoloOggetto.flagDepag = ruogg[19] == 'S'
            ruoloOggetto.progrEmissione = ruogg[20]
            ruoloOggetto.importoLordo = ruogg[21] == 'S'
            ruoloOggetto.mesiRuolo = ruogg[22]

            ruoloOggetto.sgravio = RuoloContribuente.createCriteria().list {
                eq("contribuente.codFiscale", ruogg[7])
                eq("ruolo.id", ruogg[0])
            }?.sgravi?.flatten().sum { it.importo }

            listaRuoliOggetto << ruoloOggetto
        }

        return listaRuoliOggetto

    }

    def getSgraviOggettoContribuente(def ruolo, def contribuente, def sequenza) {

        def listaSgravi = []
        def parametriQuery = [:]
        parametriQuery.pRuolo = (Long) ruolo
        parametriQuery.pContribuente = contribuente
        parametriQuery.pSequenza = sequenza

        String sql = """
                        SELECT new Map(
                            decode(s.tipoSgravio, 'S', 'Sgravio', 
                                                  'D', 'Discarico',
                                                  'R', 'Rimborso',
                                                  '') AS tipoSgravio,
                            so.ruoloContribuente.numeroCartella AS numeroCartella,
                            so.ruoloContribuente.dataCartella AS dataCartella,
                            s.numRuolo AS numRuolo,
                            s.codConcessione AS codConcessione,
                            s.numeroElenco	AS numeroElenco,
                            s.motivoSgravio	AS motivoSgravio,
                            s.dataElenco 	AS dataElenco,
                            s.importo		AS importo,
                            COALESCE(s.addizionaleEca, 0) + COALESCE(s.maggiorazioneEca, 0) AS eca,
                            COALESCE(s.addizionalePro, 0) as provinciale,
                            COALESCE(s.iva) AS iva,
                            s.flagAutomatico	AS flagAutomatico,
                            so.imposta			AS imposta,
                            s.addizionaleEca	AS addizionaleEca,
                            s.maggiorazioneTares	AS maggiorazioneTares,
                            s.iva					AS iva,
                            s.semestri				AS semestri,
                            s.mesiSgravio			AS mesiSgravio,
                            s.giorniSgravio			AS giorniSgravio,
                            s.importo - COALESCE(s.addizionaleEca, 0) 
                                      - COALESCE(s.maggiorazioneEca, 0) 
                                      - COALESCE(s.addizionalePro, 0) 
                                      - COALESCE(s.iva) 
                                      - COALESCE(s.maggiorazioneTares, 0) AS nettoSgravio)
                        FROM
                            Sgravio s,
                            Ruolo r,
                            SgraviOggetto so
                        WHERE
                                s.ruoloContribuente = so.ruoloContribuente
                            AND s.sequenzaSgravio = so.sequenzaSgravio
                            AND s.ruoloContribuente.ruolo.id  = r.id 
                            AND so.ruoloContribuente.ruolo.id = :pRuolo
                            AND so.ruoloContribuente.contribuente.codFiscale = :pContribuente
                            AND so.ruoloContribuente.sequenza = :pSequenza
                        ORDER BY
                            s.sequenzaSgravio """

        listaSgravi = Sgravio.executeQuery(sql, parametriQuery)
    }

    def calcolaAnni(long idOggetto) {

        def lista = OggettoPratica.createCriteria().list {
            createAlias("pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiContribuente", "contr", CriteriaSpecification.INNER_JOIN)

            projections { distinct("contr.anno") }

            eq("oggetto.id", idOggetto)
            'in'("prtr.tipoPratica", ['A', 'D'])
            eq("prtr.tipoTributo.tipoTributo", 'ICI')

            order("contr.anno", "desc")
        }.reverse().collect { it as String }

        lista << "Tutti"
    }

    def tributiSostituzioneOggetto(String codiceFiscale, long oggetto, long tipoOggetto) {

        def parametriQuery = [:]
        parametriQuery.pCodiceFiscale = codiceFiscale
        parametriQuery.pOggetto = oggetto
        parametriQuery.pTipoOggetto = tipoOggetto
        parametriQuery.pAnno = (new Date())[Calendar.YEAR]

        String sql = """
                            SELECT new Map(
                                prtr.tipoTributo.tipoTributo AS tipoTributo,
                                f_descrizione_titr(prtr.tipoTributo.tipoTributo, :pAnno) || ' - ' 
                                        ||  prtr.tipoTributo.descrizione AS descrizioneTipoTributo 
                                )
                            FROM
                                PraticaTributo AS prtr
                                INNER JOIN prtr.rapportiTributo ratr
                                INNER JOIN prtr.oggettiPratica ogpr
                            WHERE
                                ratr.contribuente.codFiscale = :pCodiceFiscale AND
                                ogpr.tipoOggetto.tipoOggetto = :pTipoOggetto AND
                                ogpr.oggetto.id = :pOggetto
                            ORDER BY prtr.tipoTributo.tipoTributo
                        """

        def lista = PraticaTributo.executeQuery(sql, parametriQuery)

        def generico = [:]
        generico.tipoTributo = "%"
        generico.descrizioneTipoTributo = "Tutti"
        lista << generico

        return lista

    }

    /**
     * Ritorna l'elenco delle pratiche e dei proprietari di un oggetto
     * recuperati delle dichiarazioni ICI ad un determinato anno
     *
     * @param idOggetto
     * @param anno
     * @return
     */
    def getProprietari(def idOggetto, def anno) {
        def listaProprietari = []
        def parametriQuery = [:]
        parametriQuery.pIdOggetto = (Long) idOggetto

        String sql = """
                                SELECT
                                      oggContr
                                    , contr.codFiscale
                                    , oggPrt.valore
                                    , prtTrb.id
                                    , sogg.cognomeNome
                                    , oggPrt.flagProvvisorio
                                    , sogg.dataNas
                                    , comuneTr4.ad4Comune.denominazione
                                    , oggPrt.numOrdine
                                FROM
                                    Contribuente AS contr
                                        INNER JOIN contr.soggetto as sogg
                                        LEFT JOIN sogg.comuneNascita comuneTr4
                                        INNER JOIN contr.oggettiContribuente as oggContr
                                        INNER JOIN oggContr.oggettoPratica as oggPrt
                                        INNER JOIN oggPrt.pratica as prtTrb
                                        LEFT JOIN prtTrb.rapportiTributo as rappTrb
                                        INNER JOIN oggPrt.oggetto as ogg    
                                        LEFT JOIN ogg.archivioVie as archVie
                                WHERE
                                        prtTrb.tipoPratica IN ('D', 'A') 
                                    AND    prtTrb.tipoTributo = 'ICI' 
                                    AND rappTrb.tipoRapporto IN ('D', 'E') 
                                    AND ogg.id = :pIdOggetto """

        if (anno != null) {
            Integer annoInt = (anno == "Tutti") ? 9999 : Integer.valueOf(anno)
            parametriQuery.pAnno = annoInt
            sql += """ 
                                AND ( :pAnno = 9999 
                                    OR ( oggContr.anno = :pAnno 
                                    AND  contr.codFiscale IN 
                                         (SELECT 
                                            oggContr.contribuente.codFiscale                
                                           FROM 
                                              OggettoContribuente AS oggContr
                                             WHERE 
                                            oggContr.oggettoPratica = f_max_ogpr_cont_ogge(
                                                    :pIdOggetto
                                                  , oggContr.contribuente.codFiscale
                                                  , prtTrb.tipoTributo.tipoTributo
                                                  , DECODE(:pAnno, 9999, '%', prtTrb.tipoPratica)
                                                  , :pAnno 
                                                  ,'%' ) )
                                        )
                                    )
                            ORDER BY oggContr.anno
                                    , COALESCE(oggContr.flagPossesso, 'N')
                                    , sogg.cognome
                                    , sogg.nome
                                    , contr.codFiscale
                                """
        }

        listaProprietari = Contribuente.executeQuery(sql, parametriQuery).collect { row ->
            [anno              : row[0].anno
             , tipoRapporto    : row[0].tipoRapporto
             , mesiPossesso    : row[0].mesiPossesso
             , flagPossesso    : row[0].flagPossesso
             , flagAbPrincipale: row[0].flagAbPrincipale
             , detrazione      : row[0].detrazione
             , detrazioniOgco  : !row[0].detrazioniOgco?.isEmpty()
             , aliquoteOgco    : !row[0].aliquoteOgco?.isEmpty()
             , percentuale     : row[0].percPossesso
             , codFiscale      : row[1]
             , valore          : row[2]
             , pratica         : row[3]
             , contribuente    : row[4]
             , flagProvvisorio : row[5]
             , dataNascita     : row[6]?.format("dd/MM/yyyy")
             , comuneNascita   : row[7]
             , numOrdine       : row[8]
            ]
        }

    }

    @Transactional
    def eliminaWCIN(def idWCIN) {
        if (idWCIN) {
            WebCalcoloIndividuale webCalcolo = WebCalcoloIndividuale.get(idWCIN)
            webCalcolo?.delete(failOnError: true, flush: true)
        }
    }

    def listaPertinenze(def anno, def codFiscale, def tipoTributo, def utenteEscluso = null) {
        def lista = OggettoPratica.createCriteria().list {
            createAlias("pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("oggettiContribuente", "ogco", CriteriaSpecification.INNER_JOIN)
            createAlias("categoriaCatasto", "caca", CriteriaSpecification.LEFT_JOIN)
            eq("prtr.tipoPratica", "K")
            eq("prtr.contribuente.codFiscale", codFiscale)
            eq("prtr.tipoTributo.tipoTributo", tipoTributo)
            eq("prtr.anno", anno)
            eq("ogco.flagAbPrincipale", "S")
            //quando si richiama da calcolo individuale, le pratiche prese in considerazione sono
            //quelle fatte da utenti che NON hanno codice WEB
            if (utenteEscluso) {
                ne("utente", utenteEscluso)
            }
            like("caca.id", "A%")
            eqProperty("prtr.contribuente", "ogco.contribuente")
            //            projections {
            //                property("id") //0
            //            }
            order("id", "asc")
        }
        return lista*.toDTO()
    }

    def familiariContribuente(Long idSoggetto) {
        def listafamiliari = FamiliareSoggetto.createCriteria().list {
            eq("soggetto.id", idSoggetto)
            order("anno", "desc")
            order("dal", "desc")
        }.toDTO(["soggetto"])
    }

    def getFamiliareContribuente(def soggetto, def anno, def dal) {
        return FamiliareSoggetto.createCriteria().get {
            eq("soggetto.id", soggetto.id)
            eq("anno", (Short) anno)
            eq("dal", dal)
        }
    }

    def salvaFamiliareContribuente(FamiliareSoggetto familiare) {
        familiare.save(flush: true, failOnError: true)
    }

    def eliminaFamiliareContribuente(FamiliareSoggetto familiare) {
        familiare.delete(failOnError: true, flush: true)
    }

    def documentiContribuente(String codFiscale, def tipo = "list") {
        if (tipo == "list") {
            DocumentoContribuente.executeQuery("""
                select doco
                  from DocumentoContribuente doco
                    inner join fetch doco.contribuente
                 where doco.contribuente.codFiscale = :codFiscale
                   and doco.sequenzaPrincipale is null
                 order by doco.sequenza desc
            """, [codFiscale: codFiscale])
        } else if (tipo == "count") {
            DocumentoContribuente.createCriteria().count {
                eq("contribuente.codFiscale", codFiscale)
            }
        } else {
            throw new RuntimeException("Tipo [${tipo}] non supportato")
        }
    }

    def allegatiDocumentoContribuente(DocumentoContribuente documentoContribuente) {
        DocumentoContribuente.createCriteria().list {
            eq('contribuente', documentoContribuente.contribuente)
            eq('sequenzaPrincipale', documentoContribuente.sequenza)
        }
    }

    private String createTipoTributoTipoPratica(String tipoTributo, String tipoPratica) {
        return """
                    MAX(CASE
                            WHEN coOgAn.tipoTributo.tipoTributo = '$tipoTributo' THEN
                                CASE 
                                    WHEN coOgAn.tipoPratica = '$tipoPratica' THEN true
                                    ELSE false
                                END
                            ELSE false
                        END
                    )
                """
    }

    def getResidentiOggetto(long idOggetto, long tipoResidente) {
        String sql = """
                        select   soggetti.ni,
                                 soggetti.cod_fam codFam,
                                 upper(replace(soggetti.cognome, ' ', '')) cognome,
                                 upper(replace(soggetti.nome, ' ', '')) nome,
                                 soggetti.data_nas dataNascita,
                                 decode(ad4_comuni.cap, null, '', ad4_comuni.denominazione)||' '||decode(ad4_provincie.sigla, null , '', ' (' || ad4_provincie.sigla || ')') comune,
                                 nvl(soggetti.cod_fiscale, soggetti.partita_iva) codFiscale,                             
                                 decode(soggetti.sequenza_par, 1, 1, 0) seqPar,
                                 decode(soggetti.sequenza_par, 0, 0, 0) seqTutti,
                                 prtr_ogge.cod_contr codContribuente,
                                 nvl(prtr_ogge.trib_ici,'N') tribici,
                                 nvl(prtr_ogge.trib_iciap,'N') tribiciap,
                                 nvl(prtr_ogge.trib_icp,'N') tribicp,
                                 nvl(prtr_ogge.trib_rsu,'N') tribrsu,
                                 nvl(prtr_ogge.trib_tosap,'N') tribtosap
                        from (select ni,
                                     decode(cont.cod_controllo,
                                            null,
                                            to_char(cont.cod_contribuente),
                                            cont.cod_contribuente || '-' || cont.cod_controllo) cod_contr,
                                     max(decode(tipo_tributo, 'ICI', 'S', 'N')) trib_ici,
                                     max(decode(tipo_tributo, 'ICIAP', 'S', 'N')) trib_iciap,
                                     max(decode(tipo_tributo, 'ICP', 'S', 'N')) trib_icp,
                                     max(decode(tipo_tributo, 'TARSU', 'S', 'N')) trib_rsu,
                                     max(decode(tipo_tributo, 'TOSAP', 'S', 'N')) trib_tosap
                                from contribuenti     cont,
                                     rapporti_tributo ratr,
                                     pratiche_tributo prtr,
                                     oggetti_pratica  ogpr
                               where cont.cod_fiscale = ratr.cod_fiscale
                                 and ratr.pratica = prtr.pratica
                                 and prtr.pratica = ogpr.pratica
                                 and ogpr.oggetto = :p_oggetto 
                               group by ni,
                                        decode(cont.cod_controllo,
                                               null,
                                               to_char(cont.cod_contribuente),
                                               cont.cod_contribuente || '-' || cont.cod_controllo)) prtr_ogge,
                             ad4_comuni,
                             ad4_provincie,
                             dati_generali,
                             soggetti,
                             oggetti
                       where prtr_ogge.ni(+) = soggetti.ni
                             and ad4_provincie.provincia(+) = ad4_comuni.provincia_stato
                             and ad4_comuni.comune(+) = soggetti.cod_com_nas
                             and ad4_comuni.provincia_stato(+) = soggetti.cod_pro_nas
                             and soggetti.cod_pro_res = dati_generali.pro_cliente
                             and soggetti.cod_com_res = dati_generali.com_cliente
                             and soggetti.fascia = 1
                             and nvl(soggetti.tipo, 0) in (0, 1)
                             and nvl(soggetti.cod_via, 0) = nvl(oggetti.cod_via, 0)
                             and nvl(soggetti.num_civ, 0) = nvl(oggetti.num_civ, 0)
                             and nvl(soggetti.suffisso, ' ') = nvl(oggetti.suffisso, ' ')
                             and nvl(soggetti.interno, 0) = nvl(oggetti.interno, 0)
                             and oggetti.oggetto = :p_oggetto """

        if (tipoResidente == 1) {
            sql += """ and decode(soggetti.sequenza_par, 1, 1, 0) = :p_tiporesidente """
        }

        sql += """ order by codFam asc,seqPar asc,dataNascita asc"""

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            setLong('p_oggetto', idOggetto)
            if (tipoResidente == 1) {
                setLong('p_tiporesidente', tipoResidente)
            }
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            list()
        }

        def records = []

        results.each {
            def record = [:]
            record.ni = it['NI']
            record.codFam = it['CODFAM']
            record.cognome = it['COGNOME']
            record.nome = it['NOME']
            record.dataNascita = it['DATANASCITA']
            record.comune = it['COMUNE']
            record.codFiscale = it['CODFISCALE']
            record.codContribuente = it['CODCONTRIBUENTE']
            record.ICI = it['TRIBICI'] == 'S'
            record.TASI = it['TRIBICIAP'] == 'S'
            record.ICP = it['TRIBICP'] == 'S'
            record.TARSU = it['TRIBRSU'] == 'S'
            record.TOSAP = it['TRIBTOSAP'] == 'S'
            records << record
        }
        return records
    }

    def getContribuentiOggetto(Long idOggetto, Long idPratica, def tipiTributo, def tipiPratica, def anno = null) {

        String whereIdPratica = ""
        String whereAnno = ""

        def parametriQuery = [:]
        parametriQuery.pIdOggetto = idOggetto

        if (idPratica) {
            parametriQuery.pIdPratica = idPratica
            whereIdPratica = " AND prtr.id = :pIdPratica "
        }
        if (anno) {
            whereAnno = """
                                    AND coOgAn.inizioValidita <= to_date('3112${anno}', 'ddmmyyyy')
                                    AND coOgAn.fineValidita >= to_date('0101${anno}', 'ddmmyyyy')
                                    AND nvl(to_number(to_char(coOgAn.dataDecorrenza, 'YYYY')), nvl (coOgAn.anno, 0)) <= ${anno}
                                    """
        }

        String iciD = createTipoTributoTipoPratica('ICI', 'D') + " AS iciD"
        String iciA = createTipoTributoTipoPratica('ICI', 'A') + " AS iciA"
        String iciL = createTipoTributoTipoPratica('ICI', 'L') + " AS iciL"

        String tasiD = createTipoTributoTipoPratica('TASI', 'D') + " AS tasiD"
        String tasiA = createTipoTributoTipoPratica('TASI', 'A') + " AS tasiA"
        String tasiL = createTipoTributoTipoPratica('TASI', 'L') + " AS tasiL"

        String tarsuD = createTipoTributoTipoPratica('TARSU', 'D') + " AS tarsuD"
        String tarsuA = createTipoTributoTipoPratica('TARSU', 'A') + " AS tarsuA"
        String tarsuL = createTipoTributoTipoPratica('TARSU', 'L') + " AS tarsuL"

        String icpD = createTipoTributoTipoPratica('ICP', 'D') + " AS icpD"
        String icpA = createTipoTributoTipoPratica('ICP', 'A') + " AS icpA"
        String icpL = createTipoTributoTipoPratica('ICP', 'L') + " AS icpL"

        String tosapD = createTipoTributoTipoPratica('TOSAP', 'D') + " AS tosapD"
        String tosapA = createTipoTributoTipoPratica('TOSAP', 'A') + " AS tosapA"
        String tosapL = createTipoTributoTipoPratica('TOSAP', 'L') + " AS tosapL"

        String cuniD = createTipoTributoTipoPratica('CUNI', 'D') + " AS cuniD"
        String cuniA = createTipoTributoTipoPratica('CUNI', 'A') + " AS cuniA"
        String cuniL = createTipoTributoTipoPratica('CUNI', 'L') + " AS cuniL"

        String sql = """
                            SELECT DISTINCT new Map(
                                contr.codFiscale 						AS codFiscale,
                                sogg.id 								AS ni,
                                sogg.cognome							AS cognome,
                                sogg.nome								AS nome,
                                sogg.partitaIva 						AS partitaIVA,
                                sogg.codFam 							AS codFam,
                                sogg.dataNas 							AS dataNascita,
                                coOgAn.percPossesso                     AS percPossesso,                               
                                MAX ( DECODE (vie.id, NULL, 
                                              sogg.denominazioneVia
                                              || DECODE (sogg.numCiv, NULL, '', ', ' || sogg.numCiv)
                                              || DECODE (sogg.suffisso, NULL, '', '/' || sogg.suffisso)
                                              || DECODE (sogg.interno, NULL, '', ' int. ' || sogg.interno)
                                            , vie.denomUff 
                                              || DECODE (sogg.numCiv, NULL, '', ', ' || sogg.numCiv)
                                              || DECODE (sogg.suffisso, NULL, '', '/' || sogg.suffisso)
                                              || DECODE (sogg.interno, NULL, '', ' int. ' || sogg.interno)
                                )) as indirizzo,                                     
                                MAX ( DECODE (contr.codControllo, NULL, TO_CHAR (contr.codContribuente), contr.codContribuente || '-' || contr.codControllo))  AS codContribuente,
                                ${iciD},
                                ${iciA},
                                ${iciL},
                                ${tasiD},
                                ${tasiA},
                                ${tasiL},
                                ${tarsuD},
                                ${tarsuA},
                                ${tarsuL},
                                ${icpD},
                                ${icpA},
                                ${icpL},
                                ${tosapD},
                                ${tosapA},
                                ${tosapL},
                                ${cuniD},
                                ${cuniA},
                                ${cuniL}
                    
                            )
                            FROM
                                ContribuentiOggettoAnno as coOgAn 
                                    INNER JOIN coOgAn.contribuente as contr 
                                    INNER JOIN contr.soggetto as sogg     
                                    INNER JOIN coOgAn.pratica as prtr
                                    LEFT JOIN sogg.archivioVie as vie                                  
                            WHERE
                                 coOgAn.oggetto.id = :pIdOggetto
                                 ${whereAnno}
                                 ${whereIdPratica}
                            GROUP BY
                                contr.codFiscale,
                                sogg.id,
                                sogg.cognome,
                                sogg.nome,
                                sogg.partitaIva,
                                sogg.codFam,
                                sogg.dataNas,
                                coOgAn.percPossesso,
                                vie.denomUff
                            """

        String sqlHaving = " HAVING "
        // ICI
        if (tipiTributo.ICI) {
            sqlHaving += tipiPratica.D ? createTipoTributoTipoPratica('ICI', 'D') + " = $tipiPratica.D OR " : ""
            sqlHaving += tipiPratica.A ? createTipoTributoTipoPratica('ICI', 'A') + " = $tipiPratica.A OR " : ""
            sqlHaving += tipiPratica.L ? createTipoTributoTipoPratica('ICI', 'L') + " = $tipiPratica.L OR " : ""
        }

        // TASI
        if (tipiTributo.TASI) {
            sqlHaving += tipiPratica.D ? createTipoTributoTipoPratica('TASI', 'D') + " = $tipiPratica.D OR " : ""
            sqlHaving += tipiPratica.A ? createTipoTributoTipoPratica('TASI', 'A') + " = $tipiPratica.A OR " : ""
            sqlHaving += tipiPratica.L ? createTipoTributoTipoPratica('TASI', 'L') + " = $tipiPratica.L OR " : ""
        }

        // TARSU
        if (tipiTributo.TARSU) {
            sqlHaving += tipiPratica.D ? createTipoTributoTipoPratica('TARSU', 'D') + " = $tipiPratica.D OR " : ""
            sqlHaving += tipiPratica.A ? createTipoTributoTipoPratica('TARSU', 'A') + " = $tipiPratica.A OR " : ""
            sqlHaving += tipiPratica.L ? createTipoTributoTipoPratica('TARSU', 'L') + " = $tipiPratica.L OR " : ""
        }

        // ICP
        if (tipiTributo.ICP) {
            sqlHaving += tipiPratica.D ? createTipoTributoTipoPratica('ICP', 'D') + " = $tipiPratica.D OR " : ""
            sqlHaving += tipiPratica.A ? createTipoTributoTipoPratica('ICP', 'A') + " = $tipiPratica.A OR " : ""
            sqlHaving += tipiPratica.L ? createTipoTributoTipoPratica('ICP', 'L') + " = $tipiPratica.L OR " : ""
        }

        // TOSAP
        if (tipiTributo.TOSAP) {
            sqlHaving += tipiPratica.D ? createTipoTributoTipoPratica('TOSAP', 'D') + " = $tipiPratica.D OR " : ""
            sqlHaving += tipiPratica.A ? createTipoTributoTipoPratica('TOSAP', 'A') + " = $tipiPratica.A OR " : ""
            sqlHaving += tipiPratica.L ? createTipoTributoTipoPratica('TOSAP', 'L') + " = $tipiPratica.L OR " : ""
        }

        // CUNI
        if (tipiTributo.CUNI) {
            sqlHaving += tipiPratica.D ? createTipoTributoTipoPratica('CUNI', 'D') + " = $tipiPratica.D OR " : ""
            sqlHaving += tipiPratica.A ? createTipoTributoTipoPratica('CUNI', 'A') + " = $tipiPratica.A OR " : ""
            sqlHaving += tipiPratica.L ? createTipoTributoTipoPratica('CUNI', 'L') + " = $tipiPratica.L" : ""
        }

        sqlHaving = sqlHaving.endsWith(" OR ") ? sqlHaving.substring(0, sqlHaving.length() - 3) : sqlHaving

        sqlHaving += (sqlHaving == " HAVING " ? "1=0" : "")

        sql += sqlHaving

        sql += """
                ORDER BY sogg.cognome, sogg.nome
            """

        def listaContribuenti = PraticaTributo.executeQuery(sql, parametriQuery)

        def tributiPratiche = [
                ICI  : false,
                TASI : false,
                TARSU: false,
                ICP  : false,
                TOSAP: false,
                CUNI : false,
                D    : false,
                A    : false,
                L    : false
        ]

        listaContribuenti.each {
            // Tributi attivi
            tributiPratiche.ICI |= (it.iciD || it.iciA || it.iciL)
            tributiPratiche.TASI |= (it.tasiD || it.tasiA || it.tasiL)
            tributiPratiche.TARSU |= (it.tarsuD || it.tarsuA || it.tarsuL)
            tributiPratiche.ICP |= (it.icpD || it.icpA || it.icpL)
            tributiPratiche.TOSAP |= (it.tosapD || it.tosapA || it.tosapL)
            tributiPratiche.CUNI |= (it.cuniD || it.cuniA || it.cuniL)
            // Pratiche attive
            tributiPratiche.D |= (it.iciD || it.tasiD || it.tarsuD || it.tosapD || it.icpD || it.cuniD)
            tributiPratiche.A |= (it.iciA || it.tasiA || it.tarsuA || it.tosapA || it.icpA || it.cuniA)
            tributiPratiche.L |= (it.iciL || it.tasiL || it.tarsuL || it.tosapL || it.icpL || it.cuniL)
        }

        return [tributiPratiche: tributiPratiche, lista: listaContribuenti]
    }

    def verificaOggettoAcc(String tipoTributo, String cfContr, Long oggetto) {

        def parametri = [:]
        parametri.pTipoTributo = tipoTributo
        parametri.pCfContr = cfContr
        parametri.pOggetto = oggetto

        String sql = """
                        SELECT 
                            prtTri.id            
                        FROM
                            PraticaTributo as prtTri
                        INNER JOIN
                             prtTri.tipoTributo as tipoTri
                        INNER JOIN
                             prtTri.oggettiPratica as oggPrt
                        INNER JOIN
                            oggPrt.oggettiContribuente as oggCtr
                        INNER JOIN
                            oggPrt.oggetto as ogg
                        INNER JOIN
                            oggCtr.contribuente as ctr          
                        WHERE
                                prtTri.tipoPratica in ('A', 'L')
                            and tipoTri.tipoTributo like :pTipoTributo
                            and ogg.id = :pOggetto
                            and ctr.codFiscale = :pCfContr
                        """
        def lista = PraticaTributo.executeQuery(sql, parametri)
        return lista
    }

    def verificaOggettoLiq(String tipoTributo, String cfContr, Long oggetto) {

        def parametri = [:]
        parametri.pTipoTributo = tipoTributo
        parametri.pCfContr = cfContr
        parametri.pOggetto = oggetto
        String sql = """
                            SELECT 
                                prtTri.id            
                            FROM
                                OggettoPratica as oggPrt
                            INNER JOIN
                                oggPrt.oggetto as ogg
                            INNER JOIN
                                oggPrt.pratica as prtTri
                            INNER JOIN
                                 prtTri.tipoTributo as tipoTri
                            INNER JOIN
                                prtTri.praticaTributoRif as prtTriDue
                            INNER JOIN
                                oggPrt.oggettiContribuente as oggCtr
                            INNER JOIN
                                oggCtr.contribuente as ctr 
                            INNER JOIN
                                oggPrt.oggettoPraticaRif as oggPrtDue
                            WHERE
                                    prtTriDue.tipoPratica in ('A', 'L')
                                and tipoTri.tipoTributo like :pTipoTributo
                                and ogg.id = :pOggetto
                                and ctr.codFiscale = :pCfContr
                            """
        def lista = []

        lista = OggettoPratica.executeQuery(sql, parametri)
    }

    String getAccLiqOggetto(String tipoTributo, String cfContr, Long oggetto) {
        String v
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_acc_liq_oggetto(?, ?, ?)}'
                , [
                Sql.VARCHAR,
                oggetto
                ,
                cfContr
                ,
                tipoTributo
        ]) { v = it }
        return v
    }

    String checkSostituzioneOggetto(String tipoTributo, Long oldOggetto, Long newOggetto, String domanda = null) {
        String v
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_check_sostituzione_oggetto(?, ?, ?, ?)}'
                , [
                Sql.VARCHAR,
                tipoTributo
                ,
                oldOggetto
                ,
                newOggetto
                ,
                domanda
        ]) { v = it }
        return v
    }

    @Transactional
    String sostituzioneOggetto(String cf, String tipoTributo, Long oldOggetto, Long newOggetto) {
        String v
        //Connection conn = DataSourceUtils.getConnection(dataSource)
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_web_sostituzione_oggetto(?, ?, ?, ?)}'
                , [
                Sql.VARCHAR,
                cf
                ,
                tipoTributo
                ,
                oldOggetto
                ,
                newOggetto
        ]) { v = it }
        return v
    }
    /**
     * Ritorna un DTO del contribuente con i dati relativi alle sue pratiche, oggetti, ...
     * @param codFiscale
     * @return
     */
    ContribuenteDTO getDatiContribuente(String codFiscale, boolean filtroOgCo = false, List<String> tipiTributoSelezionati, List<String> tipiPraticaSelezionati) {

        String query = "FROM Contribuente c\
                    INNER JOIN FETCH c.soggetto          sogg\
                    LEFT JOIN FETCH sogg.archivioVie     vieSogg\
                    LEFT JOIN FETCH sogg.comuneResidenza comRes\
                    LEFT JOIN FETCH comRes.ad4Comune     ad4Com\
                    LEFT JOIN FETCH ad4Com.provincia     provRes\
                    LEFT JOIN FETCH c.rapportiTributo   ratr\
                    LEFT JOIN FETCH ratr.pratica        prtr\
                    LEFT JOIN FETCH prtr.oggettiPratica  ogpr\
                    LEFT JOIN FETCH ogpr.oggetto        ogge\
                    LEFT JOIN FETCH ogge.archivioVie     vie\
                    LEFT JOIN FETCH ogge.riferimentiOggetto riog\
                    LEFT JOIN FETCH ogpr.oggettiContribuente ogco\
                    LEFT JOIN FETCH ogco.oggettiImposta      ogim\
                    LEFT JOIN FETCH ogim.ruoliContribuente   ruco\
                    LEFT JOIN FETCH ruco.sgravi              sgra\
                    LEFT JOIN FETCH ruco.ruolo ru\
                WHERE\
                    c.codFiscale = :codFiscale\
                AND (prtr.tipoTributo is null or prtr.tipoTributo.tipoTributo in (:tipiTributoSelezionati))\
                AND (prtr.tipoPratica is null or prtr.tipoPratica in (:tipiPraticaSelezionati))"

        String ogCo = " AND (prtr.tipoPratica = 'V' OR ogco.contribuente.codFiscale = :codFiscale)"
        query += filtroOgCo ? ogCo : ""

        Contribuente contribuente = Contribuente.find(query, [
                codFiscale: codFiscale,
                tipiTributoSelezionati: tipiTributoSelezionati,
                tipiPraticaSelezionati: tipiPraticaSelezionati
        ])
        ContribuenteDTO contribuenteDTO = contribuente.toDTO()
    }

    ContribuenteDTO getDatiTestata(String codFiscale) {

        String query = """FROM Contribuente c\
                    INNER JOIN FETCH c.soggetto          sogg\
                    LEFT JOIN FETCH sogg.archivioVie     vieSogg\
                    LEFT JOIN FETCH sogg.comuneResidenza comRes\
                    LEFT JOIN FETCH comRes.ad4Comune     ad4Com\
                    LEFT JOIN FETCH ad4Com.provincia     provRes\
                WHERE\
                    c.codFiscale = :codFiscale\
                """

        Contribuente contribuente = Contribuente.find(query, [codFiscale: codFiscale])
        ContribuenteDTO contribuenteDTO = contribuente.toDTO()
    }

    def getPraticheOggetto(long idOggetto, String codFiscale) {

        def parametri = [:]
        parametri.pIdOggetto = idOggetto

        String sql = """
                            SELECT new Map(
                                prtr.anno 						AS anno
                              , prtr.id 						AS pratica
                              , prtr.tipoPratica  				AS tipoPratica
                              , f_descrizione_titr(prtr.tipoTributo.tipoTributo, prtr.anno) 	AS tipoTributo
                              , prtr.tipoTributo.tipoTributo AS tipoTributoOrig
                              , ogco.contribuente.soggetto.cognomeNome AS cognomeNome
                              , ogco.contribuente.codFiscale 	AS codFiscale)
                            FROM
                                OggettoPratica				AS ogpr                
                            INNER JOIN    
                                ogpr.pratica				AS prtr               
                            INNER JOIN    
                                ogpr.oggetto				AS ogge       
                            INNER JOIN    
                                ogpr.oggettiContribuente	AS ogco                          
                            WHERE 
                                ogge.id = :pIdOggetto 					AND
                                prtr.tipoPratica.tipoPratica in ('D') 	AND
                                ogpr.id=f_max_ogpr_cont_ogge( ogge.id
                                                            , ogco.contribuente.codFiscale
                                                            , prtr.tipoTributo.tipoTributo
                                                            , '%'
                                                            , prtr.anno
                                                            , '%')"""
        if (codFiscale != null) {
            parametri.pCodFiscale = codFiscale
            sql += """ AND ogco.contribuente.codFiscale = :pCodFiscale"""
        }

        sql += """
                    ORDER BY ogco.contribuente.soggetto.cognomeNome,
                             f_descrizione_titr(prtr.tipoTributo.tipoTributo, prtr.anno),
                             prtr.id
                """

        OggettoPratica.executeQuery(sql, parametri)
    }

    def letteraGenerica(def idContribuente) {
        String sql =
                """
                SELECT *
                    FROM CONTRIBUENTI_ENTE
                    WHERE NI = :P_NI
                """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('P_NI', idContribuente)

            list()
        }

        def nomi = []
        def valori = []

        results.each {
            it.each { k, v ->
                nomi << k
                valori << (v ?: '')
            }
        }


        return [nomi: nomi, valori: valori]

    }

    def componentiFamiglia(def fascia, def codiceFamiglia) {
        String sql = """
                      SELECT SOGGETTI.NI,
                       REPLACE(SOGGETTI.COGNOME_NOME, '/', ' ') COGNOME_NOME,
                       NVL(SOGGETTI.COD_FISCALE, SOGGETTI.PARTITA_IVA) COD_FISCALE,
                       SOGGETTI.DATA_NAS,
                       UPPER(REPLACE(SOGGETTI.COGNOME, ' ', '')) COGNOME,
                       UPPER(REPLACE(SOGGETTI.NOME, ' ', '')) NOME,
                       DECODE(AD4_COMUNI.CAP, NULL, '', AD4_COMUNI.DENOMINAZIONE) || ' ' ||
                       DECODE(AD4_PROVINCIE.SIGLA,
                              NULL,
                              '',
                              ' (' || AD4_PROVINCIE.SIGLA || ')') COMUNE,
                       SOGGETTI.FASCIA,
                       SOGGETTI.TIPO_RESIDENTE,
                       SOGGETTI.COD_FAM,
                       SOGGETTI.RAPPORTO_PAR,
                       SOGGETTI.SEQUENZA_PAR,
                       ANA.DESCRIZIONE STATO,
                       SOGGETTI.DATA_ULT_EVE,
                       DECODE(COM_EVE.CAP, NULL, '', COM_EVE.DENOMINAZIONE) || ' ' ||
                       DECODE(PRO_EVE.SIGLA, NULL, '', ' (' || PRO_EVE.SIGLA || ')') COMUNE_EVENTO,
                       DECODE(CONT.COD_CONTROLLO,
                              NULL,
                              TO_CHAR(CONT.COD_CONTRIBUENTE),
                              CONT.COD_CONTRIBUENTE || '-' || CONT.COD_CONTROLLO) CODICE_CONTRIBUENTE,
                       CONT.COD_FISCALE CONT_COD_FISCALE,
                       CONT.COD_CONTRIBUENTE,
                       CONT.COD_CONTROLLO,
                       PRTR_OGGE.TRIB_ICI,
                       PRTR_OGGE.TRIB_TASI,
                       PRTR_OGGE.TRIB_ICIAP,
                       PRTR_OGGE.TRIB_ICP,
                       PRTR_OGGE.TRIB_RSU,
                       PRTR_OGGE.TRIB_TOSAP
                  FROM (SELECT SOGG.NI,
                               MAX(DECODE(TIPO_TRIBUTO, 'ICI', 'S', 'N')) TRIB_ICI,
                               MAX(DECODE(TIPO_TRIBUTO, 'ICIAP', 'S', 'N')) TRIB_ICIAP,
                               MAX(DECODE(TIPO_TRIBUTO, 'TASI', 'S', 'N')) TRIB_TASI,
                               MAX(DECODE(TIPO_TRIBUTO, 'ICP', 'S', 'N')) TRIB_ICP,
                               MAX(DECODE(TIPO_TRIBUTO, 'TARSU', 'S', 'N')) TRIB_RSU,
                               MAX(DECODE(TIPO_TRIBUTO, 'TOSAP', 'S', 'N')) TRIB_TOSAP
                          FROM PRATICHE_TRIBUTO PRTR,
                               RAPPORTI_TRIBUTO RATR,
                               CONTRIBUENTI     CONT,
                               SOGGETTI         SOGG
                         WHERE PRTR.PRATICA(+) = RATR.PRATICA
                           AND RATR.COD_FISCALE(+) = CONT.COD_FISCALE
                           AND CONT.NI(+) = SOGG.NI
                           AND SOGG.FASCIA IN (SELECT DECODE(SIGN(:P_FASCIA - 3), -1, 1, 3)
                                                 FROM DUAL
                                               UNION
                                               SELECT DECODE(SIGN(:P_FASCIA - 3), -1, 2, 4)
                                                 FROM DUAL)
                           AND SOGG.COD_FAM = :P_COD_FAM
                         GROUP BY SOGG.NI) PRTR_OGGE,
                       AD4_COMUNI COM_EVE,
                       AD4_PROVINCIE PRO_EVE,
                       AD4_COMUNI,
                       AD4_PROVINCIE,
                       CONTRIBUENTI CONT,
                       SOGGETTI,
                       ANADEV ANA
                 WHERE CONT.NI(+) = SOGGETTI.NI
                   AND PRTR_OGGE.NI(+) = SOGGETTI.NI
                   AND PRO_EVE.PROVINCIA(+) = COM_EVE.PROVINCIA_STATO
                   AND COM_EVE.COMUNE(+) = SOGGETTI.COD_COM_EVE
                   AND COM_EVE.PROVINCIA_STATO(+) = SOGGETTI.COD_PRO_EVE
                   AND AD4_PROVINCIE.PROVINCIA(+) = AD4_COMUNI.PROVINCIA_STATO
                   AND AD4_COMUNI.COMUNE(+) = SOGGETTI.COD_COM_NAS
                   AND AD4_COMUNI.PROVINCIA_STATO(+) = SOGGETTI.COD_PRO_NAS
                   AND ANA.COD_EV(+) = SOGGETTI.STATO
                   AND SOGGETTI.TIPO_RESIDENTE = 0
                   AND SOGGETTI.FASCIA IN (SELECT DECODE(SIGN(:P_FASCIA - 3), -1, 1, 3)
                                             FROM DUAL
                                           UNION
                                           SELECT DECODE(SIGN(:P_FASCIA - 3), -1, 2, 4)
                                             FROM DUAL)
                   AND SOGGETTI.COD_FAM = :P_COD_FAM
                 ORDER BY FASCIA, SEQUENZA_PAR
                """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            if (fascia) {
                setInteger('P_FASCIA', fascia)
            } else {
                setParameter('P_FASCIA', "")
            }

            setLong('P_COD_FAM', codiceFamiglia)
            list()
        }

        def records = []

        results.each {
            def record = [:]
            it.each { k, v ->
                record[k] = v
                records << record
            }

            return records

        }
    }

    def eventiEResidenzeStoriche(def matricola) {
        String sql = """
                         SELECT ANAEVE.MATRICOLA,
                               ANAEVE.COD_EVE,
                               ANAEVE.DATA_INIZIO,
                               ANAEVE.DATA_EVE,
                               TO_DATE(TO_CHAR(TO_DATE(ANAEVE.DATA_EVE, 'j'), 'dd/MM/yyyy'),
                                       'dd/MM/yyyy') DATA_EVEN,
                               TO_DATE(TO_CHAR(TO_DATE(ANAEVE.DATA_INIZIO, 'j'), 'dd/MM/yyyy'),
                                       'dd/MM/yyyy') DATA_INIZ,
                               DECODE(ANAEVE.DATA_INIZIO,
                                      NULL,
                                      ANADEV.DESCRIZIONE || ' - ' || AD4_COMUNI.DENOMINAZIONE || ' (' ||
                                      AD4_PROVINCIE.SIGLA || ')',
                                      DECODE(ANAEVE.COD_VIA,
                                             NULL,
                                             ANAEVE.VIA_AIRE,
                                             ARCHIVIO_VIE.DENOM_UFF) ||
                                      DECODE(ANAEVE.NUM_CIV, NULL, '', ', ' || ANAEVE.NUM_CIV) ||
                                      DECODE(ANAEVE.SUFFISSO, NULL, '', '/' || ANAEVE.SUFFISSO)) ||
                               DECODE(COD_MOV || COD_VARIAZIONE,
                                      '11C',
                                      '  [RIN.CIV.]',
                                      '11O',
                                      '  [REV.ONO.]',
                                      '11U',
                                      '  [VAR.UFF.]',
                                      '') DESC_EVENTO,
                               SOGGETTI.COD_FAM,
                               SOGGETTI.FASCIA,
                               SOGGETTI.TIPO_RESIDENTE,
                               TRANSLATE(SOGGETTI.COGNOME_NOME, '/', ' ') COGNOME_NOME
                          FROM ANAEVE, ANADEV, SOGGETTI, ARCHIVIO_VIE, AD4_COMUNI, AD4_PROVINCIE
                         WHERE (ANAEVE.COD_VIA = ARCHIVIO_VIE.COD_VIA(+))
                           AND (ANAEVE.COD_EVE = ANADEV.COD_EV(+))
                           AND (AD4_COMUNI.PROVINCIA_STATO = AD4_PROVINCIE.PROVINCIA(+))
                           AND (ANAEVE.COD_PRO_EVE = AD4_COMUNI.PROVINCIA_STATO(+))
                           AND (ANAEVE.COD_COM_EVE = AD4_COMUNI.COMUNE(+))
                           AND (SOGGETTI.MATRICOLA(+) = ANAEVE.MATRICOLA)
                           AND (SOGGETTI.TIPO_RESIDENTE = 0)
                           AND ((ANAEVE.MATRICOLA = :P_MATRICOLA) AND
                               (ANAEVE.DATA_INIZIO IS NULL OR ANAEVE.COD_MOV IN (11, 13)))
                         ORDER BY TO_DATE(TO_CHAR(TO_DATE(ANAEVE.DATA_EVE, 'j'), 'dd/MM/yyyy'),
                                          'dd/MM/yyyy') DESC,
                                  TO_DATE(TO_CHAR(TO_DATE(ANAEVE.DATA_INIZIO, 'j'), 'dd/MM/yyyy'),
                                          'dd/MM/yyyy') DESC
                """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('P_MATRICOLA', matricola)
            list()
        }

        def records = []

        results.each {
            def record = [:]
            it.each { k, v ->
                record[k] = v
                records << record
            }

            return records

        }
    }

    def aggiornaDocumento(DocumentoContribuente documentoContribuente) {

        documentoContribuente.lastUpdated = new Date()
        documentoContribuente.save(failOnError: true, flush: true)
    }

    def caricaDocumento(DocumentoContribuente documentoContribuente) {

        if (!documentoContribuente.sequenza) {
            def maxSeq = DocumentoContribuente.findAllByContribuente(documentoContribuente.contribuente)
                    .max { it.sequenza }?.sequenza ?: 0

            documentoContribuente.sequenza = maxSeq + 1
        }

        documentoContribuente.dataInserimento = documentoContribuente.dataInserimento ?: new Date()
        documentoContribuente.utente = springSecurityService.currentUser

        documentoContribuente.save(failOnError: true, flush: true)

        if (!documentoContribuente.titolo) {
            documentoContribuente = DocumentoContribuente.findAllByContribuente(documentoContribuente.contribuente).max {
                it.sequenza
            }
            documentoContribuente.titolo = "Documento " + (documentoContribuente.sequenza + "").padLeft(2, '0')
            documentoContribuente.save(failOnError: true, flush: true)
        }

        return documentoContribuente.refresh()
    }

    def getDocumentoContribuente(def codFiscale, def sequenza) {
        return DocumentoContribuente.createCriteria().get {
            eq('contribuente.codFiscale', codFiscale)
            eq('sequenza', sequenza)
        }
    }

    def getSoggettiCCCollegati(String codFiscale) {

        def soggetti = []

        def lista = soggettiAssociati(codFiscale)

        soggetti << codFiscale
        lista.each {
            soggetti << it.codFiscaleRic
        }

        return soggetti
    }

    def countLocazioni(def filtri) {

        def sogCCCollegati = getSoggettiCCCollegati(filtri.codFiscale)

        LocazioneSoggetto.createCriteria().list {
            'in'('codFiscale', sogCCCollegati)

            projections {
                count()
            }
        }[0]
    }

    def caricaLocazioni(def filtri, def params = [:], def sortBy = null) {

        params.max = params?.max ?: 10
        params.offset = params.activePage * params.max

        def sogCCCollegati = []
        if (filtri.codFiscale) {
            sogCCCollegati = getSoggettiCCCollegati(filtri.codFiscale)
        }

        def lista = LocazioneContratto.createCriteria().list(params) {

            createAlias("locazioneSoggetti", "sogg", CriteriaSpecification.INNER_JOIN)
            createAlias("locazioneImmobili", "imm", CriteriaSpecification.LEFT_JOIN)
            createAlias("locazioneTestata", "tes", CriteriaSpecification.INNER_JOIN)

            projections {
                distinct('id', 'id')
                property('ufficio', 'ufficio')
                property('anno', 'anno')
                property('numero', 'numero')
                property('sottoNumero', 'sottoNumero')
                property('progressivoNegozio', 'progressivoNegozio')
                property('progressivoNegozio', 'progressivoNegozio')
                property('dataStipula', 'dataStipula')
                property('dataInizio', 'dataInizio')
                property('dataFine', 'dataFine')
                property('codiceOggetto', 'codiceOggetto')
                property('codiceNegozio', 'codiceNegozio')
                property('importoCanone', 'importoCanone')
                property('tipoCanone', 'tipoCanone')

                property('tes.documentoId', 'documentoId')

                property('imm.indirizzo', 'indirizzo')
                property('imm.sezUrbComCat', 'sezUrbComCat')
                property('imm.foglio', 'foglio')
                property('imm.particellaNum', 'particellaNum')
                property('imm.subalterno', 'subalterno')
                property('imm.immAccatastamento', 'immAccatastamento')
                property('imm.tipoCatasto', 'tipoCatasto')
                property('imm.flagIp', 'flagIp')

                // Solo se si filtra per codice fiscale si estraggono le informazioni del soggetto
                if (filtri.codFiscale) {
                    property('sogg.tipoSoggetto', 'tipoSoggetto')
                    property('sogg.dataSubentro', 'dataSubentro')
                    property('sogg.dataCessazione', 'dataCessazione')
                    property('sogg.codFiscale', 'codFiscale')
                }
            }

            if (filtri.codFiscale) {
                if (sogCCCollegati.size() > 0) {
                    'in'('sogg.codFiscale', sogCCCollegati)
                } else {
                    eq('sogg.codFiscale', filtri.codFiscale)
                }
            }
            if (filtri.sezione) {
                eq('imm.sezUrbComCat', filtri.sezione)
            }
            if (filtri.foglio) {
                eq('imm.foglio', filtri.foglio)
            }
            if (filtri.numero) {
                eq('imm.particellaNum', filtri.numero)
            }
            if (filtri.subalterno) {
                eq('imm.subalterno', filtri.subalterno)
            }

            for (def s : sortBy) {
                order(s.property, s.direction)
            }

            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
        }

        def rowNum = 0
        def elencoLocazioni = lista.collect { row ->

            def tipiSoggettoLocazione = [
                    'D': 'Proprietario',
                    'A': 'Inquilino'
            ]
            def tipiCanoneLocazione = [
                    'A': 'Annuale',
                    'M': 'Mensile',
                    'I': 'Intera durata',
                    'K': 'Corrispettivo non interamente determinato annuale',
                    'L': 'Corrispettivo non interamente determinato mensile',
                    'J': 'Corrispettivo non interamente determinato intera durata'

            ]
            def tipiCatastoLocazione = [
                    'U': 'Urbano',
                    'T': 'Terreni'
            ]
            def flagIPLocazione = [
                    'I': 'Intero',
                    'P': 'Porzione'
            ]

            String patternValuta = "€ #,###.00"
            String patternNumero = "#,###.00"
            DecimalFormat valuta = new DecimalFormat(patternValuta)
            DecimalFormat numero = new DecimalFormat(patternNumero)

            // Creazione dettaglio
            def dettagli = []
            LocazioneContratto.get(row.id).locazioneSoggetti.each { s ->

                def contribuente = Contribuente.findByCodFiscale(s.codFiscale)
                def sogg = contribuente?.soggetto ?: Soggetto.findByCodFiscale(s.codFiscale) ?: Soggetto.findByPartitaIva(s.codFiscale)

                def dettaglio = [:]
                dettaglio.codFiscale = s.codFiscale

                dettaglio.cognome = sogg?.cognome
                dettaglio.nome = sogg?.nome
                dettaglio.contraente = "${dettaglio.cognome ?: ''} ${dettaglio.nome ?: ''}"
                dettaglio.sesso = s.sesso != 'S' ? s.sesso : null
                dettaglio.datiNascita = (s.cittaNascita ?: '') + (s.provNascita ? " ($s.provNascita) " : '') + (s.dataNascita?.format('dd/MM/yyyy', TimeZone.getTimeZone("Europe/Rome")) ?: '')
                dettaglio.datiResidenza = (s.cittaRes ?: '') + (s.provRes ? " ($s.provRes)" : '') +
                        (s.indirizzoRes ? " $s.indirizzoRes" : '') + (s.numCivRes ? " $s.numCivRes" : '')
                dettaglio.tipoSoggetto = (tipiSoggettoLocazione[s.tipoSoggetto] ?: '')
                dettaglio.subentro = s.dataSubentro?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null
                dettaglio.cessione = s.dataCessazione?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null

                dettagli << dettaglio
            }

            dettagli = dettagli.sort { a, b -> b.tipoSoggetto <=> a.tipoSoggetto ?: a.codFiscale <=> b.codFiscale }

            [
                    row               : rowNum++,
                    codFiscale        : row.codFiscale,
                    ufficio           : row.ufficio,
                    anno              : row.anno,
                    numero            : row.numero,
                    sottonumero       : row.sottoNumero,
                    progressivoNegozio: row.progressivoNegozio,
                    dataRegistrazione : row.dataRegistrazione?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                    dataStipula       : row.dataStipula?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                    dataInizio        : row.dataInizio?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                    dataFine          : row.dataFine?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                    codiceOggetto     : row.codiceOggetto,
                    codiceNegozio     : row.codiceNegozio,
                    importoCanone     : row.importoCanone ? valuta.format(row.importoCanone) : null,
                    tipoCanone        : row.tipoCanone ? tipiCanoneLocazione[row.tipoCanone] : null,

                    // Immobile
                    indirizzo         : row.indirizzo,
                    sezUrbComCat      : row.sezUrbComCat == '0' ? null : row.sezUrbComCat,
                    foglio            : row.foglio == '0' ? null : row.foglio,
                    particellaNum     : row.particellaNum == '0' ? null : row.particellaNum,
                    subalterno        : row.subalterno == '0' ? null : row.subalterno,
                    immAccatastamento : row.immAccatastamento == 'S',
                    tipoCatasto       : tipiCatastoLocazione[row.tipoCatasto] ?: null,
                    flagIp            : flagIPLocazione[row.flagIp] ?: null,

                    // Soggetto
                    tipoSoggetto      : tipiSoggettoLocazione[row?.tipoSoggetto] ?: null,
                    dataSubentro      : row?.dataSubentro?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                    dataCessazione    : row?.dataCessazione?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,

                    // Testata
                    documentoId       : row.documentoId,

                    contrattoId       : row.contrattoId,

                    dettagli          : dettagli,

                    // Codice Fiscale
                    codFiscale        : row.codFiscale
            ]
        }

        return [
                record      : elencoLocazioni,
                numeroRecord: lista.totalCount
        ]
    }

    def countUtenze(def filtri) {

        def sogCCCollegati = getSoggettiCCCollegati(filtri.codFiscale)

        UtenzaDatiFornitura.createCriteria().list {
            'in'('codFiscaleTitolare', sogCCCollegati)

            projections {
                count()
            }
        }[0]
    }

    def caricaUtenze(def filtri, def params = [:], def sortBy = null) {

        def tipiUtenza = [
                'E': 'Elettrica',
                'G': 'Gas',
                'I': 'Idrica'
        ]

        def sogCCCollegati = []
        if (filtri.codFiscale) {
            sogCCCollegati = getSoggettiCCCollegati(filtri.codFiscale)
        }

        params.max = params?.max ?: 10
        params.offset = params.activePage * params.max

        def lista = UtenzaFornitura.createCriteria().list(params) {

            createAlias("utenzeDati", "uted", CriteriaSpecification.INNER_JOIN)

            projections {
                property('uted.tipoUtenza.tipoFornitura') // 0
                property('uted.annoRiferimento') // 1
                property('uted.codFiscaleErogante') //2
                property('uted.datiAnagraficiTitolare') // 3
                property('uted.tipoUtenza') // 4
                property('uted.indirizzoUtenza') // 5
                property('uted.ammontareFatturato') // 6
                property('uted.consumoFatturato') // 7
                property('uted.mesiFatturazione') // 8

                property('documentoId') // 9

                property('uted.codFiscaleTitolare') // 10
            }

            if (filtri.codFiscale) {
                if (sogCCCollegati.size() > 0) {
                    'in'('uted.codFiscaleTitolare', sogCCCollegati)
                } else {
                    eq('uted.codFiscaleTitolare', filtri.codFiscale)
                }
            }

            if (filtri.tipologia && filtri.tipologia != '*') {
                eq("uted.tipoUtenza.tipoFornitura", filtri.tipologia)
            }

            for (def s : sortBy) {
                order(s.property, s.direction)
            }
        }

        String patternValuta = "€ #,###.00"
        String patternNumero = "#,###.00"
        DecimalFormat valuta = new DecimalFormat(patternValuta)
        DecimalFormat numero = new DecimalFormat(patternNumero)
        def elencoUtenze = lista.collect { row ->

            row[4].descrizione
            [
                    fornitura       : tipiUtenza[row[0]],
                    anno            : row[1],
                    cfErogante      : row[2],
                    titolare        : row[3],
                    utenza          : [descrizione: row[4].descrizione, descrizioneBreve: row[4].descrizioneBreve],
                    indirizzo       : row[5],
                    fatturato       : valuta.format(row[6]) ?: null,
                    consumo         : numero.format(row[7]) ?: null,
                    mesiFatturazione: row[8],
                    documentoId     : row[9],
                    cfTitolare      : row[10]
            ]
        }

        return [
                record      : elencoUtenze,
                numeroRecord: lista.totalCount
        ]
    }

    def caricaDatiMetrici(def filtri, def params = [:], def sortBy = null) {

        if ((!filtri.sezione && !filtri.foglio && !filtri.numero && !filtri.subalterno) && !filtri.codFiscale) {
            log.info "Estremi catastali o codice fiscale nulli, impossibile eseguire la ricerca.";
            return [
                    record      : [],
                    numeroRecord: 0
            ]
        }

        params.max = params?.max ?: 10
        params.offset = params.activePage * params.max

        if ((!filtri.sezione && !filtri.foglio && !filtri.numero && !filtri.subalterno) && !filtri.codFiscale) {
            log.info "Estremi catastali o codice fiscale nulli, impossibile eseguire la ricerca."
            return [
                    record      : [],
                    numeroRecord: 0
            ]
        } else {
            def lista = DatiMetriciTestata.createCriteria().list(params) {

                createAlias("uiu", "uiu", CriteriaSpecification.INNER_JOIN)
                createAlias("uiu.esitiAgenzia", "esag", CriteriaSpecification.LEFT_JOIN)
                createAlias("uiu.esitiComune", "sico", CriteriaSpecification.LEFT_JOIN)
                createAlias("uiu.identificativi", "iden", CriteriaSpecification.INNER_JOIN)
                createAlias("uiu.soggetti", "sogg", CriteriaSpecification.LEFT_JOIN)
                createAlias("uiu.soggetti.datiAtto", "daat", CriteriaSpecification.LEFT_JOIN)
                createAlias("uiu.datiMetrici", "dame", CriteriaSpecification.LEFT_JOIN)
                createAlias("uiu.datiNuovi", "danu", CriteriaSpecification.LEFT_JOIN)

                projections {

                    // Testata
                    distinct('documentoId', 'documentoId')

                    // UIU
                    property('uiu.id', 'uiuId')
                    property('uiu.idUiu', 'immobile')
                    property('uiu.beneComune', 'beneComune')
                    property('uiu.superficie', 'superficie')
                    property('uiu.categoria', 'categoriaCat')

                    // Dati Atto
                    property('daat.data', 'data')
                    property('daat.numeroRepertorio', 'numero')
                    property('daat.raccoltaRepertorio', 'raccolta')

                    // Esito Agenzia
                    property('esag.esitoSup', 'esitoSuperficie')

                    // Dati Nuovi
                    property('danu.superficieTot', 'superficieTotale')
                    property('danu.superficieConv', 'superficieConvenzionale')
                    property('danu.inizioValidita', 'inizioValidita')
                    property('danu.fineValidita', 'fineValidita')
                    property('danu.dataCertificazione', 'dataCertificazione')
                    property('danu.dataProvv', 'dataProvvedimento')
                    property('danu.protocolloProvv', 'protocolloProvvedimento')

                    // Dati Iden
                    property('iden.sezione', 'sezioneCat')
                    property('iden.foglio', 'foglioCat')
                    property('iden.numero', 'numeroCat')
                    property('iden.subalterno', 'subalternoCat')
                }

                if (filtri.sezione && !filtri.sezione.trim().isEmpty()) {
                    eq('iden.sezione', filtri.sezione)
                }
                if (filtri.foglio && !filtri.foglio.trim().isEmpty()) {
                    eq('iden.foglio', filtri.foglio)
                }
                if (filtri.numero && !filtri.numero.trim().isEmpty()) {
                    eq('iden.numero', filtri.numero)
                }
                if (filtri.subalterno && !filtri.subalterno.trim().isEmpty()) {
                    eq('iden.subalterno', filtri.subalterno)
                }

                if (filtri.tipologia) {
                    'in'('tipologia', filtri.tipologia)
                }

                if (filtri.codFiscale) {
                    if (filtri.codFiscale instanceof List) {
                        'in'('sogg.codFiscale', filtri.codFiscale)
                    } else {
                        eq('sogg.codFiscale', filtri.codFiscale)
                    }
                }

                for (def s : sortBy) {
                    order(s.property, s.direction)
                }

                resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            }

            def esitiSuperficie = [
                    '1': 'Calcolata',
                    '2': 'Non calcolabile',
                    '3': 'In corso di definizione',
                    '4': 'Planimetria non presente negli atti catastali'
            ]

            String patternNumero = "#,##0.00"
            DecimalFormat numero = new DecimalFormat(patternNumero)
            def index = 1
            def elencoDatiMetrici = lista.collect { row ->

                def listaIndirizzi = DatiMetriciIndirizzo.createCriteria().list {
                    eq('uiu.id', row.uiuId)
                }

                def indirizzo = "${listaIndirizzi[0]?.toponimo ?: ''} ${listaIndirizzi[0]?.denom ?: ''} ${StringUtils.stripStart(listaIndirizzi[0]?.civico1 ?: '', '0')}"

                def indirizzi = ""
                listaIndirizzi.drop(1).each {
                    if (!indirizzi.empty) {
                        indirizzi += '\n'
                    }
                    indirizzi += "${it.toponimo ?: ''} ${it.denom ?: ''} ${StringUtils.stripStart(it.civico1 ?: '', '0')}"
                }

                def listaIntestatari = []

                DatiMetriciSoggetto.createCriteria().list {
                    eq('uiu.id', row.uiuId)
                }.each { i ->
                    def cont = Contribuente.findByCodFiscale(i.codFiscale)
                    listaIntestatari << [
                            intestatario  : i.denominazione ?: "${i.cognome ?: ''} ${i.nome ?: ''}",
                            codFiscale    : i.codFiscale,
                            sesso         : (i.sesso in ['1', '2']) ? (i.sesso == '1' ? 'M' : 'F') : i.sesso,
                            dataNascita   : i.dataNascita?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                            comune        : Ad4Comune.findBySiglaCodiceFiscale(i.comune ?: i.sede)?.denominazione,
                            isContribuente: cont != null,
                            ni            : cont?.soggetto?.id
                    ]

                }

                def listaUtilizzatoriTari = []

                if (filtri.anno && filtri.anno != 'Tutti') {
                    listaUtilizzatoriTari = utilizzatoriTari(commonService.creaEtremiCatasto(
                            row.sezioneCat,
                            row.foglioCat,
                            row.numeroCat,
                            row.subalternoCat
                    ), filtri.anno as Integer)
                }

                [
                        RIGA                   : index++,
                        immobile               : row.immobile,
                        data                   : row.data?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                        numero                 : row.numero,
                        raccolta               : row.raccolta,
                        beneComune             : row.beneComune == 1,
                        indirizzo              : indirizzo,
                        indirizzi              : indirizzi,
                        superficie             : row.superficie != null ? (numero.format(row.superficie)) : null,
                        superficieNum          : row.superficie,
                        esitoSuperficie        : esitiSuperficie[row.esitoSuperficie?.toString()],
                        superficieTotale       : row.superficieTotale ? numero.format(row.superficieTotale) : null,
                        superficieConvenzionale: row.superficieConvenzionale ? numero.format(row.superficieConvenzionale) : null,
                        inizioValidita         : row.inizioValidita?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                        fineValidita           : row.fineValidita?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                        dataCertificazione     : row.dataCertificazione?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                        dataProvvedimento      : row.dataProvvedimento?.format("dd/MM/yyyy", TimeZone.getTimeZone("Europe/Rome")) ?: null,
                        protocolloProvvedimento: row.protocolloProvvedimento,
                        documentoId            : row.documentoId,
                        intestatari            : listaIntestatari,
                        utilizzatori           : listaUtilizzatoriTari,
                        categoriaCat           : row.categoriaCat,
                        sezioneCat             : row.sezioneCat,
                        foglioCat              : row.foglioCat,
                        numeroCat              : row.numeroCat,
                        subalternoCat          : row.subalternoCat,
                        uiuId                  : row.uiuId
                ]
            }

            return [
                    record      : elencoDatiMetrici,
                    numeroRecord: lista.totalCount
            ]
        }
    }

    def caricaDatiMetriciImmobile(def params) {

        String patternSuperficie = "#,##0.00"
        DecimalFormat formatoSuperficie = new DecimalFormat(patternSuperficie)

        def datiMetriciSuperficie = DatiMetrici.createCriteria().list {
            createAlias("uiu", "uiu", CriteriaSpecification.INNER_JOIN)
            // params.uiuId
            eq("uiu.id", params.uiuId)
            order("ambiente")
        }.collect {
            [
                    ambiente     : it.ambiente,
                    ambienteDescr: tipiAmbiente[it?.ambiente]?.descrizione,
                    superficie   : (it.superficieAmbiente != null) ? formatoSuperficie.format(it.superficieAmbiente) : null,
                    altezza      : (it.altezza != null) ? formatoSuperficie.format(it.altezza) : null,
                    altezzaMax   : (it.altezzaMax != null) ? formatoSuperficie.format(it.altezzaMax) : null
            ]
        }
    }

    def caricaDatiMetriciNonPresentiInArchivio(def codFiscale, def immobili, def anno) {

        def idImmobili = immobili.isEmpty() ? "(-1)" : "(${immobili.unique().join(",")})"
        def listaCf = "(" + ([
                "'${codFiscale}'"
        ] + soggettiAssociati(codFiscale)
                .collect { "'${it.codFiscaleRic}'" }).join(",") + ")"

        def sql = """
                    select rownum row_num, dm.* from (
                  select distinct *
                      from (select
                             dmui.uiu_id      uiu_id,
                             dmui.id_uiu      immobile,
                             dmui.bene_comune,
                             dmui.superficie,
                             dmui.categoria   categoria_cat,
                             dmui.sez_cens,
                             dmda.data,
                             dmda.numero_repertorio   numero,
                             dmda.raccolta_repertorio raccolta,
                             dmea.esito_sup esito_superficie,
                             dmdn.superficie_tot      superficie_totale,
                             dmdn.superficie_conv     superficie_convenzionale,
                             dmdn.inizio_validita,
                             dmdn.fine_validita,
                             dmdn.data_certificazione,
                             dmdn.data_provv          data_provvedimento,
                             dmdn.protocollo_provv    protocollo_provvedimento,
                             dmso.cod_fiscale,
                             dmid.sezione      sezione_cat,
                             dmid.foglio       foglio_cat,
                             dmid.numero       numero_cat,
                             dmid.denominatore,
                             dmid.subalterno   subalterno_cat,
                             dmid.edificialita,
                             dmin.indirizzi_id,
                             dmin.cod_toponimo,
                             dmin.toponimo,
                             dmin.toponimo || ' ' || dmin.denom || ' ' || ltrim(ltrim(dmin.civico1, '0'), ' ') indirizzo,
                             dmin.denom,
                             dmin.codice,
                             ltrim(ltrim(dmin.civico1, '0'), ' ') civico1,
                             dmin.civico2,
                             dmin.civico3,
                             dmin.fonte,
                             dmin.delibera,
                             dmin.localita,
                             dmin.cap,
                             lpad(ltrim(nvl(dmid.sezione, ' '), '0'), 3, ' ') ||
                             lpad(ltrim(nvl(dmid.foglio, ' '), '0'), 5, ' ') ||
                             lpad(ltrim(nvl(dmid.numero, ' '), '0'), 5, ' ') ||
                             lpad(ltrim(nvl(dmid.subalterno, ' '), '0'), 4, ' ') || lpad(' ', 3) estremi_catasto
                              from dati_metrici                dame,
                                   dati_metrici_uiu            dmui,
                                   dati_metrici_esiti_agenzia  dmea,
                                   dati_metrici_esiti_comune   dmec,
                                   dati_metrici_identificativi dmid,
                                   dati_metrici_soggetti       dmso,
                                   dati_metrici_dati_atto      dmda,
                                   dati_metrici_indirizzi      dmin,
                                   dati_metrici_dati_nuovi     dmdn
                             where dame.uiu_id(+) = dmui.uiu_id
                               and dmea.uiu_id(+) = dmui.uiu_id
                               and dmec.uiu_id(+) = dmui.uiu_id
                               and dmid.uiu_id = dmui.uiu_id
                               and dmso.uiu_id(+) = dmui.uiu_id
                               and dmda.soggetti_id(+) = dmso.soggetti_id
                               and dmin.uiu_id(+) = dmui.uiu_id
                               and dmdn.uiu_id(+) = dmui.uiu_id) dm
                     where dm.cod_fiscale in $listaCf
                           and dm.immobile in $idImmobili
                           and nvl(dm.inizio_validita, to_Date('18500101', 'YYYYMMDD')) <=
                                to_Date($anno || '1231', 'YYYYMMDD')
                           and nvl(dm.fine_validita, to_Date('99991231', 'YYYYMMDD')) >=
                                to_Date($anno || '0101', 'YYYYMMDD')) dm
                     order by dm.immobile
                    """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }

        return results
    }

    def soggettiAssociati(def codFiscale) {
        def sql = """
                select *
                  from contribuenti_cc_soggetti coso, cc_soggetti sogg
                 where coso.id_soggetto = sogg.id_soggetto_ric
                   and coso.cod_fiscale = :pCodFiscale
            """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            setString('pCodFiscale', codFiscale)

            list()
        }

        return results
    }

    def leggiParametroUtente(def parametro) {

        def param = ParametroUtente.createCriteria().list {

            eq('tipoParametro.id', parametro)
            eq('utente', springSecurityService.currentUser.id)
        }

        return param[0]
    }

    def creaParametroUtente(def parametro, def valore, def descrizione = 'Nuovo parametro') {

        /*
            In alcuni ambienti si verifica:
            org.hibernate.HibernateException: A collection with cascade="all-delete-orphan" was no longer referenced by the owning entity instance: it.finmatica.tr4.Oggetto.notificheOggetto
            In SVI/TEST non sono riuscito a riprodurlo, la puliza della session annulla le modifiche ed evita l'errore.
         */
        sessionFactory.currentSession.clear()

        def tipoParametro = TipoParametro.get(parametro)
        if (!tipoParametro) {
            tipoParametro = new TipoParametro()
            tipoParametro.id = parametro
            tipoParametro.descrizione = descrizione
            tipoParametro.save(failOnError: true, flush: true)
        }

        def parametroUtente = leggiParametroUtente(parametro) ?: new ParametroUtente([valore: valore, tipoParametro: tipoParametro])

        // Si aggiorna il valore in caso si sia in update
        parametroUtente.valore = valore

        parametroUtente.save(failOnError: true, flush: true)

    }

    // Cerca contribuente e in caso crea da codice fsicale e salva in db
    def ricavaContribuente(String codFiscale) {

        Contribuente contribuenteRaw = Contribuente.findByCodFiscale(codFiscale)
        if (contribuenteRaw == null) {
            contribuenteRaw = new Contribuente()
            Soggetto soggettoRaw = Soggetto.findByCodFiscale(codFiscale)
            if (soggettoRaw == null) {
                soggettoRaw = Soggetto.findByPartitaIva(codFiscale)
                if (soggettoRaw == null) {
                    throw new Exception("Soggetto ${codFiscale} non trovato ")
                }
            }
            contribuenteRaw.soggetto = soggettoRaw
            contribuenteRaw.codFiscale = codFiscale
            contribuenteRaw.save(flush: true, failOnError: true)
        }

        return contribuenteRaw
    }

    // Cerca contribuente e in caso crea contribuente da Soggetto e salva in db
    def creaContribuente(SoggettoDTO soggettoDTO) {

        Contribuente contribuente
        Soggetto soggetto = soggettoDTO.getDomainObject()

        contribuente = Contribuente.findBySoggetto(soggetto)

        if (contribuente == null) {

            String codFiscale = soggettoDTO.codFiscale ?: ""
            if (codFiscale.isEmpty()) {
                codFiscale = soggettoDTO.partitaIva ?: ""
            }
            if (codFiscale.isEmpty()) {
                throw new Exception("Codice Fiscale vuoto o non valido ")
            }
            codFiscale = codFiscale.toUpperCase()

            contribuente = new Contribuente()
            contribuente.codFiscale = codFiscale
            contribuente.soggetto = soggetto

            contribuente.save(flush: true, failOnError: true)
        }

        return contribuente
    }

    def oggettiContribuenteStoria(def codiceFiscale, List<String> listaTipiTributo = null, List<String> listaTipiPratica = null, def filtroTipoOggetto = null) {

        def whereTipoTributo = "and oca.TIPO_TRIBUTO in :pTipiTributo"
        def whereTipoPratica = "and oca.TIPO_PRATICA in :pTipiPratica"
        def whereTipoOggetto = ""


        def tipoViolazione = [
                ID: 'Infedele Denuncia',
                OD: 'Omessa Denuncia'
        ]

        if (filtroTipoOggetto) {
            if (filtroTipoOggetto == 'CF') {
                whereTipoOggetto = " and oca.tipo_oggetto = 3 "
            } else if (filtroTipoOggetto == 'CT') {
                whereTipoOggetto = " and oca.tipo_oggetto in (1,2) "
            }
        }

        String sql = """
                select Rank() over(partition by oca.oggetto order by oca.inizio_validita desc, oca.fine_validita desc, oca.oggetto) "posizione",
                       oca.anno                    "annoSelezionato",
                       oca.anno_ogco               "anno",
                       oca.tipo_tributo            "tipoTributo",
                       oca.des_tipo_tributo        "tributoDescrizione",
                       oca.tipo_pratica            "tipoPratica",
                       oca.tipo_evento             "tipoEvento",
                       oca.tipo_rapporto           "tipoRapporto",
                       oca.data_decorrenza         "dataDecorrenza",
                       oca.data_cessazione         "dataCessazione",
                       oca.mesi_possesso           "mesiPossesso",
                       oca.mesi_esclusione         "mesiEsclusione",
                       oca.mesi_riduzione          "mesiRiduzione",
                       oca.mesi_ab_principale      "mesiAbPri",
                       oca.tributo                 "tributo",
                       oca.categoria               "categoria",
                       oca.tipo_tariffa            "tipoTariffa",
                       oca.consistenza             "consistenza",
                       oca.rendita                 "rendita",
                       oca.valore                  "valore",
                       oca.oggetto                 "oggetto",
                       oca.descrizione             "descrizione",
                       oca.id_immobile             "idImmobile",
                       oca.indirizzo               "indirizzo",
                       oca.num_civ                 "numCiv",
                       oca.suffisso                "suff",
                       oca.tipo_oggetto            "tipoOggetto",
                       oca.partita                 "partita",
                       oca.sezione                 "sezione",
                       oca.foglio                  "foglio",
                       oca.numero                  "numero",
                       oca.subalterno              "subalterno",
                       oca.zona                    "zona",
                       oca.latitudine              "latitudine",
                       oca.longitudine             "longitudine",
                       oca.estremi_catasto         "estremiCatasto",
                       oca.categoria_catasto       "categoriaCatasto",
                       oca.classe                  "classeCatasto",
                       oca.flag_possesso           "flagPossesso",
                       oca.perc_possesso           "percPossesso",
                       oca.flag_esclusione         "flagEsclusione",
                       oca.flag_riduzione          "flagRiduzione",
                       oca.flag_contenzioso        "flagContenzioso",
                       oca.imm_storico             "immStorico",
                       oca.pratica                 "pratica",
                       oca.data_cessazione_ogge    "dataCessazioneOggetto",
                       oca.flag_oggetto_cessato    "oggettoCessato",
                       oca.oggetto_pratica         "oggettoPratica",
                       oca.flag_punto_raccolta     "flagPuntoRaccolta",
                       oca.flag_rfid               "flagRfid",
                       oca.flag_ab_principale      "flagAbPrincipale",
                       oca.numero_familiari        "numeroFamiliari",
                       oca.inizio_validita         "inizioValidita",
                       oca.fine_validita           "fineValidita",
                       oca.flag_aliquote_ogco      "flagAliquoteOgco",
                       oca.flag_utilizzi_oggetto   "flagUtilizziOggetto",
                       oca.inizio_validita_riog    "inizioValiditaRiog",
                       oca.flag_Anomalie             "flagAnomalie",
                       oca.oggetto_pratica_rif_ap "oggettoPraticaRifAp",
                       oca.tipo_rapporto "tipoRapportoOgim",
                       oca.flag_pertinenza_di "flagPertinenzaDi",
                       oca.flag_familiari "flagFamiliari",
                       oca.flag_altri_contribuenti "flagAltriContribuenti",
                       oca.tipo_violazione "tipoViolazione"
                  from oggetti_contribuente_anno oca
                 where
                     oca.COD_FISCALE = :pCodFis
                     and oca.utente = :pUtente
                     ${!listaTipiTributo.empty ? whereTipoTributo : "and 1 = 0"}
                     ${!listaTipiPratica.empty ? whereTipoPratica : "and 1 = 0"}
                     ${whereTipoOggetto}
                 order by "estremiCatasto",
                          "inizioValidita",
                          "fineValidita",
                          "idImmobile",
                          "oggetto"
                            """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('pCodFis', codiceFiscale)
            setString('pUtente', springSecurityService.currentUser.id)

            if (!listaTipiTributo.empty) {
                setParameterList("pTipiTributo", listaTipiTributo)
            }

            if (!listaTipiPratica.empty) {
                setParameterList("pTipiPratica", listaTipiPratica)
            }

            list()
        }

        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd")
        results.each {
            it.uuid = UUID.randomUUID().toString().replace('-', '')
            it.key = null
            it.subKey = null

            it.rendita = it.rendita?.toDouble()?.round(2)

            if (it.idImmobile) {
                it.key = "${it.oggetto}-${it.idImmobile}-${it.tipoTributo}"
                it.subKey = "${it.idImmobile}"
                if (it.inizioValiditaRiog) {
                    it.key += "-${sdf.format(it.inizioValiditaRiog)}"
                    it.subKey += "-${sdf.format(it.inizioValiditaRiog)}"
                }
            }

            it.tipoEventoViolazione = it.tipoViolazione != null ?
                    "${it.tipoEvento} - ${it.tipoViolazione}" : it.tipoEvento
            it.tipoEventoViolazioneTooltip = it.tipoViolazione != null ?
                    "${it.tipoEvento} - ${tipoViolazione[it.tipoViolazione]}" : ''
        }

        return results
    }

    def inserisciOggetti(def codFiscale, def anno, def annoFiltro, def cbTributi, def mesiPossesso, def oggettiSelezionati, def tipoPratica) {

        def result

        if (cbTributi.ICI) {
            result = inserisciPratica(codFiscale, anno, 'ICI', mesiPossesso, oggettiSelezionati, tipoPratica)
        }

        return result
    }

    def chiudiOggetti(def codFiscale, def anno, def annoFiltro, def mesiPossesso, def meseInizioPossesso, def oggetti) {

        def listaOggettiICI = oggetti.findAll { it.tipoTributo == 'ICI' }.collect { it.oggetto }
        def listaOggettiTASIPropr = oggetti.findAll { it.tipoTributo == 'TASI' && it.tipoRapporto == 'D' }.collect {
            it.oggetto
        }
        def listaOggettiTASIOcc = oggetti.findAll { it.tipoTributo == 'TASI' && it.tipoRapporto == 'A' }.collect {
            it.oggetto
        }

        // IMU/ICI
        if (!listaOggettiICI.empty) {
            chiudiElencoOggetti(codFiscale, anno, annoFiltro, 'ICI', mesiPossesso, meseInizioPossesso, listaOggettiICI)
        }

        // TASI: Proprietari
        if (!listaOggettiTASIPropr.empty) {
            chiudiElencoOggetti(codFiscale, anno, annoFiltro, 'TASI', mesiPossesso, meseInizioPossesso, listaOggettiTASIPropr)
        }

        // TASI: Occupanti
        if (!listaOggettiTASIOcc.empty) {
            chiudiElencoOggetti(codFiscale, anno, annoFiltro, 'TASI', mesiPossesso, meseInizioPossesso, listaOggettiTASIOcc)
        }
    }

    def chiudiOggettiTarsu(def anno, def contribuente, def utenze, def data1, def data2, def soggDest, def inizioOccupazione, def dataDecorrenza, def dataDel, def numero) {
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        def denuncia = new DenunciaTarsuDTO()
        denuncia.pratica = new PraticaTributoDTO()
        denuncia.pratica.tipoCarica = new TipoCaricaDTO()
        denuncia.pratica.contribuente = contribuente
        denuncia.pratica.anno = anno as short
        denuncia.pratica.tipoTributo = TipoTributo.get("TARSU").toDTO()
        denuncia.pratica.tipoEvento = TipoEventoDenuncia.C
        denuncia.pratica.numero = numero
        denuncia.pratica.data = sdf.parse(sdf.format(dataDel))

        def idPratica = denunceService.salvaDenuncia(
                denuncia, [], 'D', false, null,
                null, false, false, 'TARSU')
                .denuncia.pratica.id

        // Si annullano le info da non riportare sulle denunce di cessazione
        utenze.each {
            it.numeroFamiliari = null
            it.titoloOccupazione = -1
            it.naturaOccupazione = -1
            it.destinazioneUso = -1
            it.assenzaEstremiCatasto = -1
        }

        // Quadri di cessazione
        oggettiService.creaOggettoContribuenteTarsuDaLocazioniCessate(
                idPratica,
                utenze,
                data1,
                data2
        )

        // Trasferimento ad altro contribuente
        if (soggDest) {

            // Non si riporta il flag di abitazione principale
            utenze.each {
                it.flagAbPrincipale = false
            }

            apriOggettiTarsu(anno, soggDest, utenze, inizioOccupazione, dataDecorrenza)
        }
    }

    def variaOggettoTarsu(def anno, def contribuente, def utenze,
                          def data1, def data2,
                          def datoMetrico,
                          def flagDaDatiMetrici,
                          def superficie,
                          def flagRiduzioneSuperficie,
                          def note = "") {
        def denuncia = new DenunciaTarsuDTO()
        denuncia.pratica = new PraticaTributoDTO()
        denuncia.pratica.tipoCarica = new TipoCaricaDTO()
        denuncia.pratica.contribuente = contribuente
        denuncia.pratica.anno = anno as short
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        denuncia.pratica.data = sdf.parse(sdf.format(new Date()))
        denuncia.pratica.tipoTributo = TipoTributo.get("TARSU").toDTO()
        denuncia.pratica.tipoEvento = TipoEventoDenuncia.V

        def idPratica = denunceService.salvaDenuncia(
                denuncia, [], 'D', false, null,
                null, false, false, 'TARSU')
                .denuncia.pratica.id

        def prtr = PraticaTributo.get(idPratica)
        prtr.note = note
        prtr.save(failOnError: true, flush: true)


        def ogco = oggettiService.creaOggettoContribuenteTarsuDaLocazioniCessate(
                idPratica,
                utenze,
                data1,
                data2
        )[0]

        def dmPercRid = (OggettiCache.INSTALLAZIONE_PARAMETRI.valore.find { it.parametro == 'DM_PERCRID' }?.valore?.trim() as Double) ?: 80.0
        // Si applica la riduzione sulla superficie
        OggettoPratica ogpr = ogco.oggettoPratica.toDomain()
        ogpr.consistenza = superficie
        ogpr.flagDatiMetrici = flagDaDatiMetrici ? 'S' : null
        ogpr.percRiduzioneSup = flagRiduzioneSuperficie ? dmPercRid : 100

        ogpr.save(failOnError: true, flush: true)
    }

    private utilizzatoriTari(String estremiCatastali, Integer anno) {
        def sql = """
                    select replace(sogg.cognome_nome, '/', ' ') utilizzatore,
                           conx.cod_fiscale,
                           sogg.sesso,
                           sogg.ni,
                           to_char(sogg.data_nas, 'DD/MM/YYYY') data_nascita,
                           comu.denominazione comune
                      from oggetti_validita ogva,
                           oggetti          ogge,
                           contribuenti     conx,
                           soggetti         sogg,
                           ad4_comuni       comu
                     where ogva.tipo_tributo = 'TARSU'
                       and ogva.oggetto = ogge.oggetto
                       and ogge.estremi_catasto = :pEstremiCatasto
                       and nvl(ogva.dal, to_date('01011900', 'ddmmyyyy')) <=
                           to_date('3112' || :pAnno, 'ddmmyyyy')
                       and nvl(ogva.al, to_date('31122999', 'ddmmyyyy')) >=
                           to_date('0101' || :pAnno, 'ddmmyyyy')
                       and ogva.cod_fiscale = conx.cod_fiscale
                       and conx.ni = sogg.ni
                       and sogg.cod_com_nas = comu.comune(+)
                       and sogg.cod_pro_nas = comu.provincia_stato(+)
                    """

        return sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE
            setString('pEstremiCatasto', estremiCatastali)
            setInteger('pAnno', anno)

            list()
        }
    }

    private apriOggettiTarsu(def anno, def soggetto, def utenze, def inizioOccupazione, def dataDecorrenza) {

        def denuncia = new DenunciaTarsuDTO()
        denuncia.pratica = new PraticaTributoDTO()
        denuncia.pratica.tipoCarica = new TipoCaricaDTO()

        def codFiscale = (soggetto instanceof SoggettoDTO) ?
                (soggetto?.contribuenti[0]?.codFiscale?.toUpperCase() ?: soggetto?.codFiscale?.toUpperCase() ?: soggetto?.partitaIva?.toUpperCase()) :
                (soggetto?.codFiscale?.toUpperCase() ?: soggetto?.partitaIva?.toUpperCase())
        Contribuente cont = Contribuente.findByCodFiscale(codFiscale)

        if (!cont) {
            denuncia.pratica.contribuente = new ContribuenteDTO(codFiscale: codFiscale)
            denuncia.pratica.contribuente.soggetto = soggetto
        } else {
            denuncia.pratica.contribuente = cont.toDTO(["soggetto", "ente"])
        }

        denuncia.pratica.anno = anno as short
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
        denuncia.pratica.data = sdf.parse(sdf.format(new Date()))
        denuncia.pratica.tipoTributo = TipoTributo.get("TARSU").toDTO()
        denuncia.pratica.tipoEvento = TipoEventoDenuncia.I

        def idPratica = denunceService.salvaDenuncia(denuncia, [], 'D', false, null, null, false, false, 'TARSU')
                .denuncia.pratica.id

        oggettiService.creaOggettoContribuenteTarsuDaLocazioniCessate(
                idPratica,
                utenze,
                inizioOccupazione,
                dataDecorrenza
        )
    }

    def creaOggettiTarsuDaDatiMetrici(def contribuente, def anno, def oggettiDaInserire, def tipoPratica) {

        PraticaTributo pratica
        if (tipoPratica == TipoPratica.D.tipoPratica) {
            def denuncia = new DenunciaTarsuDTO()
            denuncia.pratica = new PraticaTributoDTO()
            denuncia.pratica.tipoCarica = new TipoCaricaDTO()
            denuncia.pratica.contribuente = contribuente
            denuncia.pratica.anno = anno as short
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
            denuncia.pratica.data = sdf.parse(sdf.format(new Date()))
            denuncia.pratica.tipoTributo = TipoTributo.get("TARSU").toDTO()
            denuncia.pratica.tipoEvento = TipoEventoDenuncia.I
            denuncia.pratica.note = "Cancellazione del ${new Date().format('dd/MM/yyyy')}"

            pratica = PraticaTributo.get(denunceService.salvaDenuncia(denuncia, [], 'D', false,
                    null, null, false, false, 'TARSU')
                    .denuncia.pratica.id)
        } else if (tipoPratica == TipoPratica.A.tipoPratica) {
            pratica = new PraticaTributo()
            pratica.contribuente = contribuente.toDomain()
            pratica.anno = anno as short
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy")
            pratica.data = sdf.parse(sdf.format(new Date()))
            pratica.tipoTributo = TipoTributo.get("TARSU")
            pratica.tipoPratica = tipoPratica
            pratica.tipoEvento = TipoEventoDenuncia.U
            pratica.note = "Inserimento da dati metrici"

            pratica = pratica.save(failOnError: true, flush: true)
            pratica.tipoCalcolo = 'N'

            // Rapporti tributo
            RapportoTributo ratr = new RapportoTributo()
            ratr.tipoRapporto = 'E'
            ratr.contribuente = contribuente.toDomain()
            ratr.pratica = pratica
            ratr.save(failOnError: true, flush: true)

        }

        try {
            oggettiDaInserire.each {
                OggettoPratica ogpr = new OggettoPratica([pratica: pratica])


                // OGG
                def ogg = [:]
                // Per i dati metrici ci aspettiamo solo fabbricati
                ogg.TIPOOGGETTO = 'F'
                ogg.INDIRIZZOCOMPLETO = it.toponimo + ' ' + it.denom
                ogg.CIVICO = it.civico1
                ogg.SCALA = null
                ogg.PIANO = null
                ogg.INTERNO = null
                ogg.SEZIONE = it.sezioneCat
                ogg.FOGLIO = it.foglioCat
                ogg.NUMERO = it.numeroCat
                ogg.SUBALTERNO = it.subalternoCat
                ogg.ZONA = null
                ogg.ESTREMICATASTO = it.estremiCatasto
                ogg.PARTITA = null
                ogg.CATEGORIACATASTO = it.categoriaCat
                ogg.CLASSECATASTO = null
                ogg.IDIMMOBILE = it.immobile

                // OGPR
                ogpr.oggetto = creaOggettoSeNonEsiste(ogg)?.oggetto
                ogpr.codiceTributo = it.codiceTributo.toDomain()

                ogpr.categoria = it.categoria?.toDomain()
                ogpr.anno = pratica.anno
                // Per le tariffe è stato creato un id fittizio, si deve associare la tariffa con l'anno preso dalla pratica
                // e non con l'anno proveniente dalla locazione selezionata
                ogpr.tariffa = it.tariffa.toDomain()
                ogpr.consistenza = it.superficie
                ogpr.tipoOccupazione = TipoOccupazione.P
                ogpr.numeroFamiliari = it.numeroFamiliari
                ogpr.flagContenzioso = it.flagContenzioso ?: false
                ogpr.flagDatiMetrici = it.flagDaDatiMetrici ? 'S' : null
                ogpr.percRiduzioneSup = it.flagRiduzioneSuperficie ? it.percRiduzioneSuperficie : null

                // OGCO
                OggettoContribuente ogco = new OggettoContribuente([
                        oggettoPratica   : ogpr,
                        contribuente     : contribuente.toDomain(),
                        anno             : anno,
                        tipoRapporto     : tipoPratica == TipoPratica.A.tipoPratica ? 'E' : 'D',
                        inizioOccupazione: it.inizioOccupazione,
                        dataDecorrenza   : it.dataDecorrenza,
                        percPossesso     : it.percPossesso,
                        flagAbPrincipale : it.flagAbPrincipale ?: false
                ])

                ogpr.oggettiContribuente = [ogco]
                ogpr.save(failOnError: true, flush: true)

                ogco.oggettoPratica = ogpr
                ogco = ogco.save(failOnError: true, flush: true)

                if (tipoPratica == TipoPratica.A.tipoPratica) {
                    liquidazioniAccertamentiService.calcolaAccertamentoManualeOgCo(pratica.anno, [:], pratica.toDTO(), ogco.toDTO())
                }

            }
        } catch (Exception e) {
            pratica?.delete(flush: true)

            commonService.serviceException(e)
        }

        return pratica
    }

    private chiudiElencoOggetti(def codFiscale, def anno, def annoFiltro, def tipoTributo, def mesiPossesso, def meseInizioPossesso, def oggetti) {

        def sqlOggetti = """
                select distinct ogco.anno "anno",
                    prtr.pratica "pratica",
                    ogpr.oggetto_pratica "oggettoPratica",
                   f_valore(nvl(f_valore_d(ogpr.oggetto_pratica, :pAnno), ogpr.valore),
                            nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),
                            prtr.anno,
                            :pAnno,
                            nvl(ogpr.categoria_catasto, ogge.categoria_catasto),
                            prtr.tipo_pratica,
                            ogpr.flag_valore_rivalutato) "valore",
                   nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) "tipoOggetto",
                   ogge.oggetto "oggetto",
                   nvl(ogpr.categoria_catasto, ogge.categoria_catasto) "categoriaCatasto",
                   nvl(ogpr.classe_catasto, ogge.classe_catasto) "classeCatasto",
                   prtr.pratica "pratica",
                   ogpr.oggetto_pratica "oggettoPratica",
                   ogpr.flag_valore_rivalutato "flagValoreRivalutato",
                   ogco.perc_possesso "percPossesso",
                   rapr.tipo_rapporto "tipoRapporto",
                   ogco.flag_esclusione "flagEsclusione",
                   ogco.flag_riduzione "flagRiduzione",
                   ogco.flag_al_ridotta "flagAlRidotta",
                   ogpr.oggetto_pratica_rif_ap "oggettoPraticaRifAp",
                    (select tipo_rapporto
                       from oggetti_imposta ogim
                      where ogim.cod_fiscale = ogco.cod_fiscale
                        and ogim.oggetto_pratica = ogpr.oggetto_pratica
                        and ogim.anno = 2015) "tipoRapportoOgim"
              from 
                   oggetti              ogge,
                   pratiche_tributo     prtr,
                   oggetti_pratica      ogpr,
                   oggetti_contribuente ogco,
                   rapporti_tributo rapr
             where prtr.pratica = ogpr.pratica
               and ogge.oggetto = ogpr.oggetto
               and ogpr.oggetto_pratica = ogco.oggetto_pratica
               AND rapr.pratica = prtr.pratica
               and rapr.cod_fiscale = prtr.cod_fiscale
               and ogco.cod_fiscale = :pCf
               and (prtr.tipo_pratica = 'D' or (prtr.tipo_pratica = 'A' and prtr.flag_Denuncia = 'S' and nvl(prtr.stato_accertamento, 'D') = 'D')) 
               and prtr.tipo_tributo = :pTipoTributo
               and ogpr.oggetto_pratica =
                   f_max_ogpr_cont_ogge(ogge.oggetto,
                                        :pCf,
                                        prtr.tipo_tributo,
                                        decode(:pAnno, 9999, '%', prtr.tipo_pratica),
                                        :pAnno,
                                        '%')
               and decode(prtr.tipo_tributo,
                          'ICI',
                          decode(flag_possesso,
                                 'S',
                                 flag_possesso,
                                 decode(:pAnno, 9999, 'S', prtr.anno, 'S', null)),
                          'S') = 'S'
               and ogpr.oggetto in (:pOggetti)
               order by ogpr.oggetto_pratica_rif_ap DESC
                        """
        def oggettiDaChiudere = sessionFactory.currentSession.createSQLQuery(sqlOggetti).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('pCf', codFiscale)
            setLong('pAnno', annoFiltro)
            setParameterList('pOggetti', oggetti)
            setString('pTipoTributo', tipoTributo)
            list()
        }

        def praticheAnniPrecedenti = oggettiDaChiudere.findAll { it.anno != anno }
        def praticheStessoAnno = oggettiDaChiudere.findAll { it.anno == anno }

        def abitazioniPrincipali = praticheAnniPrecedenti.findAll { it.oggettoPraticaRifAp != null }.collect {
            [ogpr: it.oggettoPraticaRifAp, newOgpr: null]
        }

        if (!praticheStessoAnno.empty) {
            praticheStessoAnno.each { ogg ->
                OggettoContribuente.createCriteria().list {
                    createAlias("oggettoPraticaId", "ogpr", CriteriaSpecification.INNER_JOIN)

                    eq("ogpr.id", ogg.oggettoPratica as Long)
                    eq("contribuente.codFiscale", codFiscale)
                    eq("flagPossesso", true)
                }.each { oc ->
                    if (oc.detrazione != null && oc.detrazione != 0) {
                        oc.detrazione = (oc.detrazione / (oc.mesiPossesso ?: 12)) * mesiPossesso
                    }
                    oc.flagAbPrincipale = false
                    oc.flagAlRidotta = false
                    oc.flagEsclusione = false
                    oc.flagRiduzione = false
                    oc.flagPossesso = false
                    oc.mesiPossesso = mesiPossesso
                    oc.daMesePossesso = meseInizioPossesso
                    if (mesiPossesso > 0) {
                        if (meseInizioPossesso > 6) {
                            oc.mesiPossesso1sem = 0
                        } else {
                            def mfp = (meseInizioPossesso + mesiPossesso) - 1
                            mfp = mfp > 6 ? 6 : mfp
                            oc.mesiPossesso1sem = (mfp - meseInizioPossesso) + 1
                        }
                    } else {
                        oc.mesiPossesso1sem = 0
                    }

                    oc.save(failOnError: true, flush: true)
                }
            }
        }

        if (!praticheAnniPrecedenti.empty) {
            def pratica = new PraticaTributo()
            def contribuente = Contribuente.findByCodFiscale(codFiscale)
            def note = "Cancellazione del ${new Date().format('dd/MM/yyyy')}"
            def tipoPratica = "D"

            // Pratica
            pratica.tipoTributo = TipoTributo.get(tipoTributo)
            pratica.tipoEvento = TipoEventoDenuncia.C
            pratica.tipoPratica = tipoPratica
            pratica.contribuente = contribuente
            pratica.anno = anno
            pratica.note = note

            // Si passa la data senza l'informazione sull'ora per evitare che una piccola differenza in secondi faccia scattare l'errore del trigger Oracle.
            SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy")
            pratica.data = formatter.parse(formatter.format(new Date()))

            // Rapporti tributo
            RapportoTributo ratr = new RapportoTributo()

            if (praticheAnniPrecedenti[0].tipoRapporto != 'E') {
                ratr.tipoRapporto = praticheAnniPrecedenti[0].tipoRapporto
            } else {
                ratr.tipoRapporto = (tipoTributo == 'ICI') ? 'D' : praticheAnniPrecedenti[0].tipoRapportoOgim
            }
            ratr.contribuente = contribuente
            pratica.addToRapportiTributo(ratr)

            // Si salva la pratica per recuperare l'ID
            pratica.save(failOnError: true, flush: true)

            // DenunciaTributo, al momento sono gestiti solo ICI e TASI
            def denuncia = (tipoTributo == 'ICI' ? new DenunciaIci() : new DenunciaTasi())
            denuncia.id = pratica.id
            denuncia.denuncia = pratica.id
            denuncia.pratica = pratica
            denuncia.fonte = getFonteInserimentoAutomatico()
            denuncia.save(failOnError: true, flush: true)

            // Oggetti Pratica
            def numOrd = 1
            praticheAnniPrecedenti.each {

                def ogprOriginale = OggettoPratica.get(it.oggettoPratica)
                def ogcoOriginale = ogprOriginale.oggettiContribuente.find { it.contribuente.codFiscale == codFiscale }

                OggettoPratica ogpr = new OggettoPratica()
                ogpr.oggetto = Oggetto.get(it.oggetto)
                ogpr.pratica = pratica
                ogpr.anno = anno
                ogpr.categoriaCatasto = CategoriaCatasto.get(it.categoriaCatasto)
                ogpr.classeCatasto = it.classeCatasto
                ogpr.valore = it.valore
                ogpr.note = note
                ogpr.numOrdine = numOrd++
                ogpr.tipoOggetto = TipoOggetto.get(it.tipoOggetto)

                // Se pertinenza si deve settare il nuovoOgprRifAb
                if (it.oggettoPraticaRifAp) {
                    ogpr.oggettoPraticaRifAp = abitazioniPrincipali.findAll { ap ->
                        ap.ogpr == it.oggettoPraticaRifAp
                    }[0].newOgpr
                }

                ogpr.save(failOnError: true, flush: true)
                // Se abitazione principale si salva il nuovo ogpr da utilizzare per la cessazione delle pertinenze
                abitazioniPrincipali.findAll { ap -> ap.ogpr == it.oggettoPratica }.each { it.newOgpr = ogpr }

                // Oggetti Contribuente
                OggettoContribuente ogco = new OggettoContribuente()
                ogco.oggettoPratica = ogpr
                ogco.contribuente = contribuente
                ogco.anno = anno
                ogco.tipoRapporto = pratica.rapportiTributo[0].tipoRapporto
                ogco.percPossesso = it.percPossesso
                ogco.mesiPossesso = mesiPossesso
                if (meseInizioPossesso > 0) {
                    ogco.mesiPossesso1sem = (mesiPossesso >= 6 ? 6 : mesiPossesso)
                } else {
                    ogco.mesiPossesso1sem = 0
                }
                ogco.note = note
                ogco.daMesePossesso = meseInizioPossesso

                // Gestione mesi esclusione e riduzione
                if (it.flagEsclusione == 'S') {
                    ogco.mesiEsclusione = mesiPossesso
                }
                if (it.flagRiduzione == 'S') {
                    ogco.mesiRiduzione = mesiPossesso
                }
                if (it.flagAlRidotta == 'S') {
                    ogco.mesiAliquotaRidotta = mesiPossesso
                }

                ogco.flagAbPrincipale = ogcoOriginale.flagAbPrincipale

                // Gestione detrazione
                if (ogcoOriginale.flagAbPrincipale && ogcoOriginale.detrazione == null) {
                    ogco.detrazione = 0
                }

                if (ogcoOriginale.detrazione != null && ogcoOriginale.detrazione != 0) {
                    ogco.detrazione = ricalcolaDetrazione(ogcoOriginale, ogco, pratica.tipoTributo, pratica.anno)
                }

                ogco.save(failOnError: true, flush: true)

                // Gestione Aliquote OGCO
                ogcoOriginale.aliquoteOgco.each {
                    def aOgco = new AliquotaOgco([dal                : it.dal,
                                                  al                 : it.al,
                                                  tipoAliquota       : it.tipoAliquota,
                                                  note               : it.note,
                                                  oggettoContribuente: ogco])
                    aOgco.save(flush: true, failOnError: true)
                }

                // Gestione Detrazioni OGCO
                ogcoOriginale.detrazioniOgco.each {
                    def dOgco = new DetrazioneOgco([motDetrazione      : it.motDetrazione,
                                                    anno               : it.anno,
                                                    detrazione         : it.detrazione,
                                                    note               : it.note,
                                                    detrazioneAcconto  : it.detrazioneAcconto, motivoDetrazione: it.motivoDetrazione,
                                                    oggettoContribuente: ogco])
                    dOgco.save(flush: true, failOnError: true)
                }
            }
        }
    }

    def anomalieOggetto(def anno, def cf, def oggettoPratica, def oggetto) {
        def listaAnomaliePratiche = AnomaliaParametro.createCriteria().list {
            createAlias("anomalie", "anom", CriteriaSpecification.INNER_JOIN)
            createAlias("anom.anomaliePratiche", "anpr", CriteriaSpecification.INNER_JOIN)

            eq("anno", anno as Short)
            eq("anpr.oggettoContribuente.contribuente.codFiscale", cf)
            eq("anpr.oggettoContribuente.oggettoPratica.id", oggettoPratica)

        }

        def listaAnomalieOggetto = AnomaliaParametro.createCriteria().list {
            createAlias("anomalie", "anom", CriteriaSpecification.INNER_JOIN)

            eq("anno", anno as Short)
            eq("anom.oggetto.id", oggetto)
        }

        def listaAnomalieIci = AnomaliaIci.createCriteria().list {
            createAlias("oggetto", "ogge", CriteriaSpecification.INNER_JOIN)

            eq("anno", anno as Short)
            eq('ogge.id', oggetto)
        }

        return listaAnomaliePratiche.collect { it.tipoAnomalia.tipoAnomalia }.unique() +
                listaAnomalieOggetto.collect { it.tipoAnomalia.tipoAnomalia }.unique() +
                listaAnomalieIci.collect { it.tipoAnomalia.tipoAnomalia }.unique()
    }

    private inserisciPratica(def codFiscale, def anno, def tipoTributo, def mesiPossesso, oggettiSelezionati, def tipoPratica) {

        def messaggi = ""

        def pratica = new PraticaTributo()
        def contribuente = Contribuente.findByCodFiscale(codFiscale)
        def noteD = "Inserimento del ${new Date().format('dd/MM/yyyy')}"
        def noteA = """Inserimento da ${tipoTributo == 'ICI' ? 'catasto' : 'dati metrici'}"""

        TipoEventoDenuncia tipoEvento = null
        String tipoRapporto = null
        if (tipoPratica == TipoPratica.A.tipoPratica) {
            tipoEvento = TipoEventoDenuncia.U
            tipoRapporto = "E"
        } else if (tipoPratica == TipoPratica.D.tipoPratica) {
            tipoEvento = TipoEventoDenuncia.I
            tipoRapporto = "D"
        }

        // Pratica
        pratica.tipoTributo = TipoTributo.get(tipoTributo)
        pratica.tipoEvento = tipoEvento
        pratica.tipoPratica = tipoPratica
        pratica.contribuente = contribuente
        pratica.anno = anno
        pratica.note = tipoPratica == TipoPratica.A.tipoPratica ? noteA : noteD

        // Si passa la data senza l'informazione sull'ora per evitare che una piccola differenza in secondi faccia scattare l'errore del trigger Oracle.
        SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy")
        pratica.data = formatter.parse(formatter.format(new Date()))

        // Si salva la pratica per recuperare l'ID
        pratica.save(failOnError: true, flush: true)

        // Rapporti tributo
        RapportoTributo ratr = new RapportoTributo()
        ratr.tipoRapporto = tipoRapporto
        ratr.contribuente = contribuente
        ratr.pratica = pratica
        ratr.save(failOnError: true, flush: true)

        // DenunciaTributo, al momento sono gestiti solo ICI e TASI
        if (tipoPratica == TipoPratica.D.tipoPratica) {
            def denuncia = (tipoTributo == 'ICI' ? new DenunciaIci() : new DenunciaTasi())
            denuncia.id = pratica.id
            denuncia.denuncia = pratica.id
            denuncia.pratica = pratica
            denuncia.fonte = getFonteInserimentoAutomatico()
            denuncia.save(failOnError: true, flush: true)
        }

        // Oggetti Pratica
        def numOrd = 1
        oggettiSelezionati.each {
            def oggetto = creaOggettoSeNonEsiste(it)
            def ogg = oggetto.oggetto

            if (oggetto.msg != null && !oggetto.msg.isEmpty()) {
                messaggi += "Oggetto ${ogg.id}: ${oggetto.msg}\n"
            }

            OggettoPratica ogpr = new OggettoPratica()

            if (tipoPratica == TipoPratica.A.tipoPratica) {
                ogpr.flagValoreRivalutato = true
            }

            ogpr.oggetto = ogg
            ogpr.pratica = pratica
            ogpr.anno = anno
            ogpr.categoriaCatasto = ogg.categoriaCatasto
            ogpr.classeCatasto = ogg.classeCatasto
            ogpr.valore = oggettiService.valoreDaRendita(
                    it.TIPOOGGETTO == 'F' ? it.RENDITA : it.REDDITODOMINICALE,
                    it.TIPOOGGETTO == 'F' ? 3 : 1,
                    anno,
                    it.CATEGORIACATASTO,
                    null)
            ogpr.note = tipoPratica == TipoPratica.A.tipoPratica ? noteA : noteD
            ogpr.numOrdine = numOrd++
            ogpr.tipoOggetto = ogg.tipoOggetto

            ogpr.save(failOnError: true, flush: true)

            // Oggetti Contribuente
            OggettoContribuente ogco = new OggettoContribuente()
            ogco.oggettoPratica = ogpr
            ogco.contribuente = contribuente
            ogco.anno = anno
            ogco.tipoRapporto = ratr.tipoRapporto
            ogco.percPossesso = it.POSSESSOPERC

            def mesi = calcolaMesiDaOggetto(it, anno)
            ogco.daMesePossesso = mesi.mip
            ogco.mesiPossesso = mesi.mp
            ogco.mesiPossesso1sem = mesi.mp1s
            ogco.flagPossesso = tipoPratica == TipoPratica.A.tipoPratica ? false : (mesi.fp == 'S')

            ogco.note = tipoPratica == TipoPratica.A.tipoPratica ? noteA : noteD

            ogco.save(failOnError: true, flush: true)

            // Gestione aliquote_ogco
            if (tipoPratica == TipoPratica.D.tipoPratica) {
                gestioneAlog(ogco, pratica.tipoTributo)
            }
        }

        return [pratica: pratica, messaggi: messaggi]
    }

    private gestioneAlog(OggettoContribuente ogco, def tipoTributo) {
        // Gestione ALOG
        def sqlAlog = """
                select distinct alog.dal "dal", alog.al "al", alog.tipo_aliquota "tipoAliquota", alog.note "note"
                  from aliquote_ogco alog, oggetti_pratica ogpr
                 where alog.oggetto_pratica = ogpr.oggetto_pratica
                   and alog.cod_fiscale = :codFis
                   and alog.tipo_tributo = :tipoTributo
                   and ogpr.oggetto = :oggetto
                   and to_date('01/01/' || :anno, 'dd/mm/yyyy') between alog.dal and
                       nvl(alog.al, to_date('31/12/9999', 'dd/mm/yyyy'))
                """


        def results = sessionFactory.currentSession.createSQLQuery(sqlAlog).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setLong('oggetto', ogco.oggettoPratica.oggetto.id)
            setString('codFis', ogco.contribuente.codFiscale)
            setString('anno', (ogco.anno as String))
            setString('tipoTributo', tipoTributo.tipoTributo)

            list()
        }

        results.each {
            def tAliq = TipoAliquota.findByTipoAliquotaAndTipoTributo(it.tipoAliquota, tipoTributo)
            def aOgco = new AliquotaOgco([dal                : it.dal,
                                          al                 : it.al,
                                          tipoAliquota       : tAliq,
                                          note               : it.note,
                                          oggettoContribuente: ogco])

            aOgco.save(flush: true, failOnError: true)
        }

    }

    private calcolaMesiDaOggetto(def ogg, def anno) {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd")
        def dataInizio = [ogg.DATAINIZIOVALIDITA, ogg.DATAEFFICACIAINIZIO].max { it }
        def dataFine = [ogg.DATAFINEVALIDITA ?: sdf.parse("99991231"), ogg.DATAEFFICACIAFINE ?: sdf.parse("99991231")].min { it }

        return calcolaMesi(dataInizio, dataFine, anno)
    }


    def calcolaMesi(def dataInizio, def dataFine, def anno) {

        def lastDay = { date ->
            Calendar c = Calendar.getInstance()
            c.setTime(date)
            return c.getActualMaximum(Calendar.DAY_OF_MONTH)
        }

        def giorniPossesso = { giorno1, giorno2 ->
            giorno2 - giorno1 + 1

        }

        def sdf = new SimpleDateFormat("yyyyMMdd")

        def fp = null // flagPossesso
        def mp = null //  mesiPossesso
        def mp1s = 0 // mesiPossesso1Sem
        def mip = 0 // meseInzialePossesso
        def mfp = 0

        // Inizio
        if (dataInizio.getAt(Calendar.YEAR) < anno) {
            dataInizio = sdf.parse("${anno}0101")
        }

        // Fine
        if ((dataFine?.getAt(Calendar.YEAR) ?: 9999) > anno) {
            dataFine = sdf.parse("${anno}1231")

            // Calcolo fp
            // Se l'immobile è posseduto dopo l'anno FP al 31/12 è S
            fp = 'S'
        }

        def sogliaMeseInizio = (lastDay(dataInizio) / 2).setScale(0, RoundingMode.HALF_DOWN) + 1
        def sogliaMeseFine = (lastDay(dataFine) / 2).setScale(0, RoundingMode.HALF_DOWN) + 1

        def giornoInizio = dataInizio.getAt(Calendar.DAY_OF_MONTH)
        def meseInizio = dataInizio.getAt(Calendar.MONTH) + 1

        def giornoFine = dataFine.getAt(Calendar.DAY_OF_MONTH)
        def meseFine = dataFine.getAt(Calendar.MONTH) + 1

        // Calcolo mp
        if (meseInizio == meseFine) {
            if (giornoInizio <= sogliaMeseInizio) {
                mp = 1

                if (giornoFine <= sogliaMeseFine) {
                    mp--
                }
            } else {
                mp = 0
            }
        } else {
            mp = meseFine - meseInizio + 1
            if (giornoInizio > sogliaMeseInizio) {
                mp--
            }
            if (giornoFine <= sogliaMeseFine) {
                mp--
            }
        }

        // Calcolo mip
        if (mp == 0) {
            mip = 1
        } else if (meseInizio == 12) {
            if (fp == 'S') {
                mip = 12
            } else {
                mip = 0
            }
        } else {
            mip = giornoInizio <= sogliaMeseInizio ? meseInizio : meseInizio + 1
        }

        // Calcolo mp1s
        if (meseInizio <= 6) {
            if (meseFine >= 6) {
                mp1s = 7 - mip
                if (meseFine <= 6 && giornoFine <= sogliaMeseFine) {
                    mp1s--
                }
            } else {
                mp1s = meseFine - meseInizio + 1

                if (giorniPossesso(giornoInizio, lastDay(dataInizio)) < sogliaMeseInizio) {
                    mp1s--
                }

                if (meseFine <= 6 && giornoFine <= sogliaMeseFine) {
                    mp1s--
                }
            }
        }

        return [mp: mp, mp1s: mp1s, fp: fp, mip: mip]
    }

    private creaOggettoSeNonEsiste(def ogg, def codFiscale = null) {

        def creato = false

        def tipoOggetto = TipoOggetto.findByTipoOggetto(ogg.TIPOOGGETTO == 'F' ? 3 : 1)
        def oggetti = Oggetto.createCriteria().list {
            createAlias("oggettiPratica", "ogpr", CriteriaSpecification.INNER_JOIN)
            createAlias("ogpr.pratica", "prtr", CriteriaSpecification.INNER_JOIN)
            createAlias("prtr.contribuente", "cont", CriteriaSpecification.INNER_JOIN)

            // Al momento gestiamo solo IMU/TASI
            'in'('prtr.tipoTributo.tipoTributo', ['ICI', 'TASI'])
            // eq("idImmobile", ogg.IDIMMOBILE)
            eq('estremiCatasto', ogg.ESTREMICATASTO)
            eq('tipoOggetto', tipoOggetto)

            if (codFiscale) {
                eq('cont.codFiscale', codFiscale)
            }
        }

        def oggetto = oggetti.findAll { it.idImmobile == ogg.IDIMMOBILE }.sort { -it.id }[0] ?: // Se esiste un oggetto del contribuente con stesso idImmobile
                oggetti.sort { -it.id }[0] ?: // Se esiste un oggetto del contribuente
                        Oggetto.findAllByEstremiCatastoAndTipoOggetto(ogg.ESTREMICATASTO, tipoOggetto).sort { -it.id }[0] ?: // Un qualsiasi oggetto
                                new Oggetto() // Si crea un nuovo oggetto

        if (!oggetto.id) {

            creato = true

            oggetto.tipoOggetto = TipoOggetto.findByTipoOggetto(ogg.TIPOOGGETTO == 'F' ? 3 : 1)
            oggetto.indirizzoLocalita = ogg.INDIRIZZOCOMPLETO
            if (ogg.INDIRIZZOCOMPLETO) {
                def listaDenom = DenominazioneVia.createCriteria().listDistinct {
                    ilike("descrizione", "${ogg.INDIRIZZOCOMPLETO.toLowerCase()}%")
                }

                if (listaDenom.size() == 1) {
                    oggetto.archivioVie = listaDenom[0].archivioVie
                }
            }
            if (ogg.CIVICO?.isNumber()) {
                oggetto.numCiv = ogg.CIVICO as Integer
            }
            oggetto.scala = ogg.SCALA
            oggetto.piano = ogg.PIANO?.length() > 5 ? ogg.PIANO?.substring(0, 4) : ogg.PIANO
            oggetto.interno = ogg.INTERNO
            oggetto.sezione = ogg.SEZIONE?.trim()
            oggetto.foglio = ogg.FOGLIO?.trim()
            oggetto.numero = ogg.NUMERO?.trim()
            oggetto.subalterno = ogg.SUBALTERNO?.trim()
            oggetto.zona = ogg.ZONA?.trim()
            oggetto.estremiCatasto = ogg.ESTREMICATASTO
            oggetto.partita = ogg.PARTITA
            if (oggetto.tipoOggetto.tipoOggetto == 1L) {
                oggetto.categoriaCatasto = CategoriaCatasto.findByCategoriaCatasto("T")
            } else {
                oggetto.categoriaCatasto = CategoriaCatasto.findByCategoriaCatasto(ogg.CATEGORIACATASTO?.trim())
            }
            oggetto.classeCatasto = ogg.CLASSECATASTO
            oggetto.fonte = getFonteInserimentoAutomatico()
        }

        // Solo se nulle vengono sovrascritte con le informazioni da catasto
        oggetto.idImmobile = oggetto.idImmobile ?: ogg.IDIMMOBILE
        oggetto.categoriaCatasto = oggetto.categoriaCatasto ?: CategoriaCatasto.findByCategoriaCatasto(ogg.CATEGORIACATASTO?.trim())
        oggetto.classeCatasto = oggetto.classeCatasto ?: ogg.CLASSECATASTO

        oggetto.save(failOnError: true, flush: true)

        def msg = ""
        if (creato) {
            msg = oggettiService.inserimentoOggettiRendite(
                    ogg.IDIMMOBILE,
                    oggetto.id,
                    ogg.TIPOOGGETTO,
                    new SimpleDateFormat("dd/MM/yyyy").parse("01/01/1990"),
                    'S')
        }

        return [oggetto: oggetto, msg: msg]
    }

    private ricalcolaDetrazione(def ogcoOriginale, def nuovaOgco, def tipoTributo, def anno) {

        def detrazioneAnnoDenuncia = Detrazione.findByAnnoAndTipoTributo(ogcoOriginale.anno, tipoTributo)
        def rapportoDetrazione = ((ogcoOriginale.detrazione / (ogcoOriginale.mesiPossesso ?: 12)) * 12) / detrazioneAnnoDenuncia.detrazioneBase
        def detrazioneAnnoAttuale = Detrazione.findByAnnoAndTipoTributo(anno, tipoTributo)
        def detrazioneAttuale = ((detrazioneAnnoAttuale.detrazioneBase / 12) * nuovaOgco.mesiPossesso) * rapportoDetrazione

        return detrazioneAttuale
    }

    private getFonteInserimentoAutomatico() {

        def id = 86
        def descrizione = "INSERIMENTO AUTOMATICO DICHIARAZIONI"
        def fonte = Fonte.findByDescrizione(descrizione) ?: new Fonte([fonte: id, descrizione: descrizione])
        fonte.save(failOnError: true, flush: true)

        return fonte
    }

    def contribuenteEnte(def codFiscale, def tipoTributo, def niEredePrincipale = null) {

        if (niEredePrincipale != null) {
            Sql sqlErede = new Sql(dataSource)
            sqlErede.call('{? = call stampa_common.set_ni_erede_principale(?)}',
                    [Sql.NUMERIC,
                     niEredePrincipale]
            )
        }

        String sql = """
                    SELECT coen.*
                        FROM CONTRIBUENTI CONX, CONTRIBUENTI_ENTE coen
                        where COEN.NI = CONX.NI
                        and COEN.TIPO_TRIBUTO = :P_TIPO_TRIBUTO
                        and CONX.COD_FISCALE = :P_COD_FISCALE
                    """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('P_COD_FISCALE', codFiscale)
            setString('P_TIPO_TRIBUTO', tipoTributo)
            list()
        }

        if (niEredePrincipale != null) {
            Sql sqlErede = new Sql(dataSource)
            sqlErede.call('{call stampa_common.delete_ni_erede_principale}',
            )
        }

        return results
    }

    boolean checkTipoTributo(String tipoTributo) {
        return competenzeService.tipoAbilitazioneUtente(tipoTributo) != null
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    String fRecapito(def ni, def tipoTributo, def tipoContatto) {
        String v
        Sql sql = new Sql(dataSource)
        sql.call('{? = call f_recapito(?, ?, ?)}'
                , [
                Sql.VARCHAR,
                ni,
                tipoTributo,
                tipoContatto
        ]) { v = it }
        return v
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    String fPrimoEredeCodFiscale(def ni) {
        String v
        Sql sql = new Sql(dataSource)
        sql.call('{? = call F_PRIMO_EREDE_COD_FISCALE(?)}'
                , [
                Sql.VARCHAR,
                ni
        ]) { v = it }
        return v
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    private BigDecimal fImportAccLordo(def idPratica, def ridotto) {
        def importo = 0.0
        try {
            Sql sql = new Sql(dataSource)
            sql.call('{? = call F_IMPORTO_ACC_LORDO(?,?)}',
                    [
                            Sql.NUMERIC,
                            idPratica,
                            ridotto
                    ]) { imp ->
                importo = imp
            }
        } catch (Exception e) {
            e.printStackTrace()
            commonService.serviceException(e)
        }
        return importo
    }

    def getContribuente(def filter) {
        return Contribuente.createCriteria().get {
            fetchMode('soggetto', FetchMode.JOIN)
            if (filter.codFiscale) {
                eq('codFiscale', filter.codFiscale)
            }
            if (filter.codContribuente) {
                eq('codContribuente', filter.codContribuente)
            }
        }?.toDTO(["soggetto"])
    }

    def getContribuenteSoggettoByNI(def ni) {
        return Contribuente.createCriteria().get {
            fetchMode('soggetto', FetchMode.JOIN)

            eq('soggetto.id', ni)

        } ?: Soggetto.get(ni)
    }

    def getContribuenteByCodContribuenteCodControllo(def codContribuente, def codControllo) {
        return Contribuente.findByCodContribuenteAndCodControllo(codContribuente, codControllo)
    }

    @Transactional
    void aggiornaContribuente(def contribuente) {

        Contribuente cont = Contribuente.get(contribuente.codFiscale)

        cont.id = cont.codFiscale
        cont.codAttivita = contribuente.codAttivita
        cont.codControllo = contribuente.codControllo
        cont.note = contribuente.note
        cont.codContribuente = contribuente.codContribuente
        cont.save(failOnError: true, flush: true)

        if (cont.codFiscale != contribuente.codFiscaleNuovo) {
            def updateSql = sessionFactory.currentSession
                    .createSQLQuery("update contribuenti contx set contx.cod_fiscale = :pCodFiscaleNuovo where contx.cod_fiscale = :pCodFiscale")
            updateSql.setString("pCodFiscaleNuovo", contribuente.codFiscaleNuovo)
            updateSql.setString("pCodFiscale", cont.codFiscale)
            updateSql.executeUpdate()
        }
    }

    def getCodiciAttivita() {

        String query = "select * from codici_attivita order by 1"
        return sessionFactory.currentSession.createSQLQuery(query).with {

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }
    }

    def getSoggettoContribuente(SoggettoDTO soggetto) {

        String query = """
        SELECT "SOGGETTI"."NI",
               "SOGGETTI"."STATO",
               DECODE("SOGGETTI"."RAPPORTO_PAR", 'CF', 'Intestatario Scheda', NULL) intestatario,
               DECODE("CONTRIBUENTI"."COD_CONTRIBUENTE",
                      NULL,
                      NULL,
                      "CONTRIBUENTI"."COD_CONTRIBUENTE" || '-' ||
                      "CONTRIBUENTI"."COD_CONTROLLO") cod_contr,
               COM_RES."DENOMINAZIONE" ||
               DECODE(PROV_RES."SIGLA", NULL, '', ' (' || PROV_RES."SIGLA" || ')') comune_res,
               COM_NAS."DENOMINAZIONE" ||
               DECODE(PROV_NAS."SIGLA", NULL, '', ' (' || PROV_NAS."SIGLA" || ')') comune_nas,
               decode("SOGGETTI"."COD_VIA",
                      NULL,
                      "SOGGETTI"."DENOMINAZIONE_VIA",
                      "ARCHIVIO_VIE"."DENOM_UFF") ||
               decode(num_civ, NULL, '', ', ' || num_civ) ||
               decode(suffisso, NULL, '', '/' || suffisso) ||
               decode(scala, NULL, '', ' Sc.' || scala) ||
               decode(piano, NULL, '', ' P.' || piano) ||
               decode(interno, NULL, '', ' Int.' || interno) indirizzo,
               translate("SOGGETTI"."COGNOME_NOME", '/', ' ') cognome_nome,
               NVL("SOGGETTI"."COD_FISCALE", "SOGGETTI"."PARTITA_IVA") SOGG_COD_FISCALE,
               "SOGGETTI"."TIPO_RESIDENTE",
               "SOGGETTI"."DATA_NAS",
               "SOGGETTI"."FASCIA",
               "SOGGETTI"."COD_FAM",
               "CONTRIBUENTI"."NOTE",
               "CONTRIBUENTI"."COD_FISCALE",
               "CONTRIBUENTI"."COD_CONTRIBUENTE",
               "CONTRIBUENTI"."COD_CONTROLLO",
               "CONTRIBUENTI"."COD_ATTIVITA" 
               FROM "CONTRIBUENTI",
               "SOGGETTI",
               "ARCHIVIO_VIE",
               "AD4_COMUNI"    "COM_RES",
               "AD4_PROVINCIE" "PROV_RES",
               "AD4_COMUNI"    "COM_NAS",
               "AD4_PROVINCIE" "PROV_NAS" 
         WHERE (soggetti.cod_via = archivio_vie.cod_via(+))
           and (soggetti.cod_pro_res = COM_RES.provincia_stato(+))
           and (soggetti.cod_com_res = COM_RES.comune(+))
           and (PROV_RES.provincia(+) = COM_RES.provincia_stato)
           and (COM_NAS.provincia_stato = PROV_NAS.provincia(+))
           and (soggetti.cod_pro_nas = COM_NAS.provincia_stato(+))
           and (soggetti.cod_com_nas = COM_NAS.comune(+))
           and ("SOGGETTI"."NI" = "CONTRIBUENTI"."NI")
           and ("SOGGETTI"."NI" = :p_ni)
        """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            setLong("p_ni", soggetto.id)

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0]
    }


    def getFlagsTributiPratiche(String codFiscale) {

        String query = """
        SELECT 
            MAX (DECODE (tipo_tributo, 'ICI', 'SI', 'NO')) trib_ici,
            MAX (DECODE (tipo_tributo, 'ICIAP', 'SI', 'NO')) trib_iciap,
            MAX (DECODE (tipo_tributo, 'ICP', 'SI', 'NO')) trib_icp,
            MAX (DECODE (tipo_tributo, 'TARSU', 'SI', 'NO')) trib_rsu,
            MAX (DECODE (tipo_tributo, 'TOSAP', 'SI', 'NO')) trib_tosap,
            MAX (DECODE (tipo_pratica, 'A', 'SI', 'NO')) prat_acc,
            MAX (DECODE (tipo_pratica, 'D', 'SI', 'NO')) prat_dic,
            MAX (DECODE (tipo_pratica, 'L', 'SI', 'NO')) prat_liq,
            MAX (DECODE (tipo_tributo, 'TASI', 'SI', 'NO')) trib_tasi
        FROM pratiche_tributo
        WHERE pratiche_tributo.cod_fiscale = :p_codFiscale
 """

        return sessionFactory.currentSession.createSQLQuery(query).with {

            setString("p_codFiscale", codFiscale)

            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE

            list()
        }[0]
    }


    @Deprecated
    def esistePraticaNotificata(def codFiscale, def anno, def tipoTributo, def tipoPratica) {

        def numeroPratiche = 0

        Sql sql = new Sql(dataSource)
        sql.call('{ ? = call F_ESISTE_PRATICA_NOTIFICATA(?, ?, ?, ?)}',
                [
                        Sql.NUMERIC,
                        codFiscale,
                        anno,
                        tipoTributo,
                        tipoPratica
                ],
                { numeroPratiche = it }
        )

        return numeroPratiche > 0
    }

    @Deprecated
    def esisteVersamentoPratica(def codFiscale, def anno, def tipoTributo) {

        def numeroVersamenti = 0

        Sql sql = new Sql(dataSource)
        sql.call('{ ? = call F_ESISTE_VERSAMENTO_PRATICA(?, ?, ?)}',
                [
                        Sql.NUMERIC,
                        codFiscale,
                        anno,
                        tipoTributo
                ],
                { numeroVersamenti = it }
        )

        return numeroVersamenti > 0
    }

    // Metodo con sasi di test per calcolaMesi, da eseguire nel caso di modifiche.
    static calcolaMesiTest() {

        def testCase = []
        def annoTest = 2020
        def sdf = new SimpleDateFormat("yyyyMMdd")
        def testDate = [
                // Casi per mesi di 28/29/30/31 giorni
                // Mese di 28 giorni
                [dataInizio: sdf.parse("20180214"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 11, fp: 'S', mp1s: 5, mip: 2],
                [dataInizio: sdf.parse("20180215"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 11, fp: 'S', mp1s: 5, mip: 2],
                [dataInizio: sdf.parse("20180216"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 10, fp: 'S', mp1s: 4, mip: 3],
                // Mese di 29 giorni
                [dataInizio: sdf.parse("20200214"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 11, fp: 'S', mp1s: 5, mip: 2],
                [dataInizio: sdf.parse("20200215"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 11, fp: 'S', mp1s: 5, mip: 2],
                [dataInizio: sdf.parse("20200216"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 10, fp: 'S', mp1s: 4, mip: 3],
                // Mese di 30 giorni
                [dataInizio: sdf.parse("20200415"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 9, fp: 'S', mp1s: 3, mip: 4],
                [dataInizio: sdf.parse("20200416"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 9, fp: 'S', mp1s: 3, mip: 4],
                [dataInizio: sdf.parse("20200417"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 8, fp: 'S', mp1s: 2, mip: 5],
                // Mese di 31 giorni
                [dataInizio: sdf.parse("20200515"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 8, fp: 'S', mp1s: 2, mip: 5],
                [dataInizio: sdf.parse("20200516"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 8, fp: 'S', mp1s: 2, mip: 5],
                [dataInizio: sdf.parse("20200517"), dataFine: sdf.parse("99991231"), anno: 2018, mp: 7, fp: 'S', mp1s: 1, mip: 6],
                [dataInizio: sdf.parse("20010522"), dataFine: sdf.parse("20180116"), anno: 2018, mp: 0, fp: 'N', mp1s: 0, mip: 1],
                // Anno del range coincide con anno
                // Possesso sull'intero anno
                [dataInizio: sdf.parse("${annoTest}0101"), dataFine: sdf.parse("${annoTest + 1}1231"), anno: annoTest, mp: 12, fp: 'S', mp1s: 6, mip: 1],
                // Mese inizio posseduto e mese fine posseduto
                [dataInizio: sdf.parse("${annoTest}0115"), dataFine: sdf.parse("${annoTest}1222"), anno: annoTest, mp: 12, fp: 'N', mp1s: 6, mip: 1],
                // Mese inizio non posseduto e mese fine posseduto
                [dataInizio: sdf.parse("${annoTest}0125"), dataFine: sdf.parse("${annoTest}1216"), anno: annoTest, mp: 10, fp: 'N', mp1s: 5, mip: 2],
                // Mese inizio posseduto e mese fine non posseduto
                [dataInizio: sdf.parse("${annoTest}0116"), dataFine: sdf.parse("${annoTest}1212"), anno: annoTest, mp: 11, fp: 'N', mp1s: 6, mip: 1],
                // Mese inizio e mese fine coincidono e l'oggetto è posseduto nel primo semestre
                [dataInizio: sdf.parse("${annoTest}0202"), dataFine: sdf.parse("${annoTest}0229"), anno: annoTest, mp: 1, fp: 'N', mp1s: 1, mip: 2],
                // Mese inizio e mese fine coincidono e l'oggetto è posseduto nel secondo semestre
                [dataInizio: sdf.parse("${annoTest}0702"), dataFine: sdf.parse("${annoTest}0729"), anno: annoTest, mp: 1, fp: 'N', mp1s: 0, mip: 7],
                // Mese inizio e mese fine nei due semestri mi e mf posseduti
                [dataInizio: sdf.parse("${annoTest}0502"), dataFine: sdf.parse("${annoTest}0729"), anno: annoTest, mp: 3, fp: 'N', mp1s: 2, mip: 5],
                // Mese inizio e mese fine nei due semestri mi e mf non posseduti
                [dataInizio: sdf.parse("${annoTest}0518"), dataFine: sdf.parse("${annoTest}0711"), anno: annoTest, mp: 1, fp: 'N', mp1s: 1, mip: 6],
                // Mese inizio e mese fine nei due semestri mi posseduto
                [dataInizio: sdf.parse("${annoTest}0513"), dataFine: sdf.parse("${annoTest}0711"), anno: annoTest, mp: 2, fp: 'N', mp1s: 2, mip: 5],
                // Mese inizio e mese fine nei due semestri mf posseduto
                [dataInizio: sdf.parse("${annoTest}0524"), dataFine: sdf.parse("${annoTest}0718"), anno: annoTest, mp: 2, fp: 'N', mp1s: 1, mip: 6],
                // Mese inizio e mese fine nei due semestri e possesso al 31/12
                [dataInizio: sdf.parse("${annoTest}0524"), dataFine: sdf.parse("${annoTest + 1}1218"), anno: annoTest, mp: 7, fp: 'S', mp1s: 1, mip: 6],
                // Mese 28
                [dataInizio: sdf.parse("20190205"), dataFine: sdf.parse("20190214"), anno: 2019, mp: 0, fp: 'N', mp1s: 0, mip: 1],
                [dataInizio: sdf.parse("20190205"), dataFine: sdf.parse("20190215"), anno: 2019, mp: 0, fp: 'N', mp1s: 0, mip: 1],
                // Mese 29
                [dataInizio: sdf.parse("20200205"), dataFine: sdf.parse("20200214"), anno: 2020, mp: 0, fp: 'N', mp1s: 0, mip: 1],
                [dataInizio: sdf.parse("20200205"), dataFine: sdf.parse("20200215"), anno: 2020, mp: 0, fp: 'N', mp1s: 0, mip: 1],
                // Caso di test segnalato
                [dataInizio: sdf.parse("${annoTest}0316"), dataFine: sdf.parse("${annoTest}0415"), anno: annoTest, mp: 1, fp: 'N', mp1s: 1, mip: 3],
                // Caso di test issue 45973
                [dataInizio: sdf.parse("20151029"), dataFine: sdf.parse("20151106"), anno: 2015, mp: 0, fp: 'N', mp1s: 0, mip: 1],
                // Caso di test issue 47304 nota 9
                [dataInizio: sdf.parse("20151029"), dataFine: sdf.parse("20151106"), anno: 2015, mp: 0, fp: 'N', mp1s: 0, mip: 1],
                // Caso di test 47866
                [dataInizio: sdf.parse("20080924"), dataFine: sdf.parse("20161230"), anno: 2016, mp: 12, fp: 'N', mp1s: 6, mip: 1],
                [dataInizio: sdf.parse("20161230"), dataFine: null, anno: 2016, mp: 0, fp: 'S', mp1s: 0, mip: 1],
                // Caso di test Issue 55950
                [dataInizio: sdf.parse("20111212"), dataFine: sdf.parse("20170615"), anno: 2017, mp: 5, fp: 'N', mp1s: 5, mip: 1],

                // Caso di test mese 31 giorni
                [dataInizio: sdf.parse("20220115"), dataFine: sdf.parse("20221231"), anno: 2022, mp: 12, fp: 'N', mp1s: 6, mip: 1],
                [dataInizio: sdf.parse("20220116"), dataFine: sdf.parse("20221231"), anno: 2022, mp: 12, fp: 'N', mp1s: 6, mip: 1],
                [dataInizio: sdf.parse("20220117"), dataFine: sdf.parse("20221231"), anno: 2022, mp: 11, fp: 'N', mp1s: 5, mip: 2],
                [dataInizio: sdf.parse("20220101"), dataFine: sdf.parse("20221215"), anno: 2022, mp: 11, fp: 'N', mp1s: 6, mip: 1],
                [dataInizio: sdf.parse("20220101"), dataFine: sdf.parse("20221216"), anno: 2022, mp: 11, fp: 'N', mp1s: 6, mip: 1],
                [dataInizio: sdf.parse("20220101"), dataFine: sdf.parse("20221217"), anno: 2022, mp: 12, fp: 'N', mp1s: 6, mip: 1],

                // Caso di test mese 30 giorni
                [dataInizio: sdf.parse("20220415"), dataFine: sdf.parse("20221231"), anno: 2022, mp: 9, fp: 'N', mp1s: 3, mip: 4],
                [dataInizio: sdf.parse("20220416"), dataFine: sdf.parse("20221231"), anno: 2022, mp: 9, fp: 'N', mp1s: 3, mip: 4],
                [dataInizio: sdf.parse("20220417"), dataFine: sdf.parse("20221231"), anno: 2022, mp: 8, fp: 'N', mp1s: 2, mip: 5],
                [dataInizio: sdf.parse("20220101"), dataFine: sdf.parse("20220415"), anno: 2022, mp: 3, fp: 'N', mp1s: 3, mip: 1],
                [dataInizio: sdf.parse("20220101"), dataFine: sdf.parse("20220416"), anno: 2022, mp: 3, fp: 'N', mp1s: 3, mip: 1],
                [dataInizio: sdf.parse("20220101"), dataFine: sdf.parse("20220417"), anno: 2022, mp: 4, fp: 'N', mp1s: 4, mip: 1],

                // Caso di test mese 28 giorni
                [dataInizio: sdf.parse("20220214"), dataFine: sdf.parse("20221231"), anno: 2022, mp: 11, fp: 'N', mp1s: 5, mip: 2],
                [dataInizio: sdf.parse("20220215"), dataFine: sdf.parse("20221231"), anno: 2022, mp: 11, fp: 'N', mp1s: 5, mip: 2],
                [dataInizio: sdf.parse("20220216"), dataFine: sdf.parse("20221231"), anno: 2022, mp: 10, fp: 'N', mp1s: 4, mip: 3],
                [dataInizio: sdf.parse("20220101"), dataFine: sdf.parse("20220214"), anno: 2022, mp: 1, fp: 'N', mp1s: 1, mip: 1],
                [dataInizio: sdf.parse("20220101"), dataFine: sdf.parse("20220215"), anno: 2022, mp: 1, fp: 'N', mp1s: 1, mip: 1],
                [dataInizio: sdf.parse("20220101"), dataFine: sdf.parse("20220216"), anno: 2022, mp: 2, fp: 'N', mp1s: 2, mip: 1],

                // Caso di test mese 29 giorni
                [dataInizio: sdf.parse("20200214"), dataFine: sdf.parse("20201231"), anno: 2020, mp: 11, fp: 'N', mp1s: 5, mip: 2],
                [dataInizio: sdf.parse("20200215"), dataFine: sdf.parse("20201231"), anno: 2020, mp: 11, fp: 'N', mp1s: 5, mip: 2],
                [dataInizio: sdf.parse("20200216"), dataFine: sdf.parse("20201231"), anno: 2020, mp: 10, fp: 'N', mp1s: 4, mip: 3],
                [dataInizio: sdf.parse("20200101"), dataFine: sdf.parse("20200214"), anno: 2020, mp: 1, fp: 'N', mp1s: 1, mip: 1],
                [dataInizio: sdf.parse("20200101"), dataFine: sdf.parse("20200215"), anno: 2020, mp: 1, fp: 'N', mp1s: 1, mip: 1],
                [dataInizio: sdf.parse("20200101"), dataFine: sdf.parse("20200216"), anno: 2020, mp: 2, fp: 'N', mp1s: 2, mip: 1],

        ]

        ContribuentiService service = new ContribuentiService()

        def index = 0
        testDate.each {

            index++

            def result = service.calcolaMesi(it.dataInizio, it.dataFine, it.anno)

            def check = (result.mp == it.mp && (result.fp ?: 'N') == it.fp && result.mp1s == it.mp1s && result.mip == it.mip)

            if (!check) {
                println "${index} -> $it"
                println result
                println "${result.mp} == ${it.mp} / ${(result.fp ?: 'N')} == ${it.fp} / ${result.mp1s} == ${it.mp1s} / ${result.mip} == ${it.mip}" +
                        " -> [${(result.mp == it.mp && (result.fp ?: 'N') == it.fp && result.mp1s == it.mp1s && result.mip == it.mip)}]"
            }

        }
    }

    def getSiglaStato(def denominazione) {
        String sql = """
                    SELECT SIGLA_ISO3166_ALPHA2 as "siglaStato"
                        FROM AD4_V_STATI
                        where denominazione = :pDenominazione
                    """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityMapResultTransformer.INSTANCE
            setString('pDenominazione', denominazione)
            list()
        }

        return results.empty ? null : results[0].siglaStato
    }

    def getListaSvuotamenti(def listaOggetti, def codFiscale, def anno, def filtri = null) {

        if (listaOggetti == null || listaOggetti.empty) {
            return []
        }

        // posizione = 1 rappresenta cronologicamente l'utlima riga per l'oggetto
        def oggetti = listaOggetti.findAll { it.tipoTributo == 'TARSU' && it.posizione == 1 }

        if (oggetti.empty) {
            return []
        }

        def filtriSql = """"""

        if (filtri?.rfid) {
            filtriSql += " AND svuo.cod_rfid = '${filtri.rfid.codRfid}'"
        }

        if (filtri?.dataSvuotamentoDa) {
            filtriSql += " and svuo.data_svuotamento >= to_date(${filtri.dataSvuotamentoDa?.format("yyyyMMdd")}, 'YYYYMMDD')"
        }

        if (filtri?.dataSvuotamentoA) {
            filtriSql += " AND svuo.data_svuotamento < to_date(${filtri.dataSvuotamentoA?.format("yyyyMMdd")}, 'YYYYMMDD') + 1"
        }


        def sql = """
                   select svuo.cod_fiscale,
                       svuo.oggetto,
                       svuo.cod_rfid,
                       svuo.sequenza,
                       cast(svuo.data_svuotamento as timestamp) as data_svuotamento,
                       svuo.gps,
                       svuo.stato,
                       svuo.latitudine,
                       svuo.longitudine,
                       cont.unita_di_misura,
                       svuo.quantita,
                       svuo.flag_extra,
                       svuo.documento_id,
                       svuo.utente,
                       svuo.data_variazione,
                       svuo.note,
                       svuo.documento_id,
                       svuo.cod_fiscale || '-' || svuo.oggetto || '-' || svuo.cod_rfid as id_codice_rfid,
                       nvl(svuo.quantita, '') || ' ' || nvl(cont.unita_di_misura, '') quantita_str
                  from svuotamenti svuo, codici_rfid corf, contenitori cont
                 where svuo.cod_fiscale = corf.cod_fiscale
                   and svuo.cod_rfid = corf.cod_rfid
                   and svuo.oggetto = corf.oggetto
                   and corf.cod_contenitore = cont.cod_contenitore
                   and svuo.oggetto in :pOggetti
                   and svuo.cod_fiscale = :pCodFiscale
                   and (
                    :pAnno = 'Tutti' OR
                    extract (year from svuo.data_svuotamento) = to_number(:pAnno))
                   $filtriSql
                 order by svuo.data_svuotamento desc, svuo.oggetto
                """

        def results = sessionFactory.currentSession.createSQLQuery(sql).with {
            resultTransformer = AliasToEntityCamelCaseMapResultTransformer.INSTANCE


            setParameterList('pOggetti', oggetti.collect { it.oggetto }.unique())
            setString('pCodFiscale', codFiscale)
            setString('pAnno', anno)

            list()
        }

        def svuoramenti = []

        results.each { s ->
            svuoramenti << oggetti.find { it.oggetto == s.oggetto } + s
        }

        return svuoramenti
    }
}
