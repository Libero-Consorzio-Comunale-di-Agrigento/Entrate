--liquibase formatted sql 
--changeset abrandolini:20250326_152438_F_GET_CODICE_F24 stripComments:false runOnChange:true 
 
--	Creata il: 	17/04/2023

create or replace function F_GET_CODICE_F24
(p_tipo_oggetto     number,
 p_tipo_tributo     varchar2,
 p_tipo_aliquota    varchar2,
 p_anno             number
 )
  return varchar2
is
  w_codice                  varchar2(8);
  w_flag_ab_principale      varchar2(1);
  w_flag_fabbricati_merce   varchar2(1);
BEGIN
  if p_tipo_tributo = 'ICI' then
     if p_tipo_oggetto = 1 then
        w_codice := '3914'||'3915';
     elsif p_tipo_oggetto = 2 then
        w_codice := '3916'||'3917';
     else
         begin
           select flag_ab_principale, flag_fabbricati_merce 
             into w_flag_ab_principale, w_flag_fabbricati_merce
             from aliquote
            where tipo_tributo  = p_tipo_tributo
              and anno          = p_anno
              and tipo_aliquota = p_tipo_aliquota
           ;
         EXCEPTION
           when others then null;
         end;
         if w_flag_ab_principale = 'S' then
            w_codice := '3912'; 
         elsif w_flag_fabbricati_merce = 'S' then
            w_codice := '3939'; 
         end if;
     end if;
  end if;
--     w_ab_comu           := '3912'
--     w_rurali_comu       := '3913';
--     w_terreni_comu      := '3914';
--     w_terreni_erar      := '3915';
--     w_aree_comu         := '3916';
--     w_aree_erar         := '3917';
--     w_altri_comu        := '3918';
--     w_altri_erar        := '3919';
--     w_fabbricati_d_comu := '3930';
--     w_fabbricati_d_erar := '3925';
--     w_fabbricati_merce  := '3939';
     
  return w_codice;
  
EXCEPTION
  when others then return null;
END;
/* End Function: F_GET_CODICE_F24 */
/
