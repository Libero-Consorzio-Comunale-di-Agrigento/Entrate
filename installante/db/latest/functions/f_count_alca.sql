--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_count_alca stripComments:false runOnChange:true 
 
create or replace function F_COUNT_ALCA
(a_anno             in number
,a_tipo_aliquota    in varchar2
,a_tipo_tributo     in varchar2
) return number
is
nConta     number;
BEGIN
  begin
    select count(1)
      into nConta
      from aliquote_categoria alca
     where alca.anno          = a_anno
       and alca.tipo_aliquota = a_tipo_aliquota
       and alca.tipo_tributo  = a_tipo_tributo
         ;
  EXCEPTION
     WHEN no_data_found THEN
     nConta := 0;
  END;
return nConta;
END;
/* End Function: F_COUNT_ALCA */
/

