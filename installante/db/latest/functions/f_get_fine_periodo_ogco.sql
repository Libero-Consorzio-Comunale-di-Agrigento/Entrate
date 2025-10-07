--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_fine_periodo_ogco stripComments:false runOnChange:true 
 
create or replace function F_GET_FINE_PERIODO_OGCO
/*************************************************************************
 NOME:        F_GET_FINE_PERIODO_OGCO
 DESCRIZIONE: Determina la data di fine validità del periodo di
              oggetti_contribuente.
              Utilizzata nella vista OGGETTI_CONTRIBUENTE_ANNO.
 RITORNA:     date                Data di fine validita del periodo OGCO.
 NOTE:
 Rev.    Date         Author      Note
 003     28/12/2022   AB          Gestito nvl(mesi possesso,12) e non 0
                                  Sistemato il caso di mesi_poss 0 e il da_mese 1,
                                  deve finire il 3101 e non il 3112
 002     16/12/2021   AB          Impostato giorno = 0 per mesi_possesso 0
 001     15/03/2021   VD          Corretta gestione mesi possesso > 12 e
                                  da_mese_possesso < 0.
 000     11/07/2019   VD          Prima emissione.
*************************************************************************/
( p_tipo_tributo           varchar2
, p_cod_fiscale            varchar2
, p_oggetto                number
, p_da_mese_possesso       number
, p_mesi_possesso          number
, p_flag_possesso          varchar2
, p_anno_ogco              number
) return date
is
  w_data_fine              date;
  w_giorno                 number;
  w_mese                   number;
  w_anno                   number;
  w_da_mese_possesso_succ  number;
begin
  -- Si seleziona l'eventuale ogco successivo: se il flag_possesso
  -- del periodo che si sta trattando è 'S', si considerano solo
  -- periodi di anni successivi
  select min(prtr.anno||lpad(nvl(da_mese_possesso,1),2,0))
    into w_da_mese_possesso_succ
    from pratiche_tributo prtr,
         oggetti_pratica  ogpr,
         oggetti_contribuente ogco
   where ogco.cod_fiscale = p_cod_fiscale
     and prtr.tipo_tributo = p_tipo_tributo
     and prtr.pratica = ogpr.pratica
     and ((prtr.data_notifica is not null and
           prtr.tipo_pratica||'' = 'A' and
           nvl(prtr.stato_accertamento,'D') = 'D' and
           nvl(prtr.flag_denuncia,' ')      = 'S'
          )
       or (prtr.data_notifica is null and
           prtr.tipo_pratica||'' = 'D'
          )
         )
     and ogpr.oggetto_pratica = ogco.oggetto_pratica
     and ((p_flag_possesso = 'S' and prtr.anno > p_anno_ogco) or
          (nvl(p_flag_possesso,'N') = 'N' and
           prtr.anno = p_anno_ogco and
           nvl(ogco.da_mese_possesso,0) > p_da_mese_possesso))
     and ogpr.oggetto = p_oggetto;
  if w_da_mese_possesso_succ is null then
     if nvl(p_mesi_possesso,12) = 0 then
        if nvl(p_da_mese_possesso,0) between 1 and 12 then
           w_giorno := 0;
           w_mese := p_da_mese_possesso;
           if nvl(p_flag_possesso,'N') = 'S' then
              w_anno := 9999;
           else
             --w_giorno := 15;
              w_anno := p_anno_ogco;
--              case to_number(to_char(last_day(to_date('01'||lpad(w_mese,2,'0')||w_anno,'ddmmyyyy')),'dd'))
--                   when 28 then w_giorno := 15;
--                   when 29 then w_giorno := 15;
--                   when 30 then w_giorno := 16;
--                   when 31 then w_giorno := 16;
--              end case;
           end if;
        else
           if nvl(p_flag_possesso,'N') = 'S' then
              w_giorno := 31;
              w_mese := 12;
              w_anno := 9999;
           else
              w_giorno := 16;
              w_mese := 1;
              w_anno := p_anno_ogco;
           end if;
        end if;
     else
        w_giorno := 0;
        if nvl(p_flag_possesso,'N') = 'S' then
           w_mese := 12;
           w_anno := 9999;
        else
           w_anno := p_anno_ogco;
           if nvl(p_da_mese_possesso,0) between 1 and 12 then
              w_mese := p_da_mese_possesso + nvl(p_mesi_possesso,12) - 1;
           else
              w_mese := 12;
           end if;
        end if;
     end if;
  else
     w_giorno := 0;
-- modifica di AB 17/07/2019  da verificare
--     w_mese := to_number(substr(to_char(w_da_mese_possesso_succ),5,2)) - 1;
--     w_anno := to_number(substr(to_char(w_da_mese_possesso_succ),1,4));
--     if w_mese = 0 then
--        w_mese := 12;
--        w_anno := w_anno - 1;
--     end if;
     if nvl(p_flag_possesso,'N') = 'S' then
        if to_number(substr(to_char(w_da_mese_possesso_succ),5,2)) > 0 then
           w_mese := to_number(substr(to_char(w_da_mese_possesso_succ),5,2)) - 1;
        else
           w_mese := 1;
        end if;
        w_anno := to_number(substr(to_char(w_da_mese_possesso_succ),1,4));
        -- Se il periodo trovato è di un anno successivo e il mese di inizio
        -- non è 1, si valorizza la data fine periodo con il 31/12 dell'anno
        -- precedente al periodo trovato
        if w_anno > p_anno_ogco then
           if w_mese > 1 then
              w_mese := 12;
              w_anno := w_anno - 1;
           end if;
        end if;
        if w_mese = 0 then
           w_mese := 12;
           w_anno := w_anno - 1;
        end if;
     else
        if nvl(p_mesi_possesso,12) between 0 and 12 and  -- controllato anche il mesi_possesso = 0
           nvl(p_da_mese_possesso,0) between  1 and 12 then
           w_mese := p_da_mese_possesso + nvl(p_mesi_possesso,12) - 1;
           w_anno := p_anno_ogco;
        end if;
     end if;
-- fine modifica AB
  end if;
--  28/12/2022 AB per gestire il da_mese 1 con mp 0 prima la fine veniva il 31/12 dell'anno
--  if nvl(w_mese,0) < 1 or nvl(w_mese,0) > 12 then
--     w_data_fine := to_date('3112'||p_anno_ogco,'ddmmyyyy'); --to_date(null);
  if nvl(w_mese,0) < 1 then
     w_data_fine := to_date('3101'||p_anno_ogco,'ddmmyyyy'); --to_date(null);
  elsif nvl(w_mese,0) > 12 then
     w_data_fine := to_date('3112'||p_anno_ogco,'ddmmyyyy'); --to_date(null);
  else
     if w_giorno = 0 then
        w_data_fine := last_day(to_date('01'||lpad(w_mese,2,'0')||w_anno,'ddmmyyyy'));
     else
--        dbms_output.put_line('w_giorno: '||w_giorno||' w_mese: ' ||w_mese);
        w_data_fine := to_date(lpad(w_giorno,2,'0')||lpad(w_mese,2,'0')||w_anno,'ddmmyyyy');
     end if;
  end if;
  return w_data_fine;
--
end;
/* End Function: F_GET_FINE_PERIODO_OGCO */
/

