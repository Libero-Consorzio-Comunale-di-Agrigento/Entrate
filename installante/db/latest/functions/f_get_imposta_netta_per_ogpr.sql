--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_imposta_netta_per_ogpr stripComments:false runOnChange:true 
 
create or replace function F_GET_IMPOSTA_NETTA_PER_OGPR
/******************************************************************************
 NOME:        F_GET_IMPOSTA_NETTA_PER_OGPR
 DESCRIZIONE: Calcolo dei valori del dichiarato, utilizzata nella maschera
              dell'accertamento manuale.
              Il motivo per cui si fa questa funzione è che i valori vanno
              calcolati su tutte le dichiarazioni relative all'oggetto, mentre
              dati come la data decorrenza o la superficie si prendono solo
              dall'ultima dichiarazione.
              Questa funzione in particolare restituisce l'imposta netta,
              togliendo anche gli sgravi.
 RITORNA:     number              Importo imposta netta
 NOTE:
 p_tipo_imposta                   Null: calcolo con campo imposta
                                  'P': calcolo con campo imposta_periodo.
 Rev.    Date         Author      Note
 002     07/07/2022   VD          Aggiunto parametro tipo_imposta con default
                                  null per nuovo accertamento TributiWeb che
                                  può includere più oggetti e più periodi dello
                                  stesso oggetto.
                                  Se null, la funzione si comporta come prima.
                                  Se 'P', si considera il campo imposta_periodo
                                  al posto del campo imposta.
 001     16/01/2015   Betta T.    Corretta determinazione del ruolo.
 000     XX/XX/XXXX   XX          Prima emissione.
********************************************************************************/
(  p_oggetto_pratica    NUMBER,
   p_anno               NUMBER,
   p_cf                 VARCHAR2,
   p_tipo_imposta       varchar2 default null)
   RETURN NUMBER
IS
   w_ret             NUMBER;
   w_sgravi          NUMBER;
BEGIN
   SELECT SUM (decode(p_tipo_imposta
                     ,'P',ogim_dic.imposta_periodo
                     ,OGIM_DIC.IMPOSTA
                     )
              ) imposta
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
         IN (SELECT DISTINCT OGPR_DIC.OGGETTO_PRATICA
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
            + NVL (ROUND (F_SGRAVIO_OGPR (p_cf,
                                          p_anno,
                                          'TARSU',
                                          oggetti_collegati.oggetto_pratica),
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
/* End Function: F_GET_IMPOSTA_NETTA_PER_OGPR */
/

