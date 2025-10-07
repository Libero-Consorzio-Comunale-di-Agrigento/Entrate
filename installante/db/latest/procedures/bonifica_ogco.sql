--liquibase formatted sql 
--changeset abrandolini:20250326_152423_bonifica_ogco stripComments:false runOnChange:true 
 
create or replace procedure BONIFICA_OGCO
IS
sTitr_Prec  varchar2(6);
sCofi_Prec  varchar2(16);
nRif_Prec   number;
dData_Prec  date;
sTipr_Prec  varchar2(1);
sTiev_Prec  varchar2(1);
sCofi       varchar2(16);
nRif        number;
nOgpr       number;
sOcc        varchar2(1);
nOgge       number;
nPrtr       number;
dDapr       date;
sTipr       varchar2(1);
sTiev       varchar2(1);
dDal        date;
dAl         date;
sTitr       varchar2(6);
dData       date;
sInsert     varchar2(2);
cursor sel_ogco is
select ogco.cod_fiscale               cofi
      ,nvl(ogpr.oggetto_pratica_rif
          ,ogpr.oggetto_pratica
          )                           rif
      ,ogco.oggetto_pratica           ogpr
      ,nvl(ogpr.tipo_occupazione,'P') occ
      ,ogpr.oggetto                   ogge
      ,prtr.pratica                   prtr
      ,prtr.data                      dapr
      ,prtr.tipo_pratica              tipr
      ,prtr.tipo_evento               tiev
      ,ogco.data_decorrenza           dal
      ,ogco.data_cessazione           al
      ,prtr.tipo_tributo              titr
      ,nvl(ogco.data_decorrenza
          ,nvl(ogco.data_cessazione
              ,to_date('01011900','ddmmyyyy')
              )
          )                           data
  from oggetti_contribuente           ogco
      ,oggetti_pratica                ogpr
      ,pratiche_tributo               prtr
 where prtr.pratica                 = ogpr.pratica
   and ogpr.oggetto_pratica         = ogco.oggetto_pratica
   and prtr.tipo_tributo||''       in ('ICP','TARSU','TOSAP')
   and prtr.tipo_pratica||''       in ('D','A')
   and prtr.tipo_evento||''        <> 'U'
   and decode(prtr.tipo_pratica
             ,'A',nvl(ogco.data_decorrenza,ogco.data_cessazione)
                 ,nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy'))
             )                     is not null
   and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                    = 'S'
   and ogpr.flag_contenzioso       is null
 order by
       prtr.tipo_tributo
      ,ogco.cod_fiscale
      ,nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
      ,nvl(ogco.data_decorrenza,nvl(ogco.data_cessazione,to_date('01011900','ddmmyyyy')))
      ,nvl(prtr.data,to_date('01011900','ddmmyyyy'))
      ,prtr.pratica
      ,ogpr.oggetto_pratica
;
begin
   delete from wrk_bonifica_ogco;
   insert into wrk_bonifica_ogco
         (tipo_tributo,cod_fiscale,oggetto_pratica_rif)
   values('DATA',to_char(trunc(sysdate),'dd/mm/yyyy'),0)
   ;
   open sel_ogco;
   fetch sel_ogco into sCofi,nRif,nOgpr,sOcc,nOgge,nPrtr,dDapr,
                       sTipr,sTiev,dDal,dAl,sTitr,dData;
   if sel_ogco%FOUND then
      sInsert      := 'SI';
      sCofi_Prec   := sCofi;
      nRif_Prec    := nRif;
      sTitr_Prec   := sTitr;
      sTiev_Prec   := sTiev;
      dData_Prec   := dData;
      if sTiev in ('V','C') then
         if sInsert = 'SI' then
            insert into wrk_bonifica_ogco
                  (tipo_tributo,cod_fiscale,oggetto_pratica_rif)
            values(sTitr,sCofi,nRif)
            ;
            sInsert := 'NO';
         end if;
      end if;
      loop
         fetch sel_ogco into sCofi,nRif,nOgpr,sOcc,nOgge,nPrtr,dDapr,
                             sTipr,sTiev,dDal,dAl,sTitr,dData;
         exit when sel_ogco%NOTFOUND;
         if sCofi   <> sCofi_Prec
         or nRif    <> nRif_Prec
         or sTitr   <> sTitr_Prec then
            sCofi_Prec   := sCofi;
            nRif_Prec    := nRif;
            sTitr_Prec   := sTitr;
            sTiev_Prec   := sTiev;
            dData_Prec   := dData;
            sInsert      := 'SI';
            if sTiev in ('V','C') then
               if sInsert = 'SI' then
                  insert into wrk_bonifica_ogco
                        (tipo_tributo,cod_fiscale,oggetto_pratica_rif)
                  values(sTitr,sCofi,nRif)
                  ;
                  sInsert := 'NO';
               end if;
            end if;
         else
            if sInsert = 'SI' then
               if dData = dData_Prec and sTiev <> 'C' then
                  if sTiev_Prec = 'I' and sTiev = 'V' then
                     null;
                  else
                     insert into wrk_bonifica_ogco
                          (tipo_tributo,cod_fiscale,oggetto_pratica_rif)
                     values(sTitr,sCofi,nRif)
                     ;
                     sInsert := 'NO';
                  end if;
               else
                  if sTiev = 'I' and sTiev_Prec in ('V','C')
                  or sTiev = 'V' and sTiev_Prec in ('C')          then
                     insert into wrk_bonifica_ogco
                          (tipo_tributo,cod_fiscale,oggetto_pratica_rif)
                     values(sTitr,sCofi,nRif)
                     ;
                     sInsert := 'NO';
                  end if;
               end if;
            end if;
         end if;
         dData_Prec := dData;
         sTiev_Prec := sTiev;
      end loop;
   end if;
   close sel_ogco;
   commit;
exception
   when others then
      rollback;
      raise_application_error(-20999,to_char(SQLCODE)||' - '||SQLERRM);
end;
/* End Procedure: BONIFICA_OGCO */
/

