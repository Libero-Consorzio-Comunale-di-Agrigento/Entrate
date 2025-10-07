--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_data_fine_ogco stripComments:false runOnChange:true 
 
create or replace function F_GET_DATA_FINE_OGCO
( p_tipo_tributo           varchar2
, p_cod_fiscale            varchar2
, p_oggetto                number
, p_da_mese_possesso       number
, p_mesi_possesso          number
, p_flag_possesso          varchar2
, p_anno_ogco              number
, p_anno                   number
) return date
is
  w_data_fine              date;
  w_mese                   number;
  w_mesi_possesso_succ     number;
  w_da_mese_possesso_succ  number;
begin
  if p_anno = p_anno_ogco then
     if nvl(p_mesi_possesso,12) = 0 then
        if nvl(p_da_mese_possesso,0) = 0 or nvl(p_da_mese_possesso,0) > 12 then
           if nvl(p_flag_possesso,'N') = 'S' then
              w_mese := 12;
           else
              w_mese := 1;
           end if;
        else
           w_mese := p_da_mese_possesso + p_mesi_possesso - 1;
        end if;
     else
        if nvl(p_da_mese_possesso,0) = 0 or nvl(p_da_mese_possesso,0) > 12 then
           if nvl(p_flag_possesso,'N') = 'S' then
              w_mese := 12;
           else
              w_mese := p_mesi_possesso;
           end if;
        else
           w_mese := p_da_mese_possesso + p_mesi_possesso - 1;
        end if;
     end if;
  else
     -- Si controlla se esiste un ogco per l'anno da trattare
     select min(da_mese_possesso)
       into w_da_mese_possesso_succ
       from pratiche_tributo prtr,
            oggetti_pratica  ogpr,
            oggetti_contribuente ogco
      where prtr.cod_fiscale = p_cod_fiscale
        and prtr.tipo_tributo = p_tipo_tributo
        and prtr.pratica = ogpr.pratica
        and ((prtr.data_notifica is not null and
               prtr.tipo_pratica||'' = 'A' and
               nvl(prtr.stato_accertamento,'D') = 'D' and
               nvl(prtr.flag_denuncia,' ')      = 'S')
           or (prtr.data_notifica is null and
               prtr.tipo_pratica||'' = 'D')
             )
        and ogpr.oggetto_pratica = ogco.oggetto_pratica
        --and ogco.flag_possesso = 'S'
        and prtr.anno = p_anno
        and ogpr.oggetto = p_oggetto;
     if w_da_mese_possesso_succ is null then
        w_mese := 12;
     else
        w_mese := w_da_mese_possesso_succ - 1;
     end if;
  end if;
--
  if nvl(w_mese,0) < 1 or nvl(w_mese,0) > 12 then
     w_data_fine := to_date(null);
  else
     w_data_fine := last_day(to_date('01'||lpad(w_mese,2,'0')||p_anno,'ddmmyyyy'));
  end if;
  return w_data_fine;
--
end;
/* End Function: F_GET_DATA_FINE_OGCO */
/

