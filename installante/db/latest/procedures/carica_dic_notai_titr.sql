--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_dic_notai_titr stripComments:false runOnChange:true 
 
create or replace procedure CARICA_DIC_NOTAI_TITR
/*************************************************************************
    Rev.    Date         Author      Note
    18      22/09/2022   DM          Aggiunto Id_documento sulle pratiche caricate
    17      09/03/2022   DM          Effettuata trim su W_REGIME
    16      20/01/2022   DM          Verifica della congruenza del tipo immobile
    15      12/02/2021   VD          Modificata attribuzione mesi di possesso:
                                     in presenza di piu' denunce per lo stesso
                                     contribuente/immobile caricate in ordine
                                     inverso, l'aggiornamento della prima
                                     denuncia evita la creazione di un valore
                                     negativo nei mesi possesso.
    14      11/02/2020   VD          Aggiunto test indice array per non
                                     lanciare l'archiviazione se l'array
                                     e' vuoto
    13      10/01/2020   VD          Aggiunta archiviazione denunce
                                     Si memorizzano le denunce inserite in
                                     un array; a fine trattamento si esegue
                                     l'archiviazione per ogni elemento
                                     dell'array.
    12      13/12/2019   VD          Aggiunta gestione da_mese_possesso
    11      18/10/2019   VD          Corretta composizione estremi catasto:
                                     sostituita RPAD con LPAD
    10      27/11/2018   VD          Gestione nuovo parametro per escludere
                                     dal caricamento gli oggetti con
                                     natura tra quelle indicate
    9       12/02/2018   VD          Aggiunto codice fiscale in messaggio
                                     di errore aggiornamento OGCO.
    8       18/01/2018   VD          Aggiunto codice fiscale in messaggio
                                     di errore inserimento OGCO.
    7       22/08/2017   VD          Corretto calcolo mesi primo semestre
                                     nel secondo oggetto_contribuente nel
                                     caso in cui lo stesso oggetto sia
                                     presente più volte per lo stesso
                                     contribuente nello stesso file
    6       18/05/2016   DM          * Scomposta la procedura in sottoprocedure.
                                     * Le rettifiche non vengono elaborate e si inserisce un'anomalia.
                                     * Reimplementata logica di ricerca degli oggetti
                                     * Implementato controllo sulle date delle forniture
    5       18/06/2015   VD          Corretto inserimento oggetti privi
                                     di estremi catasto (spostato azzeramento
                                     variabile w_oggetto prima del test)
    4       11/06/2015   VD          Aggiunta eliminazione finale degli
                                     oggetti non referenziati in alcuna
                                     pratica
                                     Modificata gestione dati indirizzo:
                                     se la sezione UbicazioneNota non esiste,
                                     si utilizzano le informazioni della
                                     sezione UbicazioneCatasto
    3       03/06/2015   VD          Eliminato campo flag_elab da tabella
                                     WRK_GRAFFATI
    2       24/04/2015   VD          Aggiunta gestione graffati
    1       23/03/2015   VD          Modificata query principale per
                                     analogia con calcolo imposta ICI:
                                     nella subquery non si considera più
                                     il flag_possesso = 'S'
                                     (vv modifica CALCOLO_IMPOSTA_TASI)
*************************************************************************/
(A_DOCUMENTO_ID  IN NUMBER,
 A_UTENTE        IN VARCHAR2,
 A_CTR_DENUNCIA  IN VARCHAR2,
 A_CTR_PART      IN VARCHAR2,
 A_SEZIONE_UNICA IN VARCHAR2,
 A_FONTE         IN NUMBER,
 A_TIPO_TRIBUTO  IN VARCHAR2,
 A_MESSAGGIO     IN OUT VARCHAR2) IS
--w_note           varchar2(2000);
--w_mp             number;
--w_mp_1sem        number;
--w_me             number;
  -- w_commenti abilita le dbms_outpt, può avere i seguenti valori:
  --  0  =   Nessun Commento
  --  1  =   Commenti principali Ablitati
  W_COMMENTI                NUMBER := 0;
  W_TIPO_NOTA               VARCHAR(2000) := NULL;
  W_DOCUMENTO_BLOB          BLOB;
  W_DOCUMENTO_CLOB          CLOB;
  DEST_OFFSET               NUMBER := 1;
  SRC_OFFSET                NUMBER := 1;
  AMOUNT                    INTEGER := DBMS_LOB.LOBMAXSIZE;
  BLOB_CSID                 NUMBER := DBMS_LOB.DEFAULT_CSID;
  LANG_CTX                  INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
  WARNING                   INTEGER;
  W_ERRORE                  VARCHAR(2000) := NULL;
  W_CONTROLLO               NUMBER;
  W_CIVICO                  VARCHAR2(60);
  W_ESTREMI_CATASTO         VARCHAR(20);
  W_COD_VIA                 NUMBER;
  W_OGGETTO                 NUMBER;
  W_FLAG_GRAFFATO           NUMBER;
  W_ID_IMMOBILE             NUMBER;
  W_FLAG_ELAB               VARCHAR2(1);
  W_TIPO_OGGETTO            NUMBER;
  W_NUM_CIV                 NUMBER(6);
  W_SUFFISSO                VARCHAR2(5);
  W_CATEGORIA               VARCHAR2(3);
  W_CLASSE                  VARCHAR2(2);
  W_RENDITA                 NUMBER(15, 2);
  W_VALORE                  NUMBER(15, 2);
  W_SEZIONE                 VARCHAR2(3);
  W_DATI_OGGETTO            VARCHAR(1000) := NULL;
  W_COD_FISCALE             VARCHAR2(16);
  W_NI                      NUMBER(10);
  W_ANOMALIA_CONT           VARCHAR2(1);
  W_ANOMALIA_TITO           VARCHAR2(1);
  W_COD_COM_NAS             NUMBER(3) := NULL;
  W_COD_PRO_NAS             NUMBER(3) := NULL;
  W_COD_COM_RES             NUMBER(3) := NULL;
  W_COD_PRO_RES             NUMBER(3) := NULL;
  W_RES_DENOMINAZIONE_VIA   VARCHAR2(60);
  W_RES_NUM_CIV             NUMBER(6) := NULL;
  W_RES_SUFFISSO            VARCHAR2(5);
  W_RES_COD_VIA_NUM_CIV     VARCHAR2(12);
  W_OGG_COD_VIA_NUM_CIV     VARCHAR2(12);
  W_CAP                     NUMBER(5);
  W_ANNO_DENUNCIA           NUMBER(4);
  W_DETRAZIONE_BASE         NUMBER(15, 2);
  W_PERC_POSSESSO          NUMBER(5, 2);
  W_PRATICA                NUMBER(10);
  W_OGGETTO_PRATICA        NUMBER(10);
  W_TITOLO                 VARCHAR2(1);
  W_NUM_ORDINE             NUMBER;
  W_CODICE_DIRITTO         VARCHAR2(4);
  W_REGIME                 VARCHAR2(2);
  W_PRATICA_ESISTENTE      NUMBER := 0;
  W_PRATICA_INSERITA       VARCHAR2(1);
  W_MESI_POSSESSO          NUMBER(2);
  W_MESI_POSSESSO_1SEM     NUMBER(2);
  W_DA_MESE_POSSESSO       NUMBER(2);
  W_FLAG_AB_PRINCIPALE     VARCHAR2(1);
  W_FLAG_POSSESSO          VARCHAR2(1);
  W_DETRAZIONE             NUMBER(15, 2);
  W_MESI_ESCLUSIONE        NUMBER(2);
  W_FLAG_ESCLUSIONE        VARCHAR2(1);
  W_ECCEZIONE_CODI         VARCHAR2(1);
  W_ECCEZIONE_CACA         VARCHAR2(1);
  W_DA_TRATTARE            VARCHAR2(1);
  W_CANCELLA_CONTRIBUENTE  VARCHAR2(1);
  W_CANCELLA_SOGGETTO      VARCHAR2(1);
  W_NUM_PRATICHE           NUMBER := 0;
  W_NUM_NUOVI_OGGETTI      NUMBER := 0;
  W_NUM_OGGETTI_ELIM       NUMBER := 0;
  W_NUM_NUOVI_CONTRIBUENTI NUMBER := 0;
  W_NUM_NUOVI_SOGGETTI     NUMBER := 0;
  W_NUM_NUOVI_OGPR         NUMBER := 0;
  W_NUM_SOGGETTI           NUMBER := 0;
  W_NUM_OGGETTI_ANOMALI    NUMBER := 0;
  W_NUM_NO_ACQ_CES         NUMBER := 0;
  W_NUM_TITOLARITA         NUMBER := 0;
  W_NUM_SOGGETTI_XML       NUMBER := 0;
  W_TROVA                  NUMBER;
  W_CARATTERI_ERRATI       VARCHAR2(100);
  W_NUMBER_TEMP            NUMBER;
  W_PERC_POSSESSO_PREC     NUMBER(5, 2);
  W_TIPO_OGGETTO_PREC      NUMBER;
  W_CATEGORIA_PREC         VARCHAR2(3);
  W_CLASSE_PREC            VARCHAR2(2);
  W_VALORE_PREC            NUMBER(15, 2);
  W_TITOLO_PREC            VARCHAR2(1);
  W_FLAG_ESCLUSIONE_PREC   VARCHAR2(1);
  W_FLAG_AB_PRINC_PREC     VARCHAR2(1);
  W_DETRAZIONE_PREC        NUMBER(15, 2);
  W_CF_PREC                VARCHAR2(16);
  W_OGPR_PREC              NUMBER(10);
  W_DEOG_ALOG_INS          NUMBER;
  W_ESTREMI_CATASTO_ERROR  VARCHAR2(20) := '';
  W_ANNO_OGGETTO           NUMBER(4);
  W_CONDIZIONE_ANNO        VARCHAR2(6);
  W_FONTE_OGGETTO          NUMBER(2) := NULL;
  W_POSSEDUTO               NUMBER := 0;
  W_ESISTE                  NUMBER := 0;
  W_VALORE_PREC_ANNO_DICH   NUMBER(15, 2);
  W_DOCUMENTO_ID_PREC       NUMBER;
  W_PERC_POSS_ATTESA        NUMBER(5, 2);
  W_CF_PRESENTE             NUMBER(1);
  W_MESI_POSSESSO_PREC      NUMBER(2);
  W_MESI_POSSESSO_1SEM_PREC NUMBER(2);
  W_DA_MESE_POSSESSO_PREC   NUMBER(2);
  W_CTR_NATURA              VARCHAR2(2000);
  w_max_posseduto           varchar(6);
  EX_FORNITURA_PRECEDENTE EXCEPTION;
  TYPE TYPE_OGGETTO IS TABLE OF OGGETTI.OGGETTO%TYPE INDEX BY VARCHAR2(10);
  TYPE TYPE_CATEGORIA IS TABLE OF OGGETTI.CATEGORIA_CATASTO%TYPE INDEX BY VARCHAR2(10);
  TYPE TYPE_CLASSE IS TABLE OF OGGETTI.CLASSE_CATASTO%TYPE INDEX BY VARCHAR2(10);
  TYPE TYPE_RENDITA IS TABLE OF NUMBER(15, 2) INDEX BY VARCHAR2(10);
  TYPE TYPE_COD_ESITO IS TABLE OF VARCHAR(4) INDEX BY VARCHAR2(10);
  TYPE TYPE_TIPO_OGGETTO IS TABLE OF OGGETTI.TIPO_OGGETTO%TYPE INDEX BY VARCHAR2(10);
  TYPE TYPE_FLAG_GRAFFATO IS TABLE OF NUMBER INDEX BY VARCHAR2(10);
  TYPE TYPE_ESTREMI_CATASTO IS TABLE OF VARCHAR2(20) INDEX BY VARCHAR2(10);
  TYPE TYPE_ID_IMMOBILE IS TABLE OF OGGETTI.ID_IMMOBILE%TYPE INDEX BY VARCHAR2(10);
  TYPE TYPE_PARTITA IS TABLE OF OGGETTI.PARTITA%TYPE INDEX BY VARCHAR2(10);
  TYPE TYPE_ESCLUSIONE IS TABLE OF VARCHAR2(1) INDEX BY VARCHAR2(10);
  T_OGGETTO         TYPE_OGGETTO;
  T_CATEGORIA       TYPE_CATEGORIA;
  T_CLASSE          TYPE_CLASSE;
  T_RENDITA         TYPE_RENDITA;
  T_COD_ESITO       TYPE_COD_ESITO;
  T_TIPO_OGGETTO    TYPE_TIPO_OGGETTO;
  T_FLAG_GRAFFATO   TYPE_FLAG_GRAFFATO;
  T_ID_IMMOBILE     TYPE_ID_IMMOBILE;
  T_ESTREMI_CATASTO TYPE_ESTREMI_CATASTO;
  T_PARTITA         TYPE_PARTITA;
  T_OGGETTO_ESCLUSO TYPE_ESCLUSIONE;

  --
  -- (VD - 10/01/2020): aggiunto array per memorizzare le pratiche inserite
  --                    per poi lanciare l'archiviazione delle denunce
  --
  TYPE TYPE_PRATICA IS TABLE OF PRATICHE_TRIBUTO.PRATICA%TYPE INDEX BY BINARY_INTEGER;
  T_PRATICA         TYPE_PRATICA;
  W_IND             NUMBER := 0;
  ERRORE EXCEPTION;
  SQL_ERRM VARCHAR2(1000);
  CURSOR SEL_VARI(P_DOCUMENTO CLOB) IS
    SELECT EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/NotaRettificata/TipoNota',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TIPONOTA,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Nota/NumeroNota',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') NUMERONOTA,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Nota/EsitoNota',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ESITONOTA,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Nota/Anno',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ANNO,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Nota/DataValiditaAtto',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') DATAVALIDITAATTO,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Nota/DataPresentazioneAtto',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') DATAPRESENTAZIONEATTO,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Nota/DataRegistrazioneInAtti',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') DATAREGISTRAZIONEINATTI,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Nota/NumeroRepertorio',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') NUMEROREPERTORIO,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Nota/CodiceAtto',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') CODICEATTO,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Rogante/CognomeNome',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ROGANTE_COGNOMENOME,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Rogante/CodiceFiscale',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ROGANTE_CODICEFISCALE,
           EXTRACTVALUE(VALUE(VARIAZIONE),
                        '/Variazione/Trascrizione/Rogante/Sede',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ROGANTE_SEDE,
           EXTRACT(VALUE(VARIAZIONE),
                        '/Variazione/Soggetti',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"').GETCLOBVAL() SOGGETTI,
           EXTRACT(VALUE(VARIAZIONE),
                        '/Variazione/Immobili',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"').GETCLOBVAL() IMMOBILI
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(P_DOCUMENTO),
                                     '/DatiOut/DatiPresenti/Variazioni/Variazione',
                                     'xmlns="http://www.agenziaterritorio.it/ICI.xsd"'))) VARIAZIONE
     WHERE (TO_NUMBER(TO_CHAR(TO_DATE(EXTRACTVALUE(VALUE(VARIAZIONE),
                                                   '/Variazione/Trascrizione/Nota/DataValiditaAtto',
                                                   'xmlns="http://www.agenziaterritorio.it/ICI.xsd"'),
                                      'ddmmyyyy'),
                              'yyyy')) >= 2014 AND A_TIPO_TRIBUTO = 'TASI')
        OR A_TIPO_TRIBUTO != 'TASI';
  CURSOR SEL_SOGG(P_SOGGETTI CLOB) IS
    SELECT EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/IdSoggettoNota',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') IDSOGGETTONOTA,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/PersonaFisica/Cognome',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PFCOGNOME,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/PersonaFisica/Nome',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PFNOME,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/PersonaFisica/Sesso',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PFSESSO,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/PersonaFisica/DataNascita',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PFDATANASCITA,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/PersonaFisica/LuogoNascita',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PFLUOGONASCITA,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/PersonaFisica/CodiceFiscale',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PFCODICEFISCALE,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/PersonaGiuridica/Denominazione',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PGDENOMINAZIONE,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/PersonaGiuridica/Sede',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PGSEDE,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/PersonaGiuridica/CodiceFiscale',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PGCODICEFISCALE,
           EXTRACT(VALUE(SOGGETTO),
                        '/Soggetto/DatiTitolarita',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"').GETCLOBVAL() TITOLARITA,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/Recapito/TipoIndirizzo',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TIPOINDIRIZZO,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/Recapito/Comune',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') COMUNE,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/Recapito/Provincia',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PROVINCIA,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/Recapito/Indirizzo',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') INDIRIZZO,
           EXTRACTVALUE(VALUE(SOGGETTO),
                        '/Soggetto/Recapito/CAP',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') CAP
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(P_SOGGETTI),
                                     '/Soggetti/Soggetto',
                                     'xmlns="http://www.agenziaterritorio.it/ICI.xsd"'))) SOGGETTO;
  CURSOR SEL_TITO(P_TITOLARITA CLOB) IS
    SELECT EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/TipologiaImmobile',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TIPOLOGIAIMMOBILE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/@Ref_Immobile',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') REF_IMMOBILE,
           EXISTSNODE(VALUE(TITOLARITA),
                      '/Titolarita/Acquisizione',
                      'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ACQUISIZIONE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/Acquisizione/QuotaNumeratore',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ACQQUOTANUMERATORE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/Acquisizione/QuotaDenominatore',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ACQQUOTADENOMINATORE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/Acquisizione/CodiceDiritto',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ACQCODICEDIRITTO,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/Acquisizione/Regime',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') ACQREGIME,
           EXISTSNODE(VALUE(TITOLARITA),
                      '/Titolarita/Cessione',
                      'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') CESSIONE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/Cessione/QuotaNumeratore',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') CESQUOTANUMERATORE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/Cessione/QuotaDenominatore',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') CESQUOTADENOMINATORE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/Cessione/CodiceDiritto',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') CESCODICEDIRITTO,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/Cessione/Regime',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') CESREGIME,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/PreRegistrazione/CodiceDiritto',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PRERECODICEDIRITTO,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/PreRegistrazione/QuotaNumeratore',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PREREQUOTANUMERATORE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/PreRegistrazione/QuotaDenominatore',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') PREREQUOTADENOMINATORE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/PostRegistrazione/CodiceDiritto',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') POSTRECODICEDIRITTO,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/PostRegistrazione/QuotaNumeratore',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') POSTREQUOTANUMERATORE,
           EXTRACTVALUE(VALUE(TITOLARITA),
                        '/Titolarita/PostRegistrazione/QuotaDenominatore',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') POSTREQUOTADENOMINATORE
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(P_TITOLARITA),
                                     '/DatiTitolarita/Titolarita',
                                     'xmlns="http://www.agenziaterritorio.it/ICI.xsd"'))) TITOLARITA;
  CURSOR SEL_IMMO(P_IMMOBILI CLOB) IS
    SELECT EXTRACTVALUE(VALUE(IMMOBILE),
                        '/*/TipologiaImmobile',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TIPOLOGIAIMMOBILE,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/*/@Ref_Immobile',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') REF_IMMOBILE,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/*/FlagGraffato',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FLAGGRAFFATO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/*/IdCatastaleImmobile',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') IDIMMOBILE,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/*/CodiceEsito',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') CODICEESITO,

           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/TipologiaImmobile',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TIPOLOGIAIMMOBILEFAB,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/SezioneCensuaria',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABSEZIONECENSUARIA,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/SezioneUrbana',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABSEZIONEURBANA,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/Foglio',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABFOGLIO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/Numero',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABNUMERO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/Subalterno',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABSUBALTERNO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Classamento/Zona',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABZONA,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Classamento/Natura',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABNATURA,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Classamento/Categoria',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABCATEGORIA,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Classamento/Classe',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABCLASSE,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Classamento/Superficie',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABSUPERFICIE,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/Classamento/RenditaEuro',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABRENDITAEURO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneNota/Indirizzo',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABINDIRIZZO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneNota/Civico1',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABCIVICO1,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneNota/Interno1',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABINTERNO1,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneNota/Piano1',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABPIANO1,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneNota/Scala',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABSCALA,
           --
           -- (VD - 11/06/2015): aggiunta selezione della sezione UbicazioneCatasto
           --                    per valorizzare i dati degli indirizzi
           --
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneCatasto/Indirizzo',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABCATINDIRIZZO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneCatasto/Civico1',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABCATCIVICO1,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneCatasto/Interno1',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABCATINTERNO1,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneCatasto/Piano1',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABCATPIANO1,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Fabbricato/UbicazioneCatasto/Scala',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') FABCATSCALA,

           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/TipologiaImmobile',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TIPOLOGIAIMMOBILETER,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Identificativo/SezioneCensuaria',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERSEZIONECENSUARIA,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Identificativo/SezioneUrbana',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERSEZIONEURBANA,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Identificativo/Foglio',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERFOGLIO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Identificativo/Numero',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERNUMERO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Identificativo/Subalterno',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERSUBALTERNO,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Classamento/Natura',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERNATURA,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Classamento/Classe',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERCLASSE,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Classamento/Ettari',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERETTARI,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Classamento/Are',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERARE,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Classamento/Centiare',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERCENTIARE,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Partita',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERPARTITA,
           EXTRACTVALUE(VALUE(IMMOBILE),
                        '/Terreno/Classamento/DominicaleEuro',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') TERDOMINICALEEURO
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(P_IMMOBILI),
                                     '/Immobili/*',
                                     'xmlns="http://www.agenziaterritorio.it/ICI.xsd"'))) IMMOBILE;
  /********************************************************
  PROCEDURE decodifica_indirizzo
  ********************************************************/
  PROCEDURE DECODIFICA_INDIRIZZO(P_INDIRIZZO_NOTAI IN VARCHAR2,
                                 P_INDIRIZZO       OUT VARCHAR2,
                                 P_NUM_CIV         OUT NUMBER,
                                 P_SUFFISSO        OUT VARCHAR2) IS
    W_IND_TEMP VARCHAR2(60);
  BEGIN
    IF INSTR(P_INDIRIZZO_NOTAI, ' N.') = 0 THEN
      P_INDIRIZZO := P_INDIRIZZO_NOTAI;
      P_NUM_CIV   := NULL;
      P_SUFFISSO  := NULL;
    ELSE
      P_INDIRIZZO := SUBSTR(P_INDIRIZZO_NOTAI,
                            1,
                            INSTR(P_INDIRIZZO_NOTAI, ' N.') - 1);
      W_IND_TEMP  := SUBSTR(P_INDIRIZZO_NOTAI,
                            INSTR(P_INDIRIZZO_NOTAI, ' N.') + 3);
      IF INSTR(W_IND_TEMP, '/') = 0 THEN
        P_NUM_CIV  := TO_NUMBER(W_IND_TEMP);
        P_SUFFISSO := NULL;
      ELSE
        P_NUM_CIV  := TO_NUMBER(SUBSTR(W_IND_TEMP,
                                       1,
                                       INSTR(W_IND_TEMP, '/') - 1));
        P_SUFFISSO := SUBSTR(W_IND_TEMP, INSTR(W_IND_TEMP, '/') + 1);
      END IF;
    END IF;
    P_INDIRIZZO := SUBSTR(P_INDIRIZZO, 1, 60);
  EXCEPTION
    WHEN OTHERS THEN
      P_INDIRIZZO := NULL;
      P_NUM_CIV   := NULL;
      P_SUFFISSO  := NULL;
  END DECODIFICA_INDIRIZZO;
  /********************************************************
  FUNCTION RICERCA_OGGETTO_ESTREMI_CAT
  ********************************************************/
  FUNCTION RICERCA_OGGETTO_ESTREMI_CAT(P_TIPO_TRIBUTO    VARCHAR2,
                                       P_ESTREMI_CATASTO VARCHAR2,
                                       P_CATEGORIA       VARCHAR2,
                                       P_TIPO_OGGETTO    NUMBER,
                                       P_PARTITA         VARCHAR2,
                                       P_CTR_PART        VARCHAR2,
                                       P_ANNO            VARCHAR2,
                                       P_COD_FISCALE     VARCHAR2,
                                       P_FLAG_ESCLUSIONE VARCHAR2)
    RETURN NUMBER IS
    W_OGGETTO NUMBER(10);
    W_ANNO      NUMBER := NULL;
    W_OPERATORE VARCHAR2(2) := NULL;
  BEGIN
    IF (P_ANNO IS NOT NULL) THEN
      W_ANNO      := TO_NUMBER(SUBSTR(P_ANNO, -4, 4));
      W_OPERATORE := SUBSTR(P_ANNO, 1, LENGTH(P_ANNO) - 4);
    END IF;
    SELECT MAX(OGG.OGGETTO)
      INTO W_OGGETTO
      FROM PRATICHE_TRIBUTO     PRTR,
           OGGETTI_PRATICA      OGPR,
           OGGETTI_CONTRIBUENTE OGCO,
           OGGETTI              OGG
     WHERE OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA
       AND OGPR.PRATICA = PRTR.PRATICA
       AND OGPR.OGGETTO = OGG.OGGETTO
       AND OGCO.COD_FISCALE = NVL(P_COD_FISCALE, OGCO.COD_FISCALE)
       AND OGCO.FLAG_POSSESSO = 'S'
       AND ((P_TIPO_OGGETTO = 3 AND OGG.TIPO_OGGETTO + 0 IN (3, 4, 55) AND
           OGG.CATEGORIA_CATASTO = P_CATEGORIA) OR
           (P_TIPO_OGGETTO IN (1, 2) AND OGG.TIPO_OGGETTO + 0 IN (1, 2) AND
           (P_CTR_PART = 'S' OR LPAD(NVL(OGG.PARTITA, '0'), 8, '0') =
           LPAD(NVL(P_PARTITA, '0'), 8, '0'))))
       AND NVL(OGCO.FLAG_ESCLUSIONE, 'N') =
           DECODE(P_FLAG_ESCLUSIONE,
                  'S',
                  'S',
                  'N',
                  'N',
                  NVL(OGCO.FLAG_ESCLUSIONE, 'N'))
       AND PRTR.TIPO_TRIBUTO || '' = P_TIPO_TRIBUTO
       AND OGG.ESTREMI_CATASTO = P_ESTREMI_CATASTO
       AND (OGCO.ANNO = NVL(W_ANNO, OGCO.ANNO) OR
           (W_OPERATORE = '>' AND OGCO.ANNO > W_ANNO) OR
           (W_OPERATORE = '<' AND OGCO.ANNO < W_ANNO) OR
           (W_OPERATORE = '=' AND OGCO.ANNO = W_ANNO) OR
                (W_OPERATORE = '>=' AND OGCO.ANNO >= W_ANNO) OR
           (W_OPERATORE = '<=' AND OGCO.ANNO <= W_ANNO))
       AND (OGCO.ANNO || OGCO.TIPO_RAPPORTO || 'S' ||
           LPAD(OGCO.OGGETTO_PRATICA, 10, '0')) =
           (SELECT MAX(OGCO_SUB.ANNO || OGCO_SUB.TIPO_RAPPORTO ||
                       OGCO_SUB.FLAG_POSSESSO ||
                       LPAD(OGCO_SUB.OGGETTO_PRATICA, 10, '0'))
              FROM PRATICHE_TRIBUTO     PRTR_SUB,
                   OGGETTI_PRATICA      OGPR_SUB,
                   OGGETTI_CONTRIBUENTE OGCO_SUB
             WHERE PRTR_SUB.TIPO_TRIBUTO || '' = P_TIPO_TRIBUTO
               AND ((PRTR_SUB.TIPO_PRATICA || '' = 'D' AND
                   PRTR_SUB.DATA_NOTIFICA IS NULL) OR
                   (PRTR_SUB.TIPO_PRATICA || '' = 'A' AND
                   PRTR_SUB.DATA_NOTIFICA IS NOT NULL AND
                   NVL(PRTR_SUB.STATO_ACCERTAMENTO, 'D') = 'D' AND
                   NVL(PRTR_SUB.FLAG_DENUNCIA, ' ') = 'S' AND
                   ((W_OPERATORE = '>=' AND PRTR_SUB.ANNO >= W_ANNO) OR
                   (W_OPERATORE = '<=' AND PRTR_SUB.ANNO <= W_ANNO) OR
                   (W_OPERATORE = '>' AND PRTR_SUB.ANNO > W_ANNO) OR
                   (W_OPERATORE = '<' AND PRTR_SUB.ANNO < W_ANNO) OR
                   (W_OPERATORE = '=' AND PRTR_SUB.ANNO = W_ANNO))))
               AND PRTR_SUB.PRATICA = OGPR_SUB.PRATICA
               AND ((W_OPERATORE = '>=' AND OGCO_SUB.ANNO >= W_ANNO) OR
                   (W_OPERATORE = '<=' AND OGCO_SUB.ANNO <= W_ANNO) OR
                   (W_OPERATORE = '>' AND OGCO_SUB.ANNO > W_ANNO) OR
                   (W_OPERATORE = '<' AND OGCO_SUB.ANNO < W_ANNO) OR
                   (W_OPERATORE = '=' AND OGCO_SUB.ANNO = W_ANNO))
               AND OGCO_SUB.COD_FISCALE = OGCO.COD_FISCALE
               AND OGCO_SUB.OGGETTO_PRATICA = OGPR_SUB.OGGETTO_PRATICA
               AND OGPR_SUB.OGGETTO = OGPR.OGGETTO
               AND OGCO_SUB.TIPO_RAPPORTO IN ('C', 'D', 'E'));
    RETURN W_OGGETTO;
  EXCEPTION
    WHEN OTHERS THEN
      W_OGGETTO := NULL;
      RETURN W_OGGETTO;
  END RICERCA_OGGETTO_ESTREMI_CAT;
  /********************************************************
  FUNCTION RICERCA_OGGETTO_ID
  ********************************************************/
  FUNCTION RICERCA_OGGETTO_ID(P_OGGETTO         NUMBER,
                              P_TIPO_TRIBUTO    VARCHAR2,
                              P_CATEGORIA       VARCHAR2,
                              P_TIPO_OGGETTO    NUMBER,
                              P_PARTITA         VARCHAR2,
                              P_CTR_PART        VARCHAR2,
                              P_ANNO            VARCHAR2,
                              P_COD_FISCALE     VARCHAR2,
                              P_FLAG_ESCLUSIONE VARCHAR2) RETURN NUMBER IS
    W_ESTREMI_CATASTO VARCHAR2(20);
    W_OGGETTO         NUMBER(10);
  BEGIN
    SELECT OGG.ESTREMI_CATASTO
      INTO W_ESTREMI_CATASTO
      FROM OGGETTI OGG
     WHERE OGG.OGGETTO = P_OGGETTO;
    IF (W_ESTREMI_CATASTO IS NULL) THEN
      RETURN P_OGGETTO;
    END IF;
    W_OGGETTO := RICERCA_OGGETTO_ESTREMI_CAT(P_TIPO_TRIBUTO,
                                             W_ESTREMI_CATASTO,
                                             P_CATEGORIA,
                                             P_TIPO_OGGETTO,
                                             P_PARTITA,
                                             P_CTR_PART,
                                             P_ANNO,
                                             P_COD_FISCALE,
                                             P_FLAG_ESCLUSIONE);
    RETURN W_OGGETTO;
  END RICERCA_OGGETTO_ID;
  /********************************************************
  PROCEDURE RICERCA_DATI_PER_OGGETTO
  ********************************************************/
  PROCEDURE RICERCA_DATI_PER_OGGETTO(P_OGGETTO               IN OUT NUMBER,
                                     P_TIPO_TRIBUTO          VARCHAR2,
                                     P_ANNO                  IN VARCHAR2,
                                     P_COD_FISCALE           IN VARCHAR2,
                                     P_FLAG_ESCLUSIONE       IN VARCHAR2,
                                     P_FONTE_OGGETTO         OUT NUMBER,
                                     P_ANNO_OGGETTO          OUT NUMBER,
                                     P_PERC_POSSESSO_PREC    OUT NUMBER,
                                     P_TIPO_OGGETTO_PREC     OUT NUMBER,
                                     P_CATEGORIA_PREC        OUT VARCHAR2,
                                     P_CLASSE_PREC           OUT VARCHAR2,
                                     P_VALORE_PREC           OUT NUMBER,
                                     P_TITOLO_PREC           OUT VARCHAR2,
                                     P_FLAG_ESCLUSIONE_PREC  OUT VARCHAR2,
                                     P_FLAG_AB_PRINC_PREC    OUT VARCHAR2,
                                     P_CF_PREC               OUT VARCHAR2,
                                     P_OGPR_PREC             OUT NUMBER,
                                     P_VALORE_PREC_ANNO_DICH OUT NUMBER,
                                     P_DOCUMENTO_ID_PREC     OUT NUMBER,
                                     P_MESI_POSSESSO_PREC         OUT NUMBER,
                                     P_MESI_POSSESSO_1SEM_PREC    OUT NUMBER,
                                     P_DA_MESE_POSSESSO_PREC      OUT NUMBER) IS
    W_ANNO      NUMBER;
    W_OPERATORE VARCHAR2(2);
  BEGIN
    IF (P_ANNO IS NOT NULL) THEN
      W_ANNO      := TO_NUMBER(SUBSTR(P_ANNO, -4, 4));
      W_OPERATORE := SUBSTR(P_ANNO, 1, LENGTH(P_ANNO) - 4);
    END IF;
    SELECT OGPR.OGGETTO,
           nvl(OGPR.FONTE, -1),
           OGPR.ANNO,
           OGCO.PERC_POSSESSO,
           OGPR.TIPO_OGGETTO,
           OGPR.CATEGORIA_CATASTO,
           OGPR.CLASSE_CATASTO,
           OGPR.VALORE,
           OGPR.TITOLO,
           OGCO.FLAG_ESCLUSIONE,
           OGCO.FLAG_AB_PRINCIPALE,
           OGCO.COD_FISCALE,
           OGCO.OGGETTO_PRATICA,
           F_VALORE(OGPR.VALORE,
                    OGPR.TIPO_OGGETTO,
                    PRTR.ANNO,
                    W_ANNO,
                    OGPR.CATEGORIA_CATASTO,
                    PRTR.TIPO_PRATICA,
                    OGPR.FLAG_VALORE_RIVALUTATO),
