--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_esiste_dato_caricamento stripComments:false runOnChange:true 
 
create or replace function F_ESISTE_DATO_CARICAMENTO
/*************************************************************************
 NOME:        F_ESISTE_DATO_CARICAMENTO
 DESCRIZIONE: Dato un oggetto pratica, verifica se esistono dati da
              caricamento MUI o da caricamento dichiarazioni ENC.
              Data una pratica, si verifica se esistono dati da
              dichiarazioni ENC.
 RITORNA:     varchar2              Tipo caricamento:
                                    M - Caricamento MUI
                                    E - Caricamento dichiarazioni ENC
                                    Null - nessun dato caricamento
 NOTE:
 Rev.    Date         Author      Note
 000     03/10/2018   VD          Prima emissione.
*************************************************************************/
(p_oggetto_pratica                number
,p_cod_fiscale                    varchar2
,p_tipo_tributo                   varchar2
,p_pratica                        number   default null
)
  return varchar2
is
  w_return                        varchar2(1);
begin
  if p_pratica is null then
     begin
       select 'M'
         into w_return
         from dual
        where exists (select 'x' from ATTRIBUTI_OGCO atog
                       where atog.cod_fiscale = p_cod_fiscale
                         and atog.oggetto_pratica = p_oggetto_pratica);
     exception
       when others then
         w_return := null;
     end;
   --
     if w_return is null then
        begin
          select 'E'
            into w_return
            from dual
           where exists (select 'x' from WRK_ENC_IMMOBILI wrke
                          where decode(p_tipo_tributo,'ICI',wrke.tr4_oggetto_pratica_ici
                                                           ,wrke.tr4_oggetto_pratica_tasi) = p_oggetto_pratica
                            and wrke.tipo_immobile = 'B');
        exception
          when others then
            w_return := null;
        end;
     end if;
  else
     begin
       select 'E'
         into w_return
         from dual
        where exists (select 'x' from WRK_ENC_TESTATA wrkt
                       where decode(p_tipo_tributo,'ICI',wrkt.tr4_pratica_ici
                                                        ,wrkt.tr4_pratica_tasi) = p_pratica);
     exception
       when others then
         w_return := null;
     end;
  end if;
--
  return w_return;
--
end;
/* End Function: F_ESISTE_DATO_CARICAMENTO */
/

