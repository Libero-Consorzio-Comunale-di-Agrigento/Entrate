--liquibase formatted sql
--changeset dmarotta:20251002_105925_tipi_esenzione_nr stripComments:false runOnChange:true
 
create or replace procedure TIPI_ESENZIONE_NR
( a_tipo_esenzione      IN OUT   number
)
is
begin
   if a_tipo_esenzione is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(tipo_esenzione),0)+1
            into a_tipo_esenzione
            from TIPI_ESENZIONE
          ;
       end;
    end if;
end;
/* End Procedure: TIPI_ESENZIONE_NR */
/
