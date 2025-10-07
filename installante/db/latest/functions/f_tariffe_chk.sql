--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_tariffe_chk stripComments:false runOnChange:true 
 
create or replace function F_TARIFFE_CHK
/*************************************************************************
 NOME:        F_TARIFFE_CHK
 DESCRIZIONE: invoca la procedure  TARIFFE_CHK in forma di function
              per utilizzarla lato web.
 NOTE:
 Rev.    Date         Author      Note
 000     16/02/2022   DM          Prima emissione.
*************************************************************************/
( a_tipo_tributo            in     varchar2
 ,a_anno_ruolo              in     number
 ,a_cod_fiscale             in     varchar2
 ,a_tipo_calcolo            in     varchar2
 ,a_flag_tariffa_base       in     varchar2
 ,a_flag_tariffe_ruolo      in     varchar2)
 return tr4package.tariffe_errate_rc
 is
 w_result tr4package.tariffe_errate_rc;
begin
  tariffe_chk(a_tipo_tributo
             ,a_anno_ruolo
             ,a_cod_fiscale
             ,a_tipo_calcolo
             ,a_flag_tariffa_base
             ,a_flag_tariffe_ruolo
             ,w_result);
  return(w_result);
end;
/* End Function: F_TARIFFE_CHK */
/

