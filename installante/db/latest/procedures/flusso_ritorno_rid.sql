--liquibase formatted sql 
--changeset abrandolini:20250326_152423_flusso_ritorno_rid stripComments:false runOnChange:true 
 
create or replace procedure FLUSSO_RITORNO_RID
/*************************************************************************
 NOME:        FLUSSO_RITORNO_RID
 DESCRIZIONE: Gestisce il lancio di procedure differenti a seconda del
              cliente.
 NOTE:        ATTENZIONE: LA VECCHIA PROCEDURE FLUSSO_RITORNO_RID DIVENTA
              ORA UNA FLUSSO_RITORNO_RID_STD CHE GESTISCE IL FILE RID
              SECONDO LE ESIGENZE STANDARD.
              Clienti gestiti:
              Fiorano Modenese (cod. 036013)
 Rev.    Date         Author      Note
 000     21/08/2018   VD          Prima emissione.
*************************************************************************/
( a_documento_id      in      number
, a_utente            in      varchar2
, a_messaggio         in out  varchar2
) is
  d_cod_istat         varchar2(6);
  w_errore            varchar2(200);
  errore              exception;
BEGIN
   -- Cambio stato in caricamento in corso per gestione Web
   update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
             ;
   commit;
  --
  -- Si seleziona il codice Istat dell'ente
  --
  begin
    select lpad(to_char(pro_cliente),3,'0')||
           lpad(to_char(com_cliente),3,'0')
      into d_cod_istat
      from dati_generali;
  exception
    when others then
      w_errore := substr('Errore in selezione dati generali '||
                                    ' ('||sqlerrm||')',1,200);
  end;
  --
  if d_cod_istat = '036013' then      -- Fiorano Modenese
     FLUSSO_RITORNO_RID_FMO ( a_documento_id
                            , a_utente
                            , a_messaggio
                            );
  else
     FLUSSO_RITORNO_RID_STD ( a_documento_id
                            , a_utente
                            , a_messaggio
                            );
  end if;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: FLUSSO_RITORNO_RID */
/

