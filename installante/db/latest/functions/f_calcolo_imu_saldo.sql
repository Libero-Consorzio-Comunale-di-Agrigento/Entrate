--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_calcolo_imu_saldo stripComments:false runOnChange:true 
 
create or replace function F_CALCOLO_IMU_SALDO
/*************************************************************************
 NOME:        F_CALCOLO_IMU_SALDO
 DESCRIZIONE: Calcolo importo IMU a saldo come da art. 78 del
              D.L. 14 agosto 2020, n. 104 (utilizzando il campo perc_saldo
              presente in tabella ALIQUOTE
 NOTE:
  Rev.    Date         Author      Note
  0       23/10/2020   VD          Prima emissione
*************************************************************************/
( a_tipo_tributo                   varchar2
, a_anno                           number
, a_tipo_aliquota                  number
, a_imposta                        number
, a_imposta_acconto                number
)
return number
is
  w_perc_saldo                     number;
  w_imposta                        number;
begin
  -- Selezione perc_saldo da tabella ALIQUOTE
  begin
    select perc_saldo
      into w_perc_saldo
      from aliquote
     where tipo_tributo = a_tipo_tributo
       and anno = a_anno
       and tipo_aliquota = a_tipo_aliquota;
  exception
    when others then
      w_perc_saldo := null;
  end;
  if w_perc_saldo is not null then
     w_imposta := round((a_imposta - a_imposta_acconto) * w_perc_saldo / 100,2);
     w_imposta := w_imposta + a_imposta_acconto;
  else
     w_imposta := a_imposta;
  end if;
  --
  return w_imposta;
  --
end;
/* End Function: F_CALCOLO_IMU_SALDO */
/

