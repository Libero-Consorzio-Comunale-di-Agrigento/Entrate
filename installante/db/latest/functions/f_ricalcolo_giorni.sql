--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ricalcolo_giorni stripComments:false runOnChange:true 
 
create or replace function F_RICALCOLO_GIORNI
/*************************************************************************
 NOME:        F_RICALCOLO_GIORNI
 DESCRIZIONE: Date le seguenti informazioni:
              data da confrontare
              data di riferimento
              tipo tributo
              si sommano ai giorni di riferimento gli eventuali giorni
              compresi nel periodo di sospensione feriale
 RITORNA:     numero giorni           ricalcolato
 NOTE:
 Rev.    Date         Author      Note
 002     05/05/2017   VD          Aggiunto azzeramento variabile w_add_gg
                                  (in mancanza di versamenti le date da
                                   confrontare sono uguali e la funzione
                                   restituiva null)
 002     27/10/2016   VD          Corretta gestione giorni da aggiungere
                                  al periodo di
 001     26/08/2015   VD          Prima emissione.
*************************************************************************/
( p_data              date
, p_data_confronto    date
, p_tipo_tributo      varchar2
)
  return number
is
  w_num_gg            number;
  w_add_gg            number;
  w_data_in           date;
  w_data_fi           date;
begin
  w_num_gg := 60;
  w_add_gg := 0;
  if nvl(p_tipo_tributo,'XXXXX') = '90' or
    (nvl(p_tipo_tributo,'XXXXX') = 'ICI' and
     p_data <= to_date('31122006','ddmmyyyy')) then
     w_num_gg := 90;
  end if;
--
-- Se la data da assestare e' di un anno diverso dall'anno corrente
-- non si fanno modifiche
-- Nota: se la data di notifica e' futura, la pratica non e' da trattare
--       Se e' di un anno precedente, allo stato attuale i periodi di
--       sospensione si possono non considerare in quanto comunque il limite
--       dei 60/90 gg e' sicuramente superato. Il problema si potrebbe porre
--       se il periodo di sospensione fosse prossimo alla fine o all'inizio
--       dell'anno.
--
--
  if to_number(to_char(p_data,'yyyy')) = to_number(to_char(sysdate,'yyyy'))
  and to_number(to_char(p_data_confronto,'yyyy')) = to_number(to_char(sysdate,'yyyy'))
  and p_data <= p_data_confronto then
     --
     -- Si seleziona da INSTALLAZIONE_PARAMETRI il periodo di sospensione ferie
     --
     begin
       select to_date(substr(valore,1,5)||'/'||to_char(sysdate,'yyyy'),'dd/mm/yyyy')
            , to_date(substr(valore,7,5)||'/'||to_char(sysdate,'yyyy'),'dd/mm/yyyy')
         into w_data_in
            , w_data_fi
         from INSTALLAZIONE_PARAMETRI
        where parametro = 'SOSP_FERIE';
     exception
       when others then
         w_data_in := to_date(null);
         w_data_fi := to_date(null);
     end;
     --
     if w_data_in is not null and
        w_data_fi is not null then
        if p_data between w_data_in and w_data_fi then
           w_add_gg := w_data_fi - p_data + 1;
        elsif p_data <= w_data_fi and
           p_data_confronto >= w_data_in then
           w_add_gg := w_data_fi - w_data_in + 1;
        end if;
        w_num_gg := w_num_gg + w_add_gg;
     end if;
  end if;
--
  return w_num_gg;
--
end;
/* End Function: F_RICALCOLO_GIORNI */
/

