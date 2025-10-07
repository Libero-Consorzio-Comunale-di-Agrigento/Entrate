--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ruolo_totale stripComments:false runOnChange:true 
 
create or replace function F_RUOLO_TOTALE
(p_cod_fiscale    varchar2
,p_anno           number
,p_titr           varchar2
,p_tributo        number
)
return number
is
  /******************************************************************************
  Ritorna (se esiste) il ruolo totale per il contribuente e l'anno assegnati
  Se il tributo è diverso da 'TARSU', o il ruolo totale non esiste ritorna null
  Se c'è più di un ruolo totale ritorna l'ultimo emesso
  P_tributo: -1 = tutti i tributi
  ******************************************************************************/
  w_ruolo         number;
  cursor sel_ruolo
  is
      select ruoli.ruolo
        from ruoli, ruoli_contribuente ruco
       where nvl(ruoli.tipo_emissione, 'T') = 'T'
         and ruoli.ruolo = ruco.ruolo
         and ruco.cod_fiscale = p_cod_fiscale
         and ruoli.anno_ruolo = p_anno
         and nvl(ruco.tributo, 0) = decode(p_tributo, -1, nvl(ruco.tributo, 0), p_tributo)
         and ruoli.invio_consorzio is not null
         and ruoli.specie_ruolo = 0
    order by ruoli.data_emissione desc;
begin
  w_ruolo :=    null;
  if p_titr = 'TARSU' and p_anno >= 2013 then
    /* ho bisogno di estrarre un solo ruolo totale (se c'è) e vorrei estrarre
       l'ultimo emesso. Per questo ho usato un cursore da cui leggo solo la prima
       riga, in questo modo evito una subquery per estrarre la max data
      Prima del 2013 dobbiamo prendere tutti i ruoli perchè il ruolo totale
      non esisteva
    */
    open sel_ruolo;
    fetch sel_ruolo into w_ruolo;
    close sel_ruolo;
  end if;
  return w_ruolo;
end;
/* End Function: F_RUOLO_TOTALE */
/

