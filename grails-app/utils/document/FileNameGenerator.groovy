package document

import groovy.text.GStringTemplateEngine
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory

class FileNameGenerator {

    private static Log log = LogFactory.getLog(FileNameGenerator)

    private static final def FILENAME_CODFISCALE_LENGTH = 16
    private static final def FILENAME_IDDOCUMENTO_LENGTH = 10
    private static final def FILENAME_IDELABORAZIONE_LENGTH = 8
    private static final def FILENAME_MODEL_LENGTH = 4
    private static final def FILENAME_DATETIME_FORMAT = "yyyyMMddhhmm"
    private static final def FILENAME_DATE_FORMAT = "yyyyMMdd"
    private static final def FILENAME_FILLER_CHAR = '0'

    private FileNameGenerator() {
    }

    enum GENERATORS_TYPE {
        XLSX,
        JASPER,
        MODELLI
    }

    enum GENERATORS_TITLES {
        // XLSX
        MOLTIPLICATORI("moltiplicatori"),
        SANZIONI("sanzioni"),
        ELENCO_DOCUMENTI("elenco_documenti"),
        CANONI("canoni"),
        ELENCO_SOGGETTI("elenco_soggetti"),
        VARIAZIONI_RESIDENZE("variazioni_residenze"),
        VARIAZIONI_ANAGRAFICHE("variazioni_anagrafiche"),
        CATEGORIETARIFFE_CATEGORIE("categorie_tariffe_categorie"),
        CATEGORIETARIFFE_TARIFFE("categorie_tariffe_tariffe"),
        COMPETENZE("competenze"),
        INSTALLAZIONE_PARAMETRI("installazione_parametri"),
        AGGI("aggi"),
        ALIQUOTE("aliquote"),
        ALIQUOTE_ALIQUOTE_PER_CATEGORIA("aliquote_aliquote_per_categoria"),
        CODICI_F24("codici_f24"),
        BENEFICIARI_F24("beneficiari_f24"),
        CODICI_TRIBUTO("codici_tributo"),
        CODIFICHE("codifiche"),
        COMUNICAZIONI("comunicazioni"),
        COMUNICAZIONI_DETTAGLI("comunicazioni_dettagli"),
        COMUNICAZIONI_TESTI("comunicazioni_testi"),
        CONTRIBUTI_IFEL("contributi_ifel"),
        DATI_CONTABILI("dati_contabili"),
        DETRAZIONI("detrazioni"),
        CODIFICHE_TIPI_EVENTO("tipi_evento"),
        CODIFICHE_EVENTI("eventi"),
        INTERESSI("interessi"),
        SCADENZE("scadenze"),
        TIPO_ALIQUOTA("tipo_aliquote"),
        CODIFICHE_TIPI_NOTIFICA("tipi_notifica"),
        TIPI_STATO_CONTRIBUENTE("tipi_stato_contribuente"),
        CODIFICHE_TIPI_TRIBUTO("tipi_tributo"),
        UTILIZZI("utilizzi"),
        ZONE("zone"),
        VIE("vie"),
        RUOLI_AUTOMATICI("ruoli_automatici"),
        ELENCO_IMMOBILI_CATASTO("elenco_immobili_catasto"),
        ELENCO_PROPRIETARI_CATASTO("elenco_proprietari_catasto"),
        INVIO_DEPAG("invio_depag"),
        DETTAGLI("dettagli"),
        ELENCO_PRATICHE("elenco_pratiche"),
        COMPONENTI_CONSISTENZA("componenti_consistenza"),
        COSTI_STORICI("costi_storici"),
        DENUNCE("denunce"),
        INSOLVENTI("insolventi"),
        STATISTICHE_VIOLAZIONI("statistiche_violazioni"),
        STATISTICHE_PRATICHE_RATEIZZATE("statistiche_pratiche_rateizzate"),
        RAVVEDIMENTI("ravvedimenti"),
        LISTA_UTENTI("lista_utenti"),
        LISTA_UTENZE_TARI("lista_utenze_tari"),
        LIQUIDAZIONI("liquidazioni"),
        ACCERTAMENTI("accertamenti"),
        SOLLECITI("solleciti"),
        PRATICHE_RATEIZZATE("pratiche_rateizzate"),
        CONTRIBUENTI_NON_LIQUIDATI("contribuenti_non_liquidati"),
        COMPONENTI_DELLA_FAMIGLIA("componenti_della_famiglia"),
        ELENCO_CONTRIBUENTI("elenco_contribuenti"),
        SEGNALAZIONI_BLOCCANTI("segnalazioni_bloccanti"),
        TARIFFE_MANCANTI("tariffe_mancanti"),
        DECORRENZA_CESSAZIONE("decorrenza_cessazione"),
        FAMILIARI("familiari"),
        NON_RESIDENTI_ABITAZIONE_PRINCIPALE("non_residenti_abitazione_principale"),
        EVENTI_RESIDENZE_STORICHE("eventi_residenze_storiche"),
        ELENCO_RESIDENTI_OGGETTO("elenco_residenti_oggetto"),
        LOCAZIONI("locazioni"),
        UTENZE("utenze"),
        ELENCO_VERSAMENTI("elenco_versamenti"),
        AT_RISPOSTE("at_risposte"),
        AT_PARTITE_IVA("at_partite_iva"),
        AT_DITTE("at_ditte"),
        AT_RAPPRESENTANTI("at_rappresentanti"),
        ANOMALIE_DOCFA("anomalie_docfa"),
        OGGETTI_IMPOSTA_RENDITA("oggetti_imposta_rendita"),
        SOGGETTI_NON_DICHIARANTI("soggetti_non_dichiaranti"),
        BONIFICA_VERSAMENTI_DETTAGLIO("bonifica_versamenti_dettaglio"),
        QUADRATURA_AE("quadratura_ae"),
        FORNITURA_AEG1("forniture_aeg1"),
        FORNITURA_AEG5("forniture_aeg5"),
        FORNITURA_AED("forniture_aed"),
        FORNITURA_AEM("forniture_aem"),
        IMPORT_EXPORT("import_export"),
        COMPENSAZIONI("compensazioni"),
        ELENCO_DOVUTO_VERSATO("elenco_dovuto_versato"),
        IMPOSTE_A_RIMBORSO("imposte_a_rimborso"),
        IMPOSTE_DA_PAGARE("imposte_da_pagare"),
        IMPOSTE_SALDATE("imposte_saldate"),
        IMPOSTE_CONTRIBUENTI("imposte_contribuenti"),
        IMPOSTE_DETTAGLI("imposte_dettagli"),
        IMPOSTE_PER_OGGETTO("imposte_per_oggetto"),
        IMPOSTE_PER_CATEGORIE("imposte_per_categorie"),
        IMPOSTE_PER_ALIQUOTE("imposte_per_aliquote"),
        IMPOSTE_PER_ALIQUOTE_CATEGORIE("imposte_per_aliquote_categorie"),
        IMPOSTE_PER_TIPOLOGIE("imposte_per_tipologie"),
        CARICO_RUOLI("carico_ruoli"),
        CONTRIBUENTI_A_RUOLO("contribuenti_a_ruolo"),
        PRATICHE_A_RUOLO("pratiche_a_ruolo"),
        UTENZE_RUOLO("utenze_ruolo"),
        ECCEDENZE_RUOLO("eccedenze_ruolo"),
        SGRAVI_SU_RUOLO("sgravi_su_ruolo"),
        SGRAVI("sgravi"),
        DATE_INTERESSI_VIOLAZIONI("date_interessi_violazioni"),
        // JASPER
        INSOLVENTI2("insolventi"), // Anche XLSX
        F24("f24"),
        VISURA("visura"),
        RAVVEDIMENTO("ravvedimento"),
        DETTAGLIO_SGRAVIO("dettaglio_sgravio"),
        DETTAGLIO_ELENCO_SGRAVI("dettaglio_elenco_sgravi"),
        PIANO_RIMBORSO("piano_rimborso"),
        OGGETTI_PERTINENZA("oggetti_pertinenza"),
        OGGETTO_PER_VIA("oggetto_per_via"),
        INSERIMENTO_FAMILIARI_SOGGETTI_NON_TRATTATI("inserimento_familiari_soggetti_non_trattati"),
        CODICI_FISCALI_INCOERENTI("codici_fiscali_incoerenti"),
        CODICI_FISCALI_DOPPI("codici_fiscali_doppi"),
        STATISTICHE_PRATICHE("statistiche_pratiche"),
        STATISTICHE_RAVVEDIMENTI("statistiche_ravvedimenti"), // Anche XLSX
        STATISTICHE_RATEAZIONI("statistiche_rateazioni"),
        STATISTICHE_SOLLECITI("statistiche_solleciti"),  // Anche XLSX
        STATISTICHE_ACCERTAMENTI("statistiche_accertamenti"), // Anche XLSX
        STATISTICHE_LIQUIDAZIONI("statistiche_liquidazioni"),
        CALCOLO_INDIVIDUALE("calcolo_individuale"),
        SCHEDA_OGGETTI("scheda_oggetti"),
        SCHEDA_PRATICHE("scheda_pratiche"),
        VERSAMENTI_DOPPI("versamenti_doppi"),
        SQUADRATURA_TOTALE("squadratura_totale"),
        TOTALE_VERSAMENTI("totale_versamenti"),
        TOTALE_VERSAMENTI_PER_GIORNO("totale_versamenti_per_giorno"),
        CONTRATTI_LOCAZIONI("contratti_locazioni"),
        VERSAMENTI("versamenti"),
        MINUTA_RUOLO("minuta_di_ruolo"),
        RIEPILOGO_PER_CATEGORIA("tiepilogo_per_categoria"),
        MINUTA_PER_CATEGORIA("minuta_per_categoria"),
        // MODELLI
        LIQ("LIQ"), // Anche XLSX
        ACC("ACC"), // Anche XLSX
        SOL("SOL"),
        DEN("DEN"),
        RAI("RAI"),
        PRAT("PRAT"),
        SGR("SGR"),
        COM("COM"),
        GEN("GEN"),
        LGE("LGE"),

