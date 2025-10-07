--liquibase formatted sql 
--changeset abrandolini:20250326_152423_dati_contabili_nr stripComments:false runOnChange:true 
 
create or replace procedure DATI_CONTABILI_NR
( a_id   IN OUT   number
)
is
begin
   if a_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id_dato_contabile),0)+1
            into a_id
            from DATI_CONTABILI
          ;
       end;
    end if;
end;
/* End Procedure: DATI_CONTABILI_NR */
/

