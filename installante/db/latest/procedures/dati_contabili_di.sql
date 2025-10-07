--liquibase formatted sql 
--changeset abrandolini:20250326_152423_dati_contabili_di stripComments:false runOnChange:true 
 
create or replace procedure DATI_CONTABILI_DI
(a_emissione_dal   IN   date,
 a_emissione_al           IN   date,
 a_ripartizione_dal   IN   date,
 a_ripartizione_al      IN   date
)
IS
BEGIN
   IF nvl(a_emissione_dal,to_date('01011900','ddmmyyyy')) > nvl(a_emissione_al,to_date('31129999','ddmmyyyy')) THEN
      RAISE_APPLICATION_ERROR
          (-20999,'Inizio Emissione maggiore di Fine Emissione');
   END IF;
   IF nvl(a_ripartizione_dal,to_date('01011900','ddmmyyyy'))  > nvl(a_ripartizione_al,to_date('31129999','ddmmyyyy')) THEN
      RAISE_APPLICATION_ERROR
          (-20999,'Inizio Ripartizione maggiore di Fine Ripartizione');
   END IF;
END;
/* End Procedure: DATI_CONTABILI_DI */
/

