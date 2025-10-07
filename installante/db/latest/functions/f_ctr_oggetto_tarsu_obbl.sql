--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ctr_oggetto_tarsu_obbl stripComments:false runOnChange:true 
 
create or replace function F_CTR_OGGETTO_TARSU_OBBL
(a_categoria     in varchar2
,a_tipo_tariffa  in varchar2
) return varchar2
is
nConta      number;
BEGIN
  if a_categoria = '0' then
     Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Scegliere una Categoria per i Locali e Aree occupate.</div>';
  end if;
  if a_tipo_tariffa = '0' then
      Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Scegliere una Tariffa per i Locali e Aree occupate.</div>';
  end if;
  Return '';
END;
/* End Function: F_CTR_OGGETTO_TARSU_OBBL */
/

