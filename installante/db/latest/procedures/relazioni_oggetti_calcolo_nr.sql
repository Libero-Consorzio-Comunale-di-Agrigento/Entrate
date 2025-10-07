--liquibase formatted sql 
--changeset abrandolini:20250326_152423_relazioni_oggetti_calcolo_nr stripComments:false runOnChange:true 
 
create or replace procedure RELAZIONI_OGGETTI_CALCOLO_NR
( a_id_relazione   IN OUT   number
)
is
cursor_name    integer;
ret      integer;
begin -- Assegnazione Numero Progressivo
   if a_id_relazione is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id_relazione),0)+1
            into a_id_relazione
            from RELAZIONI_OGGETTI_CALCOLO
--       :new.id_relazione := SI4.NEXT_ID ('RELAZIONI_OGGETTI_CALCOLO','ID_RELAZIONE');
          ;
       end;
    end if;
end;
/* End Procedure: RELAZIONI_OGGETTI_CALCOLO_NR */
/