        def title

        GENERATORS_TITLES(def title) {
            this.title = title
        }

        GENERATORS_TITLES() {
            this.title = this.name()
        }
    }

    private static final XLSX_GENERATORS_PATTERN = '''${prefisso}${idPratica?"_$idPratica":''}${tipoTributo?"_$tipoTributo":''}${codFiscale?"_$codFiscale":''}${anno?"_$anno":''}${utente?"_$utente":''}${funzione?"_$funzione":''}${tipoCodifica?"_$tipoCodifica":''}${nomeElaborazione?"_$nomeElaborazione":''}${idSoggetto?"_$idSoggetto":''}${idOggetto?"_$idOggetto":''}${progressivo?"_$progressivo":''}${idRuolo?"_$idRuolo":''}${servizio?"_$servizio":''}${date?"_$date":''}${datetime?"_$datetime":''}'''
    private static final MODELLI_GENERATORS_PATTERN = '''${prefisso}${tipoTributo?"_$tipoTributo":''}${idElaborazione?"_$idElaborazione":''}${modello?"_$modello":''}${idDocumento?"_$idDocumento":''}${numeroOrdineErede?"_E$numeroOrdineErede":''}${codFiscale?"_$codFiscale":''}'''
    private static final JASPER_GENERATORS_PATTERN = '''${prefisso}${tipoTributo?"_$tipoTributo":''}${idDocumento?"_$idDocumento":''}${codFiscale?"_$codFiscale":''}${anno?"_$anno":''}${idRuolo?"_$idRuolo":''}${tipoVersamento?"_$tipoVersamento":''}${extension?".$extension":''}'''

