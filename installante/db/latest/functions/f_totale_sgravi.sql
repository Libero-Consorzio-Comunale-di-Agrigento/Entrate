--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_totale_sgravi stripComments:false runOnChange:true 
 
create or replace function F_TOTALE_SGRAVI
(a_ruolo            in NUMBER
,a_cod_fiscale      in VARCHAR2
,a_sequenza         in NUMBER
,a_sequenza_sgravio in NUMBER
) Return NUMBER is
nTotale           number(16,2);
BEGIN
   BEGIN
      select nvl(sum(nvl(sgra.importo,0)),0)
        into nTotale
        from sgravi sgra
       where sgra.ruolo            between a_ruolo
                                   and decode(a_ruolo,0,9999999999,a_ruolo)
         and sgra.cod_fiscale      like a_cod_fiscale
         and sgra.sequenza         between a_sequenza
                                   and decode(a_sequenza,0,9999,a_sequenza)
         and sgra.sequenza_sgravio between a_sequenza_sgravio
                                   and decode(a_sequenza_sgravio,0,9999,a_sequenza_sgravio)
      ;
   EXCEPTION
      WHEN OTHERS THEN
         nTotale := 0;
   END;
   Return nTotale;
END;
/* End Function: F_TOTALE_SGRAVI */
/

