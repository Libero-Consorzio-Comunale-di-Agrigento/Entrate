--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_ingiunzione stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_INGIUNZIONE
(a_pratica              in number
,a_tipo                 in varchar2
) Return number is
nImporto                   number;
nConta                     number;
nImporto_arr               number;
BEGIN
   BEGIN
         select sum(nvl(f_importo_acc_lordo(prtr.pratica,'N'),0))
              , sum(nvl(
                     decode(nvl(nvl(titr.flag_tariffa,titr.flag_canone),'N')||to_char(sign(trunc(prtr.DATA_NOTIFICA) - to_date('31122006','ddmmyyyy')))
                           ,'N1',ROUND(f_importo_acc_lordo(prtr.pratica,'N'),0)
                           ,ROUND(f_importo_acc_lordo(prtr.pratica,'N'),2)
                           )
                        ,0)
                    )
               ,count(*)
           into nImporto
               ,nImporto_arr
               ,nConta
           from pratiche_tributo       prtr
              , tipi_tributo           titr
          where prtr.pratica_rif    = a_pratica
            and prtr.tipo_tributo||'' = titr.tipo_tributo||''
         ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nImporto     := 0;
         nImporto_arr := 0;
         nConta       := 0;
   END;
   if a_tipo = 'ARR' then
      Return nImporto_arr;
   else
      Return nImporto;
   end if;
END;
/* End Function: F_IMPORTO_INGIUNZIONE */
/

