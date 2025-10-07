--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_accertamento_icp stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_ACCERTAMENTO_ICP
(a_tipo_pubblicita        IN    varchar,
 a_anno                   IN    number,
 a_tributo                IN    number,
 a_categoria              IN    number,
 a_tipo_tariffa           IN    number,
 a_consistenza            IN    number,
 a_quantita               IN    number,
 a_inizio_occupazione     IN    date,
 a_fine_occupazione       IN    date,
 a_imposta            IN OUT    number)
IS
w_giornaliera   varchar2(1);
w_periodo       number;
w_tariffa       number;
BEGIN
  BEGIN
    select tari.tariffa, cate.flag_giorni
      into w_tariffa, w_giornaliera
      from tariffe tari, categorie cate
     where cate.tributo        = tari.tributo
       and cate.categoria      = tari.categoria
       and tari.tipo_tariffa   = a_tipo_tariffa
       and tari.categoria      = a_categoria
       and tari.tributo        = a_tributo
       and tari.anno           = a_anno
    ;
  EXCEPTION
    WHEN no_data_found THEN
         RAISE_APPLICATION_ERROR
       (-20999,'Manca la tariffa per l''anno indicato');
    WHEN others THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Errore in ricerca Tariffe');
  END;
  IF w_giornaliera = 'S' THEN
    w_periodo := a_fine_occupazione - a_inizio_occupazione;
      a_imposta := f_round(a_consistenza * w_tariffa * w_periodo , 1);
  ELSIF a_tipo_pubblicita = 'T' THEN
    w_periodo := ceil(months_between(a_fine_occupazione,a_inizio_occupazione));
      a_imposta := f_round(a_consistenza * (w_tariffa/10) * w_periodo  , 1);
   -- w_tariffa/10 dimende dal fatto che la quota mensile che e' un decimo di quella annuale
  ELSE
    a_imposta := f_round(a_consistenza * w_tariffa  , 1);
  END IF;
EXCEPTION
  WHEN others THEN
       RAISE_APPLICATION_ERROR
     (-20999,'Errore in calcolo Accertamento ICP'||
         '('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_ACCERTAMENTO_ICP */
/

