--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_versato_ingiunzione stripComments:false runOnChange:true 
 
create or replace function F_VERSATO_INGIUNZIONE
(a_pratica              in number
) Return number is
nImporto                   number;
nConta                     number;
data_notifica_ing          date;
BEGIN
   begin
      select nvl(data_notifica,to_date('31122999','ddmmyyyy'))
        into data_notifica_ing
        from pratiche_tributo
       where pratica = a_pratica
        ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         data_notifica_ing := to_date('31122999','ddmmyyyy');
   END;
   BEGIN
         select nvl(sum(nvl(vers.importo_versato,0)),0)
               ,count(*)
           into nImporto
               ,nConta
           from versamenti        vers
              , pratiche_tributo  prtr
          where prtr.pratica_rif    = a_pratica
            and vers.pratica        = prtr.pratica
            and vers.data_pagamento <= data_notifica_ing
         ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nImporto := 0;
         nConta   := 0;
   END;
   Return nImporto;
END;
/* End Function: F_VERSATO_INGIUNZIONE */
/

