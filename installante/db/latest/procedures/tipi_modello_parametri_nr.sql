--liquibase formatted sql 
--changeset abrandolini:20250326_152423_tipi_modello_parametri_nr stripComments:false runOnChange:true 
 
create or replace procedure TIPI_MODELLO_PARAMETRI_NR
( a_parametro_id   IN OUT   number
)
is
begin
   if a_parametro_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(parametro_id),0)+1
            into a_parametro_id
            from TIPI_MODELLO_PARAMETRI
          ;
       end;
    end if;
end;
/* End Procedure: TIPI_MODELLO_PARAMETRI_NR */
/

