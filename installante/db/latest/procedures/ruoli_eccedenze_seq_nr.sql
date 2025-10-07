--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ruoli_eccedenze_seq_nr stripComments:false runOnChange:true 
 
create or replace procedure RUOLI_ECCEDENZE_SEQ_NR
( a_ruolo               IN number
, a_cod_fiscale         IN varchar2
, a_tributo             IN number
, a_categoria           IN number
, a_sequenza      IN OUT   number
)
is
begin
   if a_sequenza is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(sequenza),0)+1
            into a_sequenza
            from RUOLI_ECCEDENZE
           where ruolo       = a_ruolo
             and cod_fiscale = a_cod_fiscale
             and tributo     = a_tributo
             and categoria   = a_categoria
          ;
       end;
    end if;
end;
/* End Procedure: RUOLI_ECCEDENZE_SEQ_NR */
/
