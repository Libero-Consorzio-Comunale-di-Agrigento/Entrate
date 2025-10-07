--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_vers_as stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_VERS_AS
/*************************************************************************
 NOME:        F_IMPORTO_VERS_AS
 DESCRIZIONE: Determina il totale dei versamenti per contribuente, anno,
              tipo_tributo e tipologia versamento passati.
              Se si indica la pratica vengono trattati solo i versamenti
              relativi alla pratica data.
              Se la pratica non è indicata, si totalizzano i versamenti
              privi di pratica oppure i versamenti su dichiarazione per
              TOSAP e ICP.
           UTILIZZATA NELLA FUNZIONE CHECK_RAVVEDIMENTO che serve a
           determinare lo scostamento tra il versato su ravvedimento
           e l'imposta dovuta.
 PARAMETRI:   a_cod_fiscale       Codice fiscale del contribuente da
                                  trattare
              a_anno              Anno di riferimento
              a_tipo_tributo      Tipo tributo da trattare
              a_tipo_versamento   Tipo versamento da considerare:
                                  A - Acconto
                                  S - Saldo
                                  Null - Totale annuo
 RITORNA:     number              Totale versamenti
 NOTE:
 Rev.    Date         Author      Note
 000     11/05/2020   VD          Prima emissione
*************************************************************************/
( a_cod_fiscale                   in varchar2
, a_anno                          in number
, a_tipo_tributo                  in varchar2
, a_tipo_versamento               in varchar2
) return number
is
  nImporto                        number;
  nConta                          number;
BEGIN
   BEGIN
     select sum(nvl(vers.importo_versato,0))
          , count(*)
       into nImporto
          , nConta
       from versamenti       vers
      where vers.cod_fiscale    = a_cod_fiscale
        and vers.tipo_tributo   = a_tipo_tributo
        and vers.anno           = a_anno
        and (a_tipo_versamento = 'U'
            or (    a_tipo_versamento = 'A'
                and nvl(vers.tipo_versamento,'U') in ('A','U')
               )
            or (    a_tipo_versamento = 'S'
                and nvl(vers.tipo_versamento,'U') = 'S'
               )
            )
        and (vers.pratica       is null or
            (vers.pratica is not null and exists
            (select 'x' from pratiche_tributo prtr
              where prtr.pratica = vers.pratica
                and prtr.anno = vers.anno
                and prtr.tipo_tributo in ('TOSAP','ICP')
                and prtr.tipo_pratica = 'D')))
         ;
      if nConta = 0 then
         raise no_data_found;
      end if;
   exception
      when no_data_found then
         nimporto := 0;
   end;
   return nImporto;
end;
/* End Function: F_IMPORTO_VERS_AS */
/

