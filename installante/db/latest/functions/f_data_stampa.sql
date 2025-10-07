--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_data_stampa stripComments:false runOnChange:true 
 
create or replace function F_DATA_STAMPA
(p_pratica number) return date is
/*************************************************************************
 NOME:        f_data_stampa
 DESCRIZIONE: estrae la data stampa per una data pratica.
 RITORNA:     date                Data di stampa.
 NOTE:
 Rev.    Date         Author      Note
 000     24/03/2020     DM        Prima emissione.
*************************************************************************/
  w_data_stampa date;
begin
  select data_stampa
    into w_data_stampa
    from (select atel.data_attivita data_stampa
            from dettagli_elaborazione deel, attivita_elaborazione atel
           where deel.stampa_id = atel.attivita_id
             and pratica = p_pratica
           order by 1 desc)
   where rownum = 1;
  return w_data_stampa;
end;
/* End Function: F_DATA_STAMPA */
/

