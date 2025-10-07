--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_imu_saldo stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_IMU_SALDO
/*************************************************************************
 NOME:        F_CALCOLO_IMU_SALDO
 DESCRIZIONE: Calcolo importo IMU a saldo come da art. 78 del
              D.L. 14 agosto 2020, n. 104 (utilizzando il campo perc_saldo
              presente in tabella ALIQUOTE)
 NOTE:
  Rev.    Date         Author      Note
  0       23/10/2020   VD          Prima emissione
*************************************************************************/
( a_tipo_tributo                   varchar2
, a_anno                           number
, a_tipo_aliquota                  number
, a_imposta                        number
, a_imposta_acconto                number
, a_imposta_erar                   number
, a_imposta_erar_acconto           number
, a_perc_saldo              in out number
, a_imposta_saldo           in out number
, a_imposta_erar_saldo      in out number
, a_note_saldo              in out varchar2
)
is
  w_perc_saldo                     number;
  w_imposta                        number;
  w_imposta_erar                   number;
  w_note_saldo                     varchar2(200);
begin
  w_perc_saldo := to_number(null);
  w_imposta    := a_imposta;
  w_note_saldo := null;
  --
  if a_tipo_tributo = 'ICI' and a_anno >= 2020 then
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
        w_imposta      := round((a_imposta - a_imposta_acconto) * w_perc_saldo / 100,2);
        w_imposta      := w_imposta + a_imposta_acconto;
        if a_imposta_erar is not null then
           w_imposta_erar := round((a_imposta_erar - a_imposta_erar_acconto) * w_perc_saldo / 100,2);
           w_imposta_erar := w_imposta_erar + a_imposta_erar_acconto;
        else
           w_imposta_erar := to_number(null);
        end if;
        w_note_saldo   := 'Perc.saldo '||ltrim(to_char(w_perc_saldo,'990D00'));
     end if;
  end if;
  --
  a_perc_saldo         := w_perc_saldo;
  a_imposta_saldo      := w_imposta;
  a_imposta_erar_saldo := w_imposta_erar;
  a_note_saldo         := w_note_saldo;
  --
end;
/* End Procedure: CALCOLO_IMU_SALDO */
/

