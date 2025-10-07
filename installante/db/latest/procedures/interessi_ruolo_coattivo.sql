--liquibase formatted sql 
--changeset abrandolini:20250326_152423_interessi_ruolo_coattivo stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     INTERESSI_RUOLO_COATTIVO
(a_pratica     in number
,a_data_fine   in date
,a_utente      in varchar2)
IS
errore              exception;
w_errore            varchar2(200);
w_conta             number;
w_interesse         number;
w_tipo_tributo      varchar2(10);
w_data_notifica     date;
w_data_inizio       date;
w_importo           number;
w_data_pratica      date;
w_sequenza_sanz     number;
BEGIN
  begin
    select prtr.tipo_tributo
         , prtr.data_notifica
         , prtr.data
      into w_tipo_tributo
         , w_data_notifica
         , w_data_pratica
      from pratiche_tributo prtr
     where prtr.pratica = a_pratica
       ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore recupero dati pratica '||to_char(a_pratica);
        raise errore;
  end;
  begin
    select sum(sapr.importo)
      into w_importo
      from sanzioni_pratica sapr
         , sanzioni sanz
         , codici_tributo cotr
     where sapr.pratica      = a_pratica
       and sanz.cod_sanzione = sapr.cod_sanzione
       and sanz.sequenza = sapr.sequenza_sanz
       and sanz.tributo      = cotr.tributo
       and cotr.flag_calcolo_interessi = 'S'
       ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore recupero importo sanzioni_pratica '||to_char(a_pratica);
        raise errore;
  end;
  if w_tipo_tributo = 'ICI' and w_data_pratica < to_date('01/01/2007','dd/mm/yyyy') then
     w_data_inizio := w_data_notifica + 91;
  else
     w_data_inizio := w_data_notifica + 61;
  end if;
  w_interesse := F_CALCOLO_INTERESSI_GG_TITR(w_importo,w_data_inizio,a_data_fine,360,w_tipo_tributo);
  begin
    select count(1)
      into w_conta
      from pratiche_tributo prtr
         , sanzioni_pratica sapr
     where sapr.pratica = prtr.pratica
       and prtr.pratica = a_pratica
       and sapr.cod_sanzione = 999
       ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore verifica sanzione 999';
        raise errore;
  end;
  if w_conta = 0 then
    begin
      insert into sanzioni_pratica
             ( pratica, cod_sanzione, sequenza
             , tipo_tributo, importo, utente)
      values ( a_pratica, 999, 1
             , w_tipo_tributo, w_interesse, a_utente)
             ;
    exception
       when others then
          w_errore := 'Errore in inserimento sanzioni pratica 999 - Pratica '||to_char(a_pratica);
          raise errore;
    end;
  elsif w_conta = 1 then
-- AB (12/12/2024) per avere la sequenza_sanz giusta
      BEGIN
         select sequenza_sanz
           into w_sequenza_sanz
           from sanzioni_pratica sapr
          where sapr.pratica = a_pratica
            and sapr.cod_sanzione = 999
         ;
      EXCEPTION
          WHEN others THEN
                w_errore := 'Errore in ricerca Sanzioni Pratica ('
                        ||'999'||') '||'('||SQLERRM||')';
               RAISE errore;
      END;

    begin
      update sanzioni_pratica
         set importo = w_interesse
           , utente  = a_utente
       where pratica = a_pratica
         and cod_sanzione = 999
         and sequenza_sanz = w_sequenza_sanz
         ;
    exception
       when others then
          w_errore := 'Errore in aggiornamento sanzioni pratica 999 - Pratica '||to_char(a_pratica);
          raise errore;
    end;
  else
    w_errore := 'Errore: Sono presenti più sanzioni con codice 999';
  end if;
  commit;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in inserimento Interessi Ruolo Coattivo - Pratica '||to_char(a_pratica)||' '||'('||SQLERRM||')');
END;
/* End Procedure: INTERESSI_RUOLO_COATTIVO */
/
