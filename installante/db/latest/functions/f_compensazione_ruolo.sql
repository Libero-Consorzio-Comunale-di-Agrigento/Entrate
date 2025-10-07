--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_compensazione_ruolo stripComments:false runOnChange:true 
 
create or replace function F_COMPENSAZIONE_RUOLO
(a_ruolo            in NUMBER
,a_cod_fiscale      in VARCHAR2
,a_ogpr             in number
) Return NUMBER is
nTotale           number(16,2);
BEGIN
   BEGIN  -- compensazione per eccedenza gettito su Ruolo a Saldo
      select nvl(sum(nvl(coru.compensazione,0)),0)
        into nTotale
        from compensazioni_ruolo coru
       where coru.ruolo            = a_ruolo
          and cod_fiscale = nvl(a_cod_fiscale,cod_fiscale)
          and motivo_compensazione = 99
          ;
   EXCEPTION
      WHEN OTHERS THEN
         nTotale := 0;
   END;
   IF nTotale = 0 THEN
       BEGIN
          select nvl(sum(nvl(coru.compensazione,0)),0)
            into nTotale
            from compensazioni_ruolo coru
           where coru.ruolo            = a_ruolo
             and not exists (select 1
                               from ruoli_contribuente
                              where ruolo = a_ruolo)
              ;
       EXCEPTION
          WHEN OTHERS THEN
             nTotale := 0;
       END;
   END IF;
   IF nTotale = 0 THEN
      BEGIN
         select nvl(sum(nvl(coru.compensazione,0)),0)
           into nTotale
           from compensazioni_ruolo coru
          where coru.ruolo            = a_ruolo
            and coru.cod_fiscale      like a_cod_fiscale
            and coru.oggetto_pratica  = a_ogpr
              ;
      EXCEPTION
         WHEN OTHERS THEN
            nTotale := 0;
      END;
   END IF;
   Return nTotale;
END;
/* End Function: F_COMPENSAZIONE_RUOLO */
/

