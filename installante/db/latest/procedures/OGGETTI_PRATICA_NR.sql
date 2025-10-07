--liquibase formatted sql 
--changeset abrandolini:20250326_152423_OGGETTI_PRATICA_NR stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure OGGETTI_PRATICA_NR
( a_oggetto_pratica	IN OUT	number
)
is
begin
   if a_oggetto_pratica is null then
       begin -- Assegnazione Numero Progressivo
--          select nvl(max(oggetto_pratica),0)+1
          select nr_ogpr_seq.nextval
            into a_oggetto_pratica
            from dual
--            from OGGETTI_PRATICA
          ; 
       end;
    end if;
end;
/* End Procedure: OGGETTI_PRATICA_NR */
/
