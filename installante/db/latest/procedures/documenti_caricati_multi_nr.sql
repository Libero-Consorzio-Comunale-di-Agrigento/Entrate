--liquibase formatted sql 
--changeset abrandolini:20250326_152423_documenti_caricati_multi_nr stripComments:false runOnChange:true 
 
create or replace procedure DOCUMENTI_CARICATI_MULTI_NR
( a_documento_id   IN   number,
  a_documento_multi_id   IN OUT   number
)
is
begin
   if a_documento_multi_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(documento_multi_id),0)+1
            into a_documento_multi_id
            from DOCUMENTI_CARICATI_MULTI
           where documento_id = a_documento_id
          ;
       end;
    end if;
end;
/* End Procedure: DOCUMENTI_CARICATI_MULTI_NR */
/

