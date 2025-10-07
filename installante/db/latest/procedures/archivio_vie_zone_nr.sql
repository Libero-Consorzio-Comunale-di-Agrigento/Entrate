--liquibase formatted sql 
--changeset abrandolini:20250326_152423_archivio_vie_zone_nr stripComments:false runOnChange:true 
 
create or replace procedure ARCHIVIO_VIE_ZONE_NR
(a_cod_zona      IN number,
 a_sequenza      IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from ARCHIVIO_VIE_ZONE
          where cod_zona     = a_cod_zona
         ;
      end;
   end if;
end;
/* End Procedure: ARCHIVIO_VIE_ZONE_NR */
/

