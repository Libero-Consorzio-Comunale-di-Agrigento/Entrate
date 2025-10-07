--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_riog_valido stripComments:false runOnChange:true 
 
create or replace function F_RIOG_VALIDO
/*************************************************************************
  Rev.    Date         Author      Note
  1       21/04/2015   PM          Creazione funzione che mi indica se il periodo della
                                   riga di riog è intersecante i mesi di possesso dell'oggetto
*************************************************************************/
(p_inizio_validita    date
,p_fine_validita      date
,p_mesi_possesso      number
,p_mesi_possesso_1sem number
,p_flag_possesso      varchar2
,p_anno               number
) return varchar2 is
  w_inizio_validita_riog  date;
  w_fine_validita_riog    date;
  w_inizio_possesso       date;
  w_fine_possesso         date;
begin
   if nvl(p_mesi_possesso,0) <= 0 then
      return 'N';
   end if;
   if p_inizio_validita is null and p_fine_validita is null then
      return 'S';
   end if;
   if p_inizio_validita is null then
      w_inizio_validita_riog  := to_date('01011900','ddmmyyyy');
   else
      w_inizio_validita_riog  := p_inizio_validita;
   end if;
   if p_fine_validita is null then
      w_fine_validita_riog  := to_date('31129999','ddmmyyyy');
   else
      w_fine_validita_riog  := p_fine_validita;
   end if;
   if p_mesi_possesso >= 12 then
      w_inizio_possesso := to_date('0101'||to_char(p_anno),'ddmmyyyy');
      w_fine_possesso   := to_date('3112'||to_char(p_anno),'ddmmyyyy');
   else
      if p_flag_possesso = 'S' then
         w_inizio_possesso := to_date('01'||lpad(to_char(12 - p_mesi_possesso + 1),2,'0')||to_char(p_anno),'ddmmyyyy');
         w_fine_possesso   := to_date('3112'||to_char(p_anno),'ddmmyyyy');
      else
         if nvl(p_mesi_possesso_1sem,0) = 0 then
            w_inizio_possesso := to_date('01'||lpad(to_char(12 - p_mesi_possesso + 1),2,'0')||to_char(p_anno),'ddmmyyyy');
            w_fine_possesso   := to_date('3112'||to_char(p_anno),'ddmmyyyy');
         else
            if p_mesi_possesso > 6 or p_mesi_possesso > nvl(p_mesi_possesso_1sem,0) then
               w_inizio_possesso := to_date('01'||lpad(to_char(6 - p_mesi_possesso_1sem + 1),2,'0')||to_char(p_anno),'ddmmyyyy');
               w_fine_possesso   := last_day(to_date('01'||lpad(to_char(6 - p_mesi_possesso_1sem + p_mesi_possesso),2,'0')||to_char(p_anno),'ddmmyyyy'));
            else
               w_inizio_possesso := to_date('0101'||to_char(p_anno),'ddmmyyyy');
               w_fine_possesso   := last_day(to_date('01'||lpad(to_char(p_mesi_possesso),2,'0')||to_char(p_anno),'ddmmyyyy'));
            end if;
         end if;
      end if;
   end if;
   if w_inizio_possesso <= w_fine_validita_riog
     and
      w_fine_possesso >= w_inizio_validita_riog
         then
      return 'S';
   else
      return 'N';
   end if;
end f_riog_valido;
/* End Function: F_RIOG_VALIDO */
/

