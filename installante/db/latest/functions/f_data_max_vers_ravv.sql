--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_data_max_vers_ravv stripComments:false runOnChange:true 
 
create or replace function F_DATA_MAX_VERS_RAVV
(a_cod_fiscale          in varchar2
,a_tipo_tributo         in varchar2
,a_anno                 in number
,a_tipo_versamento      in varchar2
) Return date is
dDataVersamento   date;
BEGIN
      BEGIN
         select max(vers.data_pagamento)
           into dDataVersamento
           from versamenti vers
              , pratiche_tributo prtr
          where vers.pratica = prtr.pratica
            and prtr.tipo_pratica = 'V'
            and prtr.tipo_tributo||''  = a_tipo_tributo
            and prtr.anno              = a_anno
            and prtr.tipo_pratica      = 'V'
            and prtr.cod_fiscale       = a_cod_fiscale
            and prtr.NUMERO            is not null
            and (a_tipo_versamento = 'U'
                or (    a_tipo_versamento = 'A'
                    and nvl(vers.tipo_versamento,'U') in ('A','U')
                   )
                or (    a_tipo_versamento = 'S'
                    and nvl(vers.tipo_versamento,'U') = 'S'
                   )
                )
              ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            dDataVersamento  := null;
         WHEN others THEN
            dDataVersamento := null;
      END;
   Return dDataVersamento;
EXCEPTION
  WHEN others THEN
       RAISE_APPLICATION_ERROR (-20999,'Errore in Calcolo Data Versamenti Ravv'||'('||SQLERRM||')');
END;
/* End Function: F_DATA_MAX_VERS_RAVV */
/

