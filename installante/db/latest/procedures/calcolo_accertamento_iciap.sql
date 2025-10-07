--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_accertamento_iciap stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_ACCERTAMENTO_ICIAP
(a_anno         IN number,
 a_classe      IN number,
 a_settore      IN number,
 a_reddito      IN number,
 a_imposta         IN OUT number)
IS
 w_reddito_inf   number;
 w_reddito_sup   number;
BEGIN
  BEGIN
    select reddito_inf, reddito_sup
      into w_reddito_inf, w_reddito_sup
      from scaglioni_reddito
     where anno = a_anno
    ;
  EXCEPTION
    WHEN no_data_found THEN
         RAISE_APPLICATION_ERROR(-20999,'Manca lo Scaglione di Reddito per l''anno indicato',TRUE);
    WHEN others THEN
    RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Scaglione di Reddito',TRUE);
  END;
  BEGIN
-- L'imposta dev'essere calcolata in questo modo: si deve prendere l'imposta
-- da classi_superifice che abbia come classe la minima classe maggiore o uguale a
-- quella passata come parametro (ovvero a_classe).
     select imposta
       into a_imposta
       from classi_superficie
      where anno   = a_anno
   and settore   = a_settore
   and classe   = (select min(classe)
                            from classi_superficie
                   where anno     = a_anno
                     and settore  = a_settore
               and classe  >= a_classe)
     ;
  EXCEPTION
    WHEN no_data_found THEN
         RAISE_APPLICATION_ERROR(-20999,'Manca la Classe Superficie per l''anno indicato',TRUE);
    WHEN others THEN
         RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca della Classe Superficie',TRUE);
  END;
  IF a_reddito < w_reddito_inf THEN
   a_imposta := a_imposta / 2;
  ELSIF a_reddito > w_reddito_sup THEN
   a_imposta := a_imposta * 2;
  END IF;
EXCEPTION
  WHEN others THEN
       RAISE_APPLICATION_ERROR
       (-20999,'Errore in Accertamento ICIAP ('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_ACCERTAMENTO_ICIAP */
/

