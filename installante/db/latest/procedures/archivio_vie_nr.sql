--liquibase formatted sql 
--changeset abrandolini:20250326_152423_archivio_vie_nr stripComments:false runOnChange:true 
 
create or replace procedure ARCHIVIO_VIE_NR
( a_cod_via   IN OUT   number
)
is
w_flag_integrazione_gsd   varchar2(1);
begin
   BEGIN
     select flag_integrazione_gsd
       into w_flag_integrazione_gsd
       from dati_generali
     ;
   EXCEPTION
     WHEN others THEN
       RAISE_APPLICATION_ERROR
         (-20999,'Errore in ricerca Dati Generali');
   END;
   if w_flag_integrazione_gsd is null and a_cod_via is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(cod_via),0)+1
            into a_cod_via
            from ARCHIVIO_VIE
          ;
       end;
    end if;
end;
/* End Procedure: ARCHIVIO_VIE_NR */
/

