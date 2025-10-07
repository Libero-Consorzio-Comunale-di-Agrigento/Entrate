--liquibase formatted sql 
--changeset abrandolini:20250326_152423_iter_pratica_nr stripComments:false runOnChange:true 
 
create or replace procedure ITER_PRATICA_NR
( a_iter_pratica   IN OUT   number
)
is
begin -- Assegnazione Numero Progressivo
   if a_iter_pratica is null then
       begin -- Assegnazione Numero Progressivo
--          select nvl(max(iter_pratica),0)+1
          select nr_itpr_seq.nextval
            into a_iter_pratica
            from dual
--            from ITER_PRATICA
          ;
       end;
    end if;
end;
/* End Procedure: ITER_PRATICA_NR */
/
