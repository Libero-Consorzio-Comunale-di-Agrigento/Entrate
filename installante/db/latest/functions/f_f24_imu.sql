--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_imu stripComments:false runOnChange:true 
 
create or replace function F_F24_IMU
(a_riga                number
,a_ab_comu             number
,a_rurali_comu         number
,a_terreni_comu        number
,a_terreni_erar        number
,a_aree_comu           number
,a_aree_erar           number
,a_altri_comu          number
,a_altri_erar          number
,a_num_fabb_ab         number
,a_num_fabb_rurali     number
,a_num_fabb_altri      number
,a_fabbricati_d_comu   number default null
,a_fabbricati_d_erar   number default null
,a_num_fabb_d          number default null
,a_fabbricati_merce    number default null
,a_num_fabb_merce      number default null
,a_sanzioni            number default null
,a_interessi           number default null
)
return varchar2
is
w_ab_comu            varchar2(19);
w_rurali_comu        varchar2(19);
w_terreni_comu       varchar2(19);
w_terreni_erar       varchar2(19);
w_aree_comu          varchar2(19);
w_aree_erar          varchar2(19);
w_altri_comu         varchar2(19);
w_altri_erar         varchar2(19);
w_fabbricati_d_comu  varchar2(19);
w_fabbricati_d_erar  varchar2(19);
w_fabbricati_merce   varchar2(19);
w_interessi          varchar2(19);
w_sanzioni           varchar2(19);
w_ab_valore number;
TYPE type_riga IS TABLE OF varchar2(19)
INDEX BY binary_integer;
t_riga       type_riga;
i            binary_integer := 1;
begin
   w_ab_comu           := '3912'||to_char(round(a_ab_comu,0),'999999990')||to_char(a_num_fabb_ab,'990');
   w_rurali_comu       := '3913'||to_char(round(a_rurali_comu,0),'99999990')||to_char(a_num_fabb_rurali,'990');
   w_terreni_comu      := '3914'||to_char(round(a_terreni_comu,0),'999999990');
   w_terreni_erar      := '3915'||to_char(round(a_terreni_erar,0),'999999990');
   w_aree_comu         := '3916'||to_char(round(a_aree_comu,0),'999999990');
   w_aree_erar         := '3917'||to_char(round(a_aree_erar,0),'999999990');
   w_altri_comu        := '3918'||to_char(round(a_altri_comu,0),'999999990')||to_char(a_num_fabb_altri,'990');
   w_altri_erar        := '3919'||to_char(round(a_altri_erar,0),'999999990')||to_char(a_num_fabb_altri,'990');
   w_fabbricati_d_comu := '3930'||to_char(round(a_fabbricati_d_comu,0),'999999990')||to_char(a_num_fabb_d,'990');
   w_fabbricati_d_erar := '3925'||to_char(round(a_fabbricati_d_erar,0),'999999990')||to_char(a_num_fabb_d,'990');
   w_fabbricati_merce  := '3939'||to_char(round(a_fabbricati_merce,0),'999999990')||to_char(a_num_fabb_merce,'990');
   w_interessi         := '3923'||to_char(round(a_interessi,0),'999999990')||to_char(a_num_fabb_altri,'990');
   w_sanzioni          := '3924'||to_char(round(a_sanzioni,0),'999999990')||to_char(a_num_fabb_altri,'990');
--   if to_char(sysdate,'yyyymm') < '201308' then
--      w_ab_valore := 0;
--   else
      w_ab_valore := a_ab_comu;
--   end if;
   if nvl(round(w_ab_valore,0),0) > 0 then
      t_riga(to_char(i)) := w_ab_comu;
      i := i+1;
   end if;
   if nvl(round(a_rurali_comu,0),0) > 0 then
      t_riga(to_char(i)) := w_rurali_comu;
      i := i+1;
   end if;
   if nvl(round(a_terreni_comu,0),0) > 0 then
      t_riga(to_char(i)) := w_terreni_comu;
      i := i+1;
   end if;
   if nvl(round(a_terreni_erar,0),0) > 0 then
      t_riga(to_char(i)) := w_terreni_erar;
      i := i+1;
   end if;
   if nvl(round(a_aree_comu,0),0) > 0 then
      t_riga(to_char(i)) := w_aree_comu;
      i := i+1;
   end if;
   if nvl(round(a_aree_erar,0),0) > 0 then
      t_riga(to_char(i)) := w_aree_erar;
      i := i+1;
   end if;
   if nvl(round(a_altri_comu,0),0) > 0 then
      t_riga(to_char(i)) := w_altri_comu;
      i := i+1;
   end if;
   if nvl(round(a_altri_erar,0),0) > 0 then
      t_riga(to_char(i)) := w_altri_erar;
      i := i+1;
   end if;
   if nvl(round(a_fabbricati_d_comu,0),0) > 0 then
      t_riga(to_char(i)) := w_fabbricati_d_comu;
      i := i+1;
   end if;
   if nvl(round(a_fabbricati_d_erar,0),0) > 0 then
      t_riga(to_char(i)) := w_fabbricati_d_erar;
      i := i+1;
   end if;
   if nvl(round(a_fabbricati_merce,0),0) > 0 then
      t_riga(to_char(i)) := w_fabbricati_merce;
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
/* End Function: F_F24_IMU */
/

