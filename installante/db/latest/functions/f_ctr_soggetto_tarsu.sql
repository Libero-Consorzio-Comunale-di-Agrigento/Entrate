--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ctr_soggetto_tarsu stripComments:false runOnChange:true 
 
create or replace function F_CTR_SOGGETTO_TARSU
(a_contribuente     in varchar2
,a_cognome          in varchar2
,a_nome             in varchar2
,a_cod_fiscale      in varchar2
,a_ragione_sociale  in varchar2
,a_partita_iva      in varchar2
) return varchar2
is
nConta      number;
BEGIN
  if nvl(a_contribuente,' ') not in ('1','2') then
     Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Scegliere se Persona Fisica o Persona Giuridica.</div>';
  end if;
  if nvl(a_contribuente,' ') = '1' then
     if a_cognome is null then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Inserire il Cognome del Beneficiario.</div>';
     end if;
     if a_nome is null then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Inserire il Nome del Beneficiario.</div>';
     end if;
     if a_cod_fiscale is null then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Inserire il Codice Fiscale del Beneficiario.</div>';
     end if;
  end if;
  if nvl(a_contribuente,' ') = '2'  then
     if a_ragione_sociale is null then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Inserire la Ragione Sociale del Beneficiario.</div>';
     end if;
     if a_partita_iva is null then
        Return 'ADS_MSG_ERROR=<div class="AFCErrorDataTD" >Inserire la Partita IVA del Beneficiario.</div>';
     end if;
  end if;
  Return '';
END;
/* End Function: F_CTR_SOGGETTO_TARSU */
/

