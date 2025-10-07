--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ftp_log_nr stripComments:false runOnChange:true 
 
create or replace procedure FTP_LOG_NR
(a_id_documento      IN number,
 a_sequenza      IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from FTP_LOG
          where id_documento    = a_id_documento
         ;
      end;
   end if;
end;
/* End Procedure: FTP_LOG_NR */
/

