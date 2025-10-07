--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_oggetto_imu stripComments:false runOnChange:true 
 
create or replace function F_CHECK_OGGETTO_IMU
/*************************************************************************
 NOME:        F_CHECK_OGGETTO_IMU
 DESCRIZIONE: Dati id. immobile ed estremi catastali, verifica se
              esistono oggetti abbinati a questi dati e se si',
              verifica che esistano denunce IMU per l'oggetto/gli oggetti.
 RITORNA:     varchar2              'S' se esiste almeno un record,
                                    altrimenti null
 NOTE:
 Rev.    Date         Author      Note
 00      02/03/2020   VD          Prima emissione.
*************************************************************************/
( p_id_immobile            number
, p_estremi_catasto        varchar2
) return number is
  d_esiste_oggetto         number;
begin
  if p_id_immobile is null and
     p_estremi_catasto is null then
     d_esiste_oggetto := 0;
  else
  -- Per ogni oggetto abbinato a id.immobile e/o estremi catasto,
  -- si verifica se esiste una denuncia per il tipo tributo indicato
     for ogge in (select oggetto
                    from oggetti
                   where tipo_oggetto = 3
                     and (id_immobile = p_id_immobile or
                          estremi_catasto = p_estremi_catasto)
                   order by 1)
     loop
       begin
        select 1
          into d_esiste_oggetto
          from dual
         where exists (select 'x'
                         from oggetti_pratica ogpr,
                              pratiche_tributo prtr
                        where prtr.tipo_tributo = 'ICI'
                          and prtr.tipo_pratica = 'D'
                          and prtr.pratica      = ogpr.pratica
                          and ogpr.oggetto      = ogge.oggetto);
       exception
         when others then
           d_esiste_oggetto := 0;
       end;
       --
       if d_esiste_oggetto = 1 then
          exit;
       end if;
     end loop;
  end if;
--
  return d_esiste_oggetto;
--
end;
/* End Function: F_CHECK_OGGETTO_IMU */
/

