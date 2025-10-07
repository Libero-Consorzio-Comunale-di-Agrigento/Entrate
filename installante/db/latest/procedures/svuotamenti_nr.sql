--liquibase formatted sql 
--changeset abrandolini:20250326_152423_svuotamenti_nr stripComments:false runOnChange:true 
 
create or replace procedure SVUOTAMENTI_NR
(a_cod_fiscale      IN varchar2,
 a_oggetto      IN number,
 a_cod_rfid      IN varchar2,
 a_sequenza      IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from SVUOTAMENTI
          where cod_fiscale = a_cod_fiscale
            and oggetto     = a_oggetto
            and cod_rfid    = a_cod_rfid
         ;
      end;
   end if;
end;
/* End Procedure: SVUOTAMENTI_NR */
/
