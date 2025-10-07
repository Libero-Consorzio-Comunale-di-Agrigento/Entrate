--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ctr_oggetto_tarsu_opz stripComments:false runOnChange:true 
 
create or replace function F_CTR_OGGETTO_TARSU_OPZ
(a_categoria     in varchar2
,a_tipo_tariffa  in varchar2
,a_superficie    in varchar2
,a_foglio        in varchar2
,a_numero        in varchar2
,a_subalterno    in varchar2
) return varchar2
is
BEGIN
  if a_superficie is not null then
     if a_foglio is null then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Inserire il Foglio (Dati Catastali) per il box, garage o posti auto coperti.</div>';
     end if;
     if a_numero is null then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Inserire il Numero (Dati Catastali) per il box, garage o posti auto coperti.</div>';
     end if;
     if a_subalterno is null then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Inserire il Subalterno (Dati Catastali) per il box, garage o posti auto coperti.</div>';
     end if;
     if a_categoria = '0' then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Scegliere una Categoria per il box, garage o posti auto coperti.</div>';
     end if;
     if a_tipo_tariffa = '0' then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Scegliere una Tariffa per il box, garage o posti auto coperti.</div>';
     end if;
  end if;
  Return '';
END;
/* End Function: F_CTR_OGGETTO_TARSU_OPZ */
/

