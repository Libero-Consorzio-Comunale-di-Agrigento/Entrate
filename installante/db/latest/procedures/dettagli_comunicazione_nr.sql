--liquibase formatted sql 
--changeset abrandolini:20250326_152423_dettagli_comunicazione_nr stripComments:false runOnChange:true 
 
create or replace procedure DETTAGLI_COMUNICAZIONE_NR
(a_tipo_tributo            varchar2,
 a_tipo_comunicazione      varchar2,
 a_sequenza         IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from DETTAGLI_COMUNICAZIONE
          where tipo_tributo       = a_tipo_tributo
            and tipo_comunicazione = a_tipo_comunicazione
         ;
      end;
   end if;
end;
/* End Procedure: DETTAGLI_COMUNICAZIONE_NR */
/
