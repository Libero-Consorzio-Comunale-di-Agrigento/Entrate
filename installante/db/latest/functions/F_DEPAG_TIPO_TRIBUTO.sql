--liquibase formatted sql 
--changeset abrandolini:20250326_152438_F_DEPAG_TIPO_TRIBUTO stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_DEPAG_TIPO_TRIBUTO
/*************************************************************************
 NOME:        F_DEPAG_TIPO_TRIBUTO

 DESCRIZIONE: Integrazione TR4/DEPAG.
              Dato un servizio si cerca di individuare il tipo_tributo
              Usato per rideterminare il recapito nel caso sdi aggiornamento 
              anagrafico di un record di depag_dovuti

 RITORNA:     string              tipo_tributo

 NOTE:

 Rev.    Date         Author      Note
 000     21/03/2024   AB          Prima emissione.
                                  #69103
*************************************************************************/
(a_servizio                in varchar2
)
RETURN varchar2
IS
  w_titr_inpa        varchar2(200);
  w_tipo_tributo     varchar2(100);
  --
  w_instr            number;
  --

BEGIN
  --
  begin
     select substr(inpa.parametro,6) 
       into w_titr_inpa
       from installazione_parametri inpa
      where inpa.parametro like 'DEPA_%'
        and inpa.parametro not like 'DEPA_GG%'
        and instr(inpa.valore,a_servizio) > 0
        and rownum = 1
         ;
  exception
     when others then
       w_titr_inpa := '';
  end;
  --
  if w_titr_inpa is null then
     begin
        select substr(inpa.parametro,6) 
          into w_titr_inpa
          from installazione_parametri inpa
         where inpa.parametro like 'DEPA_%'
           and inpa.parametro not like 'DEPA_GG%'
           and a_servizio like substr(inpa.valore,1,instr(inpa.valore,' ')-1)||'%' 
           and instr(inpa.valore,' ') > 0
           and rownum = 1
            ;
     exception
        when others then
          w_titr_inpa := '';
     end;
  end if;
  w_tipo_tributo := w_titr_inpa;
  --
  return w_tipo_tributo;
  --
END;
/* End Function: F_DEPAG_TIPO_TRIBUTO */
/
