--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_esiste_detrazione_ogco stripComments:false runOnChange:true 
 
create or replace function F_ESISTE_DETRAZIONE_OGCO
(a_oggetto_pratica   in number
,a_cod_fiscale       in varchar2
,a_tipo_tributo      in varchar2
) return varchar2
is
nConta     number;
BEGIN
  begin
    select count(1)
      into nConta
      from detrazioni_ogco deog
     where deog.oggetto_pratica = a_oggetto_pratica
       and deog.cod_fiscale     = a_cod_fiscale
       and deog.tipo_tributo    = a_tipo_tributo
         ;
  EXCEPTION
     WHEN no_data_found THEN
     nConta := 0;
  END;
  if nConta > 0 then
     return 'S';
  else
    return null;
  end if;
END;
/* End Function: F_ESISTE_DETRAZIONE_OGCO */
/