    private final static GENERATORS = [
            (GENERATORS_TYPE.XLSX)   : [
                    (GENERATORS_TITLES.MOLTIPLICATORI)                     : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SANZIONI)                           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ELENCO_DOCUMENTI)                   : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CANONI)                             : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ELENCO_SOGGETTI)                    : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.VARIAZIONI_RESIDENZE)               : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.VARIAZIONI_ANAGRAFICHE)             : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CATEGORIETARIFFE_CATEGORIE)         : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CATEGORIETARIFFE_TARIFFE)           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.COMPETENZE)                         : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.INSTALLAZIONE_PARAMETRI)            : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.AGGI)                               : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ALIQUOTE)                           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ALIQUOTE_ALIQUOTE_PER_CATEGORIA)    : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CODICI_F24)                         : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.BENEFICIARI_F24)                    : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CODICI_TRIBUTO)                     : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CODIFICHE)                          : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.COMUNICAZIONI)                      : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.COMUNICAZIONI_DETTAGLI)             : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.COMUNICAZIONI_TESTI)                : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CONTRIBUTI_IFEL)                    : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.DATI_CONTABILI)                     : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.DETRAZIONI)                         : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CODIFICHE_TIPI_EVENTO)              : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CODIFICHE_EVENTI)                   : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.INTERESSI)                          : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SCADENZE)                           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.TIPO_ALIQUOTA)                      : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CODIFICHE_TIPI_NOTIFICA)            : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.TIPI_STATO_CONTRIBUENTE)            : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CODIFICHE_TIPI_TRIBUTO)             : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.UTILIZZI)                           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ZONE)                               : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.VIE)                                : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.RUOLI_AUTOMATICI)                   : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ELENCO_IMMOBILI_CATASTO)            : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ELENCO_PROPRIETARI_CATASTO)         : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.INVIO_DEPAG)                        : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.DETTAGLI)                           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ELENCO_PRATICHE)                    : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.COMPONENTI_CONSISTENZA)             : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.COSTI_STORICI)                      : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.DENUNCE)                            : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.INSOLVENTI)                         : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_VIOLAZIONI)             : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_PRATICHE_RATEIZZATE)    : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.RAVVEDIMENTI)                       : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.LISTA_UTENTI)                       : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.LISTA_UTENZE_TARI)                  : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.LIQUIDAZIONI)                       : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ACCERTAMENTI)                       : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SOLLECITI)                          : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.PRATICHE_RATEIZZATE)                : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CONTRIBUENTI_NON_LIQUIDATI)         : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.COMPONENTI_DELLA_FAMIGLIA)          : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ELENCO_CONTRIBUENTI)                : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SEGNALAZIONI_BLOCCANTI)             : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.TARIFFE_MANCANTI)                   : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.DECORRENZA_CESSAZIONE)              : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.FAMILIARI)                          : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.NON_RESIDENTI_ABITAZIONE_PRINCIPALE): [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.EVENTI_RESIDENZE_STORICHE)          : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ELENCO_RESIDENTI_OGGETTO)           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.LOCAZIONI)                          : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.UTENZE)                             : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ELENCO_VERSAMENTI)                  : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.AT_RISPOSTE)                        : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.AT_PARTITE_IVA)                     : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.AT_DITTE)                           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.AT_RAPPRESENTANTI)                  : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ANOMALIE_DOCFA)                     : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.OGGETTI_IMPOSTA_RENDITA)            : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SOGGETTI_NON_DICHIARANTI)           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.BONIFICA_VERSAMENTI_DETTAGLIO)      : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.QUADRATURA_AE)                      : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.FORNITURA_AEG1)                     : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.FORNITURA_AEG5)                     : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.FORNITURA_AED)                      : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.FORNITURA_AEM)                      : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPORT_EXPORT)                      : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.COMPENSAZIONI)                      : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ELENCO_DOVUTO_VERSATO)              : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_A_RIMBORSO)                 : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_DA_PAGARE)                  : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_SALDATE)                    : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_CONTRIBUENTI)               : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_DETTAGLI)                   : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_PER_OGGETTO)                : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_PER_CATEGORIE)              : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_PER_ALIQUOTE)               : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_PER_ALIQUOTE_CATEGORIE)     : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.IMPOSTE_PER_TIPOLOGIE)              : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CARICO_RUOLI)                       : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CONTRIBUENTI_A_RUOLO)               : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.PRATICHE_A_RUOLO)                   : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ECCEDENZE_RUOLO)                    : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.UTENZE_RUOLO)                       : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SGRAVI_SU_RUOLO)                    : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SGRAVI)                             : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.DATE_INTERESSI_VIOLAZIONI)          : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.INSOLVENTI2)                        : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_RAVVEDIMENTI)           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_SOLLECITI)              : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_ACCERTAMENTI)           : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.LIQ)                                : [pattern: XLSX_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ACC)                                : [pattern: XLSX_GENERATORS_PATTERN],
            ],
            (GENERATORS_TYPE.JASPER) : [
                    (GENERATORS_TITLES.INSOLVENTI2)                                : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.F24)                                        : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.VISURA)                                     : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.RAVVEDIMENTO)                               : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.DETTAGLIO_SGRAVIO)                          : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.DETTAGLIO_ELENCO_SGRAVI)                    : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.PIANO_RIMBORSO)                             : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.OGGETTI_PERTINENZA)                         : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.OGGETTO_PER_VIA)                            : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.INSERIMENTO_FAMILIARI_SOGGETTI_NON_TRATTATI): [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CODICI_FISCALI_INCOERENTI)                  : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CODICI_FISCALI_DOPPI)                       : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_PRATICHE)                       : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_RAVVEDIMENTI)                   : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_RATEAZIONI)                     : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_SOLLECITI)                      : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_ACCERTAMENTI)                   : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.STATISTICHE_LIQUIDAZIONI)                   : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CALCOLO_INDIVIDUALE)                        : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SCHEDA_OGGETTI)                             : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SCHEDA_PRATICHE)                            : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.VERSAMENTI_DOPPI)                           : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SQUADRATURA_TOTALE)                         : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.TOTALE_VERSAMENTI)                          : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.TOTALE_VERSAMENTI_PER_GIORNO)               : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.CONTRATTI_LOCAZIONI)                        : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.VERSAMENTI)                                 : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.MINUTA_RUOLO)                               : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.RIEPILOGO_PER_CATEGORIA)                    : [pattern: JASPER_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.MINUTA_PER_CATEGORIA)                       : [pattern: JASPER_GENERATORS_PATTERN],
            ],
            (GENERATORS_TYPE.MODELLI): [
                    (GENERATORS_TITLES.LIQ) : [pattern: MODELLI_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.ACC) : [pattern: MODELLI_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SOL) : [pattern: MODELLI_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.DEN) : [pattern: MODELLI_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.RAI) : [pattern: MODELLI_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.PRAT): [pattern: MODELLI_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.SGR) : [pattern: MODELLI_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.COM) : [pattern: MODELLI_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.GEN) : [pattern: MODELLI_GENERATORS_PATTERN],
                    (GENERATORS_TITLES.LGE) : [pattern: MODELLI_GENERATORS_PATTERN]
            ]
    ]

    static String generateFileName(GENERATORS_TYPE type, GENERATORS_TITLES title, Map params) {
        def generatorParams = GENERATORS[type][title]

        if (generatorParams == null) {
            throw new IllegalArgumentException("Generatore per type ${type} e title ${title} non definito")
        }

        log.info("Generazione nome file per type ${type} e title ${title}")

        generatorParams += params + [prefisso: title.title]

        initParams(generatorParams)

        return new GStringTemplateEngine().createTemplate(generatorParams.pattern).make(generatorParams.withDefault { key -> null })
    }

    private static void initParams(def params) {
        params.codFiscale = params.codFiscale?.toUpperCase()?.padLeft(FILENAME_CODFISCALE_LENGTH, FILENAME_FILLER_CHAR)
        params.tipoTributo = params.tipoTributo?.toUpperCase()
        params.idDocumento = params.idDocumento != null ? "${params.anno ?: ''}${(params.idDocumento as String).padLeft(FILENAME_IDDOCUMENTO_LENGTH, FILENAME_FILLER_CHAR)}" : null
        params.idElaborazione = params.idElaborazione != null ? "${params.anno ?: ''}${(params.idElaborazione as String).padLeft(FILENAME_IDELABORAZIONE_LENGTH, FILENAME_FILLER_CHAR)}" : null
        params.modello = params.modello != null ? "${(params.modello as String).padLeft(FILENAME_MODEL_LENGTH, FILENAME_FILLER_CHAR)}${new Date().format(FILENAME_DATETIME_FORMAT)}" : null
        params.date = params.date == true ? new Date().format(FILENAME_DATE_FORMAT) : null
        params.datetime = params.datetime == true ? new Date().format(FILENAME_DATETIME_FORMAT) : null
    }

}
