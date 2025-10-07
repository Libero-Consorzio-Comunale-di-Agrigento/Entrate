--liquibase formatted sql 
--changeset abrandolini:20250326_152423_OGGETTI_NR stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure OGGETTI_NR
( a_oggetto	IN OUT	number
)
is
begin
   if a_oggetto is null then
       begin -- Assegnazione Numero Progressivo
--          select nvl(max(oggetto),0)+1
          select nr_ogge_seq.nextval
            into a_oggetto
            from dual
--            from OGGETTI
          ; 
       end;
    end if;

end;
/* End Procedure: OGGETTI_NR */
/
