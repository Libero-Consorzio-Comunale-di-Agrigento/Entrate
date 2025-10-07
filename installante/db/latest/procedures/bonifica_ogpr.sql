--liquibase formatted sql 
--changeset abrandolini:20250326_152423_bonifica_ogpr stripComments:false runOnChange:true 
 
create or replace procedure BONIFICA_OGPR
IS
nOgpr           number;
nOgpr_Rif       number;
cursor sel_ogpr is
select ogpr.oggetto_pratica
      ,ogpr.oggetto_pratica_rif
      ,prtr.tipo_tributo
  from oggetti_pratica  ogpr
      ,pratiche_tributo prtr
 where prtr.pratica = ogpr.pratica
   and prtr.tipo_tributo||'' in ('ICP','TARSU','TOSAP')
   and ogpr.oggetto_pratica_rif is not null
;
begin
   delete from wrk_bonifica_ogpr;
   for rec_ogpr in sel_ogpr
   loop
      nOgpr_Rif := rec_ogpr.oggetto_pratica_rif;
      loop
         begin
            select oggetto_pratica
                  ,oggetto_pratica_rif
              into nOgpr
                  ,nOgpr_Rif
              from oggetti_pratica
             where oggetto_pratica = nOgpr_Rif
            ;
         exception
            when no_data_found then
               nOgpr := null;
               exit;
         end;
         if nOgpr_Rif is null then
            exit;
         end if;
      end loop;
      if nvl(rec_ogpr.oggetto_pratica_rif,0) <> nvl(nOgpr,0) then
         insert into wrk_bonifica_ogpr
               (oggetto_pratica,oggetto_pratica_rif)
         values(rec_ogpr.oggetto_pratica,rec_ogpr.oggetto_pratica_rif)
         ;
         update oggetti_pratica
            set oggetto_pratica_rif = nOgpr
          where oggetto_pratica = rec_ogpr.oggetto_pratica
         ;
      end if;
   end loop;
   commit;
exception
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||SQLERRM);
end;
/* End Procedure: BONIFICA_OGPR */
/

