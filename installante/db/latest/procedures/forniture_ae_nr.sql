--liquibase formatted sql 
--changeset abrandolini:20250326_152423_forniture_ae_nr stripComments:false runOnChange:true 
 
create or replace procedure FORNITURE_AE_NR
(a_documento_id   IN number,
 a_progressivo    IN OUT number
)
is
begin
   if a_progressivo is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(progressivo),0)+1
           into a_progressivo
           from FORNITURE_AE
          where documento_id = a_documento_id
         ;
      end;
   end if;
end;
/* End Procedure: FORNITURE_AE_NR */
/

