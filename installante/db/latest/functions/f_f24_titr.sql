--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_titr stripComments:false runOnChange:true 
 
create or replace function F_F24_TITR
(a_riga                 number
,a_ab_comu              number
,a_rurali_comu          number
,a_terreni_comu         number
,a_terreni_erar         number
,a_aree_comu            number
,a_aree_erar            number
,a_altri_comu           number
,a_altri_erar           number
,a_num_fabb_ab          number
,a_num_fabb_rurali      number
,a_num_fabb_altri       number
,a_fabbricati_d_comu    number default null
,a_fabbricati_d_erar    number default null
,a_num_fabb_d           number default null
,a_fabbricati_merce     number default null
,a_num_fabb_merce       number default null
,a_sanzioni             number default null
,a_interessi            number default null
,a_titr                 varchar2 default 'ICI'
)
  return varchar2
is
  w_ritorno   varchar2(3000);
begin
  if a_titr = 'ICI' then
    w_ritorno      :=
      f_f24_imu(a_riga
                ,a_ab_comu
                ,a_rurali_comu
                ,a_terreni_comu
                ,a_terreni_erar
                ,a_aree_comu
                ,a_aree_erar
                ,a_altri_comu
                ,a_altri_erar
                ,a_num_fabb_ab
                ,a_num_fabb_rurali
                ,a_num_fabb_altri
                ,a_fabbricati_d_comu
                ,a_fabbricati_d_erar
                ,a_num_fabb_d
                ,a_fabbricati_merce
                ,a_num_fabb_merce
                ,a_sanzioni
                ,a_interessi
                );
  elsif a_titr = 'TASI' then
    w_ritorno      :=
      f_f24_tasi(a_riga
                ,a_ab_comu
                ,a_rurali_comu
                ,a_terreni_comu
                ,a_terreni_erar
                ,a_aree_comu
                ,a_aree_erar
                ,a_altri_comu
                ,a_altri_erar
                ,a_num_fabb_ab
                ,a_num_fabb_rurali
                ,a_num_fabb_altri
                ,a_fabbricati_d_comu
                ,a_fabbricati_d_erar
                ,a_num_fabb_d
                ,a_sanzioni
                ,a_interessi
                );
  end if;
  return w_ritorno;
end;
/* End Function: F_F24_TITR */
/

