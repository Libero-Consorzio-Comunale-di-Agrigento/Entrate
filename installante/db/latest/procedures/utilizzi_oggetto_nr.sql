--liquibase formatted sql 
--changeset abrandolini:20250326_152423_utilizzi_oggetto_nr stripComments:false runOnChange:true 
 
create or replace procedure UTILIZZI_OGGETTO_NR
(a_oggetto      IN    number,
 a_anno         IN   number,
 a_tipo_utilizzo   IN   number,
 a_tipo_tributo IN varchar2,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from UTILIZZI_OGGETTO
          where oggetto      = a_oggetto
            and anno      = a_anno
            and tipo_utilizzo   = a_tipo_utilizzo
            and tipo_tributo = a_tipo_tributo
         ;
      end;
   end if;
end;
/* End Procedure: UTILIZZI_OGGETTO_NR */
/

