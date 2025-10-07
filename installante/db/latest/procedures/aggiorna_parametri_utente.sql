--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiorna_parametri_utente stripComments:false runOnChange:true 
 
create or replace procedure AGGIORNA_PARAMETRI_UTENTE
( a_utente                  varchar2
, a_tipo_parametro          varchar2
, a_valore                  varchar2
) is
  w_rowid                   rowid;
  w_errore                    varchar2(32767);
  errore                      exception;
begin
  begin
    select rowid
      into w_rowid
      from parametri_utente
     where utente         = a_utente
       and tipo_parametro = a_tipo_parametro;
  exception
    when no_data_found then
      w_rowid := null;
    when others then
      raise;
  end;
--
  if w_rowid is null then
     begin
       insert into parametri_utente ( utente
                                    , tipo_parametro
                                    , valore
                                    )
       values ( a_utente
              , a_tipo_parametro
              , a_valore
              );
     exception
       when others then
         w_errore := 'Insert PAUT per utente '||a_utente||' - '||sqlerrm;
         raise errore;
     end;
  else
     begin
       update parametri_utente
          set valore = a_valore
        where rowid = w_rowid;
     exception
       when others then
         w_errore := 'Update PAUT per utente '||a_utente||' - '||sqlerrm;
         raise errore;
     end;
  end if;
  commit;
exception
  when errore then
    rollback;
    raise_application_error(-20999,w_errore);
  when others then
    rollback;
    raise_application_error
   (-20999,'Errore in Aggiornamento Parametri Utente '||'('||sqlerrm||')');
END;
/* End Procedure: AGGIORNA_PARAMETRI_UTENTE */
/

