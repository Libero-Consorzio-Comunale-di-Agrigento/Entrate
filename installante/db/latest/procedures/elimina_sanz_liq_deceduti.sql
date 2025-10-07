--liquibase formatted sql 
--changeset abrandolini:20250326_152423_elimina_sanz_liq_deceduti stripComments:false runOnChange:true 
 
create or replace procedure ELIMINA_SANZ_LIQ_DECEDUTI
/*************************************************************************
 NOME:        ELIMINA_SANZ_LIQ_DECEDUTI
 DESCRIZIONE: Elimina le sanzioni della pratica indicata lasciando solo
              imposta evasa, interessi e spese di notifica.
 NOTE:        Richiamata dalle procedure di calcolo liquidazione IMU/TASI
 Rev.    Date         Author      Note
 000     25/08/2022   VD          Prima emissione.
*************************************************************************/
( p_pratica                   number
) is
begin
  begin
    delete from sanzioni_pratica sapr
     where sapr.pratica          = p_pratica
       and sapr.cod_sanzione    in (select sanz.cod_sanzione
                                      from sanzioni sanz
                                     where sanz.tipo_tributo    = sapr.tipo_tributo
                                       and nvl(sanz.tipo_causale, 'X') not in ('E','I','S'));
  exception
    when others then
      raise_application_error(-20999,'Delete SANZIONI_PRATICA (Pratica n. '||p_pratica||
                                     ' - '||sqlerrm);
  end;
end;
/* End Procedure: ELIMINA_SANZ_LIQ_DECEDUTI */
/

