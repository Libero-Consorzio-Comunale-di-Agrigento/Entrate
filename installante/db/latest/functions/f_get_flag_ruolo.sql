--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_flag_ruolo stripComments:false runOnChange:true 
 
create or replace function F_GET_FLAG_RUOLO
(p_pratica      in number
)
  return varchar
is
  w_flag_ruolo          varchar2(1);
/******************************************************************************
Restituisce il max(flag ruolo) relativo alla pratica data
Usata in CALCOLO_ACC_AUTOMATICO_TARSU per il corretto calcolo del totale
sanzioni ai fini dell'applicazione dei limiti
******************************************************************************/
begin
  begin
    select nvl(max(nvl(cotr.flag_ruolo,'N')),'N')
      into w_flag_ruolo
      from codici_tributo          cotr
          ,oggetti_pratica         ogpr
     where cotr.tributo            = ogpr.tributo
       and ogpr.pratica            = p_pratica;
  exception
    when others
    then
      w_flag_ruolo :=   'N';
  end;
  return w_flag_ruolo;
end;
/* End Function: F_GET_FLAG_RUOLO */
/

