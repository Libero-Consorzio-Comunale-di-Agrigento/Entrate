--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_imposta_pratica stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_IMPOSTA_PRATICA
(a_anno                 IN number
,a_cod_fiscale          IN varchar2
,a_tipo_tributo         IN varchar2
,a_ogpr                 IN number
,a_utente               IN varchar2
,a_flag_normalizzato    IN char
,a_flag_richiamo        IN varchar2
,a_chk_rate             IN number
,a_limite               IN number
,a_pratica              IN number
)
IS
begin
  CALCOLO_IMPOSTA(a_anno,a_cod_fiscale,a_tipo_tributo,a_ogpr
                 ,a_utente,a_flag_normalizzato,a_flag_richiamo
                 ,a_chk_rate,a_limite,a_pratica);
end;
/* End Procedure: CALCOLO_IMPOSTA_PRATICA */
/

