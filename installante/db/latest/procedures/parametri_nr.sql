--liquibase formatted sql 
--changeset abrandolini:20250326_152423_parametri_nr stripComments:false runOnChange:true 
 
create or replace procedure PARAMETRI_NR
(a_sessione      IN    number,
 a_nome_parametro   IN    varchar2,
 a_progressivo      IN OUT   number
)
is
begin
   if a_progressivo is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(progressivo),0)+1
           into a_progressivo
           from PARAMETRI
          where sessione    = a_sessione
            and nome_parametro    = a_nome_parametro
         ;
      end;
   end if;
end;
/* End Procedure: PARAMETRI_NR */
/

