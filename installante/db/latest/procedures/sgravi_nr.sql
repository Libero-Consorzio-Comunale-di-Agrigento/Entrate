--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sgravi_nr stripComments:false runOnChange:true 
 
create or replace procedure SGRAVI_NR
(a_ruolo      IN    number,
 a_cod_fiscale      IN      varchar2,
 a_sequenza      IN    number,
 a_sequenza_sgravio   IN OUT  number
)
is
begin
   if a_sequenza_sgravio is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza_sgravio),0)+1
           into a_sequenza_sgravio
           from SGRAVI
          where ruolo      = a_ruolo
       and cod_fiscale   = a_cod_fiscale
       and sequenza   = a_sequenza
         ;
      end;
   end if;
end;
/* End Procedure: SGRAVI_NR */
/

