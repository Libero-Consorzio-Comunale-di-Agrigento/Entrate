--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_mesi_ab_princ stripComments:false runOnChange:true 
 
create or replace function F_GET_MESI_AB_PRINC
/*************************************************************************
 NOME:        F_GET_MESI_AB_PRINC
 DESCRIZIONE: Determina il numero di mesi in cui l'immobile è stato abitazione
              principale del contribuente nel periodo indicato.
 RITORNA:     number              Numero di mesi abitazione principale
 NOTE:
 Rev.    Date         Author      Note
 000     29/05/2019   VD          Prima emissione.
*************************************************************************/
( a_tipo_tributo           varchar2
, a_cod_fiscale            varchar2
, a_anno                   number
, a_oggetto_pratica        number
, a_flag_ab_principale     varchar2
, a_data_da                date
, a_data_a                 date
) return number
as
  w_mesi                   number;
      w_mese_inizio            number;
      w_mese_fine              number;
  w_flag_ab_princ          varchar2(1);
begin
--
-- Si controlla l'esistenza di una detrazione per l'oggetto_pratica:
-- se esiste, significa che l'immobile e' abitazione principale anche
-- in assenza di flag
--
  if a_flag_ab_principale is null then
               select min('S')
                     into w_flag_ab_princ
                     from detrazioni_ogco
                  where cod_fiscale = a_cod_fiscale
                        and oggetto_pratica = a_oggetto_pratica
                        and anno = a_anno
                        and tipo_tributo = a_tipo_tributo;
      else
         w_flag_ab_princ := a_flag_ab_principale;
    end if;
--
  if w_flag_ab_princ = 'S' then
     if a_data_da < to_date('0101'||a_anno,'ddmmyyyy') then
        w_mese_inizio := 1;
     else
        w_mese_inizio := to_number(to_char(a_data_da,'mm'));
                        if to_number(to_char(a_data_da,'dd')) > 15 then
                                 w_mese_inizio := w_mese_inizio + 1;
                        end if;
               end if;
     --
               if a_data_a > to_date('3112'||a_anno,'ddmmyyyy') then
                        w_mese_fine := 12;
               else
                        w_mese_fine := to_number(to_char(a_data_a,'mm'));
                        if to_number(to_char(a_data_a,'dd')) <= 15 then
                                 w_mese_fine := w_mese_fine - 1;
                        end if;
               end if;
     --
     w_mesi := w_mese_fine - w_mese_inizio + 1;
  else
     w_mesi := 0;
  end if;
--
  return w_mesi;
--
end;
/* End Function: F_GET_MESI_AB_PRINC */
/

