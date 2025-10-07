--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_imposta_lorda_per_ogpr stripComments:false runOnChange:true 
 
create or replace function F_GET_IMPOSTA_LORDA_PER_OGPR
/******************************************************************************
 NOME:        F_GET_IMPOSTA_LORDA_PER_OGPR
 DESCRIZIONE: Calcolo dei valori del dichiarato, utilizzata nella maschera
              dell'accertamento manuale TARSU.
              Il motivo per cui si fa questa funzione è che i valori vanno
              calcolati su tutte le dichiarazioni relative all'oggetto, mentre
              dati come la data decorrenza o la superficie si prendono solo
              dall'ultima dichiarazione.
              Questa funzione in particolare restituisce l'imposta netta,
              togliendo le compensazioni.
 RITORNA:     number              Importo imposta lorda
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
   w_netto           NUMBER;
BEGIN
   w_netto := f_get_imposta_netta_per_ogpr ( p_oggetto_pratica, p_anno
                                           , p_cf, p_tipo_imposta);
   SELECT   w_netto
          + ROUND (w_netto * NVL (CATA.ADDIZIONALE_ECA, 0) / 100, 2)
          + ROUND (w_netto * NVL (CATA.MAGGIORAZIONE_ECA, 0) / 100, 2)
          + ROUND (w_netto * NVL (CATA.ADDIZIONALE_PRO, 0) / 100, 2)
          + ROUND (w_netto * NVL (CATA.ALIQUOTA, 0) / 100, 2)
             imposta_lorda
     INTO w_ret
     FROM CARICHI_TARSU CATA
    WHERE (CATA.ANNO = p_anno);
   RETURN w_ret;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 0;
END;
/* End Function: F_GET_IMPOSTA_LORDA_PER_OGPR */
/

