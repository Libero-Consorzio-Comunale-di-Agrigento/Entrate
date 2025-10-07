--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_max_ogpr_tipr_anno stripComments:false runOnChange:true 
 
create or replace function F_MAX_OGPR_TIPR_ANNO
(A_ANNO      IN NUMBER,
 A_TIPR      IN VARCHAR2,
 A_OGPR      IN NUMBER,
 A_DATA      IN DATE
)
RETURN NUMBER
IS
OGPR_TIPR NUMBER;
  BEGIN
     SELECT OGPR.OGGETTO_PRATICA
         INTO OGPR_TIPR
       FROM OGGETTI_PRATICA  OGPR,
         PRATICHE_TRIBUTO PRTR
      WHERE OGPR.OGGETTO_PRATICA_RIF   = A_OGPR
   AND PRTR.PRATICA      = OGPR.PRATICA
   AND PRTR.numero = (SELECT MAX(PRTR_SUB.numero)
                       FROM OGGETTI_PRATICA  OGPR_SUB,
                     PRATICHE_TRIBUTO PRTR_SUB
                    WHERE PRTR_SUB.PRATICA      = OGPR_SUB.PRATICA
                        AND OGPR_SUB.OGGETTO_PRATICA   = OGPR.OGGETTO_PRATICA
                         AND PRTR_SUB.DATA         < A_DATA
                        AND PRTR_SUB.ANNO         = A_ANNO
                        AND PRTR_SUB.TIPO_PRATICA    = A_TIPR)
      ;
      RETURN OGPR_TIPR;
END;
/* End Function: F_MAX_OGPR_TIPR_ANNO */
/