--                TO_NUMBER(SUBSTR(prtr.NUMERO, 1, INSTR(prtr.NUMERO, '-') -1))
                    decode(afc.is_number(SUBSTR(prtr.NUMERO, 1, INSTR(prtr.NUMERO, '-') -1)),
                           1,TO_NUMBER(SUBSTR(prtr.NUMERO, 1, INSTR(prtr.NUMERO, '-') -1))
                            ,''),
                OGCO.MESI_POSSESSO,
                OGCO.MESI_POSSESSO_1SEM,
                OGCO.DA_MESE_POSSESSO
      INTO P_OGGETTO,
           P_FONTE_OGGETTO,
           P_ANNO_OGGETTO,
           P_PERC_POSSESSO_PREC,
           P_TIPO_OGGETTO_PREC,
           P_CATEGORIA_PREC,
           P_CLASSE_PREC,
           P_VALORE_PREC,
           P_TITOLO_PREC,
           P_FLAG_ESCLUSIONE_PREC,
           P_FLAG_AB_PRINC_PREC,
           P_CF_PREC,
           P_OGPR_PREC,
           P_VALORE_PREC_ANNO_DICH,
           P_DOCUMENTO_ID_PREC,
           P_MESI_POSSESSO_PREC,
           P_MESI_POSSESSO_1SEM_PREC,
           P_DA_MESE_POSSESSO_PREC
      FROM PRATICHE_TRIBUTO     PRTR,
           OGGETTI_PRATICA      OGPR,
           OGGETTI_CONTRIBUENTE OGCO
     WHERE OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA
       AND OGPR.PRATICA = PRTR.PRATICA
       AND OGCO.COD_FISCALE = NVL(P_COD_FISCALE, OGCO.COD_FISCALE)
       AND OGPR.OGGETTO = P_OGGETTO
       AND OGCO.FLAG_POSSESSO = 'S'
       AND NVL(OGCO.FLAG_ESCLUSIONE, 'N') =
           DECODE(P_FLAG_ESCLUSIONE,
                  'S',
                  'S',
                  'N',
                  'N',
                  NVL(OGCO.FLAG_ESCLUSIONE, 'N'))
       AND PRTR.TIPO_TRIBUTO || '' = P_TIPO_TRIBUTO
       AND (OGCO.ANNO || OGCO.TIPO_RAPPORTO || 'S' ||
           LPAD(OGCO.OGGETTO_PRATICA, 10, '0')) =
           (SELECT MAX(OGCO_SUB.ANNO || OGCO_SUB.TIPO_RAPPORTO ||
                       OGCO_SUB.FLAG_POSSESSO ||
                       LPAD(OGCO_SUB.OGGETTO_PRATICA, 10, '0'))
              FROM PRATICHE_TRIBUTO     PRTR_SUB,
                   OGGETTI_PRATICA      OGPR_SUB,
                   OGGETTI_CONTRIBUENTE OGCO_SUB
             WHERE PRTR_SUB.TIPO_TRIBUTO || '' = P_TIPO_TRIBUTO
               AND ((PRTR_SUB.TIPO_PRATICA || '' = 'D' AND
                   PRTR_SUB.DATA_NOTIFICA IS NULL) OR
                   (PRTR_SUB.TIPO_PRATICA || '' = 'A' AND
                   PRTR_SUB.DATA_NOTIFICA IS NOT NULL AND
                   NVL(PRTR_SUB.STATO_ACCERTAMENTO, 'D') = 'D' AND
                   NVL(PRTR_SUB.FLAG_DENUNCIA, ' ') = 'S' AND
                   ((W_OPERATORE = '>=' AND PRTR_SUB.ANNO >= W_ANNO) OR
                   (W_OPERATORE = '<=' AND PRTR_SUB.ANNO <= W_ANNO) OR
                   (W_OPERATORE = '>' AND PRTR_SUB.ANNO > W_ANNO) OR
                   (W_OPERATORE = '<' AND PRTR_SUB.ANNO < W_ANNO) OR
                   (W_OPERATORE = '=' AND PRTR_SUB.ANNO = W_ANNO))))
               AND PRTR_SUB.PRATICA = OGPR_SUB.PRATICA
               AND ((W_OPERATORE = '>=' AND OGCO_SUB.ANNO >= W_ANNO) OR
                   (W_OPERATORE = '<=' AND OGCO_SUB.ANNO <= W_ANNO) OR
                   (W_OPERATORE = '>' AND OGCO_SUB.ANNO > W_ANNO) OR
                   (W_OPERATORE = '<' AND OGCO_SUB.ANNO < W_ANNO) OR
                   (W_OPERATORE = '=' AND OGCO_SUB.ANNO = W_ANNO))
               AND OGCO_SUB.COD_FISCALE = OGCO.COD_FISCALE
               AND OGCO_SUB.OGGETTO_PRATICA = OGPR_SUB.OGGETTO_PRATICA
               AND OGPR_SUB.OGGETTO = OGPR.OGGETTO
               AND OGCO_SUB.TIPO_RAPPORTO IN ('C', 'D', 'E')
               AND NVL(OGCO_SUB.FLAG_ESCLUSIONE, 'N') =
                   DECODE(P_FLAG_ESCLUSIONE,
                          'S',
                          'S',
                          'N',
                          'N',
                          NVL(OGCO_SUB.FLAG_ESCLUSIONE, 'N')));
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      P_PERC_POSSESSO_PREC    := 0;
      P_TIPO_OGGETTO_PREC     := NULL;
      P_CATEGORIA_PREC        := NULL;
      P_CLASSE_PREC           := NULL;
      P_VALORE_PREC           := NULL;
      P_TITOLO_PREC           := NULL;
      P_FLAG_ESCLUSIONE_PREC  := NULL;
      P_FLAG_AB_PRINC_PREC    := NULL;
      P_CF_PREC               := NULL;
      P_OGPR_PREC             := NULL;
      P_VALORE_PREC_ANNO_DICH := NULL;
      WHEN OTHERS THEN
        SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
        W_ERRORE := 'Errore RICERCA_DATI_PER_OGGETTO ' || P_OGGETTO || ' ' || P_TIPO_TRIBUTO || ' ' ||  P_ANNO ||' ' || P_COD_FISCALE || ' ' || P_FLAG_ESCLUSIONE ||
                          ' (' || SQL_ERRM || ')';
      RAISE ERRORE;
  END RICERCA_DATI_PER_OGGETTO;
  /********************************************************
  FUNCTION VERIFICA_PERC_POSS_POST_REG
  ********************************************************/
  FUNCTION VERIFICA_PERC_POSS_POST_REG(P_PERC_POSS_CALCOLATA IN NUMBER,
                                       P_REC_TITO            IN SEL_TITO%ROWTYPE,
                                       P_PERC_POSS_POST      OUT NUMBER)
    RETURN CHAR IS
    W_RESULT CHAR(1) := 'S';
  BEGIN
    IF (P_REC_TITO.POSTREQUOTANUMERATORE IS NOT NULL AND
       P_REC_TITO.POSTREQUOTADENOMINATORE IS NOT NULL) THEN
      P_PERC_POSS_POST := ROUND(P_REC_TITO.POSTREQUOTANUMERATORE /
                          P_REC_TITO.POSTREQUOTADENOMINATORE * 100, 2);
      IF (P_PERC_POSS_POST != P_PERC_POSS_CALCOLATA) THEN
        W_RESULT := 'N';
      END IF;
    END IF;
    RETURN W_RESULT;
  END VERIFICA_PERC_POSS_POST_REG;
  /********************************************************
  FUNCTION VERIFICA_PERC_POSS_PRE_REG
  ********************************************************/
  FUNCTION VERIFICA_PERC_POSS_PRE_REG(P_PERC_POSS_CALCOLATA NUMBER,
                                      P_REC_TITO            SEL_TITO%ROWTYPE,
                                      P_PERC_POSS_PRE       OUT NUMBER)
    RETURN CHAR IS
    W_RESULT CHAR(1) := 'S';
  BEGIN
    IF (P_REC_TITO.PREREQUOTANUMERATORE IS NOT NULL AND
       P_REC_TITO.PREREQUOTADENOMINATORE IS NOT NULL) THEN
      P_PERC_POSS_PRE := ROUND(P_REC_TITO.PREREQUOTANUMERATORE /
                         P_REC_TITO.PREREQUOTADENOMINATORE * 100, 2);
      IF (P_PERC_POSS_PRE != P_PERC_POSS_CALCOLATA) THEN
        W_RESULT := 'N';
      END IF;
    END IF;
    RETURN W_RESULT;
  END VERIFICA_PERC_POSS_PRE_REG;
  /********************************************************
  PROCEDURE inserisci_deog_alog
  ********************************************************/
  PROCEDURE INSERISCI_DEOG_ALOG(P_COD_FISCALE     IN VARCHAR2,
                                P_OGGETTO_PRATICA IN NUMBER,
                                P_ANNO_DENUNCIA   IN NUMBER,
                                P_CF_PREC         IN VARCHAR2,
                                P_OGPR_PREC       IN NUMBER,
                                P_DEOG_ALOG_INS   OUT NUMBER) IS
    W_CONTA_DEOG NUMBER;
    W_CONTA_ALOG NUMBER;
  BEGIN
    -- DEOG
    BEGIN
      INSERT INTO DETRAZIONI_OGCO
        (COD_FISCALE,
         OGGETTO_PRATICA,
         ANNO,
         MOTIVO_DETRAZIONE,
         DETRAZIONE,
         NOTE,
         DETRAZIONE_ACCONTO,
         TIPO_TRIBUTO)
        (SELECT P_COD_FISCALE,
                P_OGGETTO_PRATICA,
                P_ANNO_DENUNCIA,
                MOTIVO_DETRAZIONE,
                DETRAZIONE,
                NOTE,
                DETRAZIONE_ACCONTO,
                TIPO_TRIBUTO
           FROM DETRAZIONI_OGCO
          WHERE COD_FISCALE = P_CF_PREC
            AND OGGETTO_PRATICA = P_OGPR_PREC
            AND ANNO = P_ANNO_DENUNCIA
            AND TIPO_TRIBUTO = A_TIPO_TRIBUTO);
    END;
    -- ALOG
    BEGIN
      INSERT INTO ALIQUOTE_OGCO
        (COD_FISCALE,
         OGGETTO_PRATICA,
         DAL,
         AL,
         TIPO_ALIQUOTA,
         NOTE,
         TIPO_TRIBUTO)
        (SELECT P_COD_FISCALE,
                P_OGGETTO_PRATICA,
                DAL,
                AL,
                TIPO_ALIQUOTA,
                NOTE,
                TIPO_TRIBUTO
           FROM ALIQUOTE_OGCO
          WHERE COD_FISCALE = P_CF_PREC
            AND OGGETTO_PRATICA = P_OGPR_PREC
            AND TIPO_TRIBUTO = A_TIPO_TRIBUTO
            AND P_ANNO_DENUNCIA BETWEEN TO_NUMBER(TO_CHAR(DAL, 'yyyy')) AND
                NVL(TO_NUMBER(TO_CHAR(AL, 'yyyy')), 9999));
    END;
    BEGIN
      SELECT COUNT(1)
        INTO W_CONTA_DEOG
        FROM DETRAZIONI_OGCO
       WHERE OGGETTO_PRATICA = P_OGGETTO_PRATICA
         AND COD_FISCALE = P_COD_FISCALE
         AND TIPO_TRIBUTO = A_TIPO_TRIBUTO;
    EXCEPTION
      WHEN OTHERS THEN
        W_CONTA_DEOG := 0;
    END;
    BEGIN
      SELECT COUNT(1)
        INTO W_CONTA_ALOG
        FROM ALIQUOTE_OGCO
       WHERE OGGETTO_PRATICA = P_OGGETTO_PRATICA
         AND COD_FISCALE = P_COD_FISCALE
         AND TIPO_TRIBUTO = A_TIPO_TRIBUTO;
    EXCEPTION
      WHEN OTHERS THEN
        W_CONTA_ALOG := 0;
    END;
    P_DEOG_ALOG_INS := NVL(W_CONTA_DEOG, 0) + NVL(W_CONTA_ALOG, 0);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END INSERISCI_DEOG_ALOG;
  /********************************************************
  PROCEDURE inserisci_anomalia
  ********************************************************/
  PROCEDURE INSERISCI_ANOMALIA(P_ANNO          NUMBER,
                               P_TIPO_ANOMALIA NUMBER,
                               P_COD_FISCALE   VARCHAR2,
                               P_OGGETTO       NUMBER,
                                              P_NOTE          VARCHAR2 DEFAULT NULL) IS
    W_UPDATE_ANOM_ANNO  NUMBER(1);
    W_INSERIRE_ANOMALIE NUMBER(3);
  BEGIN
    -- Si inserisce l'anomalia se non è già presente per l'anno,
    -- codice fiscale, oggetto e non è stata lavorata
    SELECT DECODE(COUNT(*), 0, 0, 1)
      INTO W_INSERIRE_ANOMALIE
      FROM ANOMALIE_ICI ANIC
     WHERE ANIC.ANNO = P_ANNO
       AND ANIC.TIPO_ANOMALIA = P_TIPO_ANOMALIA
       AND ANIC.COD_FISCALE = P_COD_FISCALE
       AND ANIC.OGGETTO = P_OGGETTO
       AND ANIC.FLAG_OK IS NULL;
    -- Se l'anomalia non è presente si inserisce
    IF (W_INSERIRE_ANOMALIE = 0) THEN
      SELECT COUNT(1)
        INTO W_UPDATE_ANOM_ANNO
        FROM ANOMALIE_ANNO AA
       WHERE AA.TIPO_ANOMALIA = P_TIPO_ANOMALIA
         AND AA.ANNO = P_ANNO;
      IF (W_UPDATE_ANOM_ANNO = 0) THEN
        INSERT INTO ANOMALIE_ANNO
          (TIPO_ANOMALIA, ANNO, DATA_ELABORAZIONE, SCARTO)
        VALUES
          (P_TIPO_ANOMALIA, P_ANNO, SYSDATE, 0);
      ELSE
        UPDATE ANOMALIE_ANNO AA
           SET AA.DATA_ELABORAZIONE = SYSDATE
         WHERE AA.TIPO_ANOMALIA = P_TIPO_ANOMALIA
           AND AA.ANNO = P_ANNO;
      END IF;
      INSERT INTO ANOMALIE_ICI
        (ANNO, TIPO_ANOMALIA, COD_FISCALE, OGGETTO, NOTE)
      VALUES
        (P_ANNO, P_TIPO_ANOMALIA, P_COD_FISCALE, P_OGGETTO, P_NOTE);
    END IF;
  END INSERISCI_ANOMALIA;
  /********************************************************
  PROCEDURE decodifica_categoria
  ********************************************************/
  FUNCTION DECODIFICA_CATEGORIA(P_CATEGORIA IN VARCHAR2) RETURN VARCHAR2 IS
    W_CATEGORIA_DECODIFICATA VARCHAR2(3);
  BEGIN
    SELECT DECODE(P_CATEGORIA,
                  'A1',
                  'A01',
                  'A2',
                  'A02',
                  'A3',
                  'A03',
                  'A4',
                  'A04',
                  'A5',
                  'A05',
                  'A6',
                  'A06',
                  'A7',
                  'A07',
                  'A8',
                  'A08',
                  'A9',
                  'A09',
                  'B1',
                  'B01',
                  'B2',
                  'B02',
                  'B3',
                  'B03',
                  'B4',
                  'B04',
                  'B5',
                  'B05',
                  'B6',
                  'A06',
                  'B7',
                  'B07',
                  'B8',
                  'B08',
                  'C1',
                  'C01',
                  'C2',
                  'C02',
                  'C3',
                  'C03',
                  'C4',
                  'C04',
                  'C5',
                  'C05',
                  'C6',
                  'C06',
                  'C7',
                  'C07',
                  'D1',
                  'D01',
                  'D2',
                  'D02',
                  'D3',
                  'D03',
                  'D4',
                  'D04',
                  'D5',
                  'D05',
                  'D6',
                  'D06',
                  'D7',
                  'D07',
                  'D8',
                  'D08',
                  'D9',
                  'D09',
                  'E1',
                  'E01',
                  'E2',
                  'E02',
                  'E3',
                  'E03',
                  'E4',
                  'E04',
                  'E5',
                  'E05',
                  'E6',
                  'E06',
                  'E7',
                  'E07',
                  'E8',
                  'E08',
                  'E9',
                  'E09',
                  'F1',
                  'F01',
                  'F2',
                  'F02',
                  'F3',
                  'F03',
                  'F4',
                  'F04',
                  'F5',
                  'F05',
                  P_CATEGORIA)
      INTO W_CATEGORIA_DECODIFICATA
      FROM DUAL;
    RETURN W_CATEGORIA_DECODIFICATA;
  EXCEPTION
    WHEN OTHERS THEN
      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
      W_ERRORE := 'Errore in controllo esistenza fabbricato' || ' (' ||
                  SQL_ERRM || ')';
      RAISE ERRORE;
  END DECODIFICA_CATEGORIA;
  /********************************************************
  PROCEDURE elabora_immobili
  ********************************************************/
  PROCEDURE ELABORA_IMMOBILI(P_IMMOBILI CLOB) IS
  BEGIN
    --
    -- (VD - 27/11/2018): Si seleziona il parametro di esclusione oggetti
    --
    W_CTR_NATURA := F_INPA_VALORE('CTR_NATU');
    --
    FOR REC_IMMO IN SEL_IMMO(P_IMMOBILI) LOOP

      IF (REC_IMMO.TIPOLOGIAIMMOBILEFAB = 'T' OR REC_IMMO.TIPOLOGIAIMMOBILETER = 'F') then
        W_ERRORE := 'Errore nella definizione della tipologia immobile per ' || REC_IMMO.REF_IMMOBILE;
                RAISE ERRORE;
      END IF;


      -- (VD - 27/11/2018): se l'oggetto ha natura tra quelle escluse
      --                    non si tratta e si memorizza l'esclusione
      --                    nell'apposito array
      IF W_CTR_NATURA IS NOT NULL AND
        ((REC_IMMO.TIPOLOGIAIMMOBILE = 'F' AND
          W_CTR_NATURA LIKE REC_IMMO.FABNATURA) OR
         (REC_IMMO.TIPOLOGIAIMMOBILE IN ('T', 'A', 'V') AND
          W_CTR_NATURA LIKE '')) THEN
        T_OGGETTO_ESCLUSO (REC_IMMO.REF_IMMOBILE) := 'S';
      ELSE
        T_OGGETTO_ESCLUSO (REC_IMMO.REF_IMMOBILE) := NULL;
        IF REC_IMMO.TIPOLOGIAIMMOBILE = 'F' THEN
          -- inizio trattamento fabbricati
          W_TIPO_OGGETTO := 3;
          IF NVL(A_SEZIONE_UNICA, 'N') = 'S' THEN
            W_SEZIONE := '';
          ELSE
            W_SEZIONE := NVL(REC_IMMO.FABSEZIONECENSUARIA,
                             REC_IMMO.FABSEZIONEURBANA);
          END IF;
          W_CATEGORIA := NVL(REC_IMMO.FABCATEGORIA, REC_IMMO.FABNATURA);
          --Sistemazione Categoria
          IF LENGTH(W_CATEGORIA) = 2 THEN
            W_CATEGORIA := DECODIFICA_CATEGORIA(W_CATEGORIA);
          END IF;
          --
          -- (VD - 18/06/2015): spostato azzeramento variabile w_oggetto PRIMA
          --                    del test sugli estremi catasto: in questo modo
          --                    vengono trattati correttamente anche gli oggetti
          --                    privi di riferimenti catastali
          --
          W_OGGETTO := 0;
          IF W_SEZIONE || REC_IMMO.FABFOGLIO || REC_IMMO.FABNUMERO ||
             REC_IMMO.FABSUBALTERNO IS NOT NULL THEN
            W_ESTREMI_CATASTO := LPAD(LTRIM(NVL(W_SEZIONE, ' '), '0'), 3, ' ') ||
                                 LPAD(LTRIM(NVL(REC_IMMO.FABFOGLIO, ' '), '0'),
                                      5,
                                      ' ') ||
                                 LPAD(LTRIM(NVL(REC_IMMO.FABNUMERO, ' '), '0'),
                                      5,
                                      ' ') ||
                                 LPAD(LTRIM(NVL(REC_IMMO.FABSUBALTERNO, ' '),
                                            '0'),
                                      4,
                                      ' ') || LPAD(' ', 3);
            BEGIN
              SELECT MAX(OGGETTO)
                INTO W_OGGETTO
                FROM OGGETTI OGGE
               WHERE OGGE.TIPO_OGGETTO + 0 IN (3, 4, 55)
                 AND OGGE.ESTREMI_CATASTO = W_ESTREMI_CATASTO
                 AND NVL(SUBSTR(OGGE.CATEGORIA_CATASTO, 1, 1), '   ') =
                     NVL(SUBSTR(W_CATEGORIA, 1, 1), '   ');
            EXCEPTION
              WHEN OTHERS THEN
                SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                W_ERRORE := 'Errore in controllo esistenza fabbricato' || ' (' ||
                            SQL_ERRM || ')';
                RAISE ERRORE;
            END;
          END IF;
          IF NVL(W_OGGETTO, 0) = 0 THEN
            -- Oggetto non trovato
            BEGIN
              SELECT COD_VIA
                INTO W_COD_VIA
                FROM DENOMINAZIONI_VIA DEVI
               WHERE NVL(REC_IMMO.FABINDIRIZZO, REC_IMMO.FABCATINDIRIZZO) LIKE
                     CHR(37) || DEVI.DESCRIZIONE || CHR(37)
                 AND DEVI.DESCRIZIONE IS NOT NULL
                 AND NOT EXISTS
               (SELECT 'x'
                        FROM DENOMINAZIONI_VIA DEVI1
                       WHERE NVL(REC_IMMO.FABINDIRIZZO,
                                 REC_IMMO.FABCATINDIRIZZO) LIKE
                             CHR(37) || DEVI1.DESCRIZIONE || CHR(37)
                         AND DEVI1.DESCRIZIONE IS NOT NULL
                         AND DEVI1.COD_VIA != DEVI.COD_VIA)
                 AND ROWNUM = 1;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                W_COD_VIA := 0;
              WHEN OTHERS THEN
                SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                W_ERRORE := 'Errore in controllo esistenza indirizzo fabbricato' ||
                            'indir: ' ||
                            NVL(REC_IMMO.FABINDIRIZZO,
                                REC_IMMO.FABCATINDIRIZZO) || ' (' || SQL_ERRM || ')';
                RAISE ERRORE;
            END;
            IF NVL(REC_IMMO.FABCIVICO1, REC_IMMO.FABCATCIVICO1) IS NULL THEN
              W_NUM_CIV  := NULL;
              W_SUFFISSO := NULL;
            ELSE
              W_CIVICO := TRANSLATE(NVL(REC_IMMO.FABCIVICO1,
                                        REC_IMMO.FABCATCIVICO1),
                                    '/-',
                                    '//');
              --DBMS_OUTPUT.Put_Line('w_civico: '||w_civico);
              IF TRANSLATE(NVL(W_CIVICO, ' '), 'a0123456789', 'a') IS NULL THEN
                W_NUM_CIV  := TO_NUMBER(W_CIVICO);
                W_SUFFISSO := NULL;
              ELSE
                -- Verifica di errore per Civico non numerico
                IF TRANSLATE(SUBSTR(W_CIVICO, 1, INSTR(W_CIVICO, '/') - 1),
                             '-0123456789/',
                             '-') IS NOT NULL OR INSTR(W_CIVICO, '/') < 1 THEN
                  -- Se il numero civico non è un numerico inserisco num_civ e
                  -- suffisso nulli
                  -- e una anomalia per l'oggetto con il dato del numero civico
                  -- errato
                  W_DATI_OGGETTO := 'Numero Civico : ' ||
                                    NVL(REC_IMMO.FABCIVICO1,
                                        REC_IMMO.FABCATCIVICO1);
                  W_NUM_CIV      := NULL;
                  W_SUFFISSO     := NULL;
                ELSE
                  W_NUM_CIV  := TO_NUMBER(SUBSTR(W_CIVICO,
                                                 1,
                                                 INSTR(W_CIVICO, '/') - 1));
                  W_SUFFISSO := LTRIM(SUBSTR(W_CIVICO,
                                             INSTR(W_CIVICO, '/') + 1));
                END IF;
              END IF;
            END IF;
            IF W_CATEGORIA IS NOT NULL THEN
              BEGIN
                SELECT COUNT(1)
                  INTO W_CONTROLLO
                  FROM CATEGORIE_CATASTO
                 WHERE CATEGORIA_CATASTO = W_CATEGORIA;
              EXCEPTION
                WHEN OTHERS THEN
                  SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                  W_ERRORE := 'Errore in ricerca Categorie Catasto' || ' (' ||
                              SQL_ERRM || ')';
                  RAISE ERRORE;
              END;
              IF NVL(W_CONTROLLO, 0) = 0 THEN
                BEGIN
                  INSERT INTO CATEGORIE_CATASTO
                    (CATEGORIA_CATASTO, DESCRIZIONE)
                  VALUES
                    (W_CATEGORIA, 'DA CARICAMENTO DATI NOTAI');
                EXCEPTION
                  WHEN OTHERS THEN
                    SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                    W_ERRORE := 'Errore in inserimento Categorie Catasto' || ' (' ||
                                W_CATEGORIA || ') - '||SQLERRM;
                    RAISE ERRORE;
                END;
              END IF;
            END IF; -- fine controllo categoria not null
            W_OGGETTO := NULL;
            OGGETTI_NR(W_OGGETTO);
            BEGIN
              INSERT INTO OGGETTI
                (OGGETTO,
                 TIPO_OGGETTO,
                 INDIRIZZO_LOCALITA,
                 COD_VIA,
                 NUM_CIV,
                 SUFFISSO,
                 SEZIONE,
                 FOGLIO,
                 NUMERO,
                 SUBALTERNO,
                 CATEGORIA_CATASTO,
                 CLASSE_CATASTO,
                 FONTE,
                 UTENTE,
                 DATA_VARIAZIONE,
                 ID_IMMOBILE)
              VALUES
                (W_OGGETTO,
                 W_TIPO_OGGETTO,
                 DECODE(W_COD_VIA,
                        0,
                        SUBSTR(NVL(REC_IMMO.FABINDIRIZZO,
                                   REC_IMMO.FABCATINDIRIZZO),
                               1,
                               36),
                        ''),
                 DECODE(W_COD_VIA, 0, NULL, W_COD_VIA),
                 W_NUM_CIV,
                 W_SUFFISSO,
                 W_SEZIONE,
                 REC_IMMO.FABFOGLIO,
                 REC_IMMO.FABNUMERO,
                 REC_IMMO.FABSUBALTERNO,
                 W_CATEGORIA,
                 LTRIM(REC_IMMO.FABCLASSE, '0'),
                 A_FONTE,
                 A_UTENTE,
                 TRUNC(SYSDATE),
                 REC_IMMO.IDIMMOBILE);
            EXCEPTION
              WHEN OTHERS THEN
                SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                W_ERRORE := 'Errore in inserimento fabbricato ' || ' (' ||
                            SQL_ERRM || ')';
                RAISE ERRORE;
            END;
            IF W_DATI_OGGETTO IS NOT NULL THEN
              -- Inserimento Anomalia Caricamento Oggetto
              BEGIN
                INSERT INTO ANOMALIE_CARICAMENTO
                  (DOCUMENTO_ID, OGGETTO, DESCRIZIONE, DATI_OGGETTO, NOTE)
                VALUES
                  (A_DOCUMENTO_ID,
                   W_OGGETTO,
                   'Numero Civico non Numerico',
                   W_DATI_OGGETTO,
                   NULL);
              EXCEPTION
                WHEN OTHERS THEN
                  W_ERRORE := 'Errore in inserimento anomalie_caricamento oggetto: ' ||
                              TO_CHAR(W_OGGETTO) || ' (' || SQLERRM || ')';
                  RAISE ERRORE;
              END;
              W_NUM_OGGETTI_ANOMALI := W_NUM_OGGETTI_ANOMALI + 1;
              W_DATI_OGGETTO        := NULL;
            END IF;
            W_NUM_NUOVI_OGGETTI := W_NUM_NUOVI_OGGETTI + 1;
          ELSE
            -- Oggetto trovato, aggiornamento id_immobile
            BEGIN
              UPDATE OGGETTI
                 SET ID_IMMOBILE = REC_IMMO.IDIMMOBILE
               WHERE OGGETTO = W_OGGETTO
                 AND ID_IMMOBILE IS NULL;
            EXCEPTION
              WHEN OTHERS THEN
                W_ERRORE := 'Errore in aggiornamento id_immobile: ' ||
                            TO_CHAR(W_OGGETTO) || ' (' || SQLERRM || ')';
                RAISE ERRORE;
            END;
          END IF; -- fine controllo se immobile gia' presente
          W_CLASSE  := LTRIM(REC_IMMO.FABCLASSE, '0');
          W_RENDITA := REC_IMMO.FABRENDITAEURO / 100;
        ELSIF REC_IMMO.TIPOLOGIAIMMOBILE IN ('T', 'A', 'V') THEN
          -- inizio
          -- trattamento terreni
          IF REC_IMMO.TIPOLOGIAIMMOBILE = 'A' THEN
            W_TIPO_OGGETTO := 2;
            W_CATEGORIA    := '';
          ELSE
            W_TIPO_OGGETTO := 1;
            W_CATEGORIA    := 'T';
          END IF;
          W_OGGETTO := 0;
          IF NVL(A_SEZIONE_UNICA, 'N') = 'S' THEN
            W_SEZIONE := '';
          ELSE
            W_SEZIONE := NVL(REC_IMMO.TERSEZIONECENSUARIA,
                             REC_IMMO.TERSEZIONEURBANA);
          END IF;
          IF W_SEZIONE || REC_IMMO.TERFOGLIO || REC_IMMO.TERNUMERO ||
             REC_IMMO.TERSUBALTERNO IS NOT NULL THEN
            W_OGGETTO         := 0;
            W_ESTREMI_CATASTO := LPAD(LTRIM(NVL(W_SEZIONE, ' '), '0'), 3, ' ') ||
                                 LPAD(LTRIM(NVL(REC_IMMO.TERFOGLIO, ' '), '0'),
                                      5,
                                      ' ') ||
                                 LPAD(LTRIM(NVL(REC_IMMO.TERNUMERO, ' '), '0'),
                                      5,
                                      ' ') ||
                                 LPAD(LTRIM(NVL(REC_IMMO.TERSUBALTERNO, ' '),
                                            '0'),
                                      4,
                                      ' ') || LPAD(' ', 3);
            BEGIN
              /*
              DM 08/03/2016 - Aggiunta condizione a_ctr_part = 'N' in OR
              Se si vuole escludere il controllo sulla partita si passa S in
              questo caso la prima
              condizione sarà sempre vera e la seconda non sarà influente.
              Se si vuole in controllo sulla partita si passerà N in questo modo
              la prima condizione sarà
              sempre falsa e tutto dipenderà dalla seconda.
              */
              SELECT MAX(OGGETTO)
                INTO W_OGGETTO
                FROM OGGETTI OGGE
               WHERE OGGE.TIPO_OGGETTO + 0 IN (1, 2)
                 AND OGGE.ESTREMI_CATASTO = W_ESTREMI_CATASTO
                 AND (A_CTR_PART = 'S' OR
                     LPAD(NVL(OGGE.PARTITA, '0'), 8, '0') =
                     LPAD(NVL(REC_IMMO.TERPARTITA, '0'), 8, '0'));
            EXCEPTION
              WHEN OTHERS THEN
                SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                W_ERRORE := 'Errore in controllo esistenza terreno' || ' (' ||
                            SQL_ERRM || ')';
                RAISE ERRORE;
            END;
          END IF;
          IF NVL(W_OGGETTO, 0) = 0 THEN
            -- Oggetto non trovato
            W_OGGETTO := NULL;
            OGGETTI_NR(W_OGGETTO);
            BEGIN
              INSERT INTO OGGETTI
                (OGGETTO,
                 TIPO_OGGETTO,
                 INDIRIZZO_LOCALITA,
                 PARTITA,
                 SEZIONE,
                 FOGLIO,
                 NUMERO,
                 SUBALTERNO,
                 CATEGORIA_CATASTO,
                 CLASSE_CATASTO,
                 ETTARI,
                 ARE,
                 CENTIARE,
                 FONTE,
                 UTENTE,
                 DATA_VARIAZIONE)
              VALUES
                (W_OGGETTO,
                 W_TIPO_OGGETTO,
                 '',
                 REC_IMMO.TERPARTITA,
                 W_SEZIONE,
                 REC_IMMO.TERFOGLIO,
                 REC_IMMO.TERNUMERO,
                 REC_IMMO.TERSUBALTERNO,
                 W_CATEGORIA,
                 LTRIM(REC_IMMO.TERCLASSE, '0'),
                 REC_IMMO.TERETTARI,
                 REC_IMMO.TERARE,
                 REC_IMMO.TERCENTIARE,
                 A_FONTE,
                 A_UTENTE,
                 TRUNC(SYSDATE));
            EXCEPTION
              WHEN OTHERS THEN
                SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                W_ERRORE := 'Errore in inserimento terreno ' || ' (' ||
                            SQL_ERRM || ')';
                RAISE ERRORE;
            END;
            W_NUM_NUOVI_OGGETTI := W_NUM_NUOVI_OGGETTI + 1;
          END IF; -- fine controllo se immobile gia' presente
          W_CLASSE  := LTRIM(REC_IMMO.TERCLASSE, '0');
          W_RENDITA := REC_IMMO.TERDOMINICALEEURO / 100;
        END IF;
        -- Inserimento riferimento Immobile,
        T_OGGETTO(REC_IMMO.REF_IMMOBILE) := W_OGGETTO;
        T_CATEGORIA(REC_IMMO.REF_IMMOBILE) := W_CATEGORIA;
        T_CLASSE(REC_IMMO.REF_IMMOBILE) := W_CLASSE;
        T_RENDITA(REC_IMMO.REF_IMMOBILE) := W_RENDITA;
        T_COD_ESITO(REC_IMMO.REF_IMMOBILE) := REC_IMMO.CODICEESITO;
        T_TIPO_OGGETTO(REC_IMMO.REF_IMMOBILE) := W_TIPO_OGGETTO;
        T_FLAG_GRAFFATO(REC_IMMO.REF_IMMOBILE) := REC_IMMO.FLAGGRAFFATO;
        T_ID_IMMOBILE(REC_IMMO.REF_IMMOBILE) := REC_IMMO.IDIMMOBILE;
        T_ESTREMI_CATASTO(REC_IMMO.REF_IMMOBILE) := W_ESTREMI_CATASTO;
        T_PARTITA(REC_IMMO.REF_IMMOBILE) := REC_IMMO.TERPARTITA;
        --
        IF REC_IMMO.FLAGGRAFFATO IS NOT NULL THEN
          BEGIN
            INSERT INTO WRK_GRAFFATI
              (DOCUMENTO_ID,
               RIFERIMENTO,
               ID_IMMOBILE,
               PROGR_GRAFFATO,
               OGGETTO)
            VALUES
              (A_DOCUMENTO_ID,
               REC_IMMO.REF_IMMOBILE,
               REC_IMMO.IDIMMOBILE,
               REC_IMMO.FLAGGRAFFATO,
               W_OGGETTO);
          EXCEPTION
            WHEN OTHERS THEN
              SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
              W_ERRORE := 'Insert WRK_GRAFFATI - Oggetto: '|| w_oggetto ||
                          ', Id.Immobile: '||rec_immo.idimmobile|| ' (' ||
                          SQL_ERRM || ')';
              RAISE ERRORE;
          END;
        END IF;
      END IF;
      NULL;
    END LOOP;
  END ELABORA_IMMOBILI;
  /********************************************************
  PROCEDURE elabora_soggetti
  ********************************************************/
  PROCEDURE ELABORA_SOGGETTI(P_SOGGETTI IN CLOB,
                             REC_VARI   IN SEL_VARI%ROWTYPE) IS
  BEGIN
    FOR REC_SOGG IN SEL_SOGG(P_SOGGETTI) LOOP
      IF W_COMMENTI > 0 THEN
        DBMS_OUTPUT.PUT_LINE('-- Soggetti --');
      END IF;
      W_ANOMALIA_CONT := 'N';
      W_NI            := NULL;
      W_COD_FISCALE   := NULL;
      -- Le seguente variabili indicano se cancellare il contribuente e/o il
      -- soggetto dopo il trattamento,
      -- questo nel caso non venga creata la pratica per il contribuente (
      -- Eccezione: NON Trattare)
      -- e solo se non era già soggetto e/o contribuente precedentemente
      W_CANCELLA_CONTRIBUENTE := 'N';
      W_CANCELLA_SOGGETTO     := 'N';
      IF NVL(REC_SOGG.PGCODICEFISCALE, REC_SOGG.PFCODICEFISCALE) IS NULL THEN
        -- Inserimento Anomalia Caricamento Contribuente
        BEGIN
          INSERT INTO ANOMALIE_CARICAMENTO
            (DOCUMENTO_ID, COGNOME, NOME, DESCRIZIONE, NOTE)
          VALUES
            (A_DOCUMENTO_ID,
             SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE, REC_SOGG.PFCOGNOME),
                    1,
                    60),
             SUBSTR(REC_SOGG.PFNOME, 1, 36),
             'Codice Fiscale Nullo',
             NULL);
        EXCEPTION
          WHEN OTHERS THEN
            W_ERRORE := 'Errore in inserimento anomalie_contribuente ' ||
                        SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE,
                                   REC_SOGG.PFCOGNOME),
                               1,
                               60) || ' (' || SQLERRM || ')';
            RAISE ERRORE;
        END;
        W_ANOMALIA_CONT := 'S';
      END IF;
      -- Verifica del Contribuente
      IF REC_SOGG.PGCODICEFISCALE IS NULL THEN
        IF REC_SOGG.PFCODICEFISCALE IS NOT NULL THEN
          BEGIN
            SELECT CONT.COD_FISCALE, CONT.NI
              INTO W_COD_FISCALE, W_NI
              FROM CONTRIBUENTI CONT
             WHERE CONT.COD_FISCALE = REC_SOGG.PFCODICEFISCALE;
                   -- DM 05/07/2016 - Si memorizza il CF da processre con la assegna_flag_ab_pkg.abitazioni
             SELECT DECODE(COUNT(*), 0, 0, 1)
               INTO W_CF_PRESENTE
               FROM WRK_NOTAI_CF WRK
              WHERE WRK.DOCUMENTO_ID = A_DOCUMENTO_ID
                AND WRK.COD_FISCALE = REC_SOGG.PFCODICEFISCALE;
                     IF (W_CF_PRESENTE = 0) THEN
                        INSERT INTO WRK_NOTAI_CF
                           (DOCUMENTO_ID, COD_FISCALE, ANNO)
                        VALUES
                           (A_DOCUMENTO_ID, REC_SOGG.PFCODICEFISCALE, W_ANNO_DENUNCIA);
                     END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              W_COD_FISCALE := NULL;
            WHEN OTHERS THEN
              W_ERRORE := 'Errore in verifica Codice Fiscale (PF) per ' ||
                          REC_SOGG.PFCODICEFISCALE || ' (' || SQLERRM || ')';
              RAISE ERRORE;
          END;
        END IF;
      ELSE
        BEGIN
          SELECT CONT.COD_FISCALE, CONT.NI
            INTO W_COD_FISCALE, W_NI
            FROM CONTRIBUENTI CONT
           WHERE CONT.COD_FISCALE = REC_SOGG.PGCODICEFISCALE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            W_COD_FISCALE := NULL;
          WHEN OTHERS THEN
            W_ERRORE := 'Errore in verifica Codice Fiscale (PG) per ' ||
                        REC_SOGG.PGCODICEFISCALE || ' (' || SQLERRM || ')';
            RAISE ERRORE;
        END;
      END IF;
      -- DBMS_OUTPUT.Put_Line('w_cod_fiscale: '||nvl(w_cod_fiscale,'(Nullo)'));
      IF W_COD_FISCALE IS NULL AND W_ANOMALIA_CONT = 'N' THEN
        -- Contribuente
        -- non trovato
        -- Verifica del soggetto
        IF REC_SOGG.PGCODICEFISCALE IS NULL THEN
          IF REC_SOGG.PFCODICEFISCALE IS NOT NULL THEN
            BEGIN
              SELECT SOGG.NI
                INTO W_NI
                FROM SOGGETTI SOGG
               WHERE SOGG.COD_FISCALE = REC_SOGG.PFCODICEFISCALE
                 AND SOGG.NOME = REC_SOGG.PFNOME
                 AND SOGG.COGNOME = REC_SOGG.PFCOGNOME;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                W_NI := NULL;
              WHEN TOO_MANY_ROWS THEN
                --   dbms_output.put_line('Cod.fiscale multiplo: '||
                -- rec_sogg.pfcodicefiscale);
                -- Inserimento Anomalia Codice fiscale multiplo
                BEGIN
                  INSERT INTO ANOMALIE_CARICAMENTO
                    (DOCUMENTO_ID,
                     COGNOME,
                     NOME,
                     COD_FISCALE,
                     DESCRIZIONE,
                     NOTE)
                  VALUES
                    (A_DOCUMENTO_ID,
                     SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE,
                                REC_SOGG.PFCOGNOME),
                            1,
                            60),
                     SUBSTR(REC_SOGG.PFNOME, 1, 36),
                     REC_SOGG.PFCODICEFISCALE,
                     'Ci sono piu'' soggetti con lo stesso Codice Fiscale e nessuno e'' contribuente',
                     NULL);
                EXCEPTION
                  WHEN OTHERS THEN
                    W_ERRORE := 'Errore in inserimento anomalie_caricamento ' ||
                                SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE,
                                           REC_SOGG.PFCOGNOME),
                                       1,
                                       60) || ' (' || SQLERRM || ')';
                    RAISE ERRORE;
                END;
                W_ANOMALIA_CONT := 'S';
              WHEN OTHERS THEN
                W_ERRORE := 'Errore in verifica soggetto per ' ||
                            REC_SOGG.PFCODICEFISCALE || ' (' || SQLERRM || ')';
                RAISE ERRORE;
            END;
          END IF;
        ELSE
          IF LENGTH(REC_SOGG.PGCODICEFISCALE) = 11 THEN
            BEGIN
              SELECT SOGG.NI
                INTO W_NI
                FROM SOGGETTI SOGG
               WHERE NVL(SOGG.PARTITA_IVA, SOGG.COD_FISCALE) =
                     REC_SOGG.PGCODICEFISCALE
                 AND SOGG.COGNOME = REC_SOGG.PGDENOMINAZIONE;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                W_NI := NULL;
              WHEN TOO_MANY_ROWS THEN
                -- Inserimento Anomalia Partita IVA multipla
                BEGIN
                  INSERT INTO ANOMALIE_CARICAMENTO
                    (DOCUMENTO_ID,
                     COGNOME,
                     NOME,
                     COD_FISCALE,
                     DESCRIZIONE,
                     NOTE)
                  VALUES
                    (A_DOCUMENTO_ID,
                     SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE,
                                REC_SOGG.PFCOGNOME),
                            1,
                            60),
                     SUBSTR(REC_SOGG.PFNOME, 1, 36),
                     REC_SOGG.PFCODICEFISCALE,
                     'Ci sono piu'' soggetti con la stessa Partita IVA e nessuno e'' contribuente',
                     NULL);
                EXCEPTION
                  WHEN OTHERS THEN
                    W_ERRORE := 'Errore in inserimento anomalie_caricamento ' ||
                                SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE,
                                           REC_SOGG.PFCOGNOME),
                                       1,
                                       60) || ' (' || SQLERRM || ')';
                    RAISE ERRORE;
                END;
                W_ANOMALIA_CONT := 'S';
              WHEN OTHERS THEN
                W_ERRORE := 'Errore in verifica Partita IVA (1) per ' ||
                            REC_SOGG.PGCODICEFISCALE || ' (' || SQLERRM || ')';
                RAISE ERRORE;
            END;
          ELSE
            BEGIN
              SELECT SOGG.NI
                INTO W_NI
                FROM SOGGETTI SOGG
               WHERE SOGG.COD_FISCALE = REC_SOGG.PGCODICEFISCALE
                 AND SOGG.COGNOME = REC_SOGG.PGDENOMINAZIONE;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                W_NI := NULL;
              WHEN TOO_MANY_ROWS THEN
                -- Inserimento Anomalia Codice fiscale multiplo
                BEGIN
                  INSERT INTO ANOMALIE_CARICAMENTO
                    (DOCUMENTO_ID,
                     COGNOME,
                     NOME,
                     COD_FISCALE,
                     DESCRIZIONE,
                     NOTE)
                  VALUES
                    (A_DOCUMENTO_ID,
                     SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE,
                                REC_SOGG.PFCOGNOME),
                            1,
                            60),
                     SUBSTR(REC_SOGG.PFNOME, 1, 36),
                     REC_SOGG.PFCODICEFISCALE,
                     'Ci sono piu'' soggetti con lo stesso Codice Fiscale e nessuno e'' contribuente',
                     NULL);
                EXCEPTION
                  WHEN OTHERS THEN
                    W_ERRORE := 'Errore in inserimento anomalie_caricamento ' ||
                                SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE,
                                           REC_SOGG.PFCOGNOME),
                                       1,
                                       60) || ' (' || SQLERRM || ')';
                    RAISE ERRORE;
                END;
                W_ANOMALIA_CONT := 'S';
              WHEN OTHERS THEN
                W_ERRORE := 'Errore in verifica Partita IVA (2) per ' ||
                            REC_SOGG.PGCODICEFISCALE || ' (' || SQLERRM || ')';
                RAISE ERRORE;
            END;
          END IF;
        END IF;
        -- DBMS_OUTPUT.Put_Line('w_ni: '||to_char(nvl(w_ni,-9999)));
        IF W_NI IS NULL AND W_ANOMALIA_CONT = 'N' THEN
          -- Inserimento Nuovo Soggetto
          W_CANCELLA_SOGGETTO := 'S';
          -- il soggetto verrà cancellato se la pratica risulterà non trattata
          -- (nessun ogpr da trattare)
          IF REC_SOGG.PGCODICEFISCALE IS NULL THEN
            BEGIN
              SELECT COMUNE, PROVINCIA_STATO
                INTO W_COD_COM_NAS, W_COD_PRO_NAS
                FROM AD4_COMUNI
               WHERE SIGLA_CFIS = REC_SOGG.PFLUOGONASCITA;
            EXCEPTION
              WHEN OTHERS THEN
                W_COD_COM_NAS := NULL;
                W_COD_PRO_NAS := NULL;
            END;
            DECODIFICA_INDIRIZZO(REC_SOGG.INDIRIZZO,
                                 W_RES_DENOMINAZIONE_VIA,
                                 W_RES_NUM_CIV,
                                 W_RES_SUFFISSO);
            -- DBMS_OUTPUT.Put_Line('Ind_PF: '||rec_sogg.Indirizzo);
            BEGIN
              SELECT COM.COMUNE, COM.PROVINCIA_STATO
                INTO W_COD_COM_RES, W_COD_PRO_RES
                FROM AD4_COMUNI COM, AD4_PROVINCIE PRO
               WHERE COM.PROVINCIA_STATO = PRO.PROVINCIA
                 AND COM.DENOMINAZIONE = REC_SOGG.COMUNE
                 AND PRO.SIGLA = REC_SOGG.PROVINCIA;
            EXCEPTION
              WHEN OTHERS THEN
                W_COD_COM_RES := NULL;
                W_COD_PRO_RES := NULL;
            END;
            W_CAP := TO_NUMBER(LTRIM(RTRIM(REC_SOGG.CAP)));
            W_NI  := NULL;
            SOGGETTI_NR(W_NI);
            BEGIN
              INSERT INTO SOGGETTI
                (NI,
                 TIPO_RESIDENTE,
                 COD_FISCALE,
                 COGNOME_NOME,
                 DATA_NAS,
                 COD_COM_NAS,
                 COD_PRO_NAS,
                 SESSO,
                 DENOMINAZIONE_VIA,
                 NUM_CIV,
                 SUFFISSO,
                 COD_COM_RES,
                 COD_PRO_RES,
                 CAP,
                 TIPO,
                 FONTE,
                 UTENTE,
                 DATA_VARIAZIONE)
              VALUES
                (W_NI,
                 1,
                 REC_SOGG.PFCODICEFISCALE,
                 SUBSTR(REC_SOGG.PFCOGNOME || '/' || REC_SOGG.PFNOME, 1, 60),
                 TO_DATE(REC_SOGG.PFDATANASCITA, 'ddmmyyyy'),
                 W_COD_COM_NAS,
                 W_COD_PRO_NAS,
                 DECODE(REC_SOGG.PFSESSO, '1', 'M', '2', 'F', NULL),
                 W_RES_DENOMINAZIONE_VIA,
                 W_RES_NUM_CIV,
                 W_RES_SUFFISSO,
                 W_COD_COM_RES,
                 W_COD_PRO_RES,
                 W_CAP,
                 '0',
                 A_FONTE,
                 A_UTENTE,
                 TRUNC(SYSDATE));
            EXCEPTION
              WHEN OTHERS THEN
                W_ERRORE := 'Errore in inserimento Soggetto ' ||
                            REC_SOGG.PFCODICEFISCALE || ' (' || SQLERRM || ')';
                RAISE ERRORE;
            END;
            W_NUM_NUOVI_SOGGETTI := W_NUM_NUOVI_SOGGETTI + 1;
            W_COD_FISCALE        := REC_SOGG.PFCODICEFISCALE;
            -- DBMS_OUTPUT.Put_Line('CF_PF: '||w_cod_fiscale);
          ELSE
            -- DBMS_OUTPUT.Put_Line('Ind_PG: '||rec_sogg.Indirizzo);
            DECODIFICA_INDIRIZZO(REC_SOGG.INDIRIZZO,
                                 W_RES_DENOMINAZIONE_VIA,
                                 W_RES_NUM_CIV,
                                 W_RES_SUFFISSO);
            BEGIN
              SELECT COM.COMUNE, COM.PROVINCIA_STATO
                INTO W_COD_COM_RES, W_COD_PRO_RES
                FROM AD4_COMUNI COM, AD4_PROVINCIE PRO
               WHERE COM.PROVINCIA_STATO = PRO.PROVINCIA
                 AND COM.DENOMINAZIONE = REC_SOGG.COMUNE
                 AND PRO.SIGLA = REC_SOGG.PROVINCIA;
            EXCEPTION
              WHEN OTHERS THEN
                W_COD_COM_RES := NULL;
                W_COD_PRO_RES := NULL;
            END;
            W_CAP := TO_NUMBER(LTRIM(RTRIM(REC_SOGG.CAP)));
            W_NI  := NULL;
            SOGGETTI_NR(W_NI);
            BEGIN
              INSERT INTO SOGGETTI
                (NI,
                 TIPO_RESIDENTE,
                 COD_FISCALE,
                 COGNOME_NOME,
                 PARTITA_IVA,
                 DENOMINAZIONE_VIA,
                 NUM_CIV,
                 SUFFISSO,
                 COD_COM_RES,
                 COD_PRO_RES,
                 CAP,
                 TIPO,
                 FONTE,
                 UTENTE,
                 DATA_VARIAZIONE)
              VALUES
                (W_NI,
                 1,
                 DECODE(LENGTH(REC_SOGG.PGCODICEFISCALE),
                        16,
                        REC_SOGG.PGCODICEFISCALE,
                        ''),
                 SUBSTR(REC_SOGG.PGDENOMINAZIONE, 1, 60),
                 DECODE(LENGTH(REC_SOGG.PGCODICEFISCALE),
                        16,
                        '',
                        REC_SOGG.PGCODICEFISCALE),
                 W_RES_DENOMINAZIONE_VIA,
                 W_RES_NUM_CIV,
                 W_RES_SUFFISSO,
                 W_COD_COM_RES,
                 W_COD_PRO_RES,
                 W_CAP,
                 '1',
                 A_FONTE,
                 A_UTENTE,
                 TRUNC(SYSDATE));
            EXCEPTION
              WHEN OTHERS THEN
                W_ERRORE := 'Errore in inserimento Soggetto ' ||
                            REC_SOGG.PGCODICEFISCALE || ' (' || SQLERRM || ')';
                RAISE ERRORE;
            END;
            W_NUM_NUOVI_SOGGETTI := W_NUM_NUOVI_SOGGETTI + 1;
            W_COD_FISCALE        := REC_SOGG.PGCODICEFISCALE;
            -- DBMS_OUTPUT.Put_Line('CF_PG: '||w_cod_fiscale);
          END IF;
        ELSE
          --w_ni  is not null
          W_COD_FISCALE := NVL(REC_SOGG.PGCODICEFISCALE,
                               REC_SOGG.PFCODICEFISCALE);
          -- DBMS_OUTPUT.Put_Line('CF_trovato: '||w_cod_fiscale);
        END IF;
        IF W_COMMENTI > 0 THEN
          DBMS_OUTPUT.PUT_LINE('CF: ' || W_COD_FISCALE || ' - ni: ' ||
                               TO_CHAR(W_NI));
        END IF;
        -- Inserimento Contribuente
        -- (VD - 11/05/2015): Prima di inserire il contribuente, si controlla
        -- se esiste già un record per lo stesso ni ma con c.f. diverso
        BEGIN
          SELECT 'S'
            INTO W_ANOMALIA_CONT
            FROM CONTRIBUENTI
           WHERE NI = W_NI;
          RAISE TOO_MANY_ROWS;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            W_CANCELLA_CONTRIBUENTE := 'S';
            -- il contribuente verrà cancellato se la pratica risulterà non
            -- trattata (nessun ogpr trattato)
            BEGIN
              INSERT INTO CONTRIBUENTI
                (COD_FISCALE, NI)
              VALUES
                (W_COD_FISCALE, W_NI);
            EXCEPTION
              WHEN OTHERS THEN
                W_ERRORE := 'Errore in inserimento Contribuente ' ||
                            W_COD_FISCALE || ' (' || SQLERRM || ')';
                RAISE ERRORE;
            END;
            W_NUM_NUOVI_CONTRIBUENTI := W_NUM_NUOVI_CONTRIBUENTI + 1;
          WHEN TOO_MANY_ROWS THEN
            -- Inserimento Anomalia Soggetti e Contribuenti non allineati
            BEGIN
              INSERT INTO ANOMALIE_CARICAMENTO
                (DOCUMENTO_ID,
                 COGNOME,
                 NOME,
                 COD_FISCALE,
                 DESCRIZIONE,
                 NOTE)
              VALUES
                (A_DOCUMENTO_ID,
                 SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE, REC_SOGG.PFCOGNOME),
                        1,
                        60),
                 SUBSTR(REC_SOGG.PFNOME, 1, 36),
                 REC_SOGG.PFCODICEFISCALE,
                 'Codice fiscale del Soggetto diverso dal Codice fiscale del contribuente: allineare i due archivi',
                 NULL);
            EXCEPTION
              WHEN OTHERS THEN
                W_ERRORE := 'Errore in inserimento anomalie_caricamento ' ||
                            SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE,
                                       REC_SOGG.PFCOGNOME),
                                   1,
                                   60) || ' (' || SQLERRM || ')';
                RAISE ERRORE;
            END;
            W_ANOMALIA_CONT := 'S';
        END;
      END IF;
      -- if w_cod_fiscale is null and w_anomalia_cont = 'N'
      -- in caso di anomalia sul contribuente (w_anomalia_cont = 'S') non si
      -- inseriscono
      -- le pratiche del contribuente
      IF W_ANOMALIA_CONT = 'N' -- Contribuente senza anomalie, si trattano le
      -- titolarità
       THEN
        W_NUM_SOGGETTI := W_NUM_SOGGETTI + 1;
        -- Questa variabile indica se il record pratica è stato inserito
        -- tale record viene inserito per la prima Tipologia del Soggetto
        -- in questo modo si otttiene un'unica pratica ICI per Soggetto
        W_PRATICA_INSERITA := 'N';
        FOR REC_TITO IN SEL_TITO(REC_SOGG.TITOLARITA) LOOP
          -- (vd - 27/11/2018): si escludono dal trattamento gli oggetti
          --                    con natura tra quelle da escludere
          IF T_OGGETTO_ESCLUSO (REC_TITO.REF_IMMOBILE) IS NULL THEN
            W_ANNO_OGGETTO  := 0;
            W_ANOMALIA_TITO := 'N';
            IF W_COMMENTI > 0 THEN
              DBMS_OUTPUT.PUT_LINE('- Titolarita - ' ||
                                   REC_TITO.REF_IMMOBILE);
            END IF;
            BEGIN
              W_OGGETTO       := T_OGGETTO(REC_TITO.REF_IMMOBILE);
              W_FLAG_GRAFFATO := T_FLAG_GRAFFATO(REC_TITO.REF_IMMOBILE);
              W_ID_IMMOBILE   := T_ID_IMMOBILE(REC_TITO.REF_IMMOBILE);
                          W_TIPO_OGGETTO  := T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE);
            EXCEPTION
              WHEN OTHERS THEN
                -- Inserimento Anomalia sulla Pratica  (Contribuente)
                BEGIN
                  INSERT INTO ANOMALIE_CARICAMENTO
                    (DOCUMENTO_ID, COGNOME, NOME, DESCRIZIONE, NOTE)
                  VALUES
                    (A_DOCUMENTO_ID,
                     SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE, REC_SOGG.PFCOGNOME),
                            1,
                            60),
                     SUBSTR(REC_SOGG.PFNOME, 1, 36),
                     'CF: ' || W_COD_FISCALE || ' - Immobile Non Definito ' ||
                     REC_TITO.REF_IMMOBILE,
                     NULL);
                EXCEPTION
                  WHEN OTHERS THEN
                    W_ERRORE := 'Errore in inserimento anomalie_contribuente ' ||
                                SUBSTR(NVL(REC_SOGG.PGDENOMINAZIONE,
                                           REC_SOGG.PFCOGNOME),
                                       1,
                                       60) || ' (' || SQLERRM || ')';
                    RAISE ERRORE;
                END;
                -- La variabile indica che ho una pratica Anomala
                W_ANOMALIA_TITO := 'S';
            END;
            -- se non c'è nessuna anomalia sulla titolarita
            -- verifico le ECCEZIONI
            IF W_ANOMALIA_TITO = 'N' THEN
              W_CATEGORIA := T_CATEGORIA(REC_TITO.REF_IMMOBILE);

              IF TO_NUMBER(REC_TITO.ACQUISIZIONE) > 0 THEN
                W_CODICE_DIRITTO := REC_TITO.ACQCODICEDIRITTO;
              ELSIF TO_NUMBER(REC_TITO.CESSIONE) > 0 THEN
                W_CODICE_DIRITTO := REC_TITO.CESCODICEDIRITTO;
              ELSE
                W_CODICE_DIRITTO := NULL;
              END IF;
              -- Recupero dati ECCEZIONE
              BEGIN
                SELECT ECCEZIONE
                  INTO W_ECCEZIONE_CACA
                  FROM CATEGORIE_CATASTO
                 WHERE CATEGORIA_CATASTO = W_CATEGORIA;
              EXCEPTION
                WHEN OTHERS THEN
                  W_ERRORE := 'Errore in estrazione eccezione (CATE) ' ||
                              W_CATEGORIA || ' (' || SQLERRM || ')';
                  RAISE ERRORE;
              END;
              IF W_ECCEZIONE_CACA IS NULL THEN
                IF W_CODICE_DIRITTO IS NULL THEN
                  W_ECCEZIONE_CODI := NULL;
                ELSE
                  BEGIN
                    SELECT ECCEZIONE
                      INTO W_ECCEZIONE_CODI
                      FROM CODICI_DIRITTO
                     WHERE COD_DIRITTO = UPPER(W_CODICE_DIRITTO);
                  EXCEPTION
                    WHEN OTHERS THEN
                      W_ERRORE := 'Errore in estrazione eccezione (CODI) ' ||
                                  NVL(W_CODICE_DIRITTO, 'null') || ' Ref:' ||
                                  REC_TITO.REF_IMMOBILE || ' (' || SQLERRM || ')';
                      RAISE ERRORE;
                  END;
                END IF;
              END IF;
              -- In caso sia settata una eccezione N (NON Trattare)
              -- sulla Categoria Catasto o sul codice_diritto setto la variabile
              -- w_da_trattare = 'N'
              -- in questo caso i dati della titolarita non verranno trattati
              IF NVL(W_ECCEZIONE_CACA, W_ECCEZIONE_CODI) = 'N' THEN
                W_DA_TRATTARE := 'N';
              ELSE
                W_DA_TRATTARE := 'S';
              END IF;
            END IF;
            -- Si procede solo se non ci sono anomalie sulla titolarita
            -- e se la titolarita è da trattare
            IF W_ANOMALIA_TITO = 'N' AND W_DA_TRATTARE = 'S' THEN
              IF W_FLAG_GRAFFATO IS NULL OR W_ID_IMMOBILE IS NULL THEN
                -- Verifico se l'oggetto della denuncia è già presente per il
                -- contribuente
                -- in caso positivo la percentuale di possesso va calcolata in
                -- base a quella
                -- dell'oggetto posseduto perchè quella indicata nel tracciato è
                -- la variazione
                -- di percentuale di possesso rispetto a quella esistente.
                BEGIN
                  W_CONDIZIONE_ANNO := '=' || W_ANNO_DENUNCIA;
                  -- DM 20160520: Si cerca un oggetto per l'anno di imposta
                  W_OGGETTO := RICERCA_OGGETTO_ID(T_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                  A_TIPO_TRIBUTO,
                                                  T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                  T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                  T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                  A_CTR_PART,
                                                  W_CONDIZIONE_ANNO,
                                                  NVL(REC_SOGG.PFCODICEFISCALE,
                                                      REC_SOGG.PGCODICEFISCALE),
                                                  NULL);
                  -- Se non si trova l'oggetto per l'anno di imposta si cerca negli anni precedenti
                  IF (W_OGGETTO IS NULL) THEN
                    W_CONDIZIONE_ANNO := '<' || W_ANNO_DENUNCIA;
                    W_OGGETTO         := RICERCA_OGGETTO_ID(T_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                            A_TIPO_TRIBUTO,
                                                            T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                            T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                            T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                            A_CTR_PART,
                                                            W_CONDIZIONE_ANNO,
                                                            NVL(REC_SOGG.PFCODICEFISCALE,
                                                                REC_SOGG.PGCODICEFISCALE),
                                                            NULL);
                  END IF;
                  -- Se non si trova l'oggetto per gli anni precedenti si cerca in quelli successivi
                  IF (W_OGGETTO IS NULL) THEN
                    W_CONDIZIONE_ANNO := '>' || W_ANNO_DENUNCIA;
                    W_OGGETTO         := RICERCA_OGGETTO_ID(T_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                            A_TIPO_TRIBUTO,
                                                            T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                            T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                            T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                            A_CTR_PART,
                                                            W_CONDIZIONE_ANNO,
                                                            NVL(REC_SOGG.PFCODICEFISCALE,
                                                                REC_SOGG.PGCODICEFISCALE),
                                                            NULL);
                  END IF;
                  -- Se non è stato trovato un oggetto si utilizza quello individuato in precedenza
                  IF (W_OGGETTO IS NULL) THEN
                    W_OGGETTO         := T_OGGETTO(REC_TITO.REF_IMMOBILE);
                    W_CONDIZIONE_ANNO := '<=' || W_ANNO_DENUNCIA;
                  END IF;
                  RICERCA_DATI_PER_OGGETTO(W_OGGETTO,
                                           A_TIPO_TRIBUTO,
                                           W_CONDIZIONE_ANNO,
                                           NVL(REC_SOGG.PFCODICEFISCALE,
                                               REC_SOGG.PGCODICEFISCALE),
                                           NULL,
                                           W_FONTE_OGGETTO,
                                           W_ANNO_OGGETTO,
                                           W_PERC_POSSESSO_PREC,
                                           W_TIPO_OGGETTO_PREC,
                                           W_CATEGORIA_PREC,
                                           W_CLASSE_PREC,
                                           W_VALORE_PREC,
                                           W_TITOLO_PREC,
                                           W_FLAG_ESCLUSIONE_PREC,
                                           W_FLAG_AB_PRINC_PREC,
                                           W_CF_PREC,
                                           W_OGPR_PREC,
                                           W_VALORE_PREC_ANNO_DICH,
                                           W_DOCUMENTO_ID_PREC,
                                           W_MESI_POSSESSO_PREC,
                                           W_MESI_POSSESSO_1SEM_PREC,
                                           W_DA_MESE_POSSESSO_PREC);
                  IF (W_OGGETTO IS NULL) THEN
                    W_PERC_POSSESSO_PREC   := 0;
                    W_TIPO_OGGETTO_PREC    := NULL;
                    W_CATEGORIA_PREC       := NULL;
                    W_CLASSE_PREC          := NULL;
                    W_VALORE_PREC          := NULL;
                    W_TITOLO_PREC          := NULL;
                    W_FLAG_ESCLUSIONE_PREC := NULL;
                    W_FLAG_AB_PRINC_PREC   := NULL;
                    W_CF_PREC              := NULL;
                    W_OGPR_PREC            := NULL;
                  END IF;
                END;
              ELSE
                --  gestione graffati
                --  se l'oggetto è graffato, si controlla se e' gia' stato
                --  inserito per il contribuente
                --  dbms_output.put_line ('Id. immobile: '||w_id_immobile);
                W_OGGETTO := NULL;
                BEGIN
                  SELECT 'S'
                    INTO W_FLAG_ELAB
                    FROM WRK_GRAFFATI WRGR
                   WHERE WRGR.DOCUMENTO_ID = A_DOCUMENTO_ID
                     AND WRGR.RIFERIMENTO = REC_TITO.REF_IMMOBILE
                     AND EXISTS
                   (SELECT 'x'
                            FROM WRK_GRAFFATI_CONT WGCO
                           WHERE WGCO.DOCUMENTO_ID = A_DOCUMENTO_ID
                             AND WGCO.ID_IMMOBILE = W_ID_IMMOBILE
                             AND WGCO.COD_FISCALE = W_COD_FISCALE);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    W_FLAG_ELAB := 'N';
                END;
                -- dbms_output.put_line ('Id. immobile: '||w_id_immobile||' - '||
                -- w_flag_elab);
                IF W_FLAG_ELAB = 'S' THEN
                  W_DA_TRATTARE := 'N';
                ELSE
                  --
                  -- (VD - 11/06/2015): oggetti graffati. Si esegue prima la
                  -- ricerca dell'oggetto per lo stesso contribuente, dando la
                  -- priorita agli oggetti non esclusi
                  --
                  FOR GRAF IN (SELECT OGGETTO
                                 FROM WRK_GRAFFATI
                                WHERE DOCUMENTO_ID = A_DOCUMENTO_ID
                                  AND ID_IMMOBILE = W_ID_IMMOBILE
                                ORDER BY OGGETTO) LOOP
                    W_CONDIZIONE_ANNO := '=' || W_ANNO_DENUNCIA;
                    -- DM 20160520: Si cerca un oggetto per l'anno di imposta
                    W_OGGETTO := RICERCA_OGGETTO_ID(GRAF.OGGETTO,
                                                    A_TIPO_TRIBUTO,
                                                    T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                    T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                    T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                    A_CTR_PART,
                                                    W_CONDIZIONE_ANNO,
                                                    NVL(REC_SOGG.PFCODICEFISCALE,
                                                        REC_SOGG.PGCODICEFISCALE),
                                                    'N');
                    -- Se non si trova l'oggetto per l'anno di imposta si cerca negli anni precedenti
                    IF (W_OGGETTO IS NULL) THEN
                      W_CONDIZIONE_ANNO := '<' || W_ANNO_DENUNCIA;
                      W_OGGETTO         := RICERCA_OGGETTO_ID(GRAF.OGGETTO,
                                                              A_TIPO_TRIBUTO,
                                                              T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                              T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                              T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                              A_CTR_PART,
                                                              W_CONDIZIONE_ANNO,
                                                              NVL(REC_SOGG.PFCODICEFISCALE,
                                                                  REC_SOGG.PGCODICEFISCALE),
                                                              'N');
                    END IF;
                    -- Se non si trova l'oggetto per gli anni precedenti si cerca in quelli successivi
                    IF (W_OGGETTO IS NULL) THEN
                      W_CONDIZIONE_ANNO := '>' || W_ANNO_DENUNCIA;
                      W_OGGETTO         := RICERCA_OGGETTO_ID(GRAF.OGGETTO,
                                                              A_TIPO_TRIBUTO,
                                                              T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                              T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                              T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                              A_CTR_PART,
                                                              W_CONDIZIONE_ANNO,
                                                              NVL(REC_SOGG.PFCODICEFISCALE,
                                                                  REC_SOGG.PGCODICEFISCALE),
                                                              'N');
                    END IF;
                    -- Se non è stato trovato un oggetto si utilizza quello individuato in precedenza
                    IF (W_OGGETTO IS NULL) THEN
                      W_OGGETTO         := GRAF.OGGETTO;
                      W_CONDIZIONE_ANNO := '<=' || W_ANNO_DENUNCIA;
                    END IF;
                    RICERCA_DATI_PER_OGGETTO(W_OGGETTO,
                                             A_TIPO_TRIBUTO,
                                             W_CONDIZIONE_ANNO,
                                             NVL(REC_SOGG.PFCODICEFISCALE,
                                                 REC_SOGG.PGCODICEFISCALE),
                                             'S',
                                             W_FONTE_OGGETTO,
                                             W_ANNO_OGGETTO,
                                             W_PERC_POSSESSO_PREC,
                                             W_TIPO_OGGETTO_PREC,
                                             W_CATEGORIA_PREC,
                                             W_CLASSE_PREC,
                                             W_VALORE_PREC,
                                             W_TITOLO_PREC,
                                             W_FLAG_ESCLUSIONE_PREC,
                                             W_FLAG_AB_PRINC_PREC,
                                             W_CF_PREC,
                                             W_OGPR_PREC,
                                             W_VALORE_PREC_ANNO_DICH,
                                             W_DOCUMENTO_ID_PREC,
                                             W_MESI_POSSESSO_PREC,
                                             W_MESI_POSSESSO_1SEM_PREC,
                                             W_DA_MESE_POSSESSO_PREC);
                    IF W_OGGETTO IS NOT NULL THEN
                      EXIT;
                    END IF;
                  END LOOP;
                  --
                  -- (VD - 11/06/2015): oggetti graffati. Se la ricerca
                  -- precedente e' fallita, si ricerca tra gli oggetti del
                  -- contribuente senza considerare il flag esclusione
                  --
                  IF W_OGGETTO IS NULL THEN
                    FOR GRAF IN (SELECT OGGETTO
                                   FROM WRK_GRAFFATI
                                  WHERE DOCUMENTO_ID = A_DOCUMENTO_ID
                                    AND ID_IMMOBILE = W_ID_IMMOBILE
                                  ORDER BY OGGETTO) LOOP
                      W_CONDIZIONE_ANNO := '=' || W_ANNO_DENUNCIA;
                      -- DM 20160520: Si cerca un oggetto per l'anno di imposta
                      W_OGGETTO := RICERCA_OGGETTO_ID(GRAF.OGGETTO,
                                                      A_TIPO_TRIBUTO,
                                                      T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                      T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                      T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                      A_CTR_PART,
                                                      W_CONDIZIONE_ANNO,
                                                      NVL(REC_SOGG.PFCODICEFISCALE,
                                                          REC_SOGG.PGCODICEFISCALE),
                                                      NULL);
                      -- Se non si trova l'oggetto per l'anno di imposta si cerca negli anni precedenti
                      IF (W_OGGETTO IS NULL) THEN
                        W_CONDIZIONE_ANNO := '<' || W_ANNO_DENUNCIA;
                        W_OGGETTO         := RICERCA_OGGETTO_ID(GRAF.OGGETTO,
                                                                A_TIPO_TRIBUTO,
                                                                T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                                T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                                T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                                A_CTR_PART,
                                                                W_CONDIZIONE_ANNO,
                                                                NVL(REC_SOGG.PFCODICEFISCALE,
                                                                    REC_SOGG.PGCODICEFISCALE),
                                                                NULL);
                      END IF;
                      -- Se non si trova l'oggetto per gli anni precedenti si cerca in quelli successivi
                      IF (W_OGGETTO IS NULL) THEN
                        W_CONDIZIONE_ANNO := '>' || W_ANNO_DENUNCIA;
                        W_OGGETTO         := RICERCA_OGGETTO_ID(GRAF.OGGETTO,
                                                                A_TIPO_TRIBUTO,
                                                                T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                                T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                                T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                                A_CTR_PART,
                                                                W_CONDIZIONE_ANNO,
                                                                NVL(REC_SOGG.PFCODICEFISCALE,
                                                                    REC_SOGG.PGCODICEFISCALE),
                                                                NULL);
                      END IF;
                      -- Se non è stato trovato un oggetto si utilizza quello individuato in precedenza
                      IF (W_OGGETTO IS NULL) THEN
                        W_OGGETTO         := GRAF.OGGETTO;
                        W_CONDIZIONE_ANNO := '<=' || W_ANNO_DENUNCIA;
                      END IF;
                      RICERCA_DATI_PER_OGGETTO(W_OGGETTO,
                                               A_TIPO_TRIBUTO,
                                               W_CONDIZIONE_ANNO,
                                               NVL(REC_SOGG.PFCODICEFISCALE,
                                                   REC_SOGG.PGCODICEFISCALE),
                                               NULL,
                                               W_FONTE_OGGETTO,
                                               W_ANNO_OGGETTO,
                                               W_PERC_POSSESSO_PREC,
                                               W_TIPO_OGGETTO_PREC,
                                               W_CATEGORIA_PREC,
                                               W_CLASSE_PREC,
                                               W_VALORE_PREC,
                                               W_TITOLO_PREC,
                                               W_FLAG_ESCLUSIONE_PREC,
                                               W_FLAG_AB_PRINC_PREC,
                                               W_CF_PREC,
                                               W_OGPR_PREC,
                                               W_VALORE_PREC_ANNO_DICH,
                                               W_DOCUMENTO_ID_PREC,
                                               W_MESI_POSSESSO_PREC,
                                               W_MESI_POSSESSO_1SEM_PREC,
                                               W_DA_MESE_POSSESSO_PREC);
                      IF W_OGGETTO IS NOT NULL THEN
                        EXIT;
                      END IF;
                    END LOOP;
                  END IF;
                  --
                  -- Se l'oggetto non e' stato trovato per il contribuente,
                  -- si verifica se esiste per altri contribuenti
                  --
                  IF W_OGGETTO IS NULL THEN
                    W_PERC_POSSESSO_PREC   := 0;
                    W_TIPO_OGGETTO_PREC    := NULL;
                    W_CATEGORIA_PREC       := NULL;
                    W_CLASSE_PREC          := NULL;
                    W_VALORE_PREC          := NULL;
                    W_TITOLO_PREC          := NULL;
                    W_FLAG_ESCLUSIONE_PREC := NULL;
                    W_FLAG_AB_PRINC_PREC   := NULL;
                    W_CF_PREC              := NULL;
                    W_OGPR_PREC            := NULL;
                    FOR GRAF IN (SELECT OGGETTO
                                   FROM WRK_GRAFFATI
                                  WHERE DOCUMENTO_ID = A_DOCUMENTO_ID
                                    AND ID_IMMOBILE = W_ID_IMMOBILE
                                  ORDER BY RIFERIMENTO) LOOP
                      W_CONDIZIONE_ANNO := '=' || W_ANNO_DENUNCIA;
                      -- DM 20160520: Si cerca un oggetto per l'anno di imposta
                      W_OGGETTO := RICERCA_OGGETTO_ID(GRAF.OGGETTO,
                                                      A_TIPO_TRIBUTO,
                                                      T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                      T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                      T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                      A_CTR_PART,
                                                      W_CONDIZIONE_ANNO,
                                                      NULL,
                                                      NULL);
                      -- Se non si trova l'oggetto per l'anno di imposta si cerca negli anni precedenti
                      IF (W_OGGETTO IS NULL) THEN
                        W_CONDIZIONE_ANNO := '<' || W_ANNO_DENUNCIA;
                        W_OGGETTO         := RICERCA_OGGETTO_ID(GRAF.OGGETTO,
                                                                A_TIPO_TRIBUTO,
                                                                T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                                T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                                T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                                A_CTR_PART,
                                                                W_CONDIZIONE_ANNO,
                                                                NULL,
                                                                NULL);
                      END IF;
                      -- Se non si trova l'oggetto per gli anni precedenti si cerca in quelli successivi
                      IF (W_OGGETTO IS NULL) THEN
                        W_CONDIZIONE_ANNO := '>' || W_ANNO_DENUNCIA;
                        W_OGGETTO         := RICERCA_OGGETTO_ID(GRAF.OGGETTO,
                                                                A_TIPO_TRIBUTO,
                                                                T_CATEGORIA(REC_TITO.REF_IMMOBILE),
                                                                T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE),
                                                                T_PARTITA(REC_TITO.REF_IMMOBILE),
                                                                A_CTR_PART,
                                                                W_CONDIZIONE_ANNO,
                                                                NULL,
                                                                NULL);
                      END IF;
                      -- Se non è stato trovato un oggetto si utilizza quello individuato in precedenza
                      IF (W_OGGETTO IS NULL) THEN
                        W_OGGETTO         := GRAF.OGGETTO;
                        W_CONDIZIONE_ANNO := '<=' || W_ANNO_DENUNCIA;
                      END IF;
                      RICERCA_DATI_PER_OGGETTO(W_OGGETTO,
                                               A_TIPO_TRIBUTO,
                                               W_CONDIZIONE_ANNO,
                                               NULL,
                                               NULL,
                                               W_FONTE_OGGETTO,
                                               W_ANNO_OGGETTO,
                                               W_PERC_POSSESSO_PREC,
                                               W_TIPO_OGGETTO_PREC,
                                               W_CATEGORIA_PREC,
                                               W_CLASSE_PREC,
                                               W_VALORE_PREC,
                                               W_TITOLO_PREC,
                                               W_FLAG_ESCLUSIONE_PREC,
                                               W_FLAG_AB_PRINC_PREC,
                                               W_CF_PREC,
                                               W_OGPR_PREC,
                                               W_VALORE_PREC_ANNO_DICH,
                                               W_DOCUMENTO_ID_PREC,
                                               W_MESI_POSSESSO_PREC,
                                               W_MESI_POSSESSO_1SEM_PREC,
                                               W_DA_MESE_POSSESSO_PREC);
                      IF (W_OGGETTO IS NULL) THEN
                        W_OGGETTO := NULL;
                      END IF;
                      IF W_OGGETTO IS NOT NULL THEN
                        EXIT;
                      END IF;
                    END LOOP;
                    -- Se l'oggetto non viene trovato, si utilizza l'oggetto
                    -- relativo al riferimento immobile che si sta trattando
                    IF W_OGGETTO IS NULL THEN
                      W_OGGETTO      := T_OGGETTO(REC_TITO.REF_IMMOBILE);
                      W_ANNO_OGGETTO := 0;
                    END IF;
                  END IF;
                  -- Si memorizza il contribuente trattato nella tabella
                  -- WRK_GRAFFATI_CONT
                  BEGIN
                    INSERT INTO WRK_GRAFFATI_CONT
                      (DOCUMENTO_ID, ID_IMMOBILE, COD_FISCALE)
                      SELECT A_DOCUMENTO_ID, W_ID_IMMOBILE, W_COD_FISCALE
                        FROM DUAL
                       WHERE NOT EXISTS
                       (SELECT 'x'
                                FROM WRK_GRAFFATI_CONT X
                               WHERE X.DOCUMENTO_ID = A_DOCUMENTO_ID
                                 AND X.ID_IMMOBILE = W_ID_IMMOBILE
                                 AND X.COD_FISCALE = W_COD_FISCALE);
                  EXCEPTION
                    WHEN OTHERS THEN
                      W_ERRORE := 'Errore in inserimento WRK_GRAFFATI_CONT: ' ||
                                  W_COD_FISCALE || ' Ref:' ||
                                  REC_TITO.REF_IMMOBILE || ' (' || SQLERRM || ')';
                      RAISE ERRORE;
                  END;
                END IF;
              END IF; -- fine trattamento oggetti graffati/non graffati
            END IF;
            --
            -- DM - 21/06/2016 - Se count = 0 l'oggetto non è attivo nell'anno
            /*SELECT COUNT(1)
              INTO W_POSSEDUTO
              FROM OGGETTI_PRATICA      OGPR,
                   PRATICHE_TRIBUTO     PRTR,
                   OGGETTI_CONTRIBUENTE OGCO
             WHERE OGPR.PRATICA = PRTR.PRATICA
               AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
               AND PRTR.TIPO_TRIBUTO || '' = A_TIPO_TRIBUTO
               AND OGPR.OGGETTO = W_OGGETTO
               AND OGCO.COD_FISCALE = W_COD_FISCALE
               AND PRTR.ANNO = W_ANNO_DENUNCIA
               AND OGCO.FLAG_POSSESSO = 'S';*/
            -- (VD - 10/02/2021): corretto controllo possesso oggetto.
            --                    Si verifica l'ultima denuncia relativa
            --                    all'oggetto e al contribuente avente
            --                    anno <= all'anno della nuova denuncia:
            --                    se il flag_possesso (ultimo carattere
            --                    della stringa) è 'S' l'oggetto è posseduto.
            select max(b.anno||b.tipo_rapporto||b.flag_possesso)
              into w_max_posseduto
              from pratiche_tributo c,
                   oggetti_contribuente b,
                   oggetti_pratica a
             where ((c.data_notifica is null and c.tipo_pratica = 'D')
                or (c.data_notifica is not null and c.tipo_pratica = 'A' and
                    nvl(c.stato_accertamento,'D') = 'D' and
                    nvl(c.flag_denuncia,' ')      = 'S' and
                    c.anno                        < w_anno_denuncia))
                and c.anno                  <= w_anno_denuncia
                and c.tipo_tributo||''      = 'ICI'
                and c.pratica                = a.pratica
                and b.tipo_rapporto         in ('C','D','E')
                and a.oggetto_pratica        = b.oggetto_pratica
                and b.cod_fiscale            = w_cod_fiscale
                and a.oggetto                = w_oggetto;
            if substr(nvl(w_max_posseduto,'0000XX'),6,1) = 'S' then
               w_posseduto := 1;
            else
               w_posseduto := 0;
            end if;
            IF W_ANOMALIA_TITO = 'N' AND W_DA_TRATTARE = 'S' THEN
              IF TO_NUMBER(REC_TITO.ACQUISIZIONE) > 0 THEN
                IF REC_TITO.ACQQUOTADENOMINATORE IS NOT NULL THEN
                  -- Se esiste una denuncia per l'oggetto e non proviene da fonte MUI
                                  -- o esiste una cessazione per l'oggetto nell'anno di denuncia
                  -- si crea un nuovo quadro con percentuale di possesso presa dal MUI
                  IF ((W_ANNO_OGGETTO = W_ANNO_DENUNCIA AND
                     W_FONTE_OGGETTO != A_FONTE) OR
                     (W_ANNO_OGGETTO > W_ANNO_DENUNCIA)
                                       OR W_POSSEDUTO = 0) THEN
                    W_PERC_POSSESSO := (TO_NUMBER(REC_TITO.ACQQUOTANUMERATORE) / 10) /
                                       TO_NUMBER(REC_TITO.ACQQUOTADENOMINATORE);
                  ELSE
                    W_PERC_POSSESSO := W_PERC_POSSESSO_PREC +
                                       (TO_NUMBER(REC_TITO.ACQQUOTANUMERATORE) / 10) /
                                       TO_NUMBER(REC_TITO.ACQQUOTADENOMINATORE);
                  END IF;
                ELSE
                  W_PERC_POSSESSO := NULL;
                END IF;
                W_TITOLO        := 'A';
                W_FLAG_POSSESSO := 'S';
                W_MESI_POSSESSO := 13 - TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                                  'ddmmyyyy'),
                                                          'mm'));
                W_DA_MESE_POSSESSO := TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                                  'ddmmyyyy'),
                                                          'mm'));
                IF TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                             'ddmmyyyy'),
                                     'dd')) > 15 THEN
                  W_MESI_POSSESSO := W_MESI_POSSESSO - 1;
                  W_DA_MESE_POSSESSO := W_DA_MESE_POSSESSO + 1;
                END IF;
                IF TO_DATE(REC_VARI.DATAVALIDITAATTO, 'ddmmyyyy') >
                   TO_DATE('3006' || TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                     'ddmmyyyy'),
                                             'yyyy'),
                           'ddmmyyyy') THEN
                  W_MESI_POSSESSO_1SEM := 0;
                ELSE
                  W_MESI_POSSESSO_1SEM := 7 - TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                                        'ddmmyyyy'),
                                                                'mm'));
                  IF TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                               'ddmmyyyy'),
                                       'dd')) > 15 THEN
                    W_MESI_POSSESSO_1SEM := W_MESI_POSSESSO_1SEM - 1;
                  END IF;
                END IF;
                --w_codice_diritto := rec_tito.AcqCodiceDiritto;
                W_REGIME := REC_TITO.ACQREGIME;
              ELSIF TO_NUMBER(REC_TITO.CESSIONE) > 0 THEN
                W_TITOLO := 'C';
                -- se la QuotaDenominatore è nulla inserisco una cessazione  con
                -- %pos null
                -- senza verificare i dati dell'oggetto già presente
                IF W_PERC_POSSESSO_PREC = 0 OR -- Non ho trovato l'oggetto
                   REC_TITO.CESQUOTADENOMINATORE IS NULL THEN
                  IF REC_TITO.CESQUOTADENOMINATORE IS NOT NULL THEN
                    W_PERC_POSSESSO := (TO_NUMBER(REC_TITO.CESQUOTANUMERATORE) / 10) /
                                       TO_NUMBER(REC_TITO.CESQUOTADENOMINATORE);
                  ELSE
                    W_PERC_POSSESSO := NULL;
                  END IF;
                  W_FLAG_POSSESSO := NULL;
                  W_MESI_POSSESSO := TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                               'ddmmyyyy'),
                                                       'mm'));
                  W_DA_MESE_POSSESSO := 1;
                  IF TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                               'ddmmyyyy'),
                                       'dd')) <= 15 THEN
                    W_MESI_POSSESSO := W_MESI_POSSESSO - 1;
                  END IF;
                  IF TO_DATE(REC_VARI.DATAVALIDITAATTO, 'ddmmyyyy') >
                     TO_DATE('3006' || TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                       'ddmmyyyy'),
                                               'yyyy'),
                             'ddmmyyyy') THEN
                    W_MESI_POSSESSO_1SEM := 6;
                  ELSE
                    W_MESI_POSSESSO_1SEM := TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                                      'ddmmyyyy'),
                                                              'mm'));
                    IF TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                 'ddmmyyyy'),
                                         'dd')) <= 15 THEN
                      W_MESI_POSSESSO_1SEM := W_MESI_POSSESSO_1SEM - 1;
                    END IF;
                  END IF;
                ELSE
                  -- l'oggetto era già posseduto
                  IF W_PERC_POSSESSO_PREC <=
                     (TO_NUMBER(REC_TITO.CESQUOTANUMERATORE) / 10) /
                     TO_NUMBER(REC_TITO.CESQUOTADENOMINATORE) THEN
                    -- è una cessazione
                    W_PERC_POSSESSO := (TO_NUMBER(REC_TITO.CESQUOTANUMERATORE) / 10) /
                                       TO_NUMBER(REC_TITO.CESQUOTADENOMINATORE);
                    W_FLAG_POSSESSO := NULL;
                    W_MESI_POSSESSO := TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                                 'ddmmyyyy'),
                                                         'mm'));
                    W_DA_MESE_POSSESSO := 1;
                    IF TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                 'ddmmyyyy'),
                                         'dd')) <= 15 THEN
                       W_MESI_POSSESSO := W_MESI_POSSESSO - 1;
                    END IF;
                    IF TO_DATE(REC_VARI.DATAVALIDITAATTO, 'ddmmyyyy') >
                       TO_DATE('3006' || TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                         'ddmmyyyy'),
                                                 'yyyy'),
                               'ddmmyyyy') THEN
                      W_MESI_POSSESSO_1SEM := 6;
                    ELSE
                      W_MESI_POSSESSO_1SEM := TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                                        'ddmmyyyy'),
                                                                'mm'));
                      IF TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                   'ddmmyyyy'),
                                           'dd')) <= 15 THEN
                         W_MESI_POSSESSO_1SEM := W_MESI_POSSESSO_1SEM - 1;
                      END IF;
                    END IF;
                             -- DM 20170908
                             IF W_ANNO_DENUNCIA = W_ANNO_OGGETTO THEN
                                W_MESI_POSSESSO := W_MESI_POSSESSO - (12 - W_MESI_POSSESSO_PREC);
                                W_MESI_POSSESSO_1SEM := W_MESI_POSSESSO_1SEM - (6 - W_MESI_POSSESSO_1SEM_PREC);
                                W_DA_MESE_POSSESSO := W_DA_MESE_POSSESSO_PREC + (12 - W_MESI_POSSESSO_PREC);
                             END IF;
                  ELSE
                    -- è una variazione di percentuale di possesso
                    W_PERC_POSSESSO := W_PERC_POSSESSO_PREC -
                                       (TO_NUMBER(REC_TITO.CESQUOTANUMERATORE) / 10) /
                                       TO_NUMBER(REC_TITO.CESQUOTADENOMINATORE);
                    W_FLAG_POSSESSO := 'S';
                    W_MESI_POSSESSO := 13 - TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                                      'ddmmyyyy'),
                                                              'mm'));
                    W_DA_MESE_POSSESSO := TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                                      'ddmmyyyy'),
                                                              'mm'));
                    IF TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                 'ddmmyyyy'),
                                         'dd')) > 15 THEN
                      W_MESI_POSSESSO := W_MESI_POSSESSO - 1;
                      W_DA_MESE_POSSESSO := W_DA_MESE_POSSESSO + 1;
                    END IF;
                    IF TO_DATE(REC_VARI.DATAVALIDITAATTO, 'ddmmyyyy') >
                       TO_DATE('3006' || TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                         'ddmmyyyy'),
                                                 'yyyy'),
                               'ddmmyyyy') THEN
                      W_MESI_POSSESSO_1SEM := 0;
                    ELSE
                      W_MESI_POSSESSO_1SEM := 7 -
                                              TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                                        'ddmmyyyy'),
                                                                'mm'));
                      IF TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                   'ddmmyyyy'),
                                           'dd')) > 15 THEN
                        W_MESI_POSSESSO_1SEM := W_MESI_POSSESSO_1SEM - 1;
                      END IF;
                    END IF;
                  END IF;
                END IF;
                --w_codice_diritto := rec_tito.CesCodiceDiritto;
                W_REGIME := REC_TITO.CESREGIME;
              ELSE
                -- Caso Ne di Acquisizione ne di Cessazione, esiste solo il dato
                -- catastale
                -- Utilizzo la variabile w_titolo settata a 'N' per indicare che
                -- esiste il solo
                -- dato catastale e non va inserita la pratica
                W_TITOLO             := 'N';
                W_FLAG_POSSESSO      := NULL;
                W_MESI_POSSESSO      := NULL;
                W_MESI_POSSESSO_1SEM := NULL;
                W_PERC_POSSESSO      := NULL;
                --w_codice_diritto     := null;
                W_REGIME         := NULL;
                W_NUM_NO_ACQ_CES := W_NUM_NO_ACQ_CES + 1;
              END IF;
              -- DBMS_OUTPUT.Put_Line('Titolo: '||w_titolo);
              -- DBMS_OUTPUT.Put_Line('Perc. Pos: '||to_char(w_perc_possesso));
              -- DBMS_OUTPUT.Put_Line('Mesi Pos: '||to_char(w_mesi_possesso));
              -- DBMS_OUTPUT.Put_Line('Mesi Pos 1s: '||to_char(w_mesi_possesso_1sem));
              -- Controllo esistenza Pratica
              IF NVL(A_CTR_DENUNCIA, 'N') = 'S' AND W_TITOLO IN ('A', 'C') THEN
                BEGIN
                  SELECT COUNT(1)
                    INTO W_PRATICA_ESISTENTE
                    FROM OGGETTI_PRATICA      OGPR,
                         PRATICHE_TRIBUTO     PRTR,
                         OGGETTI_CONTRIBUENTE OGCO,
                         RAPPORTI_TRIBUTO     RATR
                   WHERE OGPR.PRATICA = PRTR.PRATICA
                     AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
                     AND PRTR.TIPO_TRIBUTO || '' = A_TIPO_TRIBUTO
                     AND OGPR.OGGETTO = W_OGGETTO
                     AND OGCO.COD_FISCALE = W_COD_FISCALE
                     AND PRTR.ANNO = W_ANNO_DENUNCIA
                     AND PRTR.TIPO_PRATICA = 'D'
  --                   AND OGCO.MESI_POSSESSO = W_MESI_POSSESSO
                     AND OGCO.PERC_POSSESSO BETWEEN (W_PERC_POSSESSO - 1) AND
                         (W_PERC_POSSESSO + 1) --AB 01/06/2016
                     AND RATR.COD_FISCALE = PRTR.COD_FISCALE
                     AND RATR.PRATICA = PRTR.PRATICA
                     AND RATR.TIPO_RAPPORTO IN ('C', 'D', 'E')
                     AND NVL(OGCO.FLAG_POSSESSO, 'N') =
                         NVL(W_FLAG_POSSESSO, 'N');
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    W_PRATICA_ESISTENTE := 0;
                  WHEN OTHERS THEN
                    W_ERRORE := 'Errore in inserimento Contribuente ' ||
                                W_COD_FISCALE || ' (' || SQLERRM || ')';
                    RAISE ERRORE;
                END;
                -- SC 15/04/2014: le pratiche TASI del 2014 esistenti, ma non
                -- caricate da notai
                -- sono state copiate dall'IMU 2013, quindi vengono annullate in
                -- fase di caricamento
                -- da notai. PEr annullare si intende mettere i mesi possesso a
                -- 0 e il flag possesso a null.
                IF W_PRATICA_ESISTENTE > 0 AND A_TIPO_TRIBUTO = 'TASI' AND
                   W_ANNO_DENUNCIA = 2014 THEN
                  UPDATE OGGETTI_CONTRIBUENTE
                     SET FLAG_POSSESSO      = NULL,
                         MESI_POSSESSO      = 0,
                         MESI_ESCLUSIONE    = 0,
                         MESI_POSSESSO_1SEM = 0,
                         MESI_RIDUZIONE     = 0
                   WHERE (OGGETTO_PRATICA, COD_FISCALE) IN
                         (SELECT OGCO.OGGETTO_PRATICA, OGCO.COD_FISCALE
                            FROM OGGETTI_PRATICA      OGPR,
                                 PRATICHE_TRIBUTO     PRTR,
                                 OGGETTI_CONTRIBUENTE OGCO,
                                 RAPPORTI_TRIBUTO     RATR
                           WHERE OGPR.PRATICA = PRTR.PRATICA
                             AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
                             AND PRTR.TIPO_TRIBUTO || '' = A_TIPO_TRIBUTO
                             AND OGPR.OGGETTO = W_OGGETTO
                             AND OGCO.COD_FISCALE = W_COD_FISCALE
                             AND PRTR.ANNO = W_ANNO_DENUNCIA
                             AND PRTR.TIPO_PRATICA = 'D'
                             AND RATR.COD_FISCALE = PRTR.COD_FISCALE
                             AND RATR.PRATICA = PRTR.PRATICA
                             AND RATR.TIPO_RAPPORTO IN ('C', 'D', 'E')
                             AND NVL(OGCO.FLAG_POSSESSO, 'N') = 'S');
                  -- solo se ho azzerato una pratica devo caricare la nuova.
                  IF SQL%ROWCOUNT > 0 THEN
                    W_PRATICA_ESISTENTE := 0;
                  END IF;
                END IF;
              ELSE
                W_PRATICA_ESISTENTE := 0;
              END IF;
              /*
                  DM - 18/04/2016
                  -- In caso di rettifica la pratica non viene inserita (si inserisce un'anomalia)
                  -- TASI e tipo Terreno la pratica non viene inserita
              */
              IF NVL(W_TIPO_NOTA, ' ') = 'T' THEN
                BEGIN
                  SELECT ESTREMI_CATASTO
                    INTO W_ESTREMI_CATASTO_ERROR
                    FROM OGGETTI OGG
                   WHERE OGG.OGGETTO = W_OGGETTO;
                  W_DATI_OGGETTO := 'CF:' || W_COD_FISCALE || ';' || 'EC:' ||
                                    W_ESTREMI_CATASTO_ERROR;
                  INSERT INTO ANOMALIE_CARICAMENTO
                    (DOCUMENTO_ID, OGGETTO, DESCRIZIONE, DATI_OGGETTO, NOTE)
                  VALUES
                    (A_DOCUMENTO_ID,
                     W_OGGETTO,
                     'Tipo nota rettifica',
                     W_DATI_OGGETTO,
                     'N. Nota: ' || REC_VARI.NUMERONOTA || '; Ref. Imm.: ' ||
                     REC_TITO.REF_IMMOBILE);
                EXCEPTION
                  WHEN OTHERS THEN
                    W_ERRORE := 'Errore in inserimento anomalie_caricamento pratica: ' ||
                                TO_CHAR(W_OGGETTO) || ' (' || SQLERRM || ')';
                    RAISE ERRORE;
                END;
              END IF;
              -- La pratica viene inserita solo se esiste la parte relativa all'
              -- acquisizione o Cessazione
              -- e se non è già presente sul DB se c'è il controllo sulla
              -- denuncia
              -- non si tratta di rettifica
              -- Non è un terreno per il tributo TASI
              IF W_TITOLO IN ('A', 'C') AND W_PRATICA_ESISTENTE = 0 AND
                 NVL(W_TIPO_NOTA, ' ') != 'T' AND
                 NOT (A_TIPO_TRIBUTO = 'TASI' AND W_TIPO_OGGETTO = 1) THEN
                IF W_PRATICA_INSERITA = 'N' THEN
                  W_PRATICA := NULL;
                  PRATICHE_TRIBUTO_NR(W_PRATICA);
                  -- (VD - 10/01/2020): si memorizza la pratica da archiviare
                  --                    nel primo elemento dell'array libero
                  W_IND := W_IND + 1;
                  T_PRATICA (W_IND) := W_PRATICA;
                  BEGIN
                    INSERT INTO PRATICHE_TRIBUTO
                      (PRATICA,
                       COD_FISCALE,
                       TIPO_TRIBUTO,
                       ANNO,
                       TIPO_PRATICA,
                       TIPO_EVENTO,
                       DATA,
                       UTENTE,
                       DATA_VARIAZIONE,
                       NOTE,
                       NUMERO,
                       DOCUMENTO_ID)
                    VALUES
                      (W_PRATICA,
                       W_COD_FISCALE,
                       A_TIPO_TRIBUTO,
                       W_ANNO_DENUNCIA,
                       'D',
                       'I',
                       TO_DATE(REC_VARI.DATAPRESENTAZIONEATTO, 'ddmmyyyy'),
                       A_UTENTE,
                       TRUNC(SYSDATE),
                       'Notai',
                       A_DOCUMENTO_ID || '-' || REC_VARI.NUMERONOTA,
                       A_DOCUMENTO_ID);
                  EXCEPTION
                    WHEN OTHERS THEN
                      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                      W_ERRORE := 'Errore in inserimento nuova pratica ' ||
                                  F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                     W_ANNO_DENUNCIA) || ' (' ||
                                  SQL_ERRM || ')';
                      RAISE ERRORE;
                  END;
                  W_PRATICA_INSERITA := 'S';
                  W_NUM_PRATICHE     := W_NUM_PRATICHE + 1;
                  W_NUM_ORDINE       := 1;
                  -- se la pratica viene inserita devo settare le variabili che
                  -- indicano
                  -- la cancellazione finale del soggetto/contribuente a 'N' in
                  -- modo che
                  -- non venga cancellato
                  W_CANCELLA_CONTRIBUENTE := 'N';
                  W_CANCELLA_SOGGETTO     := 'N';
                  BEGIN
                    INSERT INTO RAPPORTI_TRIBUTO
                      (PRATICA, COD_FISCALE, TIPO_RAPPORTO)
                    VALUES
                      (W_PRATICA, W_COD_FISCALE, 'D');
                  EXCEPTION
                    WHEN OTHERS THEN
                      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                      W_ERRORE := 'Errore in inserimento rapporto tributo ' ||
                                  F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                     W_ANNO_DENUNCIA) || ' (' ||
                                  SQL_ERRM || ')';
                      RAISE ERRORE;
                  END;
                  IF A_TIPO_TRIBUTO = 'ICI' THEN
                    BEGIN
                      INSERT INTO DENUNCE_ICI
                        (PRATICA, DENUNCIA, FONTE, UTENTE, DATA_VARIAZIONE)
                      VALUES
                        (W_PRATICA,
                         W_PRATICA,
                         A_FONTE,
                         A_UTENTE,
                         TRUNC(SYSDATE));
                    EXCEPTION
                      WHEN OTHERS THEN
                        SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                        W_ERRORE := 'Errore in inserimento denunce_ici ' || ' (' ||
                                    SQL_ERRM || ')';
                        RAISE ERRORE;
                    END;
                  ELSE
                    BEGIN
                      INSERT INTO DENUNCE_TASI
                        (PRATICA, DENUNCIA, FONTE, UTENTE, DATA_VARIAZIONE)
                      VALUES
                        (W_PRATICA,
                         W_PRATICA,
                         A_FONTE,
                         A_UTENTE,
                         TRUNC(SYSDATE));
                    EXCEPTION
                      WHEN OTHERS THEN
                        SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                        W_ERRORE := 'Errore in inserimento denunce_tasi ' || ' (' ||
                                    SQL_ERRM || ')';
                        RAISE ERRORE;
                    END;
                  END IF;
                END IF;
                -- Se è presente l'informazione postRegistrazione
                -- si verifica che il valore calcolato coincida con quello aspettato solo in caso di acquisto
                IF (W_TITOLO = 'A') THEN
                                   IF (VERIFICA_PERC_POSS_POST_REG(W_PERC_POSSESSO, REC_TITO, W_PERC_POSS_ATTESA) = 'N') THEN
                                        INSERISCI_ANOMALIA(W_ANNO_DENUNCIA,
                                                                  23,
                                                                  W_COD_FISCALE,
                                                                  W_OGGETTO,
                                                                  W_PERC_POSSESSO || '-' || 'Post: ' || W_PERC_POSS_ATTESA);
                                   END IF;
                ELSIF (W_TITOLO = 'C' AND W_PERC_POSSESSO_PREC > 0
                       AND W_ANNO_OGGETTO > 0 AND W_ANNO_OGGETTO <= W_ANNO_DENUNCIA) THEN
                                -- Si verifica se presente la % pre solo se l'oggetto è trovain una denuncia precedente
                                  -- o nello stesso anno di imposta
                      IF (VERIFICA_PERC_POSS_PRE_REG(W_PERC_POSSESSO_PREC, REC_TITO, W_PERC_POSS_ATTESA) = 'N') THEN
                        INSERISCI_ANOMALIA(W_ANNO_DENUNCIA,
                                           23,
                                           W_COD_FISCALE,
                                           W_OGGETTO,
                                           W_PERC_POSSESSO_PREC || '-' || 'Pre: ' || W_PERC_POSS_ATTESA);
                      END IF;
                END IF;
                -- Se esiste già una denuncia per lo stesso anno e non ha fonte MUI
                IF (W_ANNO_OGGETTO = W_ANNO_DENUNCIA AND
                   A_FONTE != W_FONTE_OGGETTO) THEN
                   INSERISCI_ANOMALIA(W_ANNO_DENUNCIA,
                                     22,
                                     W_COD_FISCALE,
                                     W_OGGETTO);
                END IF;
                              -- DM - 21/06/2016
                              -- Si inserisce il primo quadro solo se non è già presente
                SELECT COUNT(1)
                  INTO W_ESISTE
                  FROM OGGETTI_PRATICA      OGPR,
                       PRATICHE_TRIBUTO     PRTR,
                       OGGETTI_CONTRIBUENTE OGCO,
                       RAPPORTI_TRIBUTO     RATR
                 WHERE OGPR.PRATICA = PRTR.PRATICA
                   AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
                   AND PRTR.TIPO_TRIBUTO || '' = A_TIPO_TRIBUTO
                   AND OGPR.OGGETTO = W_OGGETTO
                   AND OGCO.COD_FISCALE = W_COD_FISCALE
                   AND PRTR.ANNO = W_ANNO_DENUNCIA
                   AND PRTR.TIPO_PRATICA = 'D'
                   AND OGCO.MESI_POSSESSO = 12 - W_MESI_POSSESSO
                   AND OGCO.PERC_POSSESSO BETWEEN (W_PERC_POSSESSO_PREC - 1) AND
                       (W_PERC_POSSESSO_PREC + 1) --AB 01/06/2016
                   AND RATR.COD_FISCALE = PRTR.COD_FISCALE
                   AND RATR.PRATICA = PRTR.PRATICA
                   AND RATR.TIPO_RAPPORTO IN ('C', 'D', 'E')
                                   AND ogco.FLAG_POSSESSO IS NULL;
                -- Gestione del doppio quadro per variazioni di %possesso
                -- inserimento di un ogpr e ogco
                -- inserisco il doppio quadro se l'oggetto era precedentemente
                -- posseduto
                -- e ho il flag possesso
                              -- e non è già presente
                IF W_ESISTE = 0 AND W_PERC_POSSESSO_PREC <> 0 AND W_FLAG_POSSESSO = 'S' AND
                   W_ANNO_OGGETTO < W_ANNO_DENUNCIA THEN
                   W_OGGETTO_PRATICA := NULL;
                   OGGETTI_PRATICA_NR(W_OGGETTO_PRATICA);
                  BEGIN
                    INSERT INTO OGGETTI_PRATICA
                      (OGGETTO_PRATICA,
                       OGGETTO,
                       TIPO_OGGETTO,
                       PRATICA,
                       ANNO,
                       NUM_ORDINE,
                       CATEGORIA_CATASTO,
                       CLASSE_CATASTO,
                       VALORE,
                       FLAG_VALORE_RIVALUTATO,
                       TITOLO,
                       FONTE,
                       UTENTE,
                       DATA_VARIAZIONE,
                       NOTE)
                    VALUES
                      (W_OGGETTO_PRATICA,
                       W_OGGETTO,
                       W_TIPO_OGGETTO_PREC,
                       W_PRATICA,
                       W_ANNO_DENUNCIA,
                       TO_CHAR(W_NUM_ORDINE),
                       W_CATEGORIA_PREC,
                       LTRIM(W_CLASSE_PREC, '0'),
                       W_VALORE_PREC_ANNO_DICH,
                       DECODE(SIGN(1996 - W_ANNO_DENUNCIA), -1, 'S', ''),
                       W_TITOLO_PREC,
                       A_FONTE,
                       A_UTENTE,
                       TRUNC(SYSDATE),
                       DECODE(W_FLAG_ELAB,
                              NULL,
                              NULL,
                              DECODE(W_ID_IMMOBILE,
                                     NULL,
                                     'Oggetto graffato privo di identificativo catastale',
                                     NULL)));
                  EXCEPTION
                    WHEN OTHERS THEN
                      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                      W_ERRORE := 'Errore in inserimento oggetti_pratica doppio quadro ' ||
                                  F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                     W_ANNO_DENUNCIA) || ' (' ||
                                  SQL_ERRM || ')';
                      RAISE ERRORE;
                  END;
                  W_NUM_NUOVI_OGPR := W_NUM_NUOVI_OGPR + 1;
                  W_NUM_ORDINE     := W_NUM_ORDINE + 1;
                  IF W_FLAG_AB_PRINC_PREC = 'S' AND
                     SUBSTR(W_CATEGORIA_PREC, 1, 1) = 'A' AND
                     NVL(W_PERC_POSSESSO_PREC, 0) = 100 THEN
                    W_DETRAZIONE_PREC := ROUND(W_DETRAZIONE_BASE / 12 *
                                               (12 - W_MESI_POSSESSO),
                                               2);
                  ELSE
                    W_DETRAZIONE_PREC := NULL;
                  END IF;
                  /*if w_cod_fiscale = 'RSLSNO93R68F205G' then
                     dbms_output.put_line('Cod.fiscalev (1): '||w_cod_fiscale);
                     dbms_output.put_line('Mesi Possesso: '||w_mesi_possesso);
                     dbms_output.put_line('Mesi Possesso 1 sem.: '||w_mesi_possesso_1sem);
                     dbms_output.put_line('Da Mese Possesso: '||w_da_mese_possesso);
                     dbms_output.put_line('Mesi Esclusione: '||w_mesi_esclusione);
                     dbms_output.put_line('Flag Possesso: '||w_flag_possesso);
                     dbms_output.put_line('Flag Esclusione: '||w_flag_esclusione);
                     dbms_output.put_line('Flag Ab.Princ.: '||w_flag_ab_principale);
                  end if;*/
                  BEGIN
                    INSERT INTO OGGETTI_CONTRIBUENTE
                      (COD_FISCALE,
                       OGGETTO_PRATICA,
                       ANNO,
                       TIPO_RAPPORTO,
                       PERC_POSSESSO,
                       MESI_POSSESSO,
                       MESI_POSSESSO_1SEM,
                       DA_MESE_POSSESSO,
                       MESI_ESCLUSIONE,
                       FLAG_POSSESSO,
                       FLAG_ESCLUSIONE,
                       FLAG_AB_PRINCIPALE,
                       DETRAZIONE,
                       UTENTE,
                       DATA_VARIAZIONE,
                       PERC_DETRAZIONE)
                    VALUES
                      (W_COD_FISCALE,
                       W_OGGETTO_PRATICA,
                       W_ANNO_DENUNCIA,
                       'D',
                       W_PERC_POSSESSO_PREC,
                       12 - W_MESI_POSSESSO,
                       6 - W_MESI_POSSESSO_1SEM,
                       1,
                       DECODE(W_FLAG_ESCLUSIONE_PREC,
                              'S',
                              12 - W_MESI_POSSESSO,
                              NULL),
                       NULL,
                       NULL,
                       NULL,
                       W_DETRAZIONE_PREC,
                       A_UTENTE,
                       TRUNC(SYSDATE),
                       DECODE(W_DETRAZIONE_PREC, NULL, NULL, 100));
                  EXCEPTION
                    WHEN OTHERS THEN
                      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                      W_ERRORE := 'Insert OGCO ' ||
                                  F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                     W_ANNO_DENUNCIA) ||
                                  W_COD_FISCALE ||
                                 ' (' || SQL_ERRM || ')';
                      RAISE ERRORE;
                  END;
                  INSERT INTO ATTRIBUTI_OGCO
                    (COD_FISCALE,
                     OGGETTO_PRATICA,
                     DOCUMENTO_ID,
                     NUMERO_NOTA,
                     ESITO_NOTA,
                     DATA_REG_ATTI,
                     NUMERO_REPERTORIO,
                     COD_ATTO,
                     ROGANTE,
                     COD_FISCALE_ROGANTE,
                     SEDE_ROGANTE,
                     COD_DIRITTO,
                     REGIME,
                     COD_ESITO,
                     DATA_VALIDITA_ATTO,
                     UTENTE,
                     DATA_VARIAZIONE,
                     NOTE)
                  VALUES
                    (W_COD_FISCALE,
                     W_OGGETTO_PRATICA,
                     A_DOCUMENTO_ID,
                     REC_VARI.NUMERONOTA,
                     TO_NUMBER(REC_VARI.ESITONOTA),
                     TO_DATE(REC_VARI.DATAREGISTRAZIONEINATTI, 'ddmmyyyy'),
                     REC_VARI.NUMEROREPERTORIO,
                     TO_NUMBER(REC_VARI.CODICEATTO),
                     REC_VARI.ROGANTE_COGNOMENOME,
                     REC_VARI.ROGANTE_CODICEFISCALE,
                     REC_VARI.ROGANTE_SEDE,
                     W_CODICE_DIRITTO,
                     trim(W_REGIME),
                     T_COD_ESITO(REC_TITO.REF_IMMOBILE),
                     TO_DATE(REC_VARI.DATAVALIDITAATTO, 'ddmmyyyy'),
                     A_UTENTE,
                     TRUNC(SYSDATE),
                     '');
                  -- Gestione Deog Alog
                  W_DEOG_ALOG_INS := 0;
                  INSERISCI_DEOG_ALOG(W_COD_FISCALE,
                                      W_OGGETTO_PRATICA,
                                      W_ANNO_DENUNCIA,
                                      W_CF_PREC,
                                      W_OGPR_PREC,
                                      W_DEOG_ALOG_INS);
                  -- Nel caso di presenza di deog o alog vengono messi a null sia
                  -- il flag_ab_princiaple che la detrazione
                  IF W_DEOG_ALOG_INS > 0 THEN
                    BEGIN
                      UPDATE OGGETTI_CONTRIBUENTE
                         SET FLAG_AB_PRINCIPALE = NULL, DETRAZIONE = NULL
                       WHERE COD_FISCALE = W_COD_FISCALE
                         AND OGGETTO_PRATICA = W_OGGETTO_PRATICA;
                    EXCEPTION
                      WHEN OTHERS THEN
                        SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                        W_ERRORE := 'Update OGCO, annullamento ab_principale e detrazione ' ||
                                    F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                       W_ANNO_DENUNCIA) || '/' ||
                                    W_COD_FISCALE|| ' (' ||
                                    SQL_ERRM || ')';
                        RAISE ERRORE;
                    END;
                  END IF;
                END IF;
  -- Nel caso di oggetto precedente per lo stesso anno e fonte MUI si annulla il quadro precedente
  --
  -- (VD - 23/08/2017)
  -- Nota: la cessazione nell'ambito dello stesso file non viene gestita.
  --       Caso De Zan Fabio (Belluno): la cessione della quota non ha flag_possesso = 'S', quindi l'update del
  --       primo periodo non viene effettuato (in questo caso andrebbero annullati tutti i dati ed emesso il
  --       nuovo record con i mesi di possesso fino alla cessione).
  --
              IF W_DOCUMENTO_ID_PREC = A_DOCUMENTO_ID AND W_PERC_POSSESSO_PREC <> 0 AND (W_FLAG_POSSESSO = 'S' OR W_TITOLO = 'C') AND
                 W_ANNO_OGGETTO = W_ANNO_DENUNCIA AND W_FONTE_OGGETTO = A_FONTE THEN
  /*if REC_VARI.NUMERONOTA in (5666,6250) then
     dbms_output.put_line('Update OGCO ogpr_prec: '||w_ogpr_prec||', mesi possesso: '||w_mesi_possesso||', mesi 1 sem: '||w_mesi_possesso_1sem||', cod_fiscale: '||w_cod_fiscale);
     select note,mesi_possesso,mesi_possesso_1sem,mesi_esclusione
     into w_note, w_mp, w_mp_1sem, w_me
     from oggetti_contribuente
     where oggetto_pratica = w_ogpr_prec;
     dbms_output.put_line('Note: '||length(w_note)||', mesi possesso: '||w_mp||', mesi 1 sem: '||w_mp_1sem||', mesi escl: '||w_me);
     dbms_output.put_line('Note dopo: '||length(w_NOTE ||
                                   'modifica mesi e flag possesso per nota ' ||
                                   A_DOCUMENTO_ID || '-' ||
                                   REC_VARI.NUMERONOTA));
  end if; */
                  /*if w_cod_fiscale = '03690741206' then
                     dbms_output.put_line('Cod.fiscalev (update): '||w_cod_fiscale);
                     dbms_output.put_line('Mesi Possesso: '||w_mesi_possesso);
                     dbms_output.put_line('Mesi Possesso 1 sem.: '||w_mesi_possesso_1sem);
                     dbms_output.put_line('Da Mese Possesso: '||w_da_mese_possesso);
                     dbms_output.put_line('Mesi Esclusione: '||w_mesi_esclusione);
                     dbms_output.put_line('Flag Possesso: '||w_flag_possesso);
                     dbms_output.put_line('Flag Esclusione: '||w_flag_esclusione);
                     dbms_output.put_line('Flag Ab.Princ.: '||w_flag_ab_principale);
                  end if;*/
                begin
                   IF W_TITOLO != 'C' THEN

                      UPDATE OGGETTI_CONTRIBUENTE OGCO
                         SET FLAG_POSSESSO      = NULL,
                             FLAG_ESCLUSIONE    = NULL,
                             -- (VD - 12/02/2021): Modificata attribuzione mesi per dichiarazioni non presentate in ordine
                             MESI_POSSESSO      = greatest(0,MESI_POSSESSO - W_MESI_POSSESSO),
                             MESI_ESCLUSIONE    = decode(greatest(0,MESI_POSSESSO - W_MESI_POSSESSO),
                                                         0, null,
                                                         greatest(0,MESI_ESCLUSIONE -W_MESI_ESCLUSIONE)),

                             --MESI_POSSESSO_1SEM = MESI_POSSESSO -
                             --                     DECODE(SIGN(W_MESI_POSSESSO - 6),
                             --                            -1,
                             --                            0,
                             --                            W_MESI_POSSESSO - 6),
                             --
                             -- (VD - 22/08/2017): utilizzata variabile mesi primo
                             --                    semestre per ricalcolare il
                             --                    periodo del primo oggetto emesso
                             --                    nel caso in cui lo stesso oggetto
                             --                    sia presente 2 volte per lo stesso
                             --                    contribuente
                             MESI_POSSESSO_1SEM = decode(greatest(0,MESI_POSSESSO - W_MESI_POSSESSO),
                                                         0, 0,
                                                         greatest(0,MESI_POSSESSO_1SEM - W_MESI_POSSESSO_1SEM)),
                             NOTE               = NOTE ||
                                                  'modifica mesi e flag possesso per nota ' ||
                                                  A_DOCUMENTO_ID || '-' ||
                                                  REC_VARI.NUMERONOTA
                       WHERE OGCO.COD_FISCALE = W_COD_FISCALE
                         AND OGCO.OGGETTO_PRATICA = W_OGPR_PREC;
                   ELSE
                      UPDATE OGGETTI_CONTRIBUENTE OGCO
                         SET FLAG_POSSESSO      = NULL,
                             FLAG_ESCLUSIONE    = NULL,
                             MESI_POSSESSO      = 0,
                             MESI_ESCLUSIONE    = 0,
                             MESI_POSSESSO_1SEM = 0,
                             NOTE               = NOTE ||
                                                  'modifica mesi e flag possesso per nota ' ||
                                                  A_DOCUMENTO_ID || '-' ||
                                                  REC_VARI.NUMERONOTA
                       WHERE OGCO.COD_FISCALE = W_COD_FISCALE
                         AND OGCO.OGGETTO_PRATICA = W_OGPR_PREC;
                   END IF;
                EXCEPTION
                  WHEN OTHERS THEN
                    SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                    W_ERRORE := 'Update OGCO, annullamento denuncia prec. ' ||
                                    F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                       W_ANNO_DENUNCIA) || '/' ||
                                    W_COD_FISCALE|| ' (' ||
                                    SQL_ERRM || ')';
                    RAISE ERRORE;
                END;
  --if REC_VARI.NUMERONOTA = 6250 then
  --   dbms_output.put_line('Update OGPR ogpr_prec: '||w_ogpr_prec);
  --end if;
                   UPDATE OGGETTI_PRATICA OGPR
                      SET NOTE = NOTE || 'modifica mesi e flag possesso per nota ' || A_DOCUMENTO_ID || '-' || REC_VARI.NUMERONOTA
                    WHERE OGPR.OGGETTO_PRATICA = W_OGPR_PREC;
              END IF;
                W_CLASSE := T_CLASSE(REC_TITO.REF_IMMOBILE);
                IF REC_TITO.TIPOLOGIAIMMOBILE = 'T' THEN
                  -- per decidere se è un Terreno o un Area Fabbricabile verifico
                  -- il tipo_oggetto dell'oggetto perchè sulla titolarità non c'è
                  -- differenza tra Terreni e Aree Fabbricabili
                  IF T_TIPO_OGGETTO(REC_TITO.REF_IMMOBILE) = 2 THEN
                    W_TIPO_OGGETTO := 2;
                  ELSE
                    W_TIPO_OGGETTO := 1;
                  END IF;
                ELSE
                  W_TIPO_OGGETTO := 3;
                END IF;
                W_VALORE          := F_VALORE_DA_RENDITA(T_RENDITA(REC_TITO.REF_IMMOBILE),
                                                         W_TIPO_OGGETTO,
                                                         W_ANNO_DENUNCIA,
                                                         W_CATEGORIA,
                                                         'N' -- Immobile
                                                         -- Storico
                                                         );
                W_OGGETTO_PRATICA := NULL;
                OGGETTI_PRATICA_NR(W_OGGETTO_PRATICA);
  --if REC_VARI.NUMERONOTA in (5666,6250) then
  --   dbms_output.put_line('Nota n.: '||REC_VARI.NUMERONOTA||' Inserimento OGPR: '||w_oggetto_pratica);
  --end if;
                BEGIN
                  INSERT INTO OGGETTI_PRATICA
                    (OGGETTO_PRATICA,
                     OGGETTO,
                     TIPO_OGGETTO,
                     PRATICA,
                     ANNO,
                     NUM_ORDINE,
                     CATEGORIA_CATASTO,
                     CLASSE_CATASTO,
                     VALORE,
                     FLAG_VALORE_RIVALUTATO,
                     TITOLO,
                     FONTE,
                     UTENTE,
                     DATA_VARIAZIONE,
                     NOTE)
                  VALUES
                    (W_OGGETTO_PRATICA,
                     W_OGGETTO,
                     W_TIPO_OGGETTO,
                     W_PRATICA,
                     W_ANNO_DENUNCIA,
                     TO_CHAR(W_NUM_ORDINE),
                     W_CATEGORIA,
                     W_CLASSE,
                     W_VALORE,
                     DECODE(SIGN(1996 - W_ANNO_DENUNCIA), -1, 'S', ''),
                     W_TITOLO,
                     A_FONTE,
                     A_UTENTE,
                     TRUNC(SYSDATE),
                     DECODE(W_FLAG_GRAFFATO,
                            NULL,
                            NULL,
                            DECODE(W_ID_IMMOBILE,
                                   NULL,
                                   'Oggetto graffato privo di identificativo catastale',
                                   NULL)));
                EXCEPTION
                  WHEN OTHERS THEN
                    SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                    W_ERRORE := 'Errore in inserimento oggetti_pratica ' ||
                                F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                   W_ANNO_DENUNCIA) || ' (' ||
                                SQL_ERRM || ')';
                    RAISE ERRORE;
                END;
                W_NUM_NUOVI_OGPR := W_NUM_NUOVI_OGPR + 1;
                W_NUM_ORDINE     := W_NUM_ORDINE + 1;
                -- Recupero Flag Abitazione Principale
                IF REC_TITO.TIPOLOGIAIMMOBILE = 'F' AND W_TITOLO = 'A' AND
                   SUBSTR(W_CATEGORIA, 1, 1) IN ('A', 'C') THEN
                  BEGIN
                    SELECT NVL(LPAD(OGGE.COD_VIA, 6, '0'), 'xxxxxx') ||
                           NVL(LPAD(OGGE.NUM_CIV, 6, '0'), 'xxxxxx')
                      INTO W_OGG_COD_VIA_NUM_CIV
                      FROM OGGETTI OGGE
                     WHERE OGGE.OGGETTO = T_OGGETTO(REC_TITO.REF_IMMOBILE);
                  EXCEPTION
                    WHEN OTHERS THEN
                      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                      W_ERRORE := 'Errore in recupero indirizzo oggetto ' ||
                                  TO_CHAR(T_OGGETTO(REC_TITO.REF_IMMOBILE)) ||
                                  F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                     W_ANNO_DENUNCIA) || ' (' ||
                                  SQL_ERRM || ')';
                      RAISE ERRORE;
                  END;
                  -- Recupero Indirizzo residenza
                  W_RES_COD_VIA_NUM_CIV := F_INDIRIZZO_NI_AL(W_NI,
                                                             TO_DATE('3112' ||
                                                                     TO_CHAR(W_ANNO_DENUNCIA),
                                                                     'ddmmyyyy'));
                  IF W_OGG_COD_VIA_NUM_CIV = W_RES_COD_VIA_NUM_CIV THEN
                    W_FLAG_AB_PRINCIPALE := 'S';
                    IF SUBSTR(W_CATEGORIA, 1, 1) = 'A' AND
                       NVL(W_PERC_POSSESSO, 0) = 100 THEN
                      W_DETRAZIONE := ROUND(W_DETRAZIONE_BASE / 12 *
                                            W_MESI_POSSESSO,
                                            2);
                    ELSE
                      W_DETRAZIONE := NULL;
                    END IF;
                  ELSE
                    W_FLAG_AB_PRINCIPALE := NULL;
                    W_DETRAZIONE         := NULL;
                  END IF;
                ELSE
                  W_FLAG_AB_PRINCIPALE := NULL;
                  W_DETRAZIONE         := NULL;
                END IF;
                -- Gestione Eccezione di tipo E (Esclusione)
                IF NVL(W_ECCEZIONE_CACA, W_ECCEZIONE_CODI) = 'E' THEN
                  W_MESI_ESCLUSIONE    := W_MESI_POSSESSO;
                  W_FLAG_ESCLUSIONE    := W_FLAG_POSSESSO;
                  W_MESI_POSSESSO_1SEM := NULL;
                ELSE
                  W_MESI_ESCLUSIONE := NULL;
                  W_FLAG_ESCLUSIONE := NULL;
                END IF;
  --if REC_VARI.NUMERONOTA in (5666, 6250) then
  --   dbms_output.put_line('Nota n.: '||REC_VARI.NUMERONOTA||' Inserimento OGCO: '||w_oggetto_pratica);
  --   dbms_output.put_line('Mesi possesso: '||w_mesi_possesso||', mesi possesso 1 sem.: '||w_mesi_possesso_1sem||', cod_fiscale: '||w_cod_fiscale);
  --end if;
                  /*if w_cod_fiscale = 'RSLSNO93R68F205G' then
                     dbms_output.put_line('Cod.fiscalev (2): '||w_cod_fiscale);
                     dbms_output.put_line('Mesi Possesso: '||w_mesi_possesso);
                     dbms_output.put_line('Mesi Possesso 1 sem.: '||w_mesi_possesso_1sem);
                     dbms_output.put_line('Da Mese Possesso: '||w_da_mese_possesso);
                     dbms_output.put_line('Mesi Esclusione: '||w_mesi_esclusione);
                     dbms_output.put_line('Flag Possesso: '||w_flag_possesso);
                     dbms_output.put_line('Flag Esclusione: '||w_flag_esclusione);
                     dbms_output.put_line('Flag Ab.Princ.: '||w_flag_ab_principale);
                  end if;*/
                BEGIN
                  INSERT INTO OGGETTI_CONTRIBUENTE
                    (COD_FISCALE,
                     OGGETTO_PRATICA,
                     ANNO,
                     TIPO_RAPPORTO,
                     PERC_POSSESSO,
                     MESI_POSSESSO,
                     MESI_POSSESSO_1SEM,
                     DA_MESE_POSSESSO,
                     MESI_ESCLUSIONE,
                     FLAG_POSSESSO,
                     FLAG_ESCLUSIONE,
                     FLAG_AB_PRINCIPALE,
                     DETRAZIONE,
                     UTENTE,
                     DATA_VARIAZIONE,
                     PERC_DETRAZIONE)
                  VALUES
                    (W_COD_FISCALE,
                     W_OGGETTO_PRATICA,
                     W_ANNO_DENUNCIA,
                     'D',
                     W_PERC_POSSESSO,
                     W_MESI_POSSESSO,
                     W_MESI_POSSESSO_1SEM,
                     W_DA_MESE_POSSESSO,
                     W_MESI_ESCLUSIONE,
                     W_FLAG_POSSESSO,
                     W_FLAG_ESCLUSIONE,
                     W_FLAG_AB_PRINCIPALE,
                     W_DETRAZIONE,
                     A_UTENTE,
                     TRUNC(SYSDATE),
                     DECODE(W_DETRAZIONE, NULL, NULL, 100));
                EXCEPTION
                  WHEN OTHERS THEN
                    SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                    W_ERRORE := 'Insert OGGETTI_CONTRIBUENTE ' ||
                                F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                   W_ANNO_DENUNCIA) ||
                                W_COD_FISCALE ||
                                ' (' || SQL_ERRM || ')';
                    RAISE ERRORE;
                END;
                -- Gestione Deog Alog
                W_DEOG_ALOG_INS := 0;
                INSERISCI_DEOG_ALOG(W_COD_FISCALE,
                                    W_OGGETTO_PRATICA,
                                    W_ANNO_DENUNCIA,
                                    W_CF_PREC,
                                    W_OGPR_PREC,
                                    W_DEOG_ALOG_INS);
                -- Nel caso di presenza di deog o alog vengono messi a null sia
                -- il flag_ab_princiaple che la detrazione
                IF W_DEOG_ALOG_INS > 0 THEN
                  BEGIN
                    UPDATE OGGETTI_CONTRIBUENTE
                       SET FLAG_AB_PRINCIPALE = NULL, DETRAZIONE = NULL
                     WHERE COD_FISCALE = W_COD_FISCALE
                       AND OGGETTO_PRATICA = W_OGGETTO_PRATICA;
                  EXCEPTION
                    WHEN OTHERS THEN
                      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                      W_ERRORE := 'Errore update ogco, annullamento ab_principale e detrazione ' ||
                                  F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                     W_ANNO_DENUNCIA) || '/' ||
                                  W_COD_FISCALE|| ' (' ||
                                  SQL_ERRM || ')';
                      RAISE ERRORE;
                  END;
                END IF;
                BEGIN
                  INSERT INTO ATTRIBUTI_OGCO
                    (COD_FISCALE,
                     OGGETTO_PRATICA,
                     DOCUMENTO_ID,
                     NUMERO_NOTA,
                     ESITO_NOTA,
                     DATA_REG_ATTI,
                     NUMERO_REPERTORIO,
                     COD_ATTO,
                     ROGANTE,
                     COD_FISCALE_ROGANTE,
                     SEDE_ROGANTE,
                     COD_DIRITTO,
                     REGIME,
                     COD_ESITO,
                     DATA_VALIDITA_ATTO,
                     UTENTE,
                     DATA_VARIAZIONE,
                     NOTE)
                  VALUES
                    (W_COD_FISCALE,
                     W_OGGETTO_PRATICA,
                     A_DOCUMENTO_ID,
                     REC_VARI.NUMERONOTA,
                     TO_NUMBER(REC_VARI.ESITONOTA),
                     TO_DATE(REC_VARI.DATAREGISTRAZIONEINATTI, 'ddmmyyyy'),
                     REC_VARI.NUMEROREPERTORIO,
                     TO_NUMBER(REC_VARI.CODICEATTO),
                     REC_VARI.ROGANTE_COGNOMENOME,
                     REC_VARI.ROGANTE_CODICEFISCALE,
                     REC_VARI.ROGANTE_SEDE,
                     W_CODICE_DIRITTO,
                     trim(W_REGIME),
                     T_COD_ESITO(REC_TITO.REF_IMMOBILE),
                     TO_DATE(REC_VARI.DATAVALIDITAATTO, 'ddmmyyyy'),
                     A_UTENTE,
                     TRUNC(SYSDATE),
                     '');
                EXCEPTION
                  WHEN OTHERS THEN
                    SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
                    W_ERRORE := 'Errore in inserim. attributi_ogco ' ||
                                F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO,
                                                   W_ANNO_DENUNCIA) || ' (' ||
                                SQL_ERRM || ')';
                    RAISE ERRORE;
                END;
              END IF;
            END IF;
          END IF;
          -- Anomalia sulla Pratica w_anomalia_prat = 'N' and w_da_trattare = 'S'
        END LOOP;
      END IF; -- Anomalia Caricamento  Contribuente
      -- cancellazione del contribuente e/o soggetto
      -- nel caso che la pratica non sia stata inserita
      -- e solo se è un nuovo soggetto/contribuente
      IF W_CANCELLA_CONTRIBUENTE = 'S' THEN
        BEGIN
          DELETE CONTRIBUENTI WHERE NI = W_NI;
        EXCEPTION
          WHEN OTHERS THEN
            SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
            W_ERRORE := 'Errore in cancellazione contribuente ni:' ||
                        TO_CHAR(W_NI) || ' (' || SQL_ERRM || ')';
            RAISE ERRORE;
        END;
        W_NUM_NUOVI_CONTRIBUENTI := W_NUM_NUOVI_CONTRIBUENTI - 1;
        IF W_CANCELLA_SOGGETTO = 'S' THEN
          BEGIN
            DELETE SOGGETTI WHERE NI = W_NI;
          EXCEPTION
            WHEN OTHERS THEN
              SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
              W_ERRORE := 'Errore in cancellazione soggetto ni:' ||
                          TO_CHAR(W_NI) || ' (' || SQL_ERRM || ')';
              RAISE ERRORE;
          END;
          W_NUM_NUOVI_SOGGETTI := W_NUM_NUOVI_SOGGETTI - 1;
        END IF;
      END IF;
    END LOOP;
  END ELABORA_SOGGETTI;
  /********************************************************
  MAIN
  ********************************************************/
