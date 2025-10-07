--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_tares stripComments:false runOnChange:true 
 
create or replace function F_F24_TARES
(a_riga                number
,a_importo_tares       number
,a_num_fabb_tares      number
,a_maggiorazione_tares number
,a_se_stampa_trib      varchar2
,a_se_stampa_magg      varchar2
,a_saldo               varchar2
)
return varchar2
is
w_tares            varchar2(19);
w_magg_tares       varchar2(19);
TYPE type_riga IS TABLE OF varchar2(19)
INDEX BY binary_integer;
t_riga       type_riga;
i            binary_integer := 1;
begin
   w_tares  := '3944'||to_char(round(a_importo_tares,0),'999999990')||to_char(a_num_fabb_tares,'990');
   w_magg_tares  := '3955'||to_char(round(a_maggiorazione_tares,0),'999999990');
   if nvl(a_importo_tares,0) > 0.49
      and nvl(a_se_stampa_trib,' ') = 'S' then
      t_riga(to_char(i)) := w_tares;
      i := i+1;
   end if;
   if nvl(a_maggiorazione_tares,0) > 0.49
      and nvl(a_se_stampa_magg,' ') = 'S'
      and nvl(a_saldo,' ') = 'S' then
      t_riga(to_char(i)) := w_magg_tares;
      i := i+1;
   end if;
   return t_riga(to_char(a_riga));
end;
/* End Function: F_F24_TARES */
/

