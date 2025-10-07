--liquibase formatted sql 
--changeset abrandolini:20250326_152423_pratiche_tributo_fi stripComments:false runOnChange:true 
 
create or replace procedure PRATICHE_TRIBUTO_FI
(a_pratica           IN number,
 a_tipo_pratica      IN varchar2,
 a_stato_old        IN varchar2,
 a_stato_new        IN varchar2,
 a_tipo_atto_old    IN number,
 a_tipo_atto_new    IN number,
 a_motivo           IN varchar2,
 a_note             IN varchar2,
 a_utente           IN varchar2,
 a_operazione       IN varchar2,
 a_flag_annullamento_old  IN varchar2,
 a_flag_annullamento_new  IN varchar2)
IS
w_controllo   varchar2(1);
BEGIN
--dbms_output.put_line ('Entra '||a_tipo_pratica||' '||a_operazione||' X');
  IF a_tipo_pratica in ('A','I','L','V','S') THEN
   IF nvl(a_operazione,'X') = 'I' THEN
--dbms_output.put_line ('Insert');
     begin
       insert into iter_pratica (pratica, data, stato, tipo_atto, motivo, note, utente)
       values (a_pratica, sysdate, a_stato_new, a_tipo_atto_new, a_motivo, a_note, a_utente);
     end;
   END IF;
   IF UPDATING THEN
     if nvl(a_stato_new,'XX') != nvl(a_stato_old,'XX') or
        nvl(a_tipo_atto_new,-1) != nvl(a_tipo_atto_old,-1) then
        begin
          insert into iter_pratica (pratica, data, stato, tipo_atto, motivo, note, utente)
          values (a_pratica, sysdate, a_stato_new, a_tipo_atto_new, a_motivo, a_note, a_utente);
        end;
     end if;
   END IF;
  END IF;
  IF UPDATING and a_tipo_pratica in ('D') THEN
     if nvl(a_flag_annullamento_new,'XX') != nvl(a_flag_annullamento_old,'XX') then
        begin
          insert into iter_pratica (pratica, data, stato, tipo_atto, motivo, note, utente, flag_annullamento)
          values (a_pratica, sysdate, a_stato_new, a_tipo_atto_new, a_motivo, a_note, a_utente, a_flag_annullamento_new);
        end;
     end if;
  END IF;
  IF DELETING THEN
      BEGIN
        select 'x'
          into w_controllo
          from oggetti_pratica ogpr,
           oggetti_pratica ogpr1
         where ogpr1.oggetto_pratica_rif   = ogpr.oggetto_pratica
           and ogpr.pratica         = a_pratica
        ;
        RAISE too_many_rows;
      EXCEPTION
        WHEN too_many_rows THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Eliminazione non consentita: '||
               'esistono riferimenti in Oggetti Pratica di Riferimento');
        WHEN no_data_found THEN
         null;
        WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Oggetti Pratica di Riferimento');
      END;
      BEGIN
        select 'x'
          into w_controllo
          from rate_imposta raim,
           oggetti_imposta ogim,
           oggetti_pratica ogpr
         where raim.oggetto_imposta   = ogim.oggetto_imposta
           and ogim.oggetto_pratica   = ogpr.oggetto_pratica
           and ogpr.pratica      = a_pratica
        ;
        RAISE too_many_rows;
      EXCEPTION
        WHEN too_many_rows THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Eliminazione non consentita: '||
               'esistono riferimenti in Rate Imposta');
        WHEN no_data_found THEN
         null;
        WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Rate Imposta');
      END;
      BEGIN
        select 'x'
          into w_controllo
          from ruoli_contribuente ruco,
           oggetti_imposta ogim,
           oggetti_pratica ogpr
         where ruco.oggetto_imposta   = ogim.oggetto_imposta
           and ogim.oggetto_pratica   = ogpr.oggetto_pratica
           and ogpr.pratica      = a_pratica
        ;
        RAISE too_many_rows;
      EXCEPTION
        WHEN too_many_rows THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Eliminazione non consentita: '||
               'esistono riferimenti in Ruoli Contribuente (Imposta)');
        WHEN no_data_found THEN
         null;
        WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Ruoli Contribuente');
      END;
      BEGIN
        select 'x'
          into w_controllo
          from versamenti vers,
           oggetti_imposta ogim,
           oggetti_pratica ogpr
         where vers.oggetto_imposta   = ogim.oggetto_imposta
           and ogim.oggetto_pratica   = ogpr.oggetto_pratica
           and ogpr.pratica      = a_pratica
        ;
        RAISE too_many_rows;
      EXCEPTION
        WHEN too_many_rows THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Eliminazione non consentita: '||
               'esistono riferimenti in Versamenti');
        WHEN no_data_found THEN
         null;
        WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Versamenti');
      END;
  END IF;
END;
/* End Procedure: PRATICHE_TRIBUTO_FI */
/
