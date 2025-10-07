--liquibase formatted sql 
--changeset abrandolini:20250326_152423_conferimenti_cer_ruolo_nr stripComments:false runOnChange:true 
 
create or replace procedure CONFERIMENTI_CER_RUOLO_NR
(a_cod_fiscale      IN      varchar2,
 a_anno         IN    number,
 a_tipo_utenza      IN   varchar2,
 a_data_conferimento   IN   date,
 a_codice_cer      IN    varchar2,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from CONFERIMENTI_CER_RUOLO
          where cod_fiscale   = a_cod_fiscale
       and anno      = a_anno
            and tipo_utenza     = a_tipo_utenza
            and data_conferimento = a_data_conferimento
            and codice_cer      = a_codice_cer
         ;
      end;
   end if;
end;
/* End Procedure: CONFERIMENTI_CER_RUOLO_NR */
/

