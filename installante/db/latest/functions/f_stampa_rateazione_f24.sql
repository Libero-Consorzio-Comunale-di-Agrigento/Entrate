--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_stampa_rateazione_f24 stripComments:false runOnChange:true 
 
create or replace function F_STAMPA_RATEAZIONE_F24
/*************************************************************************
    Se la stampa della rateazione è richiesta o è facoltativa ma per
    default se ne richiede la stampa restituisce la rateazione nella forma
    NNRR altrimenti ''.
    Rev.    Date         Author      Note
    002     09/03/2023   DM          Per le rateazioni si può richiedere la
                                     stampa anche per i codici tributo che
                                     non lo prevedono.
    001     25/01/2023   DM          Versione iniziale.
  *************************************************************************/
(a_tipo_tributo in varchar2,
 a_anno         in number,
 a_tributo_f24  in varchar2,
 a_rata         in number,
 a_rate_tot     in number,
 a_rateazione   in varchar2 default null) return varchar2 is
  w_rateazione  varchar2(4);
  w_valore_rateazione varchar2(4);
  w_flag_stampa varchar2(1);
begin
  select codi.rateazione, codi.flag_stampa_rateazione
    into w_rateazione, w_flag_stampa
    from codici_f24 codi
   where codi.tributo_f24 = a_tributo_f24
     and codi.tipo_tributo = a_tipo_tributo
     and codi.descrizione_titr =
         decode(a_tributo_f24,
                'TEFA',
                a_tributo_f24,
                f_descrizione_titr(a_tipo_tributo, a_anno));
  w_valore_rateazione := lpad(to_char(a_rata), 2, '0') ||
                         lpad(to_char(a_rate_tot), 2, '0');
  -- Se rateazione ed è configurato in installazione aprametri
  if (nvl(a_rateazione, 'N') = 'S' and nvl(f_inpa_valore('RATE_NNRR'), 'N') = 'S') then
   return w_valore_rateazione;
  elsif (w_rateazione = 'NNRR' or
        (w_rateazione = 'FFFF' and w_flag_stampa = 'S')) then
    -- Rateazione obbligatoria o facoltativa ma richiesta la stampa
    return w_valore_rateazione;
  elsif (w_rateazione = '0' or
     (w_rateazione = 'FFFF' and w_flag_stampa is null)) then
     -- Da non stamparea
    return '';
  end if;
  return '';
end;
/* End Function: F_STAMPA_RATEAZIONE_F24 */
/

