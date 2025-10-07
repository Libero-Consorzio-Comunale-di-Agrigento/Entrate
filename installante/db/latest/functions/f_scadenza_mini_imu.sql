--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_scadenza_mini_imu stripComments:false runOnChange:true 
 
create or replace function F_SCADENZA_MINI_IMU
/*************************************************************************
 NOME:        F_SCADENZA_MINI_IMU
 DESCRIZIONE: Determina la scadenza della mini IMU
 PARAMETRI:   Anno
              Pratica
 RITORNA:     date              Data scadenza mini IMU
 NOTE:
 Rev.    Date         Author      Note
 000     06/07/2016   VD          Prima emissione.
*************************************************************************/
(p_anno             number
,p_pratica          number
)
 return date
is
  w_data_scadenza    date;
  w_tipo_tributo     varchar2(5) := 'ICI';
  w_tipo_aliquota    tipi_aliquota.tipo_aliquota%type;
begin
  --
  -- Si seleziona il max(tipo_aliquota) da oggetti_imposta della
  -- pratica per verificare se si tratta di mini IMU
  --
  begin
    select max(tipo_aliquota)
      into w_tipo_aliquota
      from oggetti_pratica ogpr
         , oggetti_imposta ogim
     where ogpr.pratica = p_pratica
       and ogpr.oggetto_pratica = ogim.oggetto_pratica
       and ogim.imposta_mini is not null
     group by ogpr.pratica;
  exception
    when others then
      w_tipo_aliquota := to_number(null);
  end;
  --
  if w_tipo_aliquota is not null then
     begin
       select scadenza_mini_imu
       into   w_data_scadenza
       from   aliquote
       where  anno          = p_anno
       and    tipo_tributo  = w_tipo_tributo
       and    tipo_aliquota = w_tipo_aliquota
       ;
     exception
        when others
           then w_data_scadenza := to_date(null);
     end;
  else
     w_data_scadenza := to_date(null);
  end if;
  return w_data_scadenza;
end;
/* End Function: F_SCADENZA_MINI_IMU */
/

