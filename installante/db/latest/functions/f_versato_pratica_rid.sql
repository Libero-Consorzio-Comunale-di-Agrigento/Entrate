--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_versato_pratica_rid stripComments:false runOnChange:true 
 
create or replace function F_VERSATO_PRATICA_RID
(a_pratica              in number
) Return number is
nImporto                   number;
nConta                     number;
BEGIN
   BEGIN
         select sum(nvl(vers.importo_versato,0))
              , count(*)
           into nImporto
              , nConta
           from versamenti        vers
              , pratiche_tributo  prtr
          where prtr.pratica     = vers.pratica
            and prtr.pratica     = a_pratica
            and nvl(trunc(vers.data_pagamento),trunc(prtr.data_notifica))
                - trunc(prtr.data_notifica) - 60   > 0
         ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nImporto := 0;
         nConta   := 0;
   END;
   Return nImporto;
END;
/* End Function: F_VERSATO_PRATICA_RID */
/

