--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_ici stripComments:false runOnChange:true 
 
create or replace function F_F24_ICI
(a_riga             number
,a_ab               number
,a_terreni          number
,a_aree             number
,a_altri            number
,a_interessi        number
,a_sanzioni         number
,a_num_fabb_ab      number
,a_num_fabb_altri   number
)
return varchar2
is
w_ab         varchar2(19);
w_terreni    varchar2(19);
w_aree       varchar2(19);
w_altri      varchar2(19);
w_interessi  varchar2(19);
w_sanzioni   varchar2(19);
TYPE type_riga IS TABLE OF varchar2(19)
INDEX BY binary_integer;
t_riga       type_riga;
i            binary_integer := 1;
begin
   w_ab        := '3940'||to_char(round(a_ab,0),'999999990')||to_char(a_num_fabb_ab,'990');
   w_terreni   := '3941'||to_char(round(a_terreni,0),'999999990');
   w_aree      := '3942'||to_char(round(a_aree,0),'999999990');
   w_altri     := '3943'||to_char(round(a_altri,0),'999999990')||to_char(a_num_fabb_altri,'990');
   w_interessi := '3906'||to_char(round(a_interessi,0),'999999990');
   w_sanzioni  := '3907'||to_char(round(a_sanzioni,0),'999999990');
   if nvl(round(a_ab,0),0) > 0 then
      t_riga(to_char(i)) := w_ab;
      i := i+1;
   end if;
   if nvl(round(a_terreni,0),0) > 0 then
      t_riga(to_char(i)) := w_terreni;
      i := i+1;
   end if;
   if nvl(round(a_aree,0),0) > 0 then
      t_riga(to_char(i)) := w_aree;
      i := i+1;
   end if;
   if nvl(round(a_altri,0),0) > 0 then
      t_riga(to_char(i)) := w_altri;
      i := i+1;
   end if;
   if nvl(round(a_interessi,0),0) > 0 then
      t_riga(to_char(i)) := w_interessi;
      i := i+1;
   end if;
   if nvl(round(a_sanzioni,0),0) > 0 then
      t_riga(to_char(i)) := w_sanzioni;
      i := i+1;
   end if;
   return t_riga(to_char(a_riga));
end;
/* End Function: F_F24_ICI */
/

