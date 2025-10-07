--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_dovuto_versato stripComments:false runOnChange:true 
 
create or replace function F_WEB_DOVUTO_VERSATO
(A_TITR         IN VARCHAR2,
 A_ANNO_RIF     IN NUMBER,
 A_DIC_DA_ANNO  IN NUMBER,
 A_TRIBUTO      IN NUMBER,
 A_SCF          IN VARCHAR2,
 A_SNOME        IN VARCHAR2,
 A_TIPO_IMPOSTA IN NUMBER,
 A_SIMP_DA      NUMBER,
 A_SIMP_A       NUMBER)
  RETURN SYS_REFCURSOR AS
  MY_CURSOR SYS_REFCURSOR;
BEGIN
  OPEN MY_CURSOR FOR
    SELECT CONT.COD_FISCALE,
           CONT.NI,
           sogg.tipo,
           NVL(MAX(VERS.S_VERS), 0) +
           F_IMPORTO_VERS_RAVV(CONT.COD_FISCALE, A_TITR, A_ANNO_RIF, 'U') VERSATO,
           MAX(TARD.S_TARD_VERS) TARDIVO,
           MAX(TRANSLATE(SOGG.COGNOME_NOME, '/', ' ')) COGN_NOM,
           NVL(F_DOVUTO(CONT.NI,
                        A_ANNO_RIF,
                        A_TITR,
                        A_DIC_DA_ANNO,
                        A_TRIBUTO,
                        'D',
                        NULL),
               0) DOVUTO,
           ROUND(NVL(F_DOVUTO(CONT.NI,
                              A_ANNO_RIF,
                              A_TITR,
                              A_DIC_DA_ANNO,
                              A_TRIBUTO,
                              'D',
                              NULL),
                     0)) DOVUTO_ARR,
           NVL(F_DOVUTO(CONT.NI,
                        A_ANNO_RIF,
                        A_TITR,
                        A_DIC_DA_ANNO,
                        A_TRIBUTO,
                        'DR',
                        NULL),
               0) DOVUTO_ARR_UTE,
           OGIM.ANNO,
           MAX(SOGG.DATA_NAS) DATA_NASC,
           MAX(TO_NUMBER(A_DIC_DA_ANNO)) DIC_DA_ANNO,
           MAX(OGPR_PREC.X2) DIC_PREC,
           MAX(LIQ_CONT.X) LIQ_CONT,
           MAX(ACC_CONT.X) ACC_CONT,
           UPPER(trim(SOGG.COGNOME)) COGNOME,
           UPPER(trim(SOGG.NOME)) NOME,
           MAX(TITR.DESCRIZIONE) DES_TIPO_TRIBUTO,
           PRTR.TIPO_TRIBUTO,
           MAX(DECODE(NVL(OGIM.TIPO_RAPPORTO, 'D'), 'A', 'X')) OCCUPANTE,
           MAX(DECODE(NVL(OGIM.TIPO_RAPPORTO, 'D'), 'D', 'X')) PROPRIETARIO,
           MAX(NVL(SOGG.STATO, 0)) STATO_SOGG,
           MAX(F_DESCRIZIONE_TITR(PRTR.TIPO_TRIBUTO, A_ANNO_RIF) ||
               ' - Anno ' || A_ANNO_RIF ||
               DECODE(A_DIC_DA_ANNO,
                      0,
                      '',
                      CHR(10) || ' - Dichiarazioni da Anno: ' ||
                      A_DIC_DA_ANNO)) DESCR_TRIBUTO
      FROM (SELECT NVL(SUM(VERSAMENTI.IMPORTO_VERSATO), 0) S_VERS,
                   VERSAMENTI.COD_FISCALE COFI,
                   MAX(VERSAMENTI.ANNO) ANNO
              FROM VERSAMENTI, PRATICHE_TRIBUTO
             WHERE VERSAMENTI.ANNO = A_ANNO_RIF
               AND VERSAMENTI.TIPO_TRIBUTO || '' = A_TITR
               AND VERSAMENTI.COD_FISCALE LIKE A_SCF
               AND PRATICHE_TRIBUTO.PRATICA(+) = VERSAMENTI.PRATICA
               AND (VERSAMENTI.PRATICA IS NULL OR
                   PRATICHE_TRIBUTO.TIPO_PRATICA = 'D')
             GROUP BY VERSAMENTI.COD_FISCALE) VERS,
           (SELECT NVL(SUM(VERSAMENTI.IMPORTO_VERSATO), 0) S_TARD_VERS,
                   VERSAMENTI.COD_FISCALE COFI,
                   MAX(VERSAMENTI.ANNO) ANNO
              FROM VERSAMENTI
             WHERE VERSAMENTI.ANNO = A_ANNO_RIF
               AND VERSAMENTI.TIPO_TRIBUTO || '' = A_TITR
               AND VERSAMENTI.COD_FISCALE LIKE A_SCF
                  /*and versamenti.tipo_tributo in ('ICP', 'TARSU', 'TOSAP', 'ICI') */
               AND VERSAMENTI.DATA_PAGAMENTO >
                   F_SCADENZA(VERSAMENTI.ANNO,
                              VERSAMENTI.TIPO_TRIBUTO,
                              VERSAMENTI.TIPO_VERSAMENTO,
                              VERSAMENTI.COD_FISCALE,
                              VERSAMENTI.RATA)
               AND VERSAMENTI.PRATICA IS NULL
             GROUP BY VERSAMENTI.COD_FISCALE) TARD,
           (SELECT DISTINCT 'x1' X, PRTR1.COD_FISCALE CF
              FROM OGGETTI_PRATICA  OGPR1,
                   PRATICHE_TRIBUTO PRTR1,
                   RAPPORTI_TRIBUTO RATR1
             WHERE PRTR1.PRATICA = OGPR1.PRATICA
               AND PRTR1.ANNO = A_ANNO_RIF
               AND PRTR1.TIPO_PRATICA = 'L'
               AND NVL(PRTR1.STATO_ACCERTAMENTO, 'D') = 'D'
               AND PRTR1.TIPO_TRIBUTO || '' = A_TITR
               AND PRTR1.PRATICA = RATR1.PRATICA
               AND RATR1.COD_FISCALE LIKE A_SCF) LIQ_CONT,
           (SELECT DISTINCT 'x2' X2, PRTR2.COD_FISCALE CF
              FROM OGGETTI_PRATICA  OGPR2,
                   PRATICHE_TRIBUTO PRTR2,
                   RAPPORTI_TRIBUTO RATR2
             WHERE PRTR2.PRATICA = OGPR2.PRATICA
               AND PRTR2.ANNO < A_DIC_DA_ANNO
               AND PRTR2.TIPO_PRATICA = 'D'
               AND PRTR2.TIPO_TRIBUTO || '' = A_TITR
               AND PRTR2.PRATICA = RATR2.PRATICA
               AND RATR2.COD_FISCALE LIKE A_SCF) OGPR_PREC,
           (SELECT DISTINCT 'x3' X, PRTR1.COD_FISCALE CF
              FROM OGGETTI_PRATICA  OGPR1,
                   PRATICHE_TRIBUTO PRTR1,
                   RAPPORTI_TRIBUTO RATR1
             WHERE PRTR1.PRATICA = OGPR1.PRATICA
               AND PRTR1.ANNO = A_ANNO_RIF
               AND PRTR1.TIPO_PRATICA = 'A'
               AND NVL(PRTR1.STATO_ACCERTAMENTO, 'D') = 'D'
               AND PRTR1.TIPO_TRIBUTO || '' = A_TITR
               AND PRTR1.PRATICA = RATR1.PRATICA
               AND RATR1.COD_FISCALE LIKE A_SCF) ACC_CONT,
           PRATICHE_TRIBUTO PRTR,
           TIPI_TRIBUTO TITR,
           SOGGETTI SOGG,
           CONTRIBUENTI CONT,
           DATI_GENERALI DAGE,
           OGGETTI_PRATICA OGPR,
           OGGETTI_IMPOSTA OGIM
     WHERE LIQ_CONT.CF(+) = CONT.COD_FISCALE
       AND ACC_CONT.CF(+) = CONT.COD_FISCALE
       AND OGPR_PREC.CF(+) = CONT.COD_FISCALE
       AND PRTR.ANNO >= A_DIC_DA_ANNO
       AND OGIM.COD_FISCALE = VERS.COFI(+)
       AND OGIM.ANNO = VERS.ANNO(+)
       AND OGIM.COD_FISCALE = TARD.COFI(+)
       AND OGIM.ANNO = TARD.ANNO(+)
       AND (DECODE(PRTR.TIPO_PRATICA, 'D', PRTR.ANNO - 1, OGIM.ANNO) <>
            PRTR.ANNO)
       AND DECODE(PRTR.TIPO_PRATICA, 'D', 'S', PRTR.FLAG_DENUNCIA) = 'S'
       AND NVL(PRTR.STATO_ACCERTAMENTO, 'D') = 'D'
       AND PRTR.PRATICA = OGPR.PRATICA
       AND NVL(OGPR.TRIBUTO, 0) =
           DECODE(A_TRIBUTO, -1, NVL(OGPR.TRIBUTO, 0), A_TRIBUTO)
       AND OGIM.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA
       AND PRTR.TIPO_TRIBUTO || '' = A_TITR
       AND CONT.NI = SOGG.NI
       AND CONT.COD_FISCALE = OGIM.COD_FISCALE
       AND OGIM.FLAG_CALCOLO = 'S'
       AND OGIM.ANNO = A_ANNO_RIF
       AND OGIM.COD_FISCALE LIKE A_SCF
       AND SOGG.COGNOME_NOME_RIC LIKE A_SNOME
       AND TITR.TIPO_TRIBUTO = PRTR.TIPO_TRIBUTO
     GROUP BY CONT.COD_FISCALE,
              CONT.NI,
              OGIM.ANNO,
              sogg.tipo,
              DAGE.FASE_EURO,
              SOGG.COGNOME,
              SOGG.NOME,
              PRTR.TIPO_TRIBUTO
    HAVING(DECODE(A_TIPO_IMPOSTA, 1, NVL(F_DOVUTO(CONT.NI, A_ANNO_RIF, A_TITR, A_DIC_DA_ANNO, A_TRIBUTO, 'D', NULL), 0) -
                                     (MAX(NVL(VERS.S_VERS, 0)) + F_IMPORTO_VERS_RAVV(CONT.COD_FISCALE, A_TITR, A_ANNO_RIF, 'U')),
              2, ROUND(NVL(F_DOVUTO(CONT.NI, A_ANNO_RIF, A_TITR, A_DIC_DA_ANNO, A_TRIBUTO, 'D', NULL), 0), 0) -
                 (MAX(NVL(VERS.S_VERS, 0)) + F_IMPORTO_VERS_RAVV(CONT.COD_FISCALE, A_TITR, A_ANNO_RIF, 'U')),
              3, NVL(F_DOVUTO(CONT.NI, A_ANNO_RIF, A_TITR, A_DIC_DA_ANNO, A_TRIBUTO, 'DR', NULL), 0) -
                                          (MAX(NVL(VERS.S_VERS, 0)) + F_IMPORTO_VERS_RAVV(CONT.COD_FISCALE, A_TITR, A_ANNO_RIF, 'U'))))
        BETWEEN A_SIMP_DA AND A_SIMP_A
  UNION
    SELECT CONT.COD_FISCALE,
           CONT.NI,
           sogg.tipo,
           NVL(VERS.S_VERS, 0) +
           F_IMPORTO_VERS_RAVV(CONT.COD_FISCALE, A_TITR, A_ANNO_RIF, 'U') VERSATO,
           TARD.S_TARD_VERS TARDIVO,
           TRANSLATE(SOGG.COGNOME_NOME, '/', ' ') COGN_NOM,
           TO_NUMBER(NULL) DOVUTO,
           TO_NUMBER(NULL) DOVUTO_ARR,
           TO_NUMBER(NULL) DOVUTO_ARR_UTE,
           A_ANNO_RIF,
           SOGG.DATA_NAS DATA_NASC,
           TO_NUMBER(A_DIC_DA_ANNO) DIC_DA_ANNO,
           NULL DIC_PREC,
           NULL LIQ_CONT,
           NULL ACC_CONT,
           UPPER(REPLACE(SOGG.COGNOME, ' ', '')) COGNOME,
           UPPER(REPLACE(SOGG.NOME, ' ', '')) NOME,
           TITR.DESCRIZIONE DES_TIPO_TRIBUTO,
           A_TITR,
           NULL OCCUPANTE,
           NULL PROPRIETARIO,
           NVL(SOGG.STATO, 0) STATO_SOGG,
           F_DESCRIZIONE_TITR(A_TITR, A_ANNO_RIF) ||
               ' - Anno ' || A_ANNO_RIF ||
               DECODE(A_DIC_DA_ANNO,
                      0,
                      '',
                      CHR(10) || ' - Dichiarazioni da Anno: ' ||
                      A_DIC_DA_ANNO) DESCR_TRIBUTO
     FROM (SELECT NVL(SUM(VERSAMENTI.IMPORTO_VERSATO), 0) S_VERS,
                   VERSAMENTI.COD_FISCALE COFI,
                   MAX(VERSAMENTI.ANNO) ANNO
              FROM VERSAMENTI, PRATICHE_TRIBUTO
             WHERE VERSAMENTI.ANNO = A_ANNO_RIF
               AND VERSAMENTI.TIPO_TRIBUTO || '' = A_TITR
               AND VERSAMENTI.COD_FISCALE LIKE A_SCF
               AND PRATICHE_TRIBUTO.PRATICA(+) = VERSAMENTI.PRATICA
               AND (VERSAMENTI.PRATICA IS NULL OR
                   PRATICHE_TRIBUTO.TIPO_PRATICA = 'D')
             GROUP BY VERSAMENTI.COD_FISCALE) VERS,
           (SELECT NVL(SUM(VERSAMENTI.IMPORTO_VERSATO), 0) S_TARD_VERS,
                   VERSAMENTI.COD_FISCALE COFI,
                   MAX(VERSAMENTI.ANNO) ANNO
              FROM VERSAMENTI
             WHERE VERSAMENTI.ANNO = A_ANNO_RIF
               AND VERSAMENTI.TIPO_TRIBUTO || '' = A_TITR
               AND VERSAMENTI.COD_FISCALE LIKE A_SCF
                  /*and versamenti.tipo_tributo in ('ICP', 'TARSU', 'TOSAP', 'ICI') */
               AND VERSAMENTI.DATA_PAGAMENTO >
                   F_SCADENZA(VERSAMENTI.ANNO,
                              VERSAMENTI.TIPO_TRIBUTO,
                              VERSAMENTI.TIPO_VERSAMENTO,
                              VERSAMENTI.COD_FISCALE,
                              VERSAMENTI.RATA)
               AND VERSAMENTI.PRATICA IS NULL
             GROUP BY VERSAMENTI.COD_FISCALE) TARD,
          TIPI_TRIBUTO TITR,
          SOGGETTI SOGG,
          CONTRIBUENTI CONT
     WHERE CONT.COD_FISCALE = VERS.COFI(+)
       AND A_ANNO_RIF = VERS.ANNO(+)
       AND CONT.COD_FISCALE = TARD.COFI(+)
       AND A_ANNO_RIF = TARD.ANNO(+)
       AND TITR.TIPO_TRIBUTO = A_TITR
       AND CONT.NI = SOGG.NI
       AND CONT.COD_FISCALE LIKE A_SCF
       AND SOGG.COGNOME_NOME_RIC LIKE A_SNOME
       AND NVL(VERS.S_VERS, 0) <> 0
       AND NOT EXISTS (SELECT 'X' FROM OGGETTI_IMPOSTA OGIM
                        WHERE OGIM.TIPO_TRIBUTO = A_TITR
                          AND OGIM.FLAG_CALCOLO = 'S'
                          AND OGIM.ANNO = A_ANNO_RIF
                          AND OGIM.COD_FISCALE = CONT.COD_FISCALE)
       AND 0 - (NVL(VERS.S_VERS, 0) +
           F_IMPORTO_VERS_RAVV(CONT.COD_FISCALE, A_TITR, A_ANNO_RIF, 'U'))
            BETWEEN A_SIMP_DA AND A_SIMP_A
  ;
  RETURN MY_CURSOR;
END;
/* End Function: F_WEB_DOVUTO_VERSATO */
/
