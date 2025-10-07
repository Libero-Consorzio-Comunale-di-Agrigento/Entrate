--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_accertamento_tosap stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_ACCERTAMENTO_TOSAP
(a_tipo_occupazione    IN    varchar,
 a_anno                IN    number,
 a_tributo             IN    number,
 a_categoria           IN    number,
 a_tipo_tariffa        IN    number,
 a_consistenza         IN    number,
 a_quantita            IN    number,
 a_inizio_occupazione  IN    date,
 a_fine_occupazione    IN    date,
 a_perc_possesso       IN    number,
 a_imposta         IN OUT    number)
IS
w_giornaliera    varchar2(1);
w_periodo        number;
w_tariffa        number;
w_comune         varchar2(6);
w_dal            date;
w_al             date;
BEGIN
   BEGIN
      select lpad(to_char(pro_cliente),3,'0')||
             lpad(to_char(com_cliente),3,'0')
        into w_comune
        from dati_generali
      ;
   EXCEPTION
    WHEN no_data_found THEN
         RAISE_APPLICATION_ERROR
       (-20999,'Mancano i Dati Generali');
    WHEN others THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Errore in ricerca Dati Generali');
   END;
  BEGIN
    select tari.tariffa
      into w_tariffa
      from tariffe tari
     where tari.tipo_tariffa    = a_tipo_tariffa
       and tari.categoria    = a_categoria
       and tari.tributo            = a_tributo
       and tari.anno            = a_anno
    ;
  EXCEPTION
    WHEN no_data_found THEN
         RAISE_APPLICATION_ERROR
       (-20999,'Manca la tariffa per l''anno indicato');
    WHEN others THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Errore in ricerca Tariffe');
  END;
  IF a_tipo_occupazione = 'T' THEN
      w_periodo := a_fine_occupazione - a_inizio_occupazione;
      a_imposta := f_round(a_consistenza * w_tariffa * w_periodo * nvl(a_perc_possesso,100) / 100 , 1);
  ELSE
-- Comune di Pontassieve 10/10/2006
-- Provincia di Pistoia 17/05/2017
     IF w_comune in ('048033','047014') THEN
        w_dal   := a_inizio_occupazione;
        w_al    := a_fine_occupazione;
        w_periodo := F_PERIODO(a_anno,w_dal,w_al,a_tipo_occupazione,'TOSAP',null);
        a_imposta := f_round(a_consistenza * w_tariffa * w_periodo * nvl(a_perc_possesso,100) / 100, 1);
     ELSE
        a_imposta := f_round(a_consistenza * w_tariffa * nvl(a_perc_possesso,100) / 100, 1);
     END IF;
  END IF;
EXCEPTION
  WHEN others THEN
       RAISE_APPLICATION_ERROR
     (-20999,'Errore in calcolo Accertamento TOSAP'||
         '('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_ACCERTAMENTO_TOSAP */
/

