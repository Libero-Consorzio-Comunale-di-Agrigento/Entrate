--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ftp_trasmissioni_nr stripComments:false runOnChange:true 
 
create or replace procedure FTP_TRASMISSIONI_NR
(a_id_documento      IN OUT number
)
is
begin
   if a_id_documento is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(id_documento),0)+1
           into a_id_documento
           from FTP_TRASMISSIONI
         ;
      end;
   end if;
end;
/* End Procedure: FTP_TRASMISSIONI_NR */
/

