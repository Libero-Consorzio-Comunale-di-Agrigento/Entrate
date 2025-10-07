--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_omesso_tardivo stripComments:false runOnChange:true 
 
create or replace function F_OMESSO_TARDIVO
(a_pratica        in number
)
return string is
nConta            number;
dData_Notifica    date;
nTardivo          number;
nVersato          number;
nImporto          number;
BEGIN
   BEGIN
      select nvl(sum(decode(sign(vers.data_pagamento
                                 - (prtr.data_notifica
                                    + decode(prtr.tipo_tributo
                                            ,'ICI',decode(sign(trunc(prtr.data_notifica)
                                                                - to_date('31122006','ddmmyyyy')
                                                              )
                                                         ,1,60
                                                         ,90
                                                         )
                                            ,60
                                            )
                                    )
                                )
                           ,1,nvl(vers.importo_versato,0)
                           ,0
                           )
                    ),0
                )
            ,nvl(sum(nvl(vers.importo_versato,0)),0)
            ,nvl(max(nvl(prtr.importo_totale,0)),0)
        into nTardivo
            ,nVersato
            ,nImporto
        from versamenti       vers
            ,pratiche_tributo prtr
       where vers.pratica (+)        = prtr.pratica
         and prtr.pratica            = a_pratica
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nTardivo := 0;
         nVersato := 0;
         nImporto := 0;
      WHEN OTHERS THEN
         Return null;
   END;
   if nVersato = 0 then
      Return 'O';
   end if;
   if nVersato < nImporto then
      Return 'P';
   end if;
   if nTardivo > 0 then
      Return 'T';
   end if;
   Return null;
END;
/* End Function: F_OMESSO_TARDIVO */
/

