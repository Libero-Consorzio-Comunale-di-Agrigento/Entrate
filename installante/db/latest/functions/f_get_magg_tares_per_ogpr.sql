--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_magg_tares_per_ogpr stripComments:false runOnChange:true 
 
create or replace function F_GET_MAGG_TARES_PER_OGPR
(  p_oggetto_pratica    NUMBER,
   p_anno               NUMBER,
   p_cf                 VARCHAR2)
   RETURN NUMBER
IS
   w_ret      NUMBER;
   w_sgravi   NUMBER;
-- 16/01/2015   Betta T. Corretta determinazione del ruolo
BEGIN
     /********************************************************
     Calcolo dei valori del dichiarato, utilizzata
     nella maschera dell'accertamento manuale.
     Il motivo per cui si fa questa funzione è che
     i valori vanno calcolati su tutte le dichiatazioni
     relative all'oggetto, mentre dati come la data decorrenza
     o la superficie si prendono solo dall'ultima dichiarazione.
     Questa funzione in particolare restituisce la maggiorazione tares,
     togliendo gli sgravi.
     ********************************************************/
     SELECT SUM (  NVL (OGIM_DIC.MAGGIORAZIONE_TARES, 0)) magg_tares
       INTO w_ret
       FROM CODICI_TRIBUTO COTR,
            RUOLI RUOL,
            OGGETTI_CONTRIBUENTE OGCO_DIC,
            OGGETTI_PRATICA OGPR_DIC,
            OGGETTI_IMPOSTA OGIM_DIC,
            PRATICHE_TRIBUTO PRTR_DIC
      WHERE     (COTR.TRIBUTO = OGPR_DIC.TRIBUTO)
            AND (COTR.TIPO_TRIBUTO = PRTR_DIC.TIPO_TRIBUTO)
            AND (PRTR_DIC.PRATICA = OGPR_DIC.PRATICA)
            AND (OGIM_DIC.RUOLO = RUOL.RUOLO(+))
            AND (OGIM_DIC.ANNO(+) = p_anno)
            AND (OGIM_DIC.COD_FISCALE(+) = OGCO_DIC.COD_FISCALE)
            AND (OGIM_DIC.OGGETTO_PRATICA(+) = OGCO_DIC.OGGETTO_PRATICA)
            AND (OGCO_DIC.COD_FISCALE = p_cf)
            AND (OGCO_DIC.OGGETTO_PRATICA = OGPR_DIC.OGGETTO_PRATICA)
            AND (NVL (OGPR_DIC.OGGETTO_PRATICA_RIF, OGPR_DIC.OGGETTO_PRATICA) =
                    (SELECT NVL (oggetto_pratica_rif, oggetto_pratica)
                       FROM oggetti_pratica
                      WHERE oggetto_pratica = p_oggetto_pratica))
            AND (OGIM_DIC.RUOLO IS NOT NULL)
            AND (RUOL.INVIO_CONSORZIO IS NOT NULL)
            AND  NVL (F_RUOLO_TOTALE (OGCO_DIC.COD_FISCALE,
                                  p_anno,
                                  'TARSU',
                                  -1),
                  ruol.ruolo) = ruol.ruolo;
   BEGIN
      FOR oggetti_collegati
         IN (SELECT DISTINCT
                    OGPR_DIC.OGGETTO_PRATICA, OGIM_DIC.OGGETTO_IMPOSTA
               FROM RUOLI RUOL,
                    OGGETTI_CONTRIBUENTE OGCO_DIC,
                    OGGETTI_PRATICA OGPR_DIC,
                    OGGETTI_IMPOSTA OGIM_DIC
              WHERE     (OGIM_DIC.RUOLO = RUOL.RUOLO(+))
                    AND (OGIM_DIC.ANNO(+) = p_anno)
                    AND (OGIM_DIC.COD_FISCALE(+) = OGCO_DIC.COD_FISCALE)
                    AND (OGIM_DIC.OGGETTO_PRATICA(+) =
                            OGCO_DIC.OGGETTO_PRATICA)
                    AND (OGCO_DIC.COD_FISCALE = p_cf)
                    AND (OGCO_DIC.OGGETTO_PRATICA = OGPR_DIC.OGGETTO_PRATICA)
                    AND (NVL (OGPR_DIC.OGGETTO_PRATICA_RIF,
                              OGPR_DIC.OGGETTO_PRATICA) =
                            (SELECT NVL (oggetto_pratica_rif,
                                         oggetto_pratica)
                               FROM oggetti_pratica
                              WHERE oggetto_pratica = p_oggetto_pratica))
                    AND (OGIM_DIC.RUOLO IS NOT NULL)
                    AND (RUOL.INVIO_CONSORZIO IS NOT NULL)
                    AND  NVL (F_RUOLO_TOTALE (OGCO_DIC.COD_FISCALE,
                                  p_anno,
                                  'TARSU',
                                  -1),
                  ruol.ruolo) = ruol.ruolo)
      LOOP
         w_sgravi :=
              NVL (w_sgravi, 0)
            + NVL (ROUND (F_SGRAVIO_OGIM (p_cf,
                                          p_anno,
                                          'TARSU',
                                          oggetti_collegati.oggetto_pratica,
                                          oggetti_collegati.oggetto_imposta,
                                          'S',
                                          'maggiorazione_tares'),
                          2),
                   0);
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END;
   RETURN w_ret - nvl(w_sgravi,0);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 0;
END;
/* End Function: F_GET_MAGG_TARES_PER_OGPR */
/

