--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_denuncia_doppia stripComments:false runOnChange:true 
 
create or replace function F_DENUNCIA_DOPPIA
( a_pratica   in number
, a_cod_fiscale in varchar2
) return varchar2
is
nConta     number;
cursor sel_ogco (p_pratica number, p_cod_fiscale varchar2) is
select ogco.cod_fiscale
     , prtr.anno
     , ogpr.oggetto
     , prtr.tipo_tributo
  from pratiche_tributo     prtr
     , oggetti_pratica      ogpr
     , oggetti_contribuente ogco
 where ogpr.oggetto_pratica = ogco.oggetto_pratica
   and prtr.pratica         = ogpr.pratica
   and prtr.pratica         = p_pratica
   and ogco.cod_fiscale     = p_cod_fiscale
   and prtr.tipo_pratica    = 'D'
;
BEGIN
   FOR rec_ogco IN sel_ogco(a_pratica, a_cod_fiscale)
   LOOP
      begin
         select count(1)
           into nConta
           from ( select prtr.pratica
                    from pratiche_tributo      prtr
                       , oggetti_pratica       ogpr
                       , oggetti_contribuente  ogco
                   where prtr.pratica = ogpr.pratica
                     and ogpr.oggetto_pratica = ogco.oggetto_pratica
                     and prtr.tipo_pratica    = 'D'
                     and prtr.anno        = rec_ogco.anno
                     and ogpr.oggetto     = rec_ogco.oggetto
                     and ogco.cod_fiscale = rec_ogco.cod_fiscale
                     and prtr.tipo_tributo||'' = rec_ogco.tipo_tributo
                  group by prtr.pratica
                )
              ;
      EXCEPTION
         WHEN no_data_found THEN
         nConta := 0;
      END;
      if nConta > 1 then
         return 'S';
      end if;
   end loop;
    return null;
END;
/* End Function: F_DENUNCIA_DOPPIA */
/

