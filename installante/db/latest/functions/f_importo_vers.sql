--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_vers stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_VERS
/*************************************************************************
 NOME:        F_IMPORTO_VERS
 DESCRIZIONE: Determina il totale dei versamenti per contribuente, anno e
              tipo_tributo passati. Se si indica la pratica vengono
              trattati solo i versamenti relativi alla pratica data.
              Se la pratica non è indicata, si totalizzano i versamenti
              privi di pratica oppure i versamenti su dichiarazione per
              TOSAP, ICP e CUNI.
 PARAMETRI:   Codice fiscale
              Tipo tributo
              Anno
              Pratica
              Sequenza versamento
 RITORNA:     number              Totale versamenti
 NOTE:
 Rev.    Date         Author      Note
 3       18/02/2022   RV          Rivisto caso parametro pratica null :
                                  ora prende i versamenti su pratica 'D' del
                                  tributo richiesto, ma solo per TOSAP, ICP o CUNI
 2       09/04/2019   VD          Corretta selezione versamenti con
                                  parametro pratica null: ora totalizza
                                  anche i versamenti relativi a pratiche
                                  di tipo "D" (denunce) TOSAP e ICP.
 1       08/11/2016   AB          Corretta selezione versamenti
                                  con parametro pratica null
*************************************************************************/
(a_cod_fiscale          in varchar2
,a_tipo_tributo         in varchar2
,a_anno                 in number
,a_pratica              in number
) Return number is
nImporto                   number;
nConta                     number;
BEGIN
   BEGIN
      if a_pratica is not null then
         select sum(nvl(vers.importo_versato,0))
               ,count(*)
           into nImporto
               ,nConta
           from versamenti       vers
          where vers.cod_fiscale    = a_cod_fiscale
            and vers.tipo_tributo   = a_tipo_tributo
            and vers.anno           = a_anno
            and vers.pratica        = a_pratica
         ;
      else
         select sum(nvl(vers.importo_versato,0))
               ,count(*)
           into nImporto
               ,nConta
           from versamenti       vers
           --  ,pratiche_tributo prtr
          where vers.cod_fiscale    = a_cod_fiscale
            and vers.tipo_tributo   = a_tipo_tributo
            and vers.anno           = a_anno
            --  and prtr.pratica (+)    = vers.pratica
            and (vers.pratica       is null or
                (vers.pratica is not null and exists
                (select 'x' from pratiche_tributo prtr
                  where prtr.pratica = vers.pratica
                    and prtr.anno = vers.anno
                    and prtr.tipo_tributo = a_tipo_tributo
                    and a_tipo_tributo in ('TOSAP','ICP','CUNI')
                    and prtr.tipo_pratica = 'D')))
         ;
      end if;
      if nConta = 0 then
         RAISE NO_DATA_FOUND;
      end if;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nImporto := 0;
   END;
   Return nImporto;
END;
/* End Function: F_IMPORTO_VERS */
/