BEGIN
  -- DM 20160518: Si verifica che il documento che si vuole elaborare non sia precedente all'ultimo elaborato.
  IF (F_CARICA_DIC_NOTAI_VERIFICA(A_DOCUMENTO_ID) = 2) THEN
    W_ERRORE := 'L''ultimo mui elaborato è più recente dell''attuale.';
    RAISE ERRORE;
  END IF;
  -- Pulizia tabella di servizio
  BEGIN
    DELETE FROM WRK_GRAFFATI_CONT WHERE DOCUMENTO_ID = A_DOCUMENTO_ID;
    DELETE FROM WRK_GRAFFATI WHERE DOCUMENTO_ID = A_DOCUMENTO_ID;
  END;
  -- Estrazione BLOB
  BEGIN
    SELECT CONTENUTO
      INTO W_DOCUMENTO_BLOB
      FROM DOCUMENTI_CARICATI DOCA
     WHERE DOCA.DOCUMENTO_ID = A_DOCUMENTO_ID;
  END;
  -- Verifica dimensione file caricato
  W_NUMBER_TEMP := DBMS_LOB.GETLENGTH(W_DOCUMENTO_BLOB);
  IF NVL(W_NUMBER_TEMP, 0) = 0 THEN
    W_ERRORE := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
    RAISE ERRORE;
  END IF;
  -- Trasformazione in CLOB
  BEGIN
    DBMS_LOB.CREATETEMPORARY(LOB_LOC => W_DOCUMENTO_CLOB,
                             CACHE   => TRUE,
                             DUR     => DBMS_LOB.SESSION);
    DBMS_LOB.CONVERTTOCLOB(W_DOCUMENTO_CLOB,
                           W_DOCUMENTO_BLOB,
                           AMOUNT,
                           DEST_OFFSET,
                           SRC_OFFSET,
                           BLOB_CSID,
                           LANG_CTX,
                           WARNING);
  EXCEPTION
    WHEN OTHERS THEN
      W_ERRORE := 'Errore in trasformazione Blob in Clob  (' || SQLERRM || ')';
      RAISE ERRORE;
  END;
  -- Eliminazione del prefisso XML <?xml version="1.0" encoding="ISO-8859-1"?>
  W_DOCUMENTO_CLOB := SUBSTR(W_DOCUMENTO_CLOB, 44);
  -- Verifica caratteri errati
  W_TROVA := NVL(DBMS_LOB.INSTR(W_DOCUMENTO_CLOB, 'Ã'), -9999);
  IF W_TROVA > 0 THEN
    W_CARATTERI_ERRATI := DBMS_LOB.SUBSTR(W_DOCUMENTO_CLOB,
                                          60,
                                          W_TROVA - 20);
    W_ERRORE           := 'Attenzione caratteri errati nel file:' ||
                          CHR(013) || W_CARATTERI_ERRATI;
    RAISE ERRORE;
  END IF;
  IF W_COMMENTI > 0 THEN
    DBMS_OUTPUT.PUT_LINE('---- Inizio ----');
  END IF;
  FOR REC_VARI IN SEL_VARI(W_DOCUMENTO_CLOB) LOOP
    IF W_COMMENTI > 0 THEN
      DBMS_OUTPUT.PUT_LINE('--- Variazione n: ' ||
                           TO_CHAR(NVL(REC_VARI.NUMERONOTA, 0)));
    END IF;
    W_TIPO_NOTA     := REC_VARI.TIPONOTA;
    W_ANNO_DENUNCIA := TO_NUMBER(TO_CHAR(TO_DATE(REC_VARI.DATAVALIDITAATTO,
                                                 'ddmmyyyy'),
                                         'yyyy'));
    BEGIN
      SELECT DETRAZIONE_BASE
        INTO W_DETRAZIONE_BASE
        FROM DETRAZIONI
       WHERE ANNO = W_ANNO_DENUNCIA
         AND TIPO_TRIBUTO = A_TIPO_TRIBUTO;
    EXCEPTION
      WHEN OTHERS THEN
        W_ERRORE := 'Errore in estrazione detrazione base  (' || SQLERRM || ')' ||
                    'Aggiornare il Dizionario Detrazioni per il tipo tributo ' ||
                    F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO, W_ANNO_DENUNCIA) ||
                    ' per l''anno ' || W_ANNO_DENUNCIA;
        RAISE ERRORE;
    END;
    --------------------------------------------------------------------------
    -- Inserimento Immobili --------------------------------------------------
    --------------------------------------------------------------------------
    ELABORA_IMMOBILI(REC_VARI.IMMOBILI);
    --------------------------------------------------------------------------
    -- Gestione Soggetti -----------------------------------------------------
    --------------------------------------------------------------------------
    ELABORA_SOGGETTI(REC_VARI.SOGGETTI, REC_VARI);
  END LOOP;
  --
  -- (VD - 11/06/2015): a fine elaborazione, se sono stati cessati degli
  --                    oggetti graffati, si cessano anche tutte le graffature
  --                    per lo stesso contribuente
  --
  FOR OGG_CESS IN (SELECT OGGE.ID_IMMOBILE,
                          PRTR.COD_FISCALE,
                          PRTR.PRATICA,
                          PRTR.ANNO,
                          (SELECT MAX(NUM_ORDINE)
                             FROM PRATICHE_TRIBUTO
                            WHERE PRATICA = PRTR.PRATICA) NUM_ORDINE,
                          OGPR.OGGETTO,
                          OGPR.OGGETTO_PRATICA,
                          OGCO.PERC_POSSESSO,
                          OGCO.MESI_POSSESSO,
                          OGCO.MESI_POSSESSO_1SEM,
                          OGCO.DA_MESE_POSSESSO,
                          OGCO.MESI_ESCLUSIONE,
                          OGCO.FLAG_POSSESSO,
                          OGCO.FLAG_ESCLUSIONE,
                          OGCO.FLAG_AB_PRINCIPALE,
                          OGCO.DETRAZIONE,
                          OGCO.PERC_DETRAZIONE
                     FROM PRATICHE_TRIBUTO     PRTR,
                          OGGETTI_PRATICA      OGPR,
                          OGGETTI_CONTRIBUENTE OGCO,
                          OGGETTI              OGGE
                    WHERE OGPR.UTENTE = A_UTENTE
                      AND OGPR.FONTE = A_FONTE
                      AND PRTR.TIPO_TRIBUTO = A_TIPO_TRIBUTO
                      AND OGPR.DATA_VARIAZIONE = TRUNC(SYSDATE)
                      AND OGPR.TITOLO = 'C'
                      AND OGPR.PRATICA = PRTR.PRATICA
                      AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
                      AND OGCO.COD_FISCALE = PRTR.COD_FISCALE
                      AND OGPR.OGGETTO = OGGE.OGGETTO
                      AND OGGE.ID_IMMOBILE IS NOT NULL
                    ORDER BY 1, 2) LOOP
    W_NUM_ORDINE := OGG_CESS.NUM_ORDINE;
    FOR GRAF_CESS IN (SELECT OGPR.OGGETTO,
                             OGPR.TIPO_OGGETTO,
                             OGPR.CATEGORIA_CATASTO,
                             OGPR.CLASSE_CATASTO,
                             OGPR.VALORE
                        FROM PRATICHE_TRIBUTO     PRTR,
                             OGGETTI_PRATICA      OGPR,
                             OGGETTI_CONTRIBUENTE OGCO,
                             OGGETTI              OGGE
                       WHERE OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA
                         AND OGPR.PRATICA = PRTR.PRATICA
                         AND OGCO.COD_FISCALE = OGG_CESS.COD_FISCALE
                         AND OGGE.ID_IMMOBILE = OGG_CESS.ID_IMMOBILE
                         AND OGPR.OGGETTO = OGGE.OGGETTO
                         AND OGPR.OGGETTO <> OGG_CESS.OGGETTO
                         AND OGCO.FLAG_POSSESSO = 'S'
                         AND PRTR.TIPO_TRIBUTO || '' = A_TIPO_TRIBUTO
                         AND (OGCO.ANNO || OGCO.TIPO_RAPPORTO || 'S') =
                             (SELECT MAX(OGCO_SUB.ANNO ||
                                         OGCO_SUB.TIPO_RAPPORTO ||
                                         OGCO_SUB.FLAG_POSSESSO)
                                FROM PRATICHE_TRIBUTO     PRTR_SUB,
                                     OGGETTI_PRATICA      OGPR_SUB,
                                     OGGETTI_CONTRIBUENTE OGCO_SUB
                               WHERE PRTR_SUB.TIPO_TRIBUTO || '' =
                                     A_TIPO_TRIBUTO
                                 AND ((PRTR_SUB.TIPO_PRATICA || '' = 'D' AND
                                     PRTR_SUB.DATA_NOTIFICA IS NULL) OR
                                     (PRTR_SUB.TIPO_PRATICA || '' = 'A' AND
                                     PRTR_SUB.DATA_NOTIFICA IS NOT NULL AND
                                     NVL(PRTR_SUB.STATO_ACCERTAMENTO, 'D') = 'D' AND
                                     NVL(PRTR_SUB.FLAG_DENUNCIA, ' ') = 'S' AND
                                     PRTR_SUB.ANNO <= OGG_CESS.ANNO))
                                 AND PRTR_SUB.PRATICA = OGPR_SUB.PRATICA
                                 AND OGCO_SUB.ANNO <= OGG_CESS.ANNO
                                 AND OGCO_SUB.COD_FISCALE = OGCO.COD_FISCALE
                                 AND OGCO_SUB.OGGETTO_PRATICA =
                                     OGPR_SUB.OGGETTO_PRATICA
                                 AND OGPR_SUB.OGGETTO = OGPR.OGGETTO
                                 AND OGCO_SUB.TIPO_RAPPORTO IN
                                     ('C', 'D', 'E'))) LOOP
      W_NUM_ORDINE      := W_NUM_ORDINE + 1;
      W_OGGETTO_PRATICA := TO_NUMBER(NULL);
      OGGETTI_PRATICA_NR(W_OGGETTO_PRATICA);
      BEGIN
        INSERT INTO OGGETTI_PRATICA
          (OGGETTO_PRATICA,
           OGGETTO,
           TIPO_OGGETTO,
           PRATICA,
           ANNO,
           NUM_ORDINE,
           CATEGORIA_CATASTO,
           CLASSE_CATASTO,
           VALORE,
           FLAG_VALORE_RIVALUTATO,
           TITOLO,
           FONTE,
           UTENTE,
           DATA_VARIAZIONE,
           NOTE)
        VALUES
          (W_OGGETTO_PRATICA,
           GRAF_CESS.OGGETTO,
           GRAF_CESS.TIPO_OGGETTO,
           OGG_CESS.PRATICA,
           OGG_CESS.ANNO,
           TO_CHAR(W_NUM_ORDINE),
           GRAF_CESS.CATEGORIA_CATASTO,
           LTRIM(GRAF_CESS.CLASSE_CATASTO, '0'),
           GRAF_CESS.VALORE,
           DECODE(SIGN(1996 - OGG_CESS.ANNO), -1, 'S', ''),
           'C',
           A_FONTE,
           A_UTENTE,
           TRUNC(SYSDATE),
           'Notai - Cessazione oggetto graffato');
      EXCEPTION
        WHEN OTHERS THEN
          SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
          W_ERRORE := 'Errore in inserimento oggetti_pratica (cessazione)' ||
                      F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO, W_ANNO_DENUNCIA) || ' (' ||
                      SQL_ERRM || ')';
          RAISE ERRORE;
      END;
      --
      /*if w_cod_fiscale = 'RSLSNO93R68F205G' then
         dbms_output.put_line('Cod.fiscalev (3): '||w_cod_fiscale);
         dbms_output.put_line('Mesi Possesso: '||w_mesi_possesso);
         dbms_output.put_line('Mesi Possesso 1 sem.: '||w_mesi_possesso_1sem);
         dbms_output.put_line('Da Mese Possesso: '||w_da_mese_possesso);
         dbms_output.put_line('Mesi Esclusione: '||w_mesi_esclusione);
         dbms_output.put_line('Flag Possesso: '||w_flag_possesso);
         dbms_output.put_line('Flag Esclusione: '||w_flag_esclusione);
         dbms_output.put_line('Flag Ab.Princ.: '||w_flag_ab_principale);
      end if;*/
      BEGIN
        INSERT INTO OGGETTI_CONTRIBUENTE
          (COD_FISCALE,
           OGGETTO_PRATICA,
           ANNO,
           TIPO_RAPPORTO,
           PERC_POSSESSO,
           MESI_POSSESSO,
           MESI_POSSESSO_1SEM,
           DA_MESE_POSSESSO,
           MESI_ESCLUSIONE,
           FLAG_POSSESSO,
           FLAG_ESCLUSIONE,
           FLAG_AB_PRINCIPALE,
           DETRAZIONE,
           UTENTE,
           DATA_VARIAZIONE,
           PERC_DETRAZIONE)
        VALUES
          (OGG_CESS.COD_FISCALE,
           W_OGGETTO_PRATICA,
           OGG_CESS.ANNO,
           'D',
           OGG_CESS.PERC_POSSESSO,
           OGG_CESS.MESI_POSSESSO,
           OGG_CESS.MESI_POSSESSO_1SEM,
           OGG_CESS.DA_MESE_POSSESSO,
           OGG_CESS.MESI_ESCLUSIONE,
           OGG_CESS.FLAG_POSSESSO,
           OGG_CESS.FLAG_ESCLUSIONE,
           OGG_CESS.FLAG_AB_PRINCIPALE,
           OGG_CESS.DETRAZIONE,
           A_UTENTE,
           TRUNC(SYSDATE),
           OGG_CESS.PERC_DETRAZIONE);
      EXCEPTION
        WHEN OTHERS THEN
          SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
          W_ERRORE := 'Errore in inserim. oggetti_contribuente (cessazione)' ||
                      F_DESCRIZIONE_TITR(A_TIPO_TRIBUTO, W_ANNO_DENUNCIA) ||
                      W_COD_FISCALE ||
                      ' (' || SQL_ERRM || ')';
          RAISE ERRORE;
      END;
    END LOOP;
  END LOOP;
  --
  -- (VD - 11/06/2015): a fine elaborazione, si eliminano dalla tabella OGGETTI
  --                    tutti gli oggetti inseriti e non referenziati in alcuna
  --                    pratica
  --
  BEGIN
    DELETE FROM OGGETTI OGGE
     WHERE OGGE.FONTE = A_FONTE
       AND OGGE.UTENTE = A_UTENTE
       AND OGGE.DATA_VARIAZIONE = TRUNC(SYSDATE)
       AND OGGE.ID_IMMOBILE IS NOT NULL
       AND NOT EXISTS (SELECT 'x'
              FROM OGGETTI_PRATICA OGPR
             WHERE OGPR.OGGETTO = OGGE.OGGETTO);
    W_NUM_OGGETTI_ELIM  := SQL%ROWCOUNT;
    W_NUM_NUOVI_OGGETTI := W_NUM_NUOVI_OGGETTI - NVL(W_NUM_OGGETTI_ELIM, 0);
  EXCEPTION
    WHEN OTHERS THEN
      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
      W_ERRORE := 'Errore in Eliminazione oggetti non referenziati ' || ' (' ||
                  SQL_ERRM || ')';
      RAISE ERRORE;
  END;
  --
  -- (VD - 10/01/2020): a fine elaborazione, si archiviano tutte le
  --                    denunce inserite
  -- (VD - 11/02/2020): aggiunto test su indice array per non lanciare
  --                    l'archiviazione se l'array e' vuoto
  --
  IF W_IND > 0 THEN
     FOR W_IND IN T_PRATICA.FIRST .. T_PRATICA.LAST
     LOOP
       IF T_PRATICA (W_IND) IS NOT NULL THEN
          ARCHIVIA_DENUNCE('','',T_PRATICA(W_IND));
       END IF;
     END LOOP;
  END IF;
  BEGIN
    SELECT SUM(TO_NUMBER(EXISTSNODE(VALUE(TITOLARITA),
                                    '/Titolarita',
                                    'xmlns="http://www.agenziaterritorio.it/ICI.xsd"')))
      INTO W_NUM_TITOLARITA
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(W_DOCUMENTO_CLOB),
                                     '/DatiOut/DatiPresenti/Variazioni/Variazione/Soggetti/Soggetto/DatiTitolarita/Titolarita',
                                     'xmlns="http://www.agenziaterritorio.it/ICI.xsd"'))) TITOLARITA;
  EXCEPTION
    WHEN OTHERS THEN
      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
      W_ERRORE := 'Errore in Estrazione numero Titolarita ' || ' (' ||
                  SQL_ERRM || ')';
      RAISE ERRORE;
  END;
  BEGIN
    SELECT SUM(TO_NUMBER(EXISTSNODE(VALUE(TITOLARITA),
                                    '/Soggetto',
                                    'xmlns="http://www.agenziaterritorio.it/ICI.xsd"')))
      INTO W_NUM_SOGGETTI_XML
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(W_DOCUMENTO_CLOB),
                                     '/DatiOut/DatiPresenti/Variazioni/Variazione/Soggetti/Soggetto',
                                     'xmlns="http://www.agenziaterritorio.it/ICI.xsd"'))) TITOLARITA;
  EXCEPTION
    WHEN OTHERS THEN
      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
      W_ERRORE := 'Errore in Estrazione numero Soggetti XML ' || ' (' ||
                  SQL_ERRM || ')';
      RAISE ERRORE;
  END;
  -- Aggiornamento Stato
  BEGIN
      UPDATE documenti_caricati
         SET stato = 2,
             data_variazione = SYSDATE,
             utente = a_utente,
             note = decode(note,null,'',note||'    ')
                ||upper(a_tipo_tributo)||': '
                || 'ctr_denuncia: '
                || a_ctr_denuncia
                || ' - sezione_unica: '
                || a_sezione_unica
                || ' - fonte: '
                || TO_CHAR (a_fonte)
                || ' - pratiche: '
                || TO_CHAR (w_num_pratiche)
                || ' - nuovi oggetti: '
                || TO_CHAR (w_num_nuovi_oggetti)
                || ' - nuovi contribuenti: '
                || TO_CHAR (w_num_nuovi_contribuenti)
                || ' - nuovi soggetti: '
                || TO_CHAR (w_num_nuovi_soggetti)
                || ' - titolarita: '
                || TO_CHAR (w_num_nuovi_ogpr)
                || ' su '
                || TO_CHAR (w_num_titolarita)
                || ' - soggetti: '
                || TO_CHAR (w_num_nuovi_ogpr)
                || ' su '
                || TO_CHAR (w_num_titolarita)
       WHERE documento_id = a_documento_id;
  EXCEPTION
    WHEN OTHERS THEN
      SQL_ERRM := SUBSTR(SQLERRM, 1, 1000);
      W_ERRORE := 'Errore in Aggiornamneto Dati del documento ' || ' (' ||
                  SQL_ERRM || ')';
      RAISE ERRORE;
  END;
   a_messaggio :=
        upper(a_tipo_tributo)||': '||chr(10)||chr(13)
      ||'Inserite '
      || TO_CHAR (w_num_pratiche)
      || ' pratiche '
      || CHR (13)
      || 'Inseriti '
      || TO_CHAR (w_num_nuovi_oggetti)
      || ' nuovi oggetti'
      || CHR (13)
      || 'Inseriti '
      || TO_CHAR (w_num_nuovi_contribuenti)
      || ' nuovi contribuenti'
      || CHR (13)
      || 'Inseriti '
      || TO_CHAR (w_num_nuovi_soggetti)
      || ' nuovi soggetti'
      || CHR (13)
      || 'Trattati '
      || TO_CHAR (w_num_soggetti)
      || ' Soggetti su '
      || TO_CHAR (w_num_soggetti_xml)
      || ' Presenti'
      || CHR (13)
      || 'Trattate '
      || TO_CHAR (w_num_nuovi_ogpr)
      || ' Titolarità su '
      || TO_CHAR (w_num_titolarita)
      || ' Presenti'
      || CHR (13)
      || 'Titolarità senza Acquisizione e Cessione: '
      || TO_CHAR (w_num_no_acq_ces)
      || CHR (13)
      || 'Oggetti Anomali inseriti: '
      || TO_CHAR (w_num_oggetti_anomali);
EXCEPTION
  WHEN ERRORE THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999, NVL(W_ERRORE, 'vuoto'));
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999, W_COD_FISCALE||' - '||SUBSTR(SQLERRM, 1, 200));
END;
/* End Procedure: CARICA_DIC_NOTAI_TITR */
/

