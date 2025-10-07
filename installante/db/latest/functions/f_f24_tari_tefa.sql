--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_tari_tefa stripComments:false runOnChange:true 
 
create or replace function F_F24_TARI_TEFA
(a_riga                number
,a_importo_tari        number
,a_num_fabb_tari       number
,a_importo_tefa        number
)
return varchar2
is
w_tari             varchar2(19);
w_tefa             varchar2(19);
TYPE type_riga IS TABLE OF varchar2(19)
INDEX BY binary_integer;
t_riga       type_riga;
i            binary_integer := 1;
begin
   w_tari := '3944'||to_char(round(a_importo_tari,0),'999999990')||to_char(a_num_fabb_tari,'990');
   w_tefa := 'TEFA'||to_char(round(a_importo_tefa,0),'999999990');
   if nvl(a_importo_tari,0) > 0.49 then
      t_riga(to_char(i)) := w_tari;
      i := i+1;
   end if;
   if nvl(a_importo_tefa,0) > 0.49 then
      t_riga(to_char(i)) := w_tefa;
      i := i+1;
   end if;
   return t_riga(to_char(a_riga));
end;
/* End Function: F_F24_TARI_TEFA */
/

