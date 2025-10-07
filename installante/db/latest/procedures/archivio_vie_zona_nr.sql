--liquibase formatted sql 
--changeset abrandolini:20250326_152423_archivio_vie_zona_nr stripComments:false runOnChange:true 
 
create or replace procedure ARCHIVIO_VIE_ZONA_NR
(a_cod_via      IN number,
 a_sequenza      IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from ARCHIVIO_VIE_ZONA
          where cod_via      = a_cod_via
         ;
      end;
   end if;
end;
/* End Procedure: ARCHIVIO_VIE_ZONA_NR */
/

