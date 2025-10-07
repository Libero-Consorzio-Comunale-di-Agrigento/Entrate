--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_tipo_imu stripComments:false runOnChange:true 
 
create or replace function F_GET_TIPO_IMU
/*************************************************************************
 NOME:        F_GET_TIPO_IMU
 DESCRIZIONE: Determina se gli oggetti di una pratica sono tutti soggetti
              a mini IMU, tutti soggetti a IMU oppure misti
 PARAMETRI:   Pratica
 RITORNA:     number              O - Misti
                                  1 - Solo IMU
                                  2 - Solo mini IMU
 NOTE:
 Rev.    Date         Author      Note
 000     06/07/2016   VD          Prima emissione.
*************************************************************************/
(p_pratica            number
)
 return number
is
  w_tipo_imu          number;
  w_num_oggetti       number;
  w_num_oggetti_mini  number;
  w_num_oggetti_imu   number;
begin
  --
  -- Si contano il numero degli oggetti nella pratica,
  -- il numero di oggetti soggetti a IMU e il numero
  -- degli oggetti soggetti a mini IMU
  --
  begin
    select count(*)
         , sum(decode(imposta_mini,null,1,0))
         , sum(decode(imposta_mini,null,0,1))
      into w_num_oggetti
         , w_num_oggetti_imu
         , w_num_oggetti_mini
      from oggetti_pratica ogpr
         , oggetti_imposta ogim
     where ogpr.pratica = p_pratica
       and ogpr.oggetto_pratica = ogim.oggetto_pratica
     group by ogpr.pratica;
  exception
    when others then
      w_num_oggetti      := to_number(null);
      w_num_oggetti_mini := to_number(null);
      w_num_oggetti_imu  := to_number(null);
  end;
  --
  if w_num_oggetti is not null then
     if w_num_oggetti = w_num_oggetti_imu then
        w_tipo_imu := 1;
     elsif
        w_num_oggetti = w_num_oggetti_mini then
        w_tipo_imu := 2;
     else
        w_tipo_imu := 0;
     end if;
  else
     w_tipo_imu := 1;
  end if;
  return w_tipo_imu;
end;
/* End Function: F_GET_TIPO_IMU */
/

