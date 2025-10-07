--liquibase formatted sql
--changeset dmarotta:20251002_105742_tipi_riduzione_nr stripComments:false runOnChange:true
 
create or replace procedure TIPI_RIDUZIONE_NR
( a_tipo_riduzione      IN OUT   number
)
is
begin
   if a_tipo_riduzione is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(tipo_riduzione),0)+1
            into a_tipo_riduzione
            from TIPI_RIDUZIONE
          ;
       end;
    end if;
end;
/* End Procedure: TIPI_RIDUZIONE_NR */
/
